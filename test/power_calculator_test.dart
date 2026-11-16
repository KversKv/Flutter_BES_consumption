import 'package:flutter_test/flutter_test.dart';
import 'package:bes_consumption/models/ble_chip.dart';
import 'package:bes_consumption/models/profile_params.dart';
import 'package:bes_consumption/services/power_calculator.dart';
import 'package:bes_consumption/state/app_state.dart';

BleChip _chip() => BleChip.fromJson({
      'id': 't',
      'name': 't',
      'sleepCurrent_uA': 2.0,
      'rxCurrent_mA': 6.0,
      'tifs_us': 150,
      'tifsCurrent_mA': 1.0,
      'txCurrent_mA_forDbm': {'0': 5.0},
      'postProcess_us': 350,
      'postCurrent_mA': 2.0,
      'preProcess_us': 60,
      'preProcessCurrent_mA': 4.0,
      'crystalRampUp_us': 400,
      'crystalRampUpCurrent_mA': 1.5,
      'standby_us': 1072,
      'standbyCurrent_mA': 0.4,
      'startRadio_us': 130,
      'startRadioCurrent_mA': 3.0,
      'advGap_us': 62,
      'advGapCurrent_mA': 0.5,
    });

ProfileParams _params({
  Mode mode = Mode.bleConnectionPeripheral,
  int tx = 0,
  int rx = 0,
  bool dle = true,
  bool cele = true,
}) =>
    ProfileParams(
      mode: mode,
      phy: Phy.le1M,
      txPowerDbm: 0,
      advIntervalMs: 100,
      connIntervalMs: 100,
      payloadBytes: tx,
      rxPayloadBytes: rx,
      dle: dle,
      eventLengthExt: cele,
    );

void main() {
  test('airtime follows Nordic overhead rules', () {
    expect(PowerCalculator.airtimeUs(0, Phy.le1M), 80);
    expect(PowerCalculator.airtimeUs(251, Phy.le1M), 2088);
    expect(PowerCalculator.airtimeUs(0, Phy.le2M), 44);
    expect(PowerCalculator.airtimeUs(251, Phy.le2M), 1048);
    expect(PowerCalculator.airtimeUs(0, Phy.le1M, adv: true), 134);
    expect(PowerCalculator.airtimeUs(31, Phy.le1M, adv: true), 382);
  });

  test('DLE/CELE packet splitting', () {
    final nodle = PowerCalculator.splitPayload(251, false, true);
    expect(nodle.length, 10);
    expect(nodle.last, 8);
    expect(PowerCalculator.splitPayload(1000, true, false), [251]);
    final cele = PowerCalculator.splitPayload(1000, true, true);
    expect(cele.length, 4);
    expect(cele.last, 247);
    expect(PowerCalculator.splitPayload(0, true, true), [0]);
  });

  test('window widening formula', () {
    final p = _params();
    expect(PowerCalculator.windowWideningUs(p, 100000), 36);
    p.peripheralPpm = 500;
    p.centralPpm = 500;
    expect(PowerCalculator.windowWideningUs(p, 1000000), 1032);
    p.lfRc = true;
    p.centralPpm = 20;
    expect(PowerCalculator.windowWideningUs(p, 100000), 84);
  });

  test('peripheral baseline stage machine', () {
    final events = PowerCalculator.generateBleConnectedPeripheral(
      chip: _chip(),
      params: _params(),
      periodUs: 100000,
      rxCurrentMa: 0,
    );
    expect(
      events.map((e) => e.label).toList(),
      [
        'Pre-processing',
        'Crystal ramp-up',
        'Standby',
        'Start radio',
        'Window widening',
        'RX',
        'TIFS',
        'TX',
        'Post',
        'Sleep',
      ],
    );
    expect(events[4].durationUs, 36);
    expect(events[5].durationUs, 80);
    expect(events[7].durationUs, 80);
    expect(events.last.label, 'Sleep');
  });

  test('central has no widening and TX first', () {
    final events = PowerCalculator.generateBleConnectedCentral(
      chip: _chip(),
      params: _params(mode: Mode.bleConnectionCentral),
      periodUs: 100000,
      rxCurrentMa: 0,
    );
    expect(events.any((e) => e.label == 'Window widening'), false);
    expect(events[4].label, 'TX');
    expect(events[6].label, 'RX');
  });

  test('RX payload triggers CPU overlap and post extension', () {
    final events = PowerCalculator.generateBleConnectedPeripheral(
      chip: _chip(),
      params: _params(rx: 251),
      periodUs: 100000,
      rxCurrentMa: 0,
    );
    final overlap = events.firstWhere((e) => e.label == 'TX + CPU');
    expect(overlap.durationUs, 80);
    expect(overlap.currentMa, 5.0 + 2.0);
    final post = events.firstWhere((e) => e.label == 'Post');
    expect(post.durationUs, 350 + 147);
  });

  test('multi-packet event without DLE', () {
    final events = PowerCalculator.generateBleConnectedPeripheral(
      chip: _chip(),
      params: _params(tx: 251, dle: false),
      periodUs: 100000,
      rxCurrentMa: 0,
    );
    expect(events.where((e) => e.label == 'TX').length, 10);
    expect(events.where((e) => e.label == 'RX').length, 10);
    expect(events.where((e) => e.label == 'TX').last.durationUs, 144);
  });

  test('advertising has single start radio and 3 channels', () {
    final events = PowerCalculator.generateBleAdvertisingTxRx(
      chip: _chip(),
      params: _params(mode: Mode.advertisingTxRx),
      periodUs: 105000,
      rxCurrentMa: 0,
    );
    expect(events.where((e) => e.label == 'Start radio').length, 1);
    expect(events.where((e) => e.label.endsWith('TX')).length, 3);
    expect(events.where((e) => e.label == 'RX').length, 3);
    expect(events.where((e) => e.label == 'ADV_GAP').length, 2);
  });

  test('legacy peripheral keeps fixed RX window and no widening', () {
    final events = PowerCalculator.generateBleConnectedPeripheralLegacy(
      chip: _chip(),
      params: _params(tx: 3),
      periodUs: 100000,
      rxWindowUs: 300,
      rxCurrentMa: 0,
    );
    expect(
      events.map((e) => e.label).toList(),
      [
        'Pre-processing',
        'Crystal ramp-up',
        'Standby',
        'RX',
        'TIFS',
        'TX',
        'Post',
        'Sleep',
      ],
    );
    expect(events[3].durationUs, 300);
    expect(events[5].durationUs, 104);
  });

  test('legacy adv TxRx keeps hardcoded TX and per-channel start radio', () {
    final events = PowerCalculator.generateBleAdvertisingTxRxLegacy(
      chip: _chip(),
      params: _params(mode: Mode.advertisingTxRx),
      periodUs: 100000,
      rxCurrentMa: 0,
    );
    expect(events.where((e) => e.label == 'Start radio').length, 3);
    expect(
        events.where((e) => e.label.endsWith('TX')).first.durationUs, 225.28);
    expect(events.where((e) => e.label == 'RX').first.durationUs, 100);
    expect(events.where((e) => e.label == 'ADV_GAP').first.durationUs, 62);
  });

  test('AppState mode switch swaps model, period rules and payload cap', () {
    final state = AppState();
    expect(state.useNordicModel, isTrue);
    state.setSlaveLatency(9);
    expect(state.periodUs, 200000 * 10);
    state.setPayloadBytes(1000);
    state.setUseNordicModel(false);
    expect(state.periodUs, 200000);
    expect(state.params.payloadBytes, 251);
    expect(state.events.any((e) => e.label == 'Window widening'), isFalse);
    state.setUseNordicModel(true);
    expect(state.periodUs, 200000 * 10);
    expect(state.events.any((e) => e.label == 'Window widening'), isTrue);
  });

  test('charge excludes sleep and average matches charge/period + idle', () {
    const period = 100000.0;
    final events = PowerCalculator.generateBleConnectedPeripheral(
      chip: _chip(),
      params: _params(),
      periodUs: period,
      rxCurrentMa: 0,
    );
    final charge = PowerCalculator.computeEventCharge_uC(events);
    final avg = PowerCalculator.computeAverageCurrent(events, period);
    const idleMa = 2.0 / 1000.0;
    final sleepUs = events.last.durationUs;
    expect(avg, closeTo((charge * 1000 + idleMa * sleepUs) / period, 1e-9));
  });
}
