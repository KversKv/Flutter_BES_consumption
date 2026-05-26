import 'package:bes_consumption/models/ble_chip.dart';
import 'package:bes_consumption/models/bt_chip.dart';
import 'package:bes_consumption/models/wifi_chip.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BLE tx power levels are derived from current map', () {
    final chip = BleChip.fromJson({
      'id': 'ble',
      'name': 'BLE',
      'txPowerLevelsDbm': [-20, 0, 4],
      'txCurrent_mA_forDbm': {'4': 8, '-20': 2, '0': 5},
    });

    expect(chip.txPowerLevelsDbm, [-20, 0, 4]);
    expect(chip.snapTxPower(3), 4);
    expect(chip.txCurrentForPower(3), 8);
    expect(chip.toJson().containsKey('txPowerLevelsDbm'), isFalse);
  });

  test('BT tx power levels keep legacy list only as empty-map fallback', () {
    final chip = BtChip.fromJson({
      'id': 'bt',
      'name': 'BT',
      'txPowerLevelsDbm': [1, 2],
      'txCurrent_mA_forDbm': <String, dynamic>{},
    });

    expect(chip.txPowerLevelsDbm, [1, 2]);
    expect(chip.snapTxPower(1.6), 2);
    expect(chip.txCurrentForPower(1.6), 0);
    expect(chip.toJson().containsKey('txPowerLevelsDbm'), isFalse);
  });

  test('Wi-Fi tx power levels no longer need txPowerLevelsDbm in JSON', () {
    final chip = WifiChip.fromJson({
      'id': 'wifi',
      'name': 'Wi-Fi',
      'txCurrent_mA_forDbm': {'10': 21, '0': 12},
    });

    expect(chip.txPowerLevelsDbm, [0, 10]);
    expect(chip.snapTxPower(7), 10);
    expect(chip.txCurrentForPower(7), 21);
    expect(chip.toJson().containsKey('txPowerLevelsDbm'), isFalse);
  });
}
