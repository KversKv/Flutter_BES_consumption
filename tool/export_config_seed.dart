import 'dart:convert';
import 'dart:io';

import 'package:bes_consumption/config/ble_chip_config.dart';
import 'package:bes_consumption/config/bt_chip_config.dart';
import 'package:bes_consumption/config/wifi_chip_config.dart';

void main() {
  const encoder = JsonEncoder.withIndent('  ');
  _writeDomain(
    domain: 'ble',
    chips: defaultBleChips,
    toJson: (chip) => chip.toJson(),
    encoder: encoder,
  );
  _writeDomain(
    domain: 'bt',
    chips: defaultBtChips,
    toJson: (chip) => chip.toJson(),
    encoder: encoder,
  );
  _writeDomain(
    domain: 'wifi',
    chips: defaultWifiChips,
    toJson: (chip) => chip.toJson(),
    encoder: encoder,
  );
}

void _writeDomain<T>({
  required String domain,
  required List<T> chips,
  required Map<String, dynamic> Function(T chip) toJson,
  required JsonEncoder encoder,
}) {
  final items = <Map<String, String>>[];
  for (final chip in chips) {
    final json = toJson(chip);
    final id = json['id'] as String;
    final fileName = '${_safeFileName(id)}.json';
    items.add({'id': id, 'file': fileName});
    _writeJson('assets/data/chips/$domain/$fileName', json, encoder);
  }
  _writeJson('assets/data/chips/$domain/index.json', {
    'version': 1,
    'items': items,
  }, encoder);
}

void _writeJson(String path, Object value, JsonEncoder encoder) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync('${encoder.convert(value)}\n');
}

String _safeFileName(String id) {
  final safe = id.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
  final trimmed = safe.replaceAll(RegExp(r'^_+|_+$'), '');
  return trimmed.isEmpty ? 'chip' : trimmed;
}
