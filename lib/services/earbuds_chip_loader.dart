import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/earbuds.dart';

/// 芯片"数据集"资源装载器。
///
/// [事实] 数据源拆分为多文件资源（归一化后按维度分目录）：
///   - `assets/data/chips/earbuds/index.json`：`{ version:int, order:[<id>...] }`
///   - `assets/data/chips/earbuds/<id>.json`：精简主档（id/process/massProduction/scene）
///   - `assets/data/chips/earbuds/Tx/<id>.json`：`{ txSweep }`
///   - `assets/data/chips/earbuds/Rx/<id>.json`：`{ rxVana, rxVsys }`
///   - `assets/data/chips/earbuds/CPU/<id>.json`：`{ sleep, mcuRun }`
///
/// [决策] 主档只保留展示用归一化字段；TX/RX/CPU 拆到子目录维护。
/// 加载流程：先读 index → 按 order 并行读各维度文件 → 合并成单个 EarbudsChip。
///
/// [约束] 调用方必须在 `WidgetsFlutterBinding.ensureInitialized()` 之后调用。
class EarbudsChipLoader {
  EarbudsChipLoader._();

  static const String indexAssetPath = 'assets/data/chips/earbuds/index.json';
  static const String chipsAssetDir = 'assets/data/chips/earbuds';
  static const String txAssetDir = 'assets/data/chips/earbuds/Tx';
  static const String rxAssetDir = 'assets/data/chips/earbuds/Rx';
  static const String cpuAssetDir = 'assets/data/chips/earbuds/CPU';
  static const int supportedVersion = 1;

  /// 从打包资源装载并解析芯片列表。
  /// 失败抛 [FormatException]，调用方负责兜底。
  static Future<List<EarbudsChip>> loadFromAsset() async {
    final indexRaw = await rootBundle.loadString(indexAssetPath);
    final index = jsonDecode(indexRaw);
    if (index is! Map) {
      throw const FormatException(
          'chips/earbuds/index.json: root is not an object');
    }
    final version = index['version'];
    if (version is int && version != supportedVersion) {
      throw FormatException(
        'chips/earbuds/index.json: schema version $version not supported '
        '(expected $supportedVersion)',
      );
    }
    final orderRaw = index['order'];
    if (orderRaw is! List) {
      throw const FormatException(
          'chips/earbuds/index.json: "order" is missing or not a list');
    }
    final order = orderRaw.whereType<String>().toList(growable: false);

    final futures =
        order.map(_loadMerged).toList(growable: false);
    final mergedList = await Future.wait(futures);

    final chips = <EarbudsChip>[];
    for (var i = 0; i < mergedList.length; i++) {
      final merged = mergedList[i];
      final chip = EarbudsChip.fromJson(merged);
      if (chip.id.isEmpty) continue;
      chips.add(chip);
    }
    return List<EarbudsChip>.unmodifiable(chips);
  }

  /// 读取单个芯片的主档 + Tx/Rx/CPU 子档并合并成一个 JSON。
  static Future<Map<String, dynamic>> _loadMerged(String id) async {
    final mainRaw = await rootBundle.loadString('$chipsAssetDir/$id.json');
    final decoded = jsonDecode(mainRaw);
    if (decoded is! Map) {
      throw FormatException('$id.json: root is not an object');
    }
    final merged = Map<String, dynamic>.from(decoded);

    final tx = await _tryLoadObject('$txAssetDir/$id.json');
    if (tx != null) merged['txSweep'] = tx['txSweep'];

    final rx = await _tryLoadObject('$rxAssetDir/$id.json');
    if (rx != null) {
      merged['rxVana'] = rx['rxVana'];
      merged['rxVsys'] = rx['rxVsys'];
    }

    final cpu = await _tryLoadObject('$cpuAssetDir/$id.json');
    if (cpu != null) {
      merged['sleep'] = cpu['sleep'];
      merged['mcuRun'] = cpu['mcuRun'];
    }

    return merged;
  }

  /// 尝试读取可选子档；文件缺失或非对象时返回 null。
  static Future<Map<String, dynamic>?> _tryLoadObject(String path) async {
    try {
      final raw = await rootBundle.loadString(path);
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }
}
