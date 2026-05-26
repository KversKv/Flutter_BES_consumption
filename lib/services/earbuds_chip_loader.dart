import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/earbuds.dart';

/// 芯片"数据集"资源装载器。
///
/// [事实] 数据源拆分为多文件资源：
///   - `assets/data/chips/earbuds/index.json`：`{ version:int, order:[<id>...] }`
///   - `assets/data/chips/earbuds/<id>.json`：单个 `EarbudsChip.toJson()` 对象
///
/// [决策] 每个芯片独立 JSON 文件，便于 git diff / 多人协作 / admin 导出。
/// 加载流程：先读 index → 按 order 并行读各 `<id>.json` → 拼成列表。
///
/// [约束] 调用方必须在 `WidgetsFlutterBinding.ensureInitialized()` 之后调用。
class EarbudsChipLoader {
  EarbudsChipLoader._();

  static const String indexAssetPath = 'assets/data/chips/earbuds/index.json';
  static const String chipsAssetDir = 'assets/data/chips/earbuds';
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

    final futures = order
        .map((id) => rootBundle.loadString('$chipsAssetDir/$id.json'))
        .toList(growable: false);
    final rawList = await Future.wait(futures);

    final chips = <EarbudsChip>[];
    for (var i = 0; i < rawList.length; i++) {
      final decoded = jsonDecode(rawList[i]);
      if (decoded is! Map) {
        throw FormatException(
            '${order[i]}.json: root is not an object');
      }
      final chip =
          EarbudsChip.fromJson(Map<String, dynamic>.from(decoded));
      if (chip.id.isEmpty) continue;
      chips.add(chip);
    }
    return List<EarbudsChip>.unmodifiable(chips);
  }
}
