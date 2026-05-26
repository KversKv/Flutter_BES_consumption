import 'package:bes_consumption/models/earbuds.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Earbuds mcuRun accepts map form and exports map form', () {
    final chip = EarbudsChip.fromJson({
      'id': 'demo',
      'massProduction': true,
      'mcuRun': {
        'M55': {
          'wfi24M': 1.2,
          'cm24M': 2.3,
        },
      },
      'txSweep': {
        'VPA=1.7V': {
          'values': {'0': 10.0, '4': 12.0},
        },
      },
    });

    expect(chip.mcuRun.single.label, 'M55');
    expect(chip.mcuRun.single.wfi24M, 1.2);
    expect(chip.txSweep.single.label, 'VPA=1.7V');
    expect(chip.txSweep.single.values[4], 12.0);

    final json = chip.toJson();
    expect(json['mcuRun'], isA<Map<String, dynamic>>());
    expect(json['mcuRun']['M55']['label'], isNull);
    expect(json['txSweep'], isA<Map<String, dynamic>>());
    expect(json['txSweep']['VPA=1.7V']['label'], isNull);
  });

  test('Earbuds mcuRun remains compatible with legacy list form', () {
    final chip = EarbudsChip.fromJson({
      'id': 'legacy',
      'massProduction': false,
      'mcuRun': [
        {'label': 'default', 'cm96M': 3.4},
      ],
      'txSweep': [
        {
          'label': 'polar',
          'values': {'1': 9.5},
        },
      ],
    });

    expect(chip.mcuRun.single.label, 'default');
    expect(chip.mcuRun.single.cm96M, 3.4);
    expect(chip.txSweep.single.label, 'polar');
    expect(chip.toJson()['mcuRun'], isA<Map<String, dynamic>>());
    expect(chip.toJson()['txSweep'], isA<Map<String, dynamic>>());
  });
}
