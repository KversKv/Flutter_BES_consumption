import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// 解析 .xlsx / .csv 中的 NoisePink 详情数据。
///
/// 期望表头列（大小写、空格不敏感）：
/// BES ID, Board Name, Vsys, Vcore, VcoreM, VcoreL, Vana, Vhppa,
/// Isys, Icore, IcoreM, IcoreL, Iana, Ihppa, Isys_remain。
///
/// 缺失值（空或 "/"）解析为 null。返回值 key 为去掉 "BES" 前缀并小写后的 ID。
class NoisePinkSyncService {
  static const Map<String, String> _columnAliases = {
    'besid': 'id',
    'id': 'id',
    'vsys': 'vsys',
    'vcore': 'vcore',
    'vcorem': 'vcoreM',
    'vcorel': 'vcoreL',
    'vana': 'vana',
    'vhppa': 'vhppa',
    'isys': 'isys',
    'icore': 'icore',
    'icorem': 'icoreM',
    'icorel': 'icoreL',
    'iana': 'iana',
    'ihppa': 'ihppa',
    'isysremain': 'isysRemain',
    'isys_remain': 'isysRemain',
  };

  static const List<String> _fieldKeys = [
    'vsys',
    'vcore',
    'vcoreM',
    'vcoreL',
    'vana',
    'vhppa',
    'isys',
    'icore',
    'icoreM',
    'icoreL',
    'iana',
    'ihppa',
    'isysRemain',
  ];

  /// 根据文件名后缀与字节内容解析。
  static Map<String, Map<String, dynamic>> parse(
    String fileName,
    Uint8List bytes,
  ) {
    final lower = fileName.toLowerCase();
    final List<List<String>> rows;
    if (lower.endsWith('.csv')) {
      rows = _parseCsv(bytes);
    } else {
      rows = _parseXlsx(bytes);
    }
    return _rowsToDetails(rows);
  }

  static Map<String, Map<String, dynamic>> _rowsToDetails(
    List<List<String>> rows,
  ) {
    if (rows.isEmpty) return {};

    int headerIndex = -1;
    Map<int, String> columnMap = {};
    for (var i = 0; i < rows.length; i++) {
      final candidate = _matchHeader(rows[i]);
      if (candidate != null && candidate.containsValue('id')) {
        headerIndex = i;
        columnMap = candidate;
        break;
      }
    }
    if (headerIndex < 0) return {};

    final out = <String, Map<String, dynamic>>{};
    for (var r = headerIndex + 1; r < rows.length; r++) {
      final row = rows[r];
      String? id;
      final detail = <String, dynamic>{};
      columnMap.forEach((col, field) {
        final raw = col < row.length ? row[col].trim() : '';
        if (field == 'id') {
          id = _normalizeId(raw);
        } else {
          detail[field] = _toNumber(raw);
        }
      });
      if (id == null || id!.isEmpty) continue;
      for (final key in _fieldKeys) {
        detail.putIfAbsent(key, () => null);
      }
      out[id!] = detail;
    }
    return out;
  }

  static Map<int, String>? _matchHeader(List<String> row) {
    final map = <int, String>{};
    for (var i = 0; i < row.length; i++) {
      final key = row[i].toLowerCase().replaceAll(RegExp(r'\s+'), '');
      final field = _columnAliases[key];
      if (field != null && !map.containsValue(field)) {
        map[i] = field;
      }
    }
    return map.isEmpty ? null : map;
  }

  static String _normalizeId(String raw) {
    var v = raw.trim();
    if (v.toLowerCase().startsWith('bes')) {
      v = v.substring(3);
    }
    return v.trim().toLowerCase();
  }

  static double? _toNumber(String raw) {
    final v = raw.trim();
    if (v.isEmpty || v == '/' || v == '-' || v.toLowerCase() == 'na') {
      return null;
    }
    return double.tryParse(v);
  }

  // ---------------- CSV ----------------

  static List<List<String>> _parseCsv(Uint8List bytes) {
    final text = _decodeText(bytes);
    final rows = <List<String>>[];
    for (final line in const LineSplitter().convert(text)) {
      if (line.trim().isEmpty) continue;
      rows.add(_splitCsvLine(line));
    }
    return rows;
  }

  static List<String> _splitCsvLine(String line) {
    final cells = <String>[];
    final buf = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buf.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == ',' && !inQuotes) {
        cells.add(buf.toString());
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    cells.add(buf.toString());
    return cells;
  }

  static String _decodeText(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return utf8.decode(bytes.sublist(3), allowMalformed: true);
    }
    return utf8.decode(bytes, allowMalformed: true);
  }

  // ---------------- XLSX ----------------

  static List<List<String>> _parseXlsx(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final files = <String, ArchiveFile>{
      for (final f in archive.files) f.name: f,
    };

    final sharedStrings = _readSharedStrings(files['xl/sharedStrings.xml']);

    final sheetFile = _firstWorksheet(files);
    if (sheetFile == null) return [];
    final sheetXml = _fileToString(sheetFile);
    return _parseSheet(sheetXml, sharedStrings);
  }

  static ArchiveFile? _firstWorksheet(Map<String, ArchiveFile> files) {
    final names = files.keys
        .where((n) =>
            n.startsWith('xl/worksheets/') && n.toLowerCase().endsWith('.xml'))
        .toList()
      ..sort();
    if (names.isEmpty) return null;
    return files[names.first];
  }

  static List<String> _readSharedStrings(ArchiveFile? file) {
    if (file == null) return const [];
    final xml = _fileToString(file);
    final result = <String>[];
    final siRegex = RegExp(r'<si\b[^>]*>([\s\S]*?)</si>', multiLine: true);
    final tRegex = RegExp(r'<t\b[^>]*>([\s\S]*?)</t>', multiLine: true);
    for (final m in siRegex.allMatches(xml)) {
      final inner = m.group(1) ?? '';
      final buf = StringBuffer();
      for (final t in tRegex.allMatches(inner)) {
        buf.write(_unescapeXml(t.group(1) ?? ''));
      }
      result.add(buf.toString());
    }
    return result;
  }

  static List<List<String>> _parseSheet(
    String xml,
    List<String> sharedStrings,
  ) {
    final rows = <int, Map<int, String>>{};
    final rowRegex = RegExp(r'<row\b[^>]*\br="(\d+)"[^>]*>([\s\S]*?)</row>',
        multiLine: true);
    final cellRegex = RegExp(
        r'<c\b[^>]*\br="([A-Z]+)(\d+)"([^>]*)>([\s\S]*?)</c>',
        multiLine: true);
    final emptyCellRegex =
        RegExp(r'<c\b[^>]*\br="([A-Z]+)(\d+)"([^>]*)/>', multiLine: true);

    void handleCell(String colRef, int rowNum, String attrs, String inner) {
      final col = _colToIndex(colRef);
      final typeMatch = RegExp(r't="([^"]+)"').firstMatch(attrs);
      final type = typeMatch?.group(1);
      final vMatch =
          RegExp(r'<v\b[^>]*>([\s\S]*?)</v>', multiLine: true).firstMatch(inner);
      String value;
      if (type == 's') {
        final idx = int.tryParse(_unescapeXml(vMatch?.group(1) ?? ''));
        value = (idx != null && idx >= 0 && idx < sharedStrings.length)
            ? sharedStrings[idx]
            : '';
      } else if (type == 'inlineStr') {
        final tMatch = RegExp(r'<t\b[^>]*>([\s\S]*?)</t>', multiLine: true)
            .firstMatch(inner);
        value = _unescapeXml(tMatch?.group(1) ?? '');
      } else {
        value = _unescapeXml(vMatch?.group(1) ?? '');
      }
      rows.putIfAbsent(rowNum, () => {})[col] = value;
    }

    for (final rm in rowRegex.allMatches(xml)) {
      final rowNum = int.parse(rm.group(1)!);
      final body = rm.group(2) ?? '';
      for (final cm in cellRegex.allMatches(body)) {
        handleCell(cm.group(1)!, rowNum, cm.group(3) ?? '', cm.group(4) ?? '');
      }
      for (final cm in emptyCellRegex.allMatches(body)) {
        rows.putIfAbsent(rowNum, () => {})[_colToIndex(cm.group(1)!)] = '';
      }
    }

    if (rows.isEmpty) return [];
    final maxRow = rows.keys.reduce((a, b) => a > b ? a : b);
    final out = <List<String>>[];
    for (var r = 1; r <= maxRow; r++) {
      final cells = rows[r];
      if (cells == null || cells.isEmpty) {
        out.add(const []);
        continue;
      }
      final maxCol = cells.keys.reduce((a, b) => a > b ? a : b);
      final line = List<String>.filled(maxCol + 1, '');
      cells.forEach((c, v) => line[c] = v);
      out.add(line);
    }
    return out;
  }

  static int _colToIndex(String col) {
    var result = 0;
    for (final code in col.codeUnits) {
      result = result * 26 + (code - 64);
    }
    return result - 1;
  }

  static String _fileToString(ArchiveFile file) {
    final content = file.content;
    if (content is List<int>) {
      return utf8.decode(content, allowMalformed: true);
    }
    return content.toString();
  }

  static String _unescapeXml(String s) => s
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&');
}
