import 'package:flutter_test/flutter_test.dart';
import 'package:bes_consumption/models/ble_chip.dart';
import 'package:bes_consumption/models/power_event.dart';
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

  test('shared BLE calculation matches generators and assigns stable stage IDs',
      () {
    void expectSameEvents(
      List<PowerEvent> actual,
      List<PowerEvent> expected,
    ) {
      expect(actual.length, expected.length);
      for (var i = 0; i < actual.length; i++) {
        expect(actual[i].label, expected[i].label);
        expect(actual[i].startUs, closeTo(expected[i].startUs, 1e-9));
        expect(actual[i].durationUs, closeTo(expected[i].durationUs, 1e-9));
        expect(actual[i].currentMa, closeTo(expected[i].currentMa, 1e-9));
      }
    }

    const modes = [
      Mode.advertisingTxOnly,
      Mode.advertisingTxRx,
      Mode.bleConnectionCentral,
      Mode.bleConnectionPeripheral,
    ];
    for (final nordic in [true, false]) {
      for (final mode in modes) {
        final params = _params(mode: mode, tx: 3, rx: 20);
        final result = PowerCalculator.calculateBle(
          chip: _chip(),
          params: params,
          useNordicModel: nordic,
          rxWindowUs: 300,
        );
        late final double period;
        late final List<PowerEvent> expected;
        switch (mode) {
          case Mode.advertisingTxOnly:
            period = (nordic ? 105 : 100) * 1000.0;
            expected = nordic
                ? PowerCalculator.generateBleAdvertisingTxOnly(
                    chip: _chip(), params: params, periodUs: period)
                : PowerCalculator.generateBleAdvertisingTxOnlyLegacy(
                    chip: _chip(), params: params, periodUs: period);
          case Mode.advertisingTxRx:
            period = (nordic ? 105 : 100) * 1000.0;
            expected = nordic
                ? PowerCalculator.generateBleAdvertisingTxRx(
                    chip: _chip(),
                    params: params,
                    periodUs: period,
                    rxCurrentMa: 0,
                  )
                : PowerCalculator.generateBleAdvertisingTxRxLegacy(
                    chip: _chip(),
                    params: params,
                    periodUs: period,
                    rxCurrentMa: 0,
                  );
          case Mode.bleConnectionCentral:
            period = 100000;
            expected = nordic
                ? PowerCalculator.generateBleConnectedCentral(
                    chip: _chip(),
                    params: params,
                    periodUs: period,
                    rxCurrentMa: 0,
                  )
                : PowerCalculator.generateBleConnectedCentralLegacy(
                    chip: _chip(),
                    params: params,
                    periodUs: period,
                    rxWindowUs: 300,
                    rxCurrentMa: 0,
                  );
          case Mode.bleConnectionPeripheral:
            period = 100000;
            expected = nordic
                ? PowerCalculator.generateBleConnectedPeripheral(
                    chip: _chip(),
                    params: params,
                    periodUs: period,
                    rxCurrentMa: 0,
                  )
                : PowerCalculator.generateBleConnectedPeripheralLegacy(
                    chip: _chip(),
                    params: params,
                    periodUs: period,
                    rxWindowUs: 300,
                    rxCurrentMa: 0,
                  );
          case Mode.hdt:
            throw StateError('HDT is tested separately');
        }
        expect(result.periodUs, period);
        expectSameEvents(result.events, expected);
        final ids = result.events.map((event) => event.stageId).toList();
        expect(ids, everyElement(isNotNull));
        expect(ids.toSet().length, ids.length);
        final repeated = PowerCalculator.calculateBle(
          chip: _chip(),
          params: params,
          useNordicModel: nordic,
          rxWindowUs: 300,
        );
        expect(
          repeated.events.map((event) => event.stageId).toList(),
          ids,
        );
      }
    }

    final hdtParams = _params(mode: Mode.hdt);
    final hdt = PowerCalculator.calculateBle(
      chip: _chip(),
      params: hdtParams,
      useNordicModel: true,
    );
    expectSameEvents(
      hdt.events,
      PowerCalculator.generateHdt(
        chip: _chip(),
        periodUs: 500,
        txPowerDbm: 0,
      ),
    );
    expect(hdt.events.map((event) => event.stageId).toSet().length,
        hdt.events.length);
  });

  test('shared BLE calculation matches AppState output', () {
    final state = AppState();
    final result = PowerCalculator.calculateBle(
      chip: state.chip,
      params: state.params,
      useNordicModel: state.useNordicModel,
      rxWindowUs: state.rxWindowConnectedUs,
      rxCurrentMa: state.rxCurrentConnected_mA,
      hdtModule: state.hdtModule,
      hdtBand: state.hdtBand,
    );
    expect(result.periodUs, state.periodUs);
    expect(result.events.length, state.events.length);
    for (var i = 0; i < result.events.length; i++) {
      expect(result.events[i].stageId, state.events[i].stageId);
      expect(result.events[i].durationUs, state.events[i].durationUs);
      expect(result.events[i].currentMa, state.events[i].currentMa);
    }
    expect(
      PowerCalculator.computeAverageCurrent(result.events, result.periodUs),
      closeTo(state.averageCurrent_mA, 1e-9),
    );
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
