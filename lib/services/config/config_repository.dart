import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../config/ble_chip_config.dart';
import '../../config/bt_chip_config.dart';
import '../../config/wifi_chip_config.dart';
import '../../models/ble_chip.dart';
import '../../models/bt_chip.dart';
import '../../models/earbuds.dart';
import '../../models/wifi_chip.dart';
import '../earbuds_repository.dart';

class ConfigRepository extends ChangeNotifier {
  ConfigRepository._();

  static final ConfigRepository instance = ConfigRepository._();

  static const String bleChipsDir = 'assets/data/chips/ble';
  static const String btChipsDir = 'assets/data/chips/bt';
  static const String wifiChipsDir = 'assets/data/chips/wifi';

  List<BleChip> _bleChips = defaultBleChips;
  List<BtChip> _btChips = defaultBtChips;
  List<WifiChip> _wifiChips = defaultWifiChips;
  bool _loaded = false;

  bool get isLoaded => _loaded;
  List<BleChip> get bleChips => _bleChips;
  List<BtChip> get btChips => _btChips;
  List<WifiChip> get wifiChips => _wifiChips;

  Future<void> load() async {
    if (_loaded) return;
    final loaded = await Future.wait<Object>([
      _loadIndexedList<BleChip>(
        bleChipsDir,
        (j) => BleChip.fromJson(j),
        defaultBleChips,
      ),
      _loadIndexedList<BtChip>(
        btChipsDir,
        (j) => BtChip.fromJson(j),
        defaultBtChips,
      ),
      _loadIndexedList<WifiChip>(
        wifiChipsDir,
        (j) => WifiChip.fromJson(j),
        defaultWifiChips,
      ),
    ]);
    _bleChips = loaded[0] as List<BleChip>;
    _btChips = loaded[1] as List<BtChip>;
    _wifiChips = loaded[2] as List<WifiChip>;
    _loaded = true;
    notifyListeners();
  }

  List<EarbudsChip> get earbudsChips => EarbudsRepository.instance.chips;

  Future<List<T>> _loadIndexedList<T>(
    String assetDir,
    T Function(Map<String, dynamic>) decode,
    List<T> fallback,
  ) async {
    try {
      final indexRaw = await rootBundle.loadString('$assetDir/index.json');
      final index = jsonDecode(indexRaw);
      final items = index is Map ? index['items'] : null;
      if (items is! List) return List<T>.unmodifiable(fallback);
      final futures = <Future<T?>>[];
      for (final item in items) {
        final file = _indexFileName(item);
        if (file == null || file.isEmpty) continue;
        futures.add(rootBundle.loadString('$assetDir/$file').then((raw) {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            return decode(Map<String, dynamic>.from(decoded));
          }
          return null;
        }));
      }
      final chips =
          (await Future.wait(futures)).whereType<T>().toList(growable: false);
      return List<T>.unmodifiable(chips);
    } catch (e, st) {
      debugPrint('[ConfigRepository] load $assetDir failed: $e\n$st');
      return List<T>.unmodifiable(fallback);
    }
  }

  String? _indexFileName(dynamic item) {
    if (item is String) return '$item.json';
    if (item is Map) {
      final file = item['file'];
      if (file is String) return file;
      final id = item['id'];
      if (id is String) return '$id.json';
    }
    return null;
  }

  Map<String, String> exportFiles() {
    const encoder = JsonEncoder.withIndent('  ');
    return {
      'chips/ble/index.json': encoder.convert({
        'version': 1,
        'items': _bleChips
            .map((c) => {'id': c.id, 'file': '${_safeFileName(c.id)}.json'})
            .toList(),
      }),
      for (final c in _bleChips)
        'chips/ble/${_safeFileName(c.id)}.json': encoder.convert(c.toJson()),
      'chips/bt/index.json': encoder.convert({
        'version': 1,
        'items': _btChips
            .map((c) => {'id': c.id, 'file': '${_safeFileName(c.id)}.json'})
            .toList(),
      }),
      for (final c in _btChips)
        'chips/bt/${_safeFileName(c.id)}.json': encoder.convert(c.toJson()),
      'chips/wifi/index.json': encoder.convert({
        'version': 1,
        'items': _wifiChips
            .map((c) => {'id': c.id, 'file': '${_safeFileName(c.id)}.json'})
            .toList(),
      }),
      for (final c in _wifiChips)
        'chips/wifi/${_safeFileName(c.id)}.json': encoder.convert(c.toJson()),
      ...EarbudsRepository.instance.exportAsJsonFiles(),
    };
  }

  void replaceBleChips(List<BleChip> chips) {
    _bleChips = List<BleChip>.unmodifiable(chips);
    notifyListeners();
  }

  void replaceBtChips(List<BtChip> chips) {
    _btChips = List<BtChip>.unmodifiable(chips);
    notifyListeners();
  }

  void replaceWifiChips(List<WifiChip> chips) {
    _wifiChips = List<WifiChip>.unmodifiable(chips);
    notifyListeners();
  }

  String _safeFileName(String id) {
    final buf = StringBuffer();
    for (final r in id.runes) {
      final c = String.fromCharCode(r);
      if (RegExp(r'[A-Za-z0-9_\-]').hasMatch(c)) {
        buf.write(c);
      } else {
        buf.write('_');
      }
    }
    final safe = buf.toString().replaceAll(RegExp(r'_+'), '_');
    return safe.replaceAll(RegExp(r'^_|_$'), '').isEmpty
        ? 'chip'
        : safe.replaceAll(RegExp(r'^_|_$'), '');
  }
}
