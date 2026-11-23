import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ChipBackendSnapshot {
  final Map<String, String> files;
  final String? revision;

  const ChipBackendSnapshot({required this.files, required this.revision});
}

class ChipSaveConflict implements Exception {
  final List<String> conflicts;

  ChipSaveConflict(List<String> conflicts)
      : conflicts = List.unmodifiable(conflicts);

  @override
  String toString() => 'ChipSaveConflict(${conflicts.join(', ')})';
}

/// 与最小后端 `tool/chip_server` 通信的客户端。
///
/// 协议（与 ChipJsonRepository.exportFiles() 的 map 结构一致）：
///   - GET  $base/api/chips        -> { "revision": ..., "files": { "chips/earbuds/Scene/index.json": "...", ... } }
///   - POST $base/api/chips        body { "baseRevision": ..., "actor": ..., "domain": ..., "files": { 相对路径: JSON字符串 } }
///
/// base 地址解析顺序：
///   1. 编译期注入 `--dart-define=CHIP_API_BASE=http://host:port`
///   2. 否则使用同源（部署时后端同时托管 web 与 API，base 为空即可）
class ChipBackendClient {
  ChipBackendClient._();

  static final ChipBackendClient instance = ChipBackendClient._();

  static const String _envBase =
      String.fromEnvironment('CHIP_API_BASE', defaultValue: '');

  /// 默认调试约定：Web 5174 调试时后端跑在 8088。
  /// 仅在未注入 CHIP_API_BASE 且为 Web 调试时作为兜底候选。
  static const String _devFallbackBase = 'http://localhost:8088';

  String _resolveBase() {
    if (_envBase.trim().isNotEmpty) return _envBase.trim();
    if (kIsWeb && kDebugMode) return _devFallbackBase;
    return '';
  }

  Uri _endpoint() => Uri.parse('${_resolveBase()}/api/chips');

  bool _available = false;
  bool get isAvailable => _available;

  /// 从后端读取全部 chips JSON 与 Git revision；不可用时返回 null。
  Future<ChipBackendSnapshot?> fetchFiles() async {
    try {
      final res = await http
          .get(_endpoint())
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) {
        _available = false;
        return null;
      }
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      final files = decoded is Map ? decoded['files'] : null;
      if (files is! Map) {
        _available = false;
        return null;
      }
      _available = true;
      return ChipBackendSnapshot(
        files: files.map(
          (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
        ),
        revision: decoded['revision']?.toString(),
      );
    } catch (e) {
      _available = false;
      debugPrint('[ChipBackendClient] fetch failed: $e');
      return null;
    }
  }

  /// 把 {相对路径: 内容} 写回后端，成功返回新 revision。
  Future<String?> saveFiles(
    Map<String, String> files, {
    String? baseRevision,
    String actor = 'unknown',
    String? domain,
  }) async {
    final res = await http
        .post(
          _endpoint(),
          headers: {'content-type': 'application/json; charset=utf-8'},
          body: jsonEncode({
            'baseRevision': baseRevision,
            'actor': actor,
            'domain': domain,
            'files': files,
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 409) {
      _available = true;
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      final rawConflicts = decoded is Map ? decoded['conflicts'] : null;
      throw ChipSaveConflict(
        rawConflicts is List
            ? rawConflicts.map((path) => path.toString()).toList()
            : const [],
      );
    }
    if (res.statusCode != 200) {
      _available = false;
      throw StateError('backend POST ${res.statusCode}: ${res.body}');
    }
    _available = true;
    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    return decoded is Map ? decoded['revision']?.toString() : null;
  }
}
