import 'package:bes_consumption/models/bt_chip.dart';
import 'package:bes_consumption/state/bt_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BT state initializes supply voltage from selected chip vbat', () {
    final state = BTState();

    expect(state.supplyVoltage_V, closeTo(state.chip.vbat, 0.001));
  });

  test('BT state syncs supply voltage when switching chips', () {
    final state = BTState()..setChip('nrf52832');

    expect(state.supplyVoltage_V, closeTo(3.0, 0.001));
    expect(state.supplyVoltage_V, closeTo(state.chip.vbat, 0.001));
  });

  test('BT sniff default config uses JSON lengths and only sleep follows CI',
      () {
    final state = BTState()
      ..setCase(BTCase.btSniff)
      ..setAttemptCount(3)
      ..setClockDriftPpm(500)
      ..setRxPayloadBytes(100);
    final config = (state.chip as BtChip).effectiveDefaultConfig;

    final mainRx =
        state.events.singleWhere((event) => event.label == 'Main RX');
    final guard =
        state.events.singleWhere((event) => event.label == 'Window widening');
    final nonSleepLength = state.events
        .where((event) => event.label != 'Sleep')
        .fold<double>(0, (sum, event) => sum + event.durationUs);

    expect(state.useDefaultConfig, isTrue);
    expect(state.events.where((event) => event.label.startsWith('RXmin')),
        isEmpty);
    expect(guard.durationUs, closeTo(config.windowWideningLength_us, 0.001));
    expect(mainRx.durationUs, closeTo(config.mainRxLength_us, 0.001));

    state.setConnectIntervalMs(1000);
    final updatedNonSleepLength = state.events
        .where((event) => event.label != 'Sleep')
        .fold<double>(0, (sum, event) => sum + event.durationUs);

    expect(updatedNonSleepLength, closeTo(nonSleepLength, 0.001));
    expect(
      state.events.singleWhere((event) => event.label == 'Sleep').durationUs,
      closeTo(1000000.0 - updatedNonSleepLength, 0.001),
    );
  });

  test('BT sniff attempt adds extra RXmin without extra TX', () {
    final state = BTState()
      ..setCase(BTCase.btSniff)
      ..setUseDefaultConfig(false)
      ..setAttemptCount(3);

    final labels = state.events.map((e) => e.label).toList();

    expect(labels.where((label) => label == 'Main RX'), hasLength(1));
    expect(labels.where((label) => label == 'TX'), hasLength(1));
    expect(labels.where((label) => label.startsWith('Attempt wait standby')),
        hasLength(2));
    expect(labels.where((label) => label.startsWith('RXmin')), hasLength(2));
  });

  test('BT sniff manual config uses separate RX and TX minimum lengths', () {
    final state = BTState()
      ..setCase(BTCase.btSniff)
      ..setChip('BES2711IUC2/3')
      ..setUseDefaultConfig(false)
      ..setAttemptCount(2);

    final tx = state.events.singleWhere((event) => event.label == 'TX');
    final rxMin = state.events.singleWhere((event) => event.label == 'RXmin');

    expect(tx.durationUs, closeTo(120.0, 0.001));
    expect(rxMin.durationUs, closeTo(88.0, 0.001));
  });

  test('BT sniff keeps window widening separate from main RX', () {
    final state = BTState()
      ..setCase(BTCase.btSniff)
      ..setUseDefaultConfig(false)
      ..setConnectIntervalMs(500)
      ..setClockDriftPpm(100)
      ..setRxPayloadBytes(10);

    final mainRx = state.events.singleWhere(
      (event) => event.label == 'Main RX',
    );
    final guard = state.events.singleWhere(
      (event) => event.label == 'Window widening',
    );

    expect(guard.durationUs, closeTo(50.0, 0.001));
    expect(mainRx.durationUs, closeTo(948.0, 0.001));
    expect(guard.previewLabel, 'Main RX');
    expect(guard.totalLengthUs, closeTo(998.0, 0.001));
    expect(guard.windowWideningLengthUs, closeTo(50.0, 0.001));
    expect(guard.occupiedLengthUs, closeTo(948.0, 0.001));
    expect(mainRx.previewLabel, 'Main RX');
    expect(mainRx.totalLengthUs, closeTo(998.0, 0.001));
    expect(mainRx.windowWideningLengthUs, closeTo(50.0, 0.001));
    expect(mainRx.occupiedLengthUs, closeTo(948.0, 0.001));
  });

  test('BT sniff attempt wait uses standby current', () {
    final state = BTState()
      ..setCase(BTCase.btSniff)
      ..setUseDefaultConfig(false)
      ..setAttemptCount(2);

    final wait = state.events.singleWhere(
      (event) => event.label == 'Attempt wait standby',
    );

    expect(wait.durationUs, closeTo(450.0, 0.001));
    expect(wait.currentMa, closeTo(state.chip.standbyCurrent_mA, 0.001));
  });

  test('BT sniff clock drift is clamped to at least 20 ppm', () {
    final state = BTState()
      ..setCase(BTCase.btSniff)
      ..setUseDefaultConfig(false)
      ..setClockDriftPpm(0);

    expect(state.clockDriftPpm, 20.0);
  });
}
