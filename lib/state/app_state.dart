// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import '../models/ble_chip.dart';
import '../models/power_event.dart';
import '../models/profile_params.dart';
import '../config/ble_chip_config.dart';
import '../services/power_calculator.dart';

class AppState extends ChangeNotifier {
  final List<BleChip> chips = defaultBleChips;

  late String selectedChipId;
  late ProfileParams params;

  // Mode-specific RX parameters
  double rxWindowConnectedUs = 0.0;
  double rxCurrentConnected_mA = 0.0;
  double rxWindowAdvertisingUs = 0.0;
  double rxCurrentAdvertising_mA = 0.0;

  List<PowerEvent> events = [];
  double periodUs = 0;
  double averageCurrent_mA = 0;
  double batteryCapacity_mAh = 220;

  bool hideLowPowerGaps = true;

  // HDT specific options (exposed for BLE-mode HDT UI)
  HdtModule hdtModule = HdtModule.sink;
  String hdtBand = '2.4G';

  AppState() {
    selectedChipId = chips.first.id;
    final initialTx = chips.first.txPowerLevelsDbm.firstWhere(
      (e) => e == 0,
      orElse: () => chips.first.txPowerLevelsDbm.first,
    );
    params = ProfileParams(
      mode: Mode.bleConnectionPeripheral,
      phy: Phy.le1M,
      txPowerDbm: initialTx,
      advIntervalMs: 100.0,
      connIntervalMs: 200.0,
      payloadBytes: 0,
    );
    // Initialize mode-specific RX params from the selected chip defaults
    rxWindowConnectedUs = chip.rxWindow_us;
    rxCurrentConnected_mA = chip.rxCurrent_mA;
    rxWindowAdvertisingUs = chip.rxWindow_us;
    rxCurrentAdvertising_mA = chip.rxCurrent_mA;
    recompute();
  }

  BleChip get chip => chips.firstWhere((c) => c.id == selectedChipId);

  void setChip(String id) {
    selectedChipId = id;
    params.txPowerDbm = chip.snapTxPower(params.txPowerDbm);
    // If the newly selected chip does not support HDT, ensure the
    // current mode is valid. This avoids DropdownButton value mismatches
    // where the UI's `value` (e.g. Mode.hdt) is not present in `items`.
    if (!chip.supportsHDT && params.mode == Mode.hdt) {
      params.mode = Mode.bleConnectionPeripheral;
    }
    // Update RX params when chip changes
    rxWindowConnectedUs = chip.rxWindow_us;
    rxCurrentConnected_mA = chip.rxCurrent_mA;
    rxWindowAdvertisingUs = chip.rxWindow_us;
    rxCurrentAdvertising_mA = chip.rxCurrent_mA;
    recompute();
  }

  void setRxWindowConnectedUs(double us) {
    rxWindowConnectedUs = us.clamp(50.0, 10000.0);
    recompute();
  }

  void setRxCurrentConnected_mA(double ma) {
    rxCurrentConnected_mA = ma;
    recompute();
  }

  void setRxWindowAdvertisingUs(double us) {
    rxWindowAdvertisingUs = us.clamp(50.0, 10000.0);
    recompute();
  }

  void setRxCurrentAdvertising_mA(double ma) {
    rxCurrentAdvertising_mA = ma;
    recompute();
  }

  void setMode(Mode m) {
    params.mode = m;
    recompute();
  }

  void setHdtModule(HdtModule m) {
    hdtModule = m;
    recompute();
  }

  void setHdtBand(String b) {
    hdtBand = b;
    recompute();
  }

  void setPhy(Phy p) {
    params.phy = p;
    recompute();
  }

  void setTxPower(double dbm) {
    params.txPowerDbm = chip.snapTxPower(dbm);
    recompute();
  }

  void setAdvInterval(double ms) {
    params.advIntervalMs = ms;
    recompute();
  }

  void setConnInterval(double ms) {
    params.connIntervalMs = ms;
    recompute();
  }

  void setPayloadBytes(int bytes) {
    params.payloadBytes = bytes;
    recompute();
  }

  void setBatteryCapacity(double mAh) {
    batteryCapacity_mAh = mAh;
    recompute();
  }

  void setHideLowPowerGaps(bool hide) {
    hideLowPowerGaps = hide;
    notifyListeners();
  }

  void toggleHideLowPower() {
    hideLowPowerGaps = !hideLowPowerGaps;
    notifyListeners();
  }

  void recompute() {
    if (params.mode == Mode.advertisingTxOnly ) {
      final intervalUs = (params.advIntervalMs * 1000).clamp(20000, 3_000_000).toDouble();
      periodUs = intervalUs;
      events = PowerCalculator.generateBleAdvertisingTxOnly(
        chip: chip,
        params: params,
        periodUs: periodUs,
      );
    } else if (params.mode == Mode.advertisingTxRx) {
      final intervalUs = (params.advIntervalMs * 1000).clamp(20000, 3_000_000).toDouble();
      periodUs = intervalUs;
      events = PowerCalculator.generateBleAdvertisingTxRx(
        chip: chip,
        params: params,
        periodUs: periodUs,
        rxCurrentMa: rxCurrentConnected_mA,
      );
    } else if (params.mode == Mode.bleConnectionCentral) {
      final intervalUs = (params.connIntervalMs * 1000).clamp(7500, 4_000_000).toDouble();
      periodUs = intervalUs;
      events = PowerCalculator.generateBleConnectedCentral(
        chip: chip,
        params: params,
        periodUs: periodUs,
        rxWindowUs: rxWindowConnectedUs,
        rxCurrentMa: rxCurrentConnected_mA,
      );
    } else if (params.mode == Mode.bleConnectionPeripheral) {
      final intervalUs = (params.connIntervalMs * 1000).clamp(7500, 4_000_000).toDouble();
      periodUs = intervalUs;
      events = PowerCalculator.generateBleConnectedPeripheral(
        chip: chip,
        params: params,
        periodUs: periodUs,
        rxWindowUs: rxWindowConnectedUs,
        rxCurrentMa: rxCurrentConnected_mA,
      );
    } else if (params.mode == Mode.hdt) {
      // Use HDT configuration from AppState HDT fields
      final intervalUs = 500.0; // default HDT period (us)
      periodUs = intervalUs;
      events = PowerCalculator.generateHdt(
        chip: chip,
        periodUs: periodUs,
        txPowerDbm: params.txPowerDbm,
        band: hdtBand,
        repeats: 1,
        moduleSink: (hdtModule == HdtModule.sink),
        hdtPhyRateMbps: 15.0,
        hdtPayloadBytes: 144,
      );
    } 
    averageCurrent_mA = PowerCalculator.computeAverageCurrent(events, periodUs);
    notifyListeners();
  }

  double get batteryLife_hours {
    if (averageCurrent_mA <= 0) return double.infinity;
    return batteryCapacity_mAh / averageCurrent_mA;
  }

  double get maxCurrent_mA {
    return PowerCalculator.computeMaxCurrent(events);
  }

  double get sleepCurrent_uA {
    return chip.sleepCurrent_uA;
  }



  double get period_ms => periodUs / 1000.0;

  String formatCurrentAuto(double currentMa) {
    if (currentMa < 1.0) {
      final ua = currentMa * 1000.0;
      return '${ua.toStringAsFixed(2)} µA';
    } else {
      return '${currentMa.toStringAsFixed(2)} mA';
    }
  }
}