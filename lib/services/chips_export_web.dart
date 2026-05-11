// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

/// Web 平台：用 Blob + AnchorElement 触发浏览器下载。
/// 返回值用作 SnackBar 提示，浏览器无法暴露真实保存路径。
Future<String> deliverZip(String fileName, List<int> bytes) async {
  final blob = html.Blob(<dynamic>[Uint8List.fromList(bytes)],
      'application/zip');
  final url = html.Url.createObjectUrlFromBlob(blob);
  try {
    final anchor = html.AnchorElement(href: url)
      ..download = fileName
      ..style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
  } finally {
    html.Url.revokeObjectUrl(url);
  }
  return fileName;
}
