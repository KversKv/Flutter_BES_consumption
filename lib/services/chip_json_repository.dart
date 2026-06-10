import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ble_chip.dart';
import '../models/bt_chip.dart';
import '../models/wifi_chip.dart';
import 'chip_backend_client.dart';
import 'config/config_repository.dart';
import 'earbuds_repository.dart';

enum ChipJsonDomain {
  ble('ble', 'BLE CASE'),
  bt('bt', 'BT CASE'),
  earbuds('earbuds/Scene', 'Earbuds Scene'),
  earbudsTx('earbuds/Tx', 'Earbuds TX'),
  earbudsRx('earbuds/Rx', 'Earbuds RX'),
  earbudsCpu('earbuds/CPU', 'Earbuds CPU'),
  wifi('wifi', 'Wi-Fi');

  final String key;
  final String label;

  const ChipJsonDomain(this.key, this.label);

  /// 是否使用 `index.json` 的 `order` 列表（earbuds 家族）而非 `items`。
  bool get usesOrderIndex =>
      this == earbuds ||
      this == earbudsTx ||
      this == earbudsRx ||
      this == earbudsCpu;
}

class ChipJsonRecord {
  Map<String, dynamic> data;

  ChipJsonRecord(Map<String, dynamic> source)
      : data = _normalizeMap(Map<String, dynamic>.from(source));

  String get id => (data['id'] ?? '').toString();

  set id(String value) => data['id'] = value;

  ChipJsonRecord cloneWithId(String id) {
    final jsonText = jsonEncode(data);
    final clone = ChipJsonRecord(
      Map<String, dynamic>.from(jsonDecode(jsonText) as Map),
    );
    clone.id = id;
    return clone;
  }

  static Map<String, dynamic> _normalizeMap(Map<String, dynamic> source) {
    final out = <String, dynamic>{};
    for (final entry in source.entries) {
      out[entry.key] = _normalizeValue(entry.value);
    }
    return out;
  }

  static dynamic _normalizeValue(dynamic value) {
    if (value is Map) {
      return _normalizeMap(Map<String, dynamic>.from(value));
    }
    if (value is List) {
      return value.map(_normalizeValue).toList();
    }
    return value;
  }
}

/// `update()` 返回的细分结果，便于 UI 显示精准的错误提示。
enum ChipUpdateResult {
  success,
  idEmpty,
  idDuplicate,
  notFound,
}

class ChipJsonRepository extends ChangeNotifier {
  ChipJsonRepository._();

  static final ChipJsonRepository instance = ChipJsonRepository._();

  /// 新增芯片时的占位 ID。该 ID 仅用于 admin 编辑器内填值；
  /// 不应出现在任何用户可见列表（Comparison / 校验池）。
  /// 用户把它改成有效 ID 后才视为"真正存在"。
  static const String placeholderId = 'chip_new';

  static const int _schemaVersion = 1;
  static const String _storagePrefix = 'admin_chip_json_db_v2_';

  final Map<ChipJsonDomain, List<ChipJsonRecord>> _records = {
    for (final domain in ChipJsonDomain.values) domain: <ChipJsonRecord>[],
  };

  bool _loaded = false;
  ChipJsonDomain? _lastChangedDomain;
  int _revision = 0;

  /// 本次 load 是否成功从后端拉到了数据（决定 Save 是否能真正落地 JSON）。
  bool _backendActive = false;

  bool get isLoaded => _loaded;
  ChipJsonDomain? get lastChangedDomain => _lastChangedDomain;

  /// 数据修订号：每次结构性或字段写入（经 `_commit`）后自增，
  /// 供 UI 把它拼进编辑器 Key 以强制重建、重读最新 `record.data`。
  int get revision => _revision;

  /// 后端是否可用：true 时 Save 会写回服务器 JSON 源文件；false 时只能本地暂存。
  bool get isBackendActive => _backendActive;

  List<ChipJsonRecord> records(ChipJsonDomain domain) =>
      List.unmodifiable(_records[domain] ?? const <ChipJsonRecord>[]);

  ChipJsonRecord? recordById(ChipJsonDomain domain, String id) {
    for (final record in _records[domain] ?? const <ChipJsonRecord>[]) {
      if (record.id == id) return record;
    }
    return null;
  }

  Future<void> load() async {
    if (_loaded) return;

    // 优先从后端拉取 JSON 源文件，保证「每次打开从 JSON 加载」且与磁盘同步。
    final fromBackend = await _tryLoadFromBackend();
    if (fromBackend) {
      _loaded = true;
      _lastChangedDomain = null;
      notifyListeners();
      return;
    }

    // 后端不可用：回退到「本地存档 -> 资源种子」，并明确标记未与 JSON 同步。
    _backendActive = false;
    final sp = await SharedPreferences.getInstance();
    final loaded = await Future.wait(
      ChipJsonDomain.values.map((domain) async {
        return MapEntry(domain, await _loadDomain(domain, sp));
      }),
    );
    for (final entry in loaded) {
      _records[entry.key]!
        ..clear()
        ..addAll(entry.value);
    }
    for (final domain in ChipJsonDomain.values) {
      _applyDomain(domain);
    }
    _loaded = true;
    _lastChangedDomain = null;
    notifyListeners();
  }

  /// 尝试从后端拉取全部 chips JSON 并填充 `_records`。
  /// 成功返回 true（同时置 `_backendActive=true`），否则返回 false。
  Future<bool> _tryLoadFromBackend() async {
    final files = await ChipBackendClient.instance.fetchFiles();
    if (files == null || files.isEmpty) return false;
    try {
      for (final domain in ChipJsonDomain.values) {
        final records = _recordsFromBackendFiles(domain, files);
        if (records == null) continue;
        _records[domain]!
          ..clear()
          ..addAll(records);
      }
      for (final domain in ChipJsonDomain.values) {
        _applyDomain(domain);
      }
      _backendActive = true;
      return true;
    } catch (e, st) {
      debugPrint('[ChipJsonRepository] parse backend files failed: $e\n$st');
      return false;
    }
  }

  /// 把后端返回的 {相对路径: 内容} 解析为某个 domain 的记录列表，保持 index 顺序。
  /// 该 domain 无任何文件时返回 null（保留回退/原值）。
  List<ChipJsonRecord>? _recordsFromBackendFiles(
    ChipJsonDomain domain,
    Map<String, String> files,
  ) {
    final prefix = 'chips/${domain.key}/';
    final indexRaw = files['${prefix}index.json'];
    // 只取该 domain 目录下的"直系"文件：剥掉 prefix 后不能再含 '/'，
    // 防止后端 recursive 扫描时把更深层子目录文件误纳入本 domain。
    final domainFiles = <String, String>{
      for (final entry in files.entries)
        if (entry.key.startsWith(prefix) &&
            entry.key != '${prefix}index.json' &&
            !entry.key.substring(prefix.length).contains('/'))
          entry.key.substring(prefix.length): entry.value,
    };
    if (indexRaw == null && domainFiles.isEmpty) return null;

    final order = <_IndexEntry>[];
    if (indexRaw != null) {
      try {
        order.addAll(_indexEntries(jsonDecode(indexRaw), domain));
      } catch (_) {}
    }

    final out = <ChipJsonRecord>[];
    final consumed = <String>{};
    for (final entry in order) {
      final raw = domainFiles[entry.file];
      if (raw == null) continue;
      final record = _recordFromRaw(domain, raw, entry.id);
      if (record != null) {
        out.add(record);
        consumed.add(entry.file);
      }
    }
    // index 未覆盖到的孤立文件也纳入，避免漏数据；
    // 但 placeholder（chip_new）仅是 admin 临时占位，绝不能被当作"真实芯片"补回来。
    for (final fileEntry in domainFiles.entries) {
      if (consumed.contains(fileEntry.key)) continue;
      final record = _recordFromRaw(domain, fileEntry.value, null);
      if (record == null) continue;
      if (record.id == placeholderId) continue;
      out.add(record);
    }
    return out;
  }

  ChipJsonRecord? _recordFromRaw(
    ChipJsonDomain domain,
    String raw,
    String? fallbackId,
  ) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final data = _canonicalData(domain, Map<String, dynamic>.from(decoded));
      if (fallbackId != null) data['id'] ??= fallbackId;
      final record = ChipJsonRecord(data);
      return record.id.trim().isEmpty ? null : record;
    } catch (_) {
      return null;
    }
  }

  /// 将当前内存数据推送到后端 JSON 源文件。
  /// 后端不可用时抛异常，调用方负责提示用户「未落地」。
  Future<void> pushToBackend({ChipJsonDomain? only}) async {
    final files = exportFiles(only: only);
    await ChipBackendClient.instance.saveFiles(files);
    _backendActive = true;
  }

  Future<List<ChipJsonRecord>> _loadDomain(
    ChipJsonDomain domain,
    SharedPreferences sp,
  ) async {
    final saved = sp.getString('$_storagePrefix${domain.key}');
    if (saved != null && saved.isNotEmpty) {
      try {
        final decoded = jsonDecode(saved);
        final chips = decoded is Map ? decoded['chips'] : null;
        if (chips is List) {
          return chips
              .whereType<Map>()
              .map((e) => ChipJsonRecord(
                    _canonicalData(domain, Map<String, dynamic>.from(e)),
                  ))
              .where((e) => e.id.isNotEmpty)
              .toList();
        }
      } catch (e, st) {
        debugPrint('[ChipJsonRepository] load saved ${domain.key}: $e\n$st');
      }
    }
    return _loadSeed(domain);
  }

  Future<List<ChipJsonRecord>> _loadSeed(ChipJsonDomain domain) async {
    final dir = 'assets/data/chips/${domain.key}';
    final indexRaw = await rootBundle.loadString('$dir/index.json');
    final index = jsonDecode(indexRaw);
    final entries = _indexEntries(index, domain);
    final futures = entries.map((entry) async {
      // placeholder 不应出现在磁盘上；如果 index 里残留也跳过，避免 404 抛异常。
      if (entry.id == placeholderId) return null;
      try {
        final raw = await rootBundle.loadString('$dir/${entry.file}');
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final data =
              _canonicalData(domain, Map<String, dynamic>.from(decoded));
          data['id'] ??= entry.id;
          return ChipJsonRecord(data);
        }
      } catch (e) {
        debugPrint(
            '[ChipJsonRepository] seed skip ${domain.key}/${entry.file}: $e');
      }
      return null;
    });
    final out =
        (await Future.wait(futures)).whereType<ChipJsonRecord>().toList();
    return out;
  }

  List<_IndexEntry> _indexEntries(dynamic index, ChipJsonDomain domain) {
    final rawItems = index is Map
        ? (domain.usesOrderIndex ? index['order'] : index['items'])
        : null;
    if (rawItems is! List) return const [];
    return rawItems
        .map((item) {
          if (item is String) return _IndexEntry(item, '$item.json');
          if (item is Map) {
            final id = (item['id'] ?? item['file'] ?? '').toString();
            final file = (item['file'] ?? '$id.json').toString();
            return _IndexEntry(id, file);
          }
          return const _IndexEntry('', '');
        })
        .where((e) => e.file.isNotEmpty)
        .toList();
  }

  ChipJsonRecord add(ChipJsonDomain domain) {
    // 复用已有的占位项：避免重复点 "+ Add" 不断累积 chip_new / chip_new_2…
    final list = _records[domain]!;
    final existing = list.firstWhere(
      (r) => r.id == placeholderId,
      orElse: () => ChipJsonRecord(const {}),
    );
    if (existing.id == placeholderId) {
      return existing;
    }
    final record = ChipJsonRecord(_skeletonFor(domain, placeholderId));
    list.add(record);
    _commit(domain);
    return record;
  }

  /// 新增芯片时按 domain 生成归一化字段骨架。
  /// earbuds 主档生成 15 个展示项 + NoisePink 详情占位；TX/RX/CPU 生成各自结构。
  static Map<String, dynamic> _skeletonFor(ChipJsonDomain domain, String id) {
    switch (domain) {
      case ChipJsonDomain.earbuds:
        return {
          'id': id,
          'process': null,
          'massProduction': false,
          'scene': {
            'hotelCal': null,
            'mute': null,
            'noisePink': null,
            'k1Hz': null,
            'call': null,
            'standby': null,
            'powerOff': null,
            'testConfig': {
              'testPhone': null,
              'vbat': null,
              'audioEncoder': null,
              'outputLoad': null,
              'audioOutputPower': null,
              'softwareVersion': null,
              'moduleVoltageDetail': null,
            },
          },
          'noisePinkDetail': {
            'vsys': null,
            'vcore': null,
            'vcoreM': null,
            'vcoreL': null,
            'vana': null,
            'vhppa': null,
            'isys': null,
            'icore': null,
            'icoreM': null,
            'icoreL': null,
            'iana': null,
            'ihppa': null,
            'isysRemain': null,
          },
        };
      case ChipJsonDomain.earbudsTx:
        return {'id': id, 'txSweep': <String, dynamic>{}};
      case ChipJsonDomain.earbudsRx:
        return {
          'id': id,
          'rxVana': {'values': <String, dynamic>{}, 'vana': null},
          'rxVsys': {'values': <String, dynamic>{}, 'vana': null},
        };
      case ChipJsonDomain.earbudsCpu:
        return {
          'id': id,
          'sleep': {
            'vcoreM': null,
            'vcoreL': null,
            'vana': null,
            'vhppa': null,
            'pdSleep256': null,
            'pdSleepFull': null,
            'deepSleep': null,
          },
          'mcuRun': <String, dynamic>{},
        };
      case ChipJsonDomain.ble:
      case ChipJsonDomain.bt:
      case ChipJsonDomain.wifi:
        return {'id': id};
    }
  }

  ChipJsonRecord duplicate(ChipJsonDomain domain, String id) {
    final source = recordById(domain, id);
    if (source == null) return add(domain);
    final clone = source.cloneWithId(_generateId(domain, '${id}_copy'));
    _records[domain]!.add(clone);
    _commit(domain);
    return clone;
  }

  bool delete(ChipJsonDomain domain, String id) {
    final list = _records[domain]!;
    final before = list.length;
    list.removeWhere((e) => e.id == id);
    if (before == list.length) return false;
    _commit(domain);
    return true;
  }

  void reorder(ChipJsonDomain domain, int oldIndex, int newIndex) {
    final list = _records[domain]!;
    if (oldIndex < 0 || oldIndex >= list.length) return;
    var target = newIndex;
    if (target < 0) target = 0;
    if (target >= list.length) target = list.length - 1;
    if (target == oldIndex) return;
    final moved = list.removeAt(oldIndex);
    list.insert(target, moved);
    _commit(domain);
  }

  ChipUpdateResult update(
    ChipJsonDomain domain,
    String oldId,
    Map<String, dynamic> data,
  ) {
    final newRecord = ChipJsonRecord(_canonicalData(domain, data));
    final newId = newRecord.id.trim();
    if (newId.isEmpty || newId == placeholderId) {
      return ChipUpdateResult.idEmpty;
    }
    final list = _records[domain]!;
    final idx = list.indexWhere((e) => e.id == oldId);
    if (idx < 0) return ChipUpdateResult.notFound;
    // 查重时排除"自身条目"（同一行改回原 id 不算重复），
    // 也排除其它仍在编辑中的占位 placeholder（它们不算真实芯片）。
    final duplicate = list.asMap().entries.any((entry) {
      if (entry.key == idx) return false;
      final existingId = entry.value.id;
      if (existingId == placeholderId) return false;
      return existingId == newId;
    });
    if (duplicate) return ChipUpdateResult.idDuplicate;
    list[idx] = newRecord;
    _commit(domain);
    return ChipUpdateResult.success;
  }

  Future<void> resetToSeed(ChipJsonDomain domain) async {
    _records[domain]!
      ..clear()
      ..addAll(await _loadSeed(domain));
    await _persist(domain);
    _applyDomain(domain);
    _lastChangedDomain = domain;
    notifyListeners();
  }

  /// 把 JSON 种子里「当前内存中缺失」的芯片补进 `_records`（按 id 大小写不敏感去重）。
  /// 仅追加缺失项，不覆盖也不删除已有记录，因此不会丢失用户已做的编辑。
  Future<void> _mergeMissingSeed(ChipJsonDomain domain) async {
    final list = _records[domain]!;
    final existing = <String>{
      for (final r in list)
        if (r.id.trim().isNotEmpty) r.id.trim().toLowerCase(),
    };
    final seed = await _loadSeed(domain);
    var added = false;
    for (final record in seed) {
      final key = record.id.trim().toLowerCase();
      if (key.isEmpty || existing.contains(key)) continue;
      list.add(record);
      existing.add(key);
      added = true;
    }
    if (added) _commit(domain);
  }

  /// 将外部解析得到的 NoisePink 详情按 BES ID 大小写不敏感匹配到 earbuds 记录。
  /// [detailsByLowerId] 的 key 为去掉前缀 "BES" 并小写后的芯片 ID。
  /// 返回 (已同步 ID 列表, 未匹配跳过的 ID 列表)。
  ///
  /// 匹配前先用 JSON 种子补齐内存中「缺失的已知芯片」（仅补缺、不覆盖已有编辑），
  /// 避免旧存档丢失某些种子芯片时把本可匹配的行误判为未匹配而跳过。
  Future<({List<String> matched, List<String> skipped})>
      syncEarbudsNoisePinkDetail(
    Map<String, Map<String, dynamic>> detailsByLowerId,
  ) async {
    await _mergeMissingSeed(ChipJsonDomain.earbuds);
    final list = _records[ChipJsonDomain.earbuds]!;
    final index = <String, ChipJsonRecord>{};
    for (final record in list) {
      final id = record.id.trim().toLowerCase();
      if (id.isNotEmpty) index[id] = record;
    }
    final matched = <String>[];
    final skipped = <String>[];
    for (final entry in detailsByLowerId.entries) {
      final record = index[entry.key];
      if (record == null) {
        skipped.add(entry.key);
        continue;
      }
      record.data['noisePinkDetail'] =
          ChipJsonRecord._normalizeMap(Map<String, dynamic>.from(entry.value));
      final rawScene = record.data['scene'];
      if (rawScene is Map) {
        final scene = Map<String, dynamic>.from(rawScene);
        scene.remove('noisePinkDetail');
        record.data['scene'] = scene;
      }
      matched.add(record.id);
    }
    if (matched.isNotEmpty) {
      _commit(ChipJsonDomain.earbuds);
    }
    return (matched: matched, skipped: skipped);
  }

  Map<String, String> exportFiles({ChipJsonDomain? only}) {
    const encoder = JsonEncoder.withIndent('  ');
    final domains = only == null ? ChipJsonDomain.values : [only];
    final files = <String, String>{};
    for (final domain in domains) {
      final list = _records[domain] ?? const <ChipJsonRecord>[];
      if (domain.usesOrderIndex) {
        final order = <String>[];
        for (final record in list) {
          final id = record.id.trim();
          // placeholder 仅是 admin 的"待编辑占位"，不写入 index.json / 主档文件，
          // 避免 seed 加载时去 fetch 不存在的 chip_new.json 抛 404 异常。
          if (id.isEmpty || id == placeholderId) continue;
          final file = _safeFileName(id);
          order.add(file);
          files['chips/${domain.key}/$file.json'] =
              encoder.convert(_canonicalData(domain, record.data));
        }
        files['chips/${domain.key}/index.json'] = encoder.convert({
          'version': _schemaVersion,
          'order': order,
        });
      } else {
        final items = <Map<String, String>>[];
        for (final record in list) {
          final id = record.id.trim();
          if (id.isEmpty || id == placeholderId) continue;
          final file = '${_safeFileName(id)}.json';
          items.add({'id': id, 'file': file});
          files['chips/${domain.key}/$file'] =
              encoder.convert(_canonicalData(domain, record.data));
        }
        files['chips/${domain.key}/index.json'] = encoder.convert({
          'version': _schemaVersion,
          'items': items,
        });
      }
    }
    return files;
  }

  void _commit(ChipJsonDomain domain) {
    _applyDomain(domain);
    _lastChangedDomain = domain;
    _revision++;
    notifyListeners();
    unawaited(_persist(domain));
    // 后端可用时，结构性改动（增/删/复制/排序）也尽力同步到 JSON 源文件；
    // 失败不在此处抛出（无 UI 上下文），由显式 Save/Sync/Reset 负责报错。
    if (_backendActive) {
      unawaited(
        ChipBackendClient.instance.saveFiles(exportFiles(only: domain)).catchError(
          (Object e) => debugPrint('[ChipJsonRepository] backend sync: $e'),
        ),
      );
    }
  }

  Future<void> _persist(ChipJsonDomain domain) async {
    final sp = await SharedPreferences.getInstance();
    final payload = {
      'version': _schemaVersion,
      'chips': (_records[domain] ?? const <ChipJsonRecord>[])
          .map((e) => _canonicalData(domain, e.data))
          .toList(),
    };
    await sp.setString('$_storagePrefix${domain.key}', jsonEncode(payload));
  }

  void _applyDomain(ChipJsonDomain domain) {
    final maps = (_records[domain] ?? const <ChipJsonRecord>[])
        .map((e) => _canonicalData(domain, e.data))
        .toList();
    switch (domain) {
      case ChipJsonDomain.ble:
        ConfigRepository.instance.replaceBleChips(
          maps.map(BleChip.fromJson).where((e) => e.id.isNotEmpty).toList(),
        );
        break;
      case ChipJsonDomain.bt:
        ConfigRepository.instance.replaceBtChips(
          maps.map(BtChip.fromJson).where((e) => e.id.isNotEmpty).toList(),
        );
        break;
      case ChipJsonDomain.earbuds:
        EarbudsRepository.instance.replaceFromJsonRecords(maps);
        break;
      case ChipJsonDomain.earbudsTx:
      case ChipJsonDomain.earbudsRx:
      case ChipJsonDomain.earbudsCpu:
        break;
      case ChipJsonDomain.wifi:
        ConfigRepository.instance.replaceWifiChips(
          maps.map(WifiChip.fromJson).where((e) => e.id.isNotEmpty).toList(),
        );
        break;
    }
  }

  String _generateId(ChipJsonDomain domain, String hint) {
    final base = hint.trim().isEmpty ? placeholderId : hint.trim();
    if (recordById(domain, base) == null) return base;
    var i = 2;
    while (recordById(domain, '${base}_$i') != null) {
      i++;
    }
    return '${base}_$i';
  }

  String _safeFileName(String id) {
    final buf = StringBuffer();
    for (final r in id.runes) {
      final c = String.fromCharCode(r);
      if (RegExp(r'[A-Za-z0-9_\-]').hasMatch(c)) {
        buf.write(c);
      } else {
        buf.write('_');
      }
    }
    final safe = buf.toString().replaceAll(RegExp(r'_+'), '_');
    final trimmed = safe.replaceAll(RegExp(r'^_|_$'), '');
    return trimmed.isEmpty ? 'chip' : trimmed;
  }

  static Map<String, dynamic> _canonicalData(
    ChipJsonDomain domain,
    Map<String, dynamic> source,
  ) {
    final data = ChipJsonRecord._normalizeMap(
      Map<String, dynamic>.from(source),
    );
    switch (domain) {
      case ChipJsonDomain.ble:
      case ChipJsonDomain.bt:
      case ChipJsonDomain.wifi:
        data.remove('txPowerLevelsDbm');
        break;
      case ChipJsonDomain.earbuds:
        data['mcuRun'] = _labeledListToMap(data['mcuRun']);
        data['txSweep'] = _labeledListToMap(data['txSweep']);
        break;
      case ChipJsonDomain.earbudsTx:
        data['txSweep'] = _labeledListToMap(data['txSweep']);
        break;
      case ChipJsonDomain.earbudsCpu:
        data['mcuRun'] = _labeledListToMap(data['mcuRun']);
        break;
      case ChipJsonDomain.earbudsRx:
        break;
    }
    return data;
  }

  static dynamic _labeledListToMap(dynamic value) {
    if (value is Map) return value;
    if (value is! List) return value;
    final out = <String, dynamic>{};
    for (var i = 0; i < value.length; i++) {
      final item = value[i];
      if (item is! Map) continue;
      final data = Map<String, dynamic>.from(item);
      final rawLabel = data.remove('label')?.toString().trim();
      final label =
          rawLabel == null || rawLabel.isEmpty ? 'variant_${i + 1}' : rawLabel;
      out[_uniqueLabel(out, label)] = data;
    }
    return out;
  }

  static String _uniqueLabel(Map<String, dynamic> existing, String label) {
    if (!existing.containsKey(label)) return label;
    var i = 2;
    while (existing.containsKey('${label}_$i')) {
      i++;
    }
    return '${label}_$i';
  }
}

class _IndexEntry {
  final String id;
  final String file;

  const _IndexEntry(this.id, this.file);
}
