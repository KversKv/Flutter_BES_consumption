import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/earbuds.dart';

/// 芯片"数据集"资源装载器。
///
/// [事实] 数据源为打包资源 `assets/data/earbuds_chips.json`，
/// Schema = `{ version:int, chips:[EarbudsChip.toJson()...] }`。
///
/// [决策] 让 `EarbudsRepository` 在没有用户存档（首启 / resetToSeed）时
/// 从此处取种子；以后修改芯片数据请改 JSON，不要再改 Dart 常量。
///
/// [约束] 调用方必须在 `WidgetsFlutterBinding.ensureInitialized()` 之后调用。
class EarbudsChipLoader {
  EarbudsChipLoader._();

  static const String assetPath = 'assets/data/earbuds_chips.json';
  static const int supportedVersion = 1;

  /// 从打包资源装载并解析芯片列表。
  /// 失败抛 [FormatException]，调用方负责兜底。
  static Future<List<EarbudsChip>> loadFromAsset() async {
    final raw = await rootBundle.loadString(assetPath);
    return _decode(raw);
  }

  static List<EarbudsChip> _decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('earbuds_chips.json: root is not an object');
    }
    final version = decoded['version'];
    if (version is int && version != supportedVersion) {
      throw FormatException(
        'earbuds_chips.json: schema version $version not supported '
        '(expected $supportedVersion)',
      );
    }
    final chipsRaw = decoded['chips'];
    if (chipsRaw is! List) {
      throw const FormatException('earbuds_chips.json: "chips" is missing or not a list');
    }
    return chipsRaw
        .whereType<Map>()
        .map((m) => EarbudsChip.fromJson(Map<String, dynamic>.from(m)))
        .where((c) => c.id.isNotEmpty)
        .toList(growable: false);
  }
}
