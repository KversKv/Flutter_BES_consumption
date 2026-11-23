import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

/// bes_consumption admin 数据落地后端（最小实现）。
///
/// 职责：
///   - GET  /api/chips  读取 assets/data/chips/ 下全部 JSON，返回 {files:{相对路径:内容}}
///   - POST /api/chips  接收同样结构的 {files:{...}}，校验后写回 JSON 源文件；
///                      CHIP_GIT_COMMIT=1 时提交 Git，否则写前备份
///   - GET  /api/history 读取芯片 Git 提交与工作区状态
///   - GET  /api/history/<sha> 读取单提交的芯片 diff
///   - 其余路径：静态托管 web build 产物（若存在），便于部署时一个服务同时发前端 + API
///
/// 协议中的「相对路径」与前端 ChipJsonRepository.exportFiles() 完全一致，
/// 形如 `chips/earbuds/Scene/index.json`、`chips/earbuds/Scene/1607.json`，
/// 落盘根目录为 <projectRoot>/assets/data/。
void main(List<String> args) async {
  final projectRoot = _resolveProjectRoot();
  final chipsRoot = Directory('${projectRoot.path}/assets/data');
  final backupRoot = Directory('${projectRoot.path}/.chip_backups');
  final webRoot = Directory('${projectRoot.path}/build/web');
  final gitCommit = Platform.environment['CHIP_GIT_COMMIT'] == '1';

  final port = int.tryParse(
        Platform.environment['CHIP_SERVER_PORT'] ??
            (args.isNotEmpty ? args.first : ''),
      ) ??
      8088;

  final router = Router();

  router.get('/api/chips', (Request req) async {
    final files = <String, String>{};
    final dir = Directory('${chipsRoot.path}/chips');
    if (await dir.exists()) {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is! File) continue;
        if (!entity.path.toLowerCase().endsWith('.json')) continue;
        final rel = _relativePosix(chipsRoot.path, entity.path);
        files[rel] = await entity.readAsString();
      }
    }
    return Response.ok(
      jsonEncode({'files': files, 'revision': await _gitRevision(projectRoot)}),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });

  router.post('/api/chips', (Request req) {
    return _enqueueWrite(
      () => _saveChips(req, chipsRoot, backupRoot, projectRoot, gitCommit),
    );
  });

  router.get(
    '/api/history',
    (Request req) => _history(req, projectRoot),
  );
  router.get(
    '/api/history/<sha>',
    (Request req, String sha) => _historyDiff(projectRoot, sha),
  );

  Response notFound(Request req) => Response.notFound('not found');

  Handler webHandler = (Request req) async => notFound(req);
  if (await webRoot.exists()) {
    webHandler = (Request req) async {
      var rel = req.url.path;
      if (rel.isEmpty) rel = 'index.html';
      var file = File('${webRoot.path}/$rel');
      if (!await file.exists()) {
        file = File('${webRoot.path}/index.html');
      }
      if (!await file.exists()) return notFound(req);
      final bytes = await file.readAsBytes();
      return Response.ok(bytes, headers: {
        'content-type': _contentTypeFor(file.path),
      });
    };
  }

  final handler = const Pipeline().addMiddleware(_cors()).addHandler(
    (Request req) async {
      if (req.url.path.startsWith('api/')) {
        return router.call(req);
      }
      return webHandler(req);
    },
  );

  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  stdout.writeln('[chip_server] listening on http://localhost:${server.port}');
  stdout.writeln('[chip_server] chips root : ${chipsRoot.path}/chips');
  stdout.writeln(
    gitCommit
        ? '[chip_server] git commits: enabled'
        : '[chip_server] backups in : ${backupRoot.path}',
  );
  if (await webRoot.exists()) {
    stdout.writeln('[chip_server] serving web: ${webRoot.path}');
  } else {
    stdout.writeln('[chip_server] web build not found (API-only mode)');
  }
}

Future<void> _writeQueue = Future<void>.value();

Future<T> _enqueueWrite<T>(Future<T> Function() action) {
  final result = _writeQueue.then((_) => action());
  _writeQueue = result.then<void>(
    (_) {},
    onError: (Object error, StackTrace stackTrace) {},
  );
  return result;
}

Future<Response> _saveChips(
  Request req,
  Directory chipsRoot,
  Directory backupRoot,
  Directory projectRoot,
  bool gitCommit,
) async {
  Map<String, dynamic> decoded;
  try {
    decoded = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
  } catch (e) {
    return Response(400, body: 'invalid json: $e');
  }

  final rawFiles = decoded['files'];
  if (rawFiles is! Map) {
    return Response(400, body: 'missing "files" object');
  }

  final files = <String, String>{};
  for (final entry in rawFiles.entries) {
    final rel = entry.key.toString();
    final content = entry.value?.toString() ?? '';
    if (!_isSafeRelative(rel)) {
      return Response(400, body: 'unsafe path: $rel');
    }
    try {
      jsonDecode(content);
    } catch (e) {
      return Response(400, body: 'invalid json for $rel: $e');
    }
    files[rel] = content;
  }

  final revision = await _gitRevision(projectRoot);
  if (!gitCommit && revision == null) {
    return _saveWithBackup(files, chipsRoot, backupRoot);
  }

  try {
    return await _saveWithGit(
      files,
      decoded,
      chipsRoot,
      projectRoot,
      commit: gitCommit,
      backupRoot: gitCommit ? null : backupRoot,
    );
  } catch (e) {
    stderr.writeln('[chip_server] git save failed: $e');
    return Response(500, body: 'git save failed: $e');
  }
}

Future<Response> _saveWithBackup(
  Map<String, String> files,
  Directory chipsRoot,
  Directory backupRoot,
) async {
  final stamp = DateTime.now()
      .toIso8601String()
      .replaceAll(':', '-')
      .replaceAll('.', '-');
  final backupDir = Directory('${backupRoot.path}/$stamp');
  final written = <String>[];

  for (final entry in files.entries) {
    final rel = entry.key;
    final target = File('${chipsRoot.path}/$rel');
    if (await target.exists()) {
      final backupFile = File('${backupDir.path}/$rel');
      await backupFile.parent.create(recursive: true);
      await target.copy(backupFile.path);
    }
    await target.parent.create(recursive: true);
    await target.writeAsString(entry.value, flush: true);
    written.add(rel);
  }

  return Response.ok(
    jsonEncode({
      'ok': true,
      'written': written.length,
      'backup': written.isEmpty ? null : backupDir.path,
      'revision': null,
    }),
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

Future<Response> _saveWithGit(
  Map<String, String> files,
  Map<String, dynamic> request,
  Directory chipsRoot,
  Directory projectRoot, {
  required bool commit,
  required Directory? backupRoot,
}) async {
  final baseRevision =
      await _resolveBaseRevision(projectRoot, request['baseRevision']);
  final domainDirs =
      files.keys.map((rel) => rel.substring(0, rel.lastIndexOf('/'))).toSet();
  final paths = <String>{...files.keys};

  for (final domainDir in domainDirs) {
    final tree = await _runGit(projectRoot, [
      'ls-tree',
      '-r',
      '--name-only',
      baseRevision,
      '--',
      'assets/data/$domainDir',
    ]);
    for (final repoPath in tree.stdout.toString().split(RegExp(r'\r?\n'))) {
      if (!repoPath.startsWith('assets/data/chips/') ||
          !repoPath.toLowerCase().endsWith('.json')) {
        continue;
      }
      paths.add(repoPath.substring('assets/data/'.length));
    }
  }

  final writes = <String, String>{};
  final deleted = <String>[];
  final conflicts = <String>[];
  final sortedPaths = paths.toList()..sort();
  for (final rel in sortedPaths) {
    final base = await _readBaseJson(projectRoot, baseRevision, rel);
    final current =
        files.containsKey(rel) ? jsonDecode(files[rel]!) : _jsonAbsent;
    if (_jsonEquals(current, base)) continue;

    final disk = await _readCurrentJson(chipsRoot, rel);
    if (_jsonEquals(disk, base)) {
      if (identical(current, _jsonAbsent)) {
        deleted.add(rel);
      } else {
        writes[rel] = files[rel]!;
      }
    } else if (!_jsonEquals(disk, current)) {
      conflicts.add(rel);
    }
  }

  if (conflicts.isNotEmpty) {
    return Response(
      409,
      body: jsonEncode({
        'revision': await _gitRevision(projectRoot),
        'conflicts': conflicts,
      }),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  final touched = <String>[...writes.keys, ...deleted];
  Directory? backupDir;
  if (backupRoot != null && touched.isNotEmpty) {
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    backupDir = Directory('${backupRoot.path}/$stamp');
    for (final rel in touched) {
      final target = File('${chipsRoot.path}/$rel');
      if (!await target.exists()) continue;
      final backupFile = File('${backupDir.path}/$rel');
      await backupFile.parent.create(recursive: true);
      await target.copy(backupFile.path);
    }
  }

  for (final rel in deleted) {
    final target = File('${chipsRoot.path}/$rel');
    if (await target.exists()) await target.delete();
  }
  for (final entry in writes.entries) {
    final target = File('${chipsRoot.path}/${entry.key}');
    await target.parent.create(recursive: true);
    await target.writeAsString(entry.value, flush: true);
  }

  final changed = <String>[];
  if (commit && touched.isNotEmpty) {
    final repoPaths = touched.map(_repoPath).toList();
    await _runGit(projectRoot, ['add', '--', ...repoPaths]);
    final diff = await _runGit(
      projectRoot,
      ['diff', '--cached', '--name-only', '--', ...repoPaths],
    );
    changed.addAll(
      diff.stdout
          .toString()
          .split(RegExp(r'\r?\n'))
          .where((line) => line.trim().isNotEmpty),
    );
  }

  if (changed.isNotEmpty) {
    final actor = (request['actor'] ?? 'unknown').toString().trim();
    final safeActor = actor.isEmpty ? 'unknown' : actor;
    final domain = _commitDomain(request['domain'], changed);
    final ids = changed
        .map(_chipIdFromRepoPath)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
    final idSummary = ids.isEmpty ? 'index' : ids.join(', ');
    await _runGit(projectRoot, [
      'commit',
      '--author',
      '$safeActor <$safeActor@chip-admin>',
      '-m',
      'admin($domain): $idSummary',
    ]);
  }

  return Response.ok(
    jsonEncode({
      'ok': true,
      'written': writes.length,
      'deleted': deleted.length,
      'backup': backupDir?.path,
      'revision': await _gitRevision(projectRoot),
    }),
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

const Object _jsonAbsent = Object();

Future<String> _resolveBaseRevision(
  Directory projectRoot,
  dynamic rawRevision,
) async {
  final requested = rawRevision?.toString().trim() ?? '';
  final candidate = requested.isEmpty ? 'HEAD' : requested;
  final result = await _runGit(
    projectRoot,
    ['rev-parse', '--verify', '$candidate^{commit}'],
  );
  return result.stdout.toString().trim();
}

Future<dynamic> _readBaseJson(
  Directory projectRoot,
  String baseRevision,
  String rel,
) async {
  final result = await Process.run(
    'git',
    ['show', '$baseRevision:${_repoPath(rel)}'],
    workingDirectory: projectRoot.path,
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  if (result.exitCode != 0) return _jsonAbsent;
  return jsonDecode(result.stdout.toString());
}

Future<dynamic> _readCurrentJson(Directory chipsRoot, String rel) async {
  final file = File('${chipsRoot.path}/$rel');
  if (!await file.exists()) return _jsonAbsent;
  return jsonDecode(await file.readAsString());
}

bool _jsonEquals(dynamic a, dynamic b) {
  if (identical(a, b)) return true;
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key) ||
          !_jsonEquals(entry.value, b[entry.key])) {
        return false;
      }
    }
    return true;
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_jsonEquals(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}

String _repoPath(String rel) => 'assets/data/$rel';

String _commitDomain(dynamic rawDomain, List<String> changed) {
  final requested = rawDomain?.toString().trim() ?? '';
  if (requested.isNotEmpty) return requested;

  final dirs = changed
      .map((path) {
        final start = path.indexOf('chips/');
        final end = path.lastIndexOf('/');
        if (start < 0 || end <= start) return null;
        return path.substring(start + 'chips/'.length, end);
      })
      .whereType<String>()
      .toSet();
  return dirs.length == 1 ? dirs.single : 'chips';
}

String? _chipIdFromRepoPath(String path) {
  final name = path.split('/').last;
  if (name == 'index.json' || !name.endsWith('.json')) return null;
  return name.substring(0, name.length - '.json'.length);
}

Future<String?> _gitRevision(Directory projectRoot) async {
  try {
    final result = await Process.run(
      'git',
      ['rev-parse', 'HEAD'],
      workingDirectory: projectRoot.path,
    );
    if (result.exitCode != 0) return null;
    final revision = result.stdout.toString().trim();
    return revision.isEmpty ? null : revision;
  } catch (_) {
    return null;
  }
}

Future<Response> _history(Request req, Directory projectRoot) async {
  final domain = req.url.queryParameters['domain']?.trim() ?? '';
  if (!_isSafeHistoryDomain(domain)) {
    return Response(400, body: 'unsafe domain: $domain');
  }

  final limit = int.tryParse(req.url.queryParameters['limit'] ?? '30');
  final skip = int.tryParse(req.url.queryParameters['skip'] ?? '0');
  if (limit == null || limit <= 0 || skip == null || skip < 0) {
    return Response(400, body: 'invalid limit or skip');
  }
  if (!await _isGitRepository(projectRoot)) return _historyNotGit();

  final path =
      domain.isEmpty ? 'assets/data/chips' : 'assets/data/chips/$domain';
  try {
    final log = await _runGit(projectRoot, [
      'log',
      '--format=%H%x1f%an%x1f%aI%x1f%s',
      '-n',
      '$limit',
      '--skip',
      '$skip',
      '--',
      path,
    ]);
    final status = await _runGit(projectRoot, [
      'status',
      '--porcelain',
      '--',
      'assets/data/chips',
    ]);
    final entries = <Map<String, String>>[];
    for (final line in log.stdout.toString().split(RegExp(r'\r?\n'))) {
      if (line.isEmpty) continue;
      final fields = line.split('\x1f');
      if (fields.length < 4) continue;
      entries.add({
        'sha': fields[0],
        'author': fields[1],
        'time': fields[2],
        'subject': fields.sublist(3).join('\x1f'),
      });
    }
    return Response.ok(
      jsonEncode({
        'entries': entries,
        'uncommitted': _uncommittedPaths(status.stdout.toString()),
      }),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  } catch (e) {
    stderr.writeln('[chip_server] git history failed: $e');
    return Response(500, body: 'git history failed: $e');
  }
}

Future<Response> _historyDiff(Directory projectRoot, String sha) async {
  if (!RegExp(r'^[0-9a-fA-F]{7,40}$').hasMatch(sha)) {
    return Response(400, body: 'invalid sha');
  }
  if (!await _isGitRepository(projectRoot)) return _historyNotGit();

  try {
    final result = await _runGit(projectRoot, [
      'show',
      '--format=',
      sha,
      '--',
      'assets/data/chips',
    ]);
    return Response.ok(
      jsonEncode({'sha': sha, 'diff': result.stdout.toString()}),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  } catch (e) {
    return Response(404, body: 'git show failed: $e');
  }
}

Response _historyNotGit() => Response(
      501,
      body: jsonEncode({'error': 'not a git repository'}),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Future<bool> _isGitRepository(Directory projectRoot) async {
  try {
    final result = await Process.run(
      'git',
      ['rev-parse', '--is-inside-work-tree'],
      workingDirectory: projectRoot.path,
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    return result.exitCode == 0 && result.stdout.toString().trim() == 'true';
  } catch (_) {
    return false;
  }
}

bool _isSafeHistoryDomain(String domain) {
  if (domain.isEmpty) return true;
  return RegExp(r'^[A-Za-z0-9_-]+(?:/[A-Za-z0-9_-]+)*$').hasMatch(domain);
}

List<String> _uncommittedPaths(String status) {
  final paths = <String>[];
  for (final line in status.split(RegExp(r'\r?\n'))) {
    if (line.length < 4) continue;
    var path = line.substring(3);
    final rename = path.indexOf(' -> ');
    if (rename >= 0) path = path.substring(rename + 4);
    const prefix = 'assets/data/';
    if (path.startsWith('${prefix}chips/')) {
      paths.add(path.substring(prefix.length));
    }
  }
  return paths;
}

Future<ProcessResult> _runGit(
  Directory projectRoot,
  List<String> args,
) async {
  final result = await Process.run(
    'git',
    args,
    workingDirectory: projectRoot.path,
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  if (result.exitCode != 0) {
    throw StateError(
      'git ${args.join(' ')} failed (${result.exitCode}): '
      '${result.stderr.toString().trim()}',
    );
  }
  return result;
}

Middleware _cors() {
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept',
  };
  return (Handler inner) {
    return (Request req) async {
      if (req.method == 'OPTIONS') {
        return Response.ok('', headers: headers);
      }
      final res = await inner(req);
      return res.change(headers: {...res.headers, ...headers});
    };
  };
}

/// 解析项目根目录：从 bin/ 向上两级到 tool/chip_server/，再向上两级到项目根。
Directory _resolveProjectRoot() {
  final override = Platform.environment['CHIP_PROJECT_ROOT'];
  if (override != null && override.trim().isNotEmpty) {
    return Directory(override.trim());
  }
  final script = File(Platform.script.toFilePath());
  // .../tool/chip_server/bin/server.dart -> 项目根 = bin 的上上上级
  final root = script.parent.parent.parent.parent;
  return root;
}

String _relativePosix(String base, String full) {
  var rel = full.substring(base.length);
  rel = rel.replaceAll('\\', '/');
  if (rel.startsWith('/')) rel = rel.substring(1);
  return rel;
}

bool _isSafeRelative(String rel) {
  if (rel.isEmpty) return false;
  if (rel.contains('..')) return false;
  if (rel.startsWith('/') || rel.startsWith('\\')) return false;
  if (!rel.startsWith('chips/')) return false;
  if (!rel.toLowerCase().endsWith('.json')) return false;
  return true;
}

String _contentTypeFor(String path) {
  final p = path.toLowerCase();
  if (p.endsWith('.html')) return 'text/html; charset=utf-8';
  if (p.endsWith('.js')) return 'application/javascript; charset=utf-8';
  if (p.endsWith('.json')) return 'application/json; charset=utf-8';
  if (p.endsWith('.css')) return 'text/css; charset=utf-8';
  if (p.endsWith('.wasm')) return 'application/wasm';
  if (p.endsWith('.png')) return 'image/png';
  if (p.endsWith('.svg')) return 'image/svg+xml';
  if (p.endsWith('.ico')) return 'image/x-icon';
  return 'application/octet-stream';
}
