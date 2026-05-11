import 'dart:io';

/// 原生平台（Android/iOS/Windows/macOS/Linux）：
/// 把 zip 写入系统临时目录，返回绝对路径。
Future<String> deliverZip(String fileName, List<int> bytes) async {
  final dir = Directory.systemTemp;
  final file = File('${dir.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
