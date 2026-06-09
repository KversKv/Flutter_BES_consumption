import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/earbuds.dart';
import 'earbuds_chip_loader.dart';

/// 可变芯片副本（CRUD 友好）。
///
/// [事实] 现有 `EarbudsChip` 全部 `final`，运行期不可修改。本仓储在启动时
/// 把 JSON 资源（或用户存档）一次性「种子化」为可变记录（行为类似数据库表），
/// 提供 list/get/update/add/delete 接口。
///
/// [决策] 数据源（种子）= `assets/data/earbuds_chips.json`（由
/// `EarbudsChipLoader` 装载）；用户编辑落盘到 `shared_preferences` 单键
/// `earbuds_db_v1`，整库以单 JSON 字符串存放，Schema = `{ version, chips:[...] }`，
/// 版本变更需写迁移。六端原生通过；唯一写入入口；UI 永远读 `chips` 不可变快照。
class MutableSleepCurrent {
  double? vcoreM;
  double? vcoreL;
  double? vana;
  double? vhppa;
  double? pdSleep256;
  double? pdSleepFull;
  double? deepSleep;

  MutableSleepCurrent({
    this.vcoreM,
    this.vcoreL,
    this.vana,
    this.vhppa,
    this.pdSleep256,
    this.pdSleepFull,
    this.deepSleep,
  });

  factory MutableSleepCurrent.from(SleepCurrent s) => MutableSleepCurrent(
        vcoreM: s.vcoreM,
        vcoreL: s.vcoreL,
        vana: s.vana,
        vhppa: s.vhppa,
        pdSleep256: s.pdSleep256,
        pdSleepFull: s.pdSleepFull,
        deepSleep: s.deepSleep,
      );

  SleepCurrent toImmutable() => SleepCurrent(
        vcoreM: vcoreM,
        vcoreL: vcoreL,
        vana: vana,
        vhppa: vhppa,
        pdSleep256: pdSleep256,
        pdSleepFull: pdSleepFull,
        deepSleep: deepSleep,
      );
}

class MutableRunCurrent {
  String label;
  double? wfi24M;
  double? cm24M;
  double? cm48M;
  double? cm96M;
  double? cm192M;

  MutableRunCurrent({
    required this.label,
    this.wfi24M,
    this.cm24M,
    this.cm48M,
    this.cm96M,
    this.cm192M,
  });

  factory MutableRunCurrent.from(RunCurrent r) => MutableRunCurrent(
        label: r.label,
        wfi24M: r.wfi24M,
        cm24M: r.cm24M,
        cm48M: r.cm48M,
        cm96M: r.cm96M,
        cm192M: r.cm192M,
      );

  RunCurrent toImmutable() => RunCurrent(
        label: label,
        wfi24M: wfi24M,
        cm24M: cm24M,
        cm48M: cm48M,
        cm96M: cm96M,
        cm192M: cm192M,
      );
}

class MutableSceneTestConfig {
  String? testPhone;
  double? vbat;
  String? audioEncoder;
  String? outputLoad;
  String? audioOutputPower;
  String? softwareVersion;
  String? moduleVoltageDetail;

  MutableSceneTestConfig({
    this.testPhone,
    this.vbat,
    this.audioEncoder,
    this.outputLoad,
    this.audioOutputPower,
    this.softwareVersion,
    this.moduleVoltageDetail,
  });

  factory MutableSceneTestConfig.from(SceneTestConfig? c) =>
      MutableSceneTestConfig(
        testPhone: c?.testPhone,
        vbat: c?.vbat,
        audioEncoder: c?.audioEncoder,
        outputLoad: c?.outputLoad,
        audioOutputPower: c?.audioOutputPower,
        softwareVersion: c?.softwareVersion,
        moduleVoltageDetail: c?.moduleVoltageDetail,
      );

  SceneTestConfig toImmutable() => SceneTestConfig(
        testPhone: testPhone,
        vbat: vbat,
        audioEncoder: audioEncoder,
        outputLoad: outputLoad,
        audioOutputPower: audioOutputPower,
        softwareVersion: softwareVersion,
        moduleVoltageDetail: moduleVoltageDetail,
      );
}

class MutableEarbudsScene {
  double? hotelCal;
  double? mute;
  double? noisePink;
  double? k1Hz;
  double? call;
  double? standby;
  double? powerOff;
  MutableSceneTestConfig testConfig;

  MutableEarbudsScene({
    this.hotelCal,
    this.mute,
    this.noisePink,
    this.k1Hz,
    this.call,
    this.standby,
    this.powerOff,
    MutableSceneTestConfig? testConfig,
  }) : testConfig = testConfig ?? MutableSceneTestConfig();

  factory MutableEarbudsScene.from(EarbudsScene s) => MutableEarbudsScene(
        hotelCal: s.hotelCal,
        mute: s.mute,
        noisePink: s.noisePink,
        k1Hz: s.k1Hz,
        call: s.call,
        standby: s.standby,
        powerOff: s.powerOff,
        testConfig: MutableSceneTestConfig.from(s.testConfig),
      );

  EarbudsScene toImmutable() => EarbudsScene(
        hotelCal: hotelCal,
        mute: mute,
        noisePink: noisePink,
        k1Hz: k1Hz,
        call: call,
        standby: standby,
        powerOff: powerOff,
        testConfig: testConfig.toImmutable(),
      );
}

class MutableTxSweepVariant {
  String label;
  Map<int, double> values;

  MutableTxSweepVariant({required this.label, required this.values});

  factory MutableTxSweepVariant.from(TxSweepVariant t) => MutableTxSweepVariant(
        label: t.label,
        values: Map<int, double>.from(t.values),
      );

  TxSweepVariant toImmutable() =>
      TxSweepVariant(label: label, values: Map<int, double>.from(values));
}

class MutableRxSweep {
  Map<int, double> values;
  double? vana;

  MutableRxSweep({required this.values, this.vana});

  factory MutableRxSweep.from(RxSweep? r) => r == null
      ? MutableRxSweep(values: <int, double>{})
      : MutableRxSweep(
          values: Map<int, double>.from(r.values),
          vana: r.vana,
        );

  RxSweep toImmutable() =>
      RxSweep(values: Map<int, double>.from(values), vana: vana);
}

/// 可变芯片记录（一行）。
class MutableEarbudsChip {
  String id;
  String? process;
  bool massProduction;
  MutableSleepCurrent sleep;
  List<MutableRunCurrent> mcuRun;
  MutableEarbudsScene scene;
  NoisePinkDetail? noisePinkDetail;
  List<MutableTxSweepVariant> txSweep;
  MutableRxSweep rxVana;
  MutableRxSweep rxVsys;

  MutableEarbudsChip({
    required this.id,
    this.process,
    this.massProduction = false,
    MutableSleepCurrent? sleep,
    List<MutableRunCurrent>? mcuRun,
    MutableEarbudsScene? scene,
    this.noisePinkDetail,
    List<MutableTxSweepVariant>? txSweep,
    MutableRxSweep? rxVana,
    MutableRxSweep? rxVsys,
  })  : sleep = sleep ?? MutableSleepCurrent(),
        mcuRun = mcuRun ?? <MutableRunCurrent>[],
        scene = scene ?? MutableEarbudsScene(),
        txSweep = txSweep ?? <MutableTxSweepVariant>[],
        rxVana = rxVana ?? MutableRxSweep(values: <int, double>{}),
        rxVsys = rxVsys ?? MutableRxSweep(values: <int, double>{});

  factory MutableEarbudsChip.from(EarbudsChip c) => MutableEarbudsChip(
        id: c.id,
        process: c.process,
        massProduction: c.massProduction,
        sleep: MutableSleepCurrent.from(c.sleep),
        mcuRun: c.mcuRun.map(MutableRunCurrent.from).toList(),
        scene: MutableEarbudsScene.from(c.scene),
        noisePinkDetail: c.noisePinkDetail,
        txSweep: c.txSweep.map(MutableTxSweepVariant.from).toList(),
        rxVana: MutableRxSweep.from(c.rxVana),
        rxVsys: MutableRxSweep.from(c.rxVsys),
      );

  EarbudsChip toImmutable() => EarbudsChip(
        id: id,
        process: process,
        massProduction: massProduction,
        sleep: sleep.toImmutable(),
        mcuRun: mcuRun.map((e) => e.toImmutable()).toList(),
        scene: scene.toImmutable(),
        noisePinkDetail: noisePinkDetail,
        txSweep: txSweep.map((e) => e.toImmutable()).toList(),
        rxVana: rxVana.toImmutable(),
        rxVsys: rxVsys.toImmutable(),
      );
}

/// 全局耳机芯片仓储（运行期可变「数据库」）。
///
/// - 数据源（种子）：`assets/data/earbuds_chips.json`，由 [EarbudsChipLoader] 装载
/// - 持久化（用户改动）：`shared_preferences` 键 `earbuds_db_v1`
/// - Schema：`{ version: 1, chips: [EarbudsChip.toJson(), ...] }`
/// - 启动流程：`await load()`：优先用户存档；缺省读 JSON 资源 → 落盘
/// - 写操作：`commit / add / duplicate / delete / resetToSeed` 均触发 `_persist()` 与 `notifyListeners()`
class EarbudsRepository extends ChangeNotifier {
  EarbudsRepository._();

  static final EarbudsRepository instance = EarbudsRepository._();

  static const String _storageKey = 'earbuds_db_v2';
  static const int _schemaVersion = 2;

  final List<MutableEarbudsChip> _records = [];
  List<EarbudsChip> _snapshot = const [];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// 启动时调用一次：
  /// 1. 读 SharedPreferences 存档；命中则直接用
  /// 2. 否则读 `assets/data/earbuds_chips.json` 作为种子，并落盘
  /// 3. 任何环节异常 → 退化为空仓库（不再有 const 兜底，避免数据二源不一致）
  Future<void> load() async {
    if (_loaded) return;
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map && decoded['chips'] is List) {
          final chips = (decoded['chips'] as List)
              .whereType<Map>()
              .map((m) => EarbudsChip.fromJson(Map<String, dynamic>.from(m)))
              .where((c) => c.id.isNotEmpty)
              .toList();
          _records
            ..clear()
            ..addAll(chips.map(MutableEarbudsChip.from));
          _dedupeRecords();
          _rebuildSnapshot();
          _loaded = true;
          notifyListeners();
          return;
        }
      }
      // 无存档或存档损坏：从 JSON 资源种子化
      await _seedFromAsset();
      await _persist();
    } catch (e, st) {
      debugPrint('[EarbudsRepository] load failed: $e\n$st');
      try {
        await _seedFromAsset();
      } catch (e2, st2) {
        debugPrint('[EarbudsRepository] seed asset also failed: $e2\n$st2');
        _records.clear();
        _rebuildSnapshot();
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _seedFromAsset() async {
    final chips = await EarbudsChipLoader.loadFromAsset();
    _records
      ..clear()
      ..addAll(chips.map(MutableEarbudsChip.from));
    _rebuildSnapshot();
  }

  void _rebuildSnapshot() {
    final seen = <String>{};
    final unique = <EarbudsChip>[];
    for (final r in _records) {
      final chip = r.toImmutable();
      if (chip.id.isEmpty) continue;
      if (!seen.add(chip.id)) continue;
      unique.add(chip);
    }
    _snapshot = List<EarbudsChip>.unmodifiable(unique);
  }

  Future<void> _persist() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final payload = <String, dynamic>{
        'version': _schemaVersion,
        'chips': _snapshot.map((c) => c.toJson()).toList(),
      };
      await sp.setString(_storageKey, jsonEncode(payload));
    } catch (e, st) {
      debugPrint('[EarbudsRepository] persist failed: $e\n$st');
    }
  }

  /// 当前不可变快照（供原有 UI 使用，签名保持 `List<EarbudsChip>`）。
  List<EarbudsChip> get chips => _snapshot;

  /// 编辑用：返回内部可变记录（仅供 admin 页使用）。
  List<MutableEarbudsChip> get records => List.unmodifiable(_records);

  MutableEarbudsChip? recordById(String id) {
    for (final r in _records) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// 提交对某条记录的修改，刷新快照、持久化并通知。
  void commit() {
    _rebuildSnapshot();
    notifyListeners();
    unawaited(_persist());
  }

  /// 新增一条空白记录。
  MutableEarbudsChip add({String? id}) {
    final newId = _generateId(id);
    final rec = MutableEarbudsChip(id: newId);
    _records.add(rec);
    _rebuildSnapshot();
    notifyListeners();
    unawaited(_persist());
    return rec;
  }

  /// 复制现有记录。
  MutableEarbudsChip duplicate(String id) {
    final src = recordById(id);
    if (src == null) {
      return add();
    }
    final cloned = MutableEarbudsChip.from(src.toImmutable());
    cloned.id = _generateId('${src.id}_copy');
    _records.add(cloned);
    _rebuildSnapshot();
    notifyListeners();
    unawaited(_persist());
    return cloned;
  }

  bool delete(String id) {
    final before = _records.length;
    _records.removeWhere((r) => r.id == id);
    if (_records.length == before) return false;
    _rebuildSnapshot();
    notifyListeners();
    unawaited(_persist());
    return true;
  }

  /// 调整芯片顺序(拖拽排序入口)。
  ///
  /// - 参数语义遵循 Flutter `ReorderableListView.onReorder`:
  ///   `newIndex` 是"移除 oldIndex 前"的目标下标,需要在 `newIndex > oldIndex`
  ///   时减 1 才是真实插入位置。
  /// - 同样触发 snapshot 重建 / 持久化 / `notifyListeners`,用户展示界面会
  ///   通过 `EarbudsRepository.instance.chips` 自动按新顺序渲染。
  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _records.length) return;
    var target = newIndex;
    if (target > oldIndex) target -= 1;
    _moveRecord(oldIndex, target);
  }

  /// 调整芯片顺序(新 Flutter `onReorderItem` 入口)。
  ///
  /// `newIndex` 已经是移除 oldIndex 后的真实插入位置，不需要再手动校正。
  void reorderItem(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _records.length) return;
    _moveRecord(oldIndex, newIndex);
  }

  void _moveRecord(int oldIndex, int target) {
    if (target < 0) target = 0;
    if (target >= _records.length) target = _records.length - 1;
    if (target == oldIndex) return;
    final moved = _records.removeAt(oldIndex);
    _records.insert(target, moved);
    _rebuildSnapshot();
    notifyListeners();
    unawaited(_persist());
  }

  /// 重置为 JSON 资源里的出厂种子（同时清掉用户编辑落盘）。
  Future<void> resetToSeed() async {
    try {
      await _seedFromAsset();
    } catch (e, st) {
      debugPrint('[EarbudsRepository] resetToSeed: seed asset failed: $e\n$st');
      _records.clear();
      _rebuildSnapshot();
    }
    notifyListeners();
    await _persist();
  }

  void replaceFromJsonRecords(List<Map<String, dynamic>> records) {
    final chips = records
        .map(EarbudsChip.fromJson)
        .where((chip) => chip.id.isNotEmpty)
        .toList();
    _records
      ..clear()
      ..addAll(chips.map(MutableEarbudsChip.from));
    _dedupeRecords();
    _rebuildSnapshot();
    notifyListeners();
    unawaited(_persist());
  }

  /// 按 id 去重内部记录（保留首次出现），防止下游 `DropdownButton` 等
  /// 依赖唯一 id 的控件因重复芯片触发断言。
  void _dedupeRecords() {
    final seen = <String>{};
    _records.removeWhere((r) => !seen.add(r.id));
  }

  /// 把当前内存中的全套芯片数据导出为「拆分文件」格式。
  ///
  /// 返回 `{ 相对路径 -> JSON 字符串 }`，包括：
  ///   - `chips/earbuds/index.json`
  ///   - `chips/earbuds/<id>.json`（每芯片一个）
  ///
  /// 调用方负责把它们打包 / 下载 / 落盘；本方法不触碰 IO。
  Map<String, String> exportAsJsonFiles() {
    const encoder = JsonEncoder.withIndent('  ');
    final files = <String, String>{};
    final order = <String>[];
    for (final r in _records) {
      final id = r.id.trim();
      if (id.isEmpty) continue;
      final safe = _safeFileName(id);
      if (files.containsKey('chips/earbuds/$safe.json')) continue;
      files['chips/earbuds/$safe.json'] =
          encoder.convert(r.toImmutable().toJson());
      order.add(safe);
    }
    files['chips/earbuds/index.json'] = encoder.convert(<String, Object>{
      'version': _schemaVersion,
      'order': order,
    });
    return files;
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
    return buf.toString();
  }

  String _generateId(String? hint) {
    final base =
        (hint == null || hint.trim().isEmpty) ? 'chip_new' : hint.trim();
    if (recordById(base) == null) return base;
    var i = 2;
    while (recordById('${base}_$i') != null) {
      i++;
    }
    return '${base}_$i';
  }
}
