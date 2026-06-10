import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/earbuds.dart';

/// 芯片"数据集"资源装载器。
///
/// [事实] 数据源拆分为多文件资源（归一化后按维度分目录），4 个 domain 物理上完全平行：
///   - `assets/data/chips/earbuds/Scene/index.json`：`{ version:int, order:[<id>...] }`
///   - `assets/data/chips/earbuds/Scene/<id>.json`：精简主档（id/process/massProduction/scene）
///   - `assets/data/chips/earbuds/Tx/<id>.json`：`{ txSweep }`
///   - `assets/data/chips/earbuds/Rx/<id>.json`：`{ rxVana, rxVsys }`
///   - `assets/data/chips/earbuds/CPU/<id>.json`：`{ sleep, mcuRun }`
///
/// [决策] 主档只保留展示用归一化字段；Scene/TX/RX/CPU 各占一个子目录，
/// 避免任何"前缀包含子目录"的歧义（旧版直接放在 earbuds/ 下导致后端 recursive
/// 扫描时被各 domain 重复纳入）。
/// 加载流程：先读 index → 按 order 并行读各维度文件 → 合并成单个 EarbudsChip。
///
/// [约束] 调用方必须在 `WidgetsFlutterBinding.ensureInitialized()` 之后调用。
class EarbudsChipLoader {
  EarbudsChipLoader._();

  static const String indexAssetPath =
      'assets/data/chips/earbuds/Scene/index.json';
  static const String chipsAssetDir = 'assets/data/chips/earbuds/Scene';
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
          'chips/earbuds/Scene/index.json: root is not an object');
    }
    final version = index['version'];
    if (version is int && version != supportedVersion) {
      throw FormatException(
        'chips/earbuds/Scene/index.json: schema version $version not supported '
        '(expected $supportedVersion)',
      );
    }
    final orderRaw = index['order'];
    if (orderRaw is! List) {
      throw const FormatException(
          'chips/earbuds/Scene/index.json: "order" is missing or not a list');
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
    final mainRaw = await _loadStringAnyCase(chipsAssetDir, id);
    if (mainRaw == null) {
      throw FormatException('$id.json: not found in $chipsAssetDir');
    }
    final decoded = jsonDecode(mainRaw);
    if (decoded is! Map) {
      throw FormatException('$id.json: root is not an object');
    }
    final merged = Map<String, dynamic>.from(decoded);

    final tx = await _tryLoadObject(txAssetDir, id);
    if (tx != null) merged['txSweep'] = tx['txSweep'];

    final rx = await _tryLoadObject(rxAssetDir, id);
    if (rx != null) {
      merged['rxVana'] = rx['rxVana'];
      merged['rxVsys'] = rx['rxVsys'];
    }

    final cpu = await _tryLoadObject(cpuAssetDir, id);
    if (cpu != null) {
      merged['sleep'] = cpu['sleep'];
      merged['mcuRun'] = cpu['mcuRun'];
    }

    return merged;
  }

  /// 尝试读取可选子档；文件缺失或非对象时返回 null。
  /// [事实] index.json 中的 id 可能为大写（如 `1306P`），而磁盘上的文件名为小写
  /// （如 `1306p.json`）。Flutter web/Linux 的资源系统大小写敏感，需要回退尝试。
  static Future<Map<String, dynamic>?> _tryLoadObject(
    String dir,
    String id,
  ) async {
    final raw = await _loadStringAnyCase(dir, id);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }

  /// 依次尝试 `<dir>/<id>.json` / `<dir>/<id_lower>.json` / `<dir>/<id_upper>.json`
  /// ，第一个成功命中的资源返回其字符串内容，全部失败返回 null。
  static Future<String?> _loadStringAnyCase(String dir, String id) async {
    final candidates = <String>{
      id,
      id.toLowerCase(),
      id.toUpperCase(),
    };
    for (final c in candidates) {
      try {
        return await rootBundle.loadString('$dir/$c.json');
      } catch (_) {
        // try next casing
      }
    }
    return null;
  }
}
