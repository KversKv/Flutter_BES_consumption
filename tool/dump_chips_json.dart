// 一次性脚本：把当前 lib/config/earbuds/ 下的 const kAllChips
// 序列化为 assets/data/earbuds_chips.json。
//
// 用法：
//   dart run tool/dump_chips_json.dart
//
// 生成后请勿手动编辑 lib 内的 const 数据；以后改数据请改 assets/data/earbuds_chips.json。
//
// 注意：该脚本不依赖 Flutter，仅依赖 dart:io + dart:convert + 项目 models。
// ignore_for_file: avoid_relative_lib_imports, deprecated_member_use_from_same_package
import 'dart:convert';
import 'dart:io';

import 'package:bes_consumption/config/earbuds/earbuds_chip_registry.dart';

void main() {
  const encoder = JsonEncoder.withIndent('  ');
  final payload = <String, dynamic>{
    'version': 1,
    'chips': kAllChips.map((c) => c.toJson()).toList(),
  };
  final text = encoder.convert(payload);
  final file = File('assets/data/earbuds_chips.json');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(text);
  stdout.writeln('Wrote ${file.path} (${text.length} bytes, ${kAllChips.length} chips)');
}
