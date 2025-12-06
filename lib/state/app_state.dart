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
    if (params.mode == Mode.advertisingTxOnly ||
        params.mode == Mode.advertisingTxRx) {
      final intervalUs = (params.advIntervalMs * 1000).clamp(20000, 3_000_000).toDouble();
      periodUs = intervalUs;
      events = PowerCalculator.generateBleAdvertising(
        chip: chip,
        params: params,
        periodUs: periodUs,
      );
    } else if (params.mode == Mode.hdt) {
      // Use a default HDT configuration similar to BTState defaults
      final intervalUs = 500.0; // default HDT period (us)
      periodUs = intervalUs;
      events = PowerCalculator.generateHdt(
        chip: chip,
        periodUs: periodUs,
        txPowerDbm: params.txPowerDbm,
        band: '2.4G',
        repeats: 1,
        moduleSink: true,
        hdtPhyRateMbps: 15.0,
        hdtPayloadBytes: 144,
      );
    } else {
      final intervalUs = (params.connIntervalMs * 1000).clamp(7500, 4_000_000).toDouble();
      periodUs = intervalUs;
      events = PowerCalculator.generateBleConnected(
        chip: chip,
        params: params,
        periodUs: periodUs,
        rxWindowUs: rxWindowConnectedUs,
        rxCurrentMa: rxCurrentConnected_mA,
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