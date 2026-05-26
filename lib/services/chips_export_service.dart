import 'dart:convert' show utf8;

import 'package:archive/archive.dart';

import 'chips_export_io.dart'
    if (dart.library.html) 'chips_export_web.dart' as platform;

/// admin「导出 JSON」按钮的统一入口。
///
/// [files] 形如 `{ 'chips/earbuds/index.json': '...', 'chips/earbuds/1607.json': '...' }`，
/// 由 `EarbudsRepository.exportAsJsonFiles()` 提供。
///
/// 行为：
///   - 把 [files] 打成内存 zip
///   - Web：触发浏览器下载 `bes_chips_export.zip`
///   - 原生：写到系统临时目录，返回绝对路径
///
/// 返回：
///   - 下载或落盘成功时返回提示用的"位置字符串"（Web 端为文件名，原生端为绝对路径）
///   - 失败抛异常，调用方负责 SnackBar 兜底
Future<String> saveChipsExportZip(
  Map<String, String> files, {
  String fileName = 'bes_chips_export.zip',
}) async {
  final archive = Archive();
  files.forEach((path, content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  });
  final zipBytes = ZipEncoder().encode(archive);
  if (zipBytes == null) {
    throw StateError('zip encode returned null');
  }
  return platform.deliverZip(fileName, zipBytes);
}
