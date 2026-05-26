import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ble_chip.dart';
import '../models/bt_chip.dart';
import '../models/wifi_chip.dart';
import 'config/config_repository.dart';
import 'earbuds_repository.dart';

enum ChipJsonDomain {
  ble('ble', 'BLE CASE'),
  bt('bt', 'BT CASE'),
  earbuds('earbuds', 'Earbuds'),
  wifi('wifi', 'Wi-Fi');

  final String key;
  final String label;

  const ChipJsonDomain(this.key, this.label);
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

class ChipJsonRepository extends ChangeNotifier {
  ChipJsonRepository._();

  static final ChipJsonRepository instance = ChipJsonRepository._();

  static const int _schemaVersion = 1;
  static const String _storagePrefix = 'admin_chip_json_db_v1_';

  final Map<ChipJsonDomain, List<ChipJsonRecord>> _records = {
    for (final domain in ChipJsonDomain.values) domain: <ChipJsonRecord>[],
  };

  bool _loaded = false;
  ChipJsonDomain? _lastChangedDomain;

  bool get isLoaded => _loaded;
  ChipJsonDomain? get lastChangedDomain => _lastChangedDomain;

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
      final raw = await rootBundle.loadString('$dir/${entry.file}');
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final data = _canonicalData(domain, Map<String, dynamic>.from(decoded));
        data['id'] ??= entry.id;
        return ChipJsonRecord(data);
      }
      return null;
    });
    final out =
        (await Future.wait(futures)).whereType<ChipJsonRecord>().toList();
    return out;
  }

  List<_IndexEntry> _indexEntries(dynamic index, ChipJsonDomain domain) {
    final rawItems = index is Map
        ? (domain == ChipJsonDomain.earbuds ? index['order'] : index['items'])
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
    final record = ChipJsonRecord({'id': _generateId(domain, 'chip_new')});
    _records[domain]!.add(record);
    _commit(domain);
    return record;
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

  bool update(
    ChipJsonDomain domain,
    String oldId,
    Map<String, dynamic> data,
  ) {
    final newRecord = ChipJsonRecord(_canonicalData(domain, data));
    final newId = newRecord.id.trim();
    if (newId.isEmpty) return false;
    final duplicate =
        recordById(domain, newId) != null && oldId.trim() != newId;
    if (duplicate) return false;
    final list = _records[domain]!;
    final idx = list.indexWhere((e) => e.id == oldId);
    if (idx < 0) return false;
    list[idx] = newRecord;
    _commit(domain);
    return true;
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

  Map<String, String> exportFiles({ChipJsonDomain? only}) {
    const encoder = JsonEncoder.withIndent('  ');
    final domains = only == null ? ChipJsonDomain.values : [only];
    final files = <String, String>{};
    for (final domain in domains) {
      final list = _records[domain] ?? const <ChipJsonRecord>[];
      if (domain == ChipJsonDomain.earbuds) {
        final order = <String>[];
        for (final record in list) {
          final id = record.id.trim();
          if (id.isEmpty) continue;
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
          if (id.isEmpty) continue;
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
    notifyListeners();
    unawaited(_persist(domain));
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
      case ChipJsonDomain.wifi:
        ConfigRepository.instance.replaceWifiChips(
          maps.map(WifiChip.fromJson).where((e) => e.id.isNotEmpty).toList(),
        );
        break;
    }
  }

  String _generateId(ChipJsonDomain domain, String hint) {
    final base = hint.trim().isEmpty ? 'chip_new' : hint.trim();
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
