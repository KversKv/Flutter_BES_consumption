// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/ble_chip.dart';
import '../models/bt_chip.dart';
import '../config/bt_chip_config.dart';
import '../models/power_event.dart';
import 'app_state.dart';
import '../models/profile_params.dart';
import '../services/power_calculator.dart';

enum BTCase { btSniff, btPage, btPagescan, hdt, relay }
enum HdtModule { source, sink }

class BTState extends ChangeNotifier {
  final List<BleChip> bleChips = AppState().chips;
  final List<BtChip> btChips = defaultBtChips;

  late String selectedChipId;

  double sniffIntervalMs = 500.0;
  double sniffWindowUs = 80.0;
  int channelsPerCycle = 3;
  double channelGapUs = 150.0;
  int hdtRepeats = 1;
  HdtModule hdtModule = HdtModule.sink;
  double relayHopGapUs = 1000.0;
  double hdtPeriodUs = 500.0;
  
  double hdtPhyRateMbps = 15.0; 
  int hdtPayloadBytes = 144;
  int hdtPayloadHeaderBytes = 16;
  int hdtCrcBits = 32;
  int hdtMicBits = 64;
  int hdtZeroPaddingBits = 0;

  double txPowerDbm = 0.0;
  String band = '2.4G';
  
  // --- Chip settings ---
  double supplyVoltage_V = 3.7; // Voltage setting (V)

  // --- BLE settings ---
  Mode mode = Mode.advertisingTxRx;
  int blePayloadBytes = 20;
  double connIntervalMs = 200.0;
  double advIntervalMs = 100.0;
  BTCase caseType = BTCase.btSniff;

  dynamic get chip {
    final isBtCase = caseType == BTCase.btSniff || caseType == BTCase.btPage || caseType == BTCase.btPagescan || caseType == BTCase.relay || caseType == BTCase.hdt;
    if (isBtCase) {
      final matches = btChips.where((c) => c.id == selectedChipId);
      if (matches.isNotEmpty) return matches.first;
      return btChips.first;
    } else {
      final matches = bleChips.where((c) => c.id == selectedChipId);
      if (matches.isNotEmpty) return matches.first;
      return bleChips.first;
    }
  }

  List<PowerEvent> events = [];
  double periodUs = 0;
  double averageCurrent_mA = 0;
  double batteryCapacity_mAh = 220;
  bool hideLowPowerGaps = true;

  BTState() {
    final isBtCase = caseType == BTCase.btSniff ||
        caseType == BTCase.btPage ||
        caseType == BTCase.btPagescan ||
        caseType == BTCase.relay ||
        caseType == BTCase.hdt;
    selectedChipId = isBtCase ? btChips.first.id : bleChips.first.id;
    recompute();
  }

  // --- Setters (unchanged mostly) ---

  void setTxPower(double dbm) { txPowerDbm = dbm; recompute(); }
  void setBand(String b) { if (b != band) { band = b; recompute(); } }
  void setMode(Mode m) { mode = m; recompute(); }
  void setBlePayload(int bytes) { blePayloadBytes = bytes.clamp(0, 1024).toInt(); recompute(); }
  void setSupplyVoltage(double v) { supplyVoltage_V = v.clamp(1.8, 5.5); notifyListeners(); }
  void setConnIntervalMs(double ms) { connIntervalMs = ms; recompute(); }
  void setAdvIntervalMs(double ms) { advIntervalMs = ms; recompute(); }
  void setSniffIntervalMs(double ms) { sniffIntervalMs = ms.clamp(10.0, 5000.0); recompute(); }
  void setSniffWindowUs(double us) { sniffWindowUs = us.clamp(50.0, 50000.0); recompute(); }
  void setChannels(int n) { channelsPerCycle = n.clamp(1, 3).toInt(); recompute(); }
  void setHdtModule(HdtModule m) { hdtModule = m; recompute(); }
  void setHdtRepeats(int n) { hdtRepeats = n.clamp(1, 10).toInt(); recompute(); }
  void setRelayHopGapUs(double us) { relayHopGapUs = us.clamp(0.0, 100000.0); recompute(); }
  void setBatteryCapacity(double mAh) { batteryCapacity_mAh = mAh; recompute(); }
  void setHdtPhyRate(double mbps) { hdtPhyRateMbps = mbps.clamp(2.0, 15.0); recompute(); }

  void setChip(String id) {
    selectedChipId = id;
    recompute();
  }

  void setCase(BTCase c) {
    caseType = c;
    if (caseType == BTCase.btSniff || caseType == BTCase.btPage || caseType == BTCase.btPagescan) {
      if (!btChips.any((b) => b.id == selectedChipId)) {
        selectedChipId = btChips.first.id;
      }
    } else {
      if (!bleChips.any((b) => b.id == selectedChipId)) {
        selectedChipId = bleChips.first.id;
      }
    }
    recompute();
  }

  void setHideLowPowerGaps(bool hide) {
    hideLowPowerGaps = hide;
    notifyListeners();
  }

  // Advanced visibility and PHY
  Phy phy = Phy.le1M;
  bool get showAdvanced {
    return (mode == Mode.bleConnectionCentral || mode == Mode.bleConnectionPeripheral);
  }
  void setPhy(Phy p) { phy = p; recompute(); }

  // --- Calculation Helpers ---

  double _fixedOverheadUsAtRate() {
    const double fixedAt15 = 44.0; 
    return fixedAt15 * (15.0 / hdtPhyRateMbps);
  }

  double _pduAirtimeUs() {
    final int pduBits = (hdtPayloadBytes + hdtPayloadHeaderBytes) * 8 + hdtCrcBits + hdtMicBits + hdtZeroPaddingBits;
    return pduBits / hdtPhyRateMbps;
  }

  double computeHdtActiveUs() {
    final fixed = _fixedOverheadUsAtRate();
    final pdu = _pduAirtimeUs();
    return fixed + pdu;
  }

  // --- Main Recompute ---

  void recompute() {
    switch (caseType) {
      case BTCase.btSniff: _recomputeBtSniff(); break;
      case BTCase.btPage: _recomputeBtPage(); break;
      case BTCase.btPagescan: _recomputeBtPagescan(); break;
      case BTCase.hdt: _recomputeHdt(); break;
      case BTCase.relay: _recomputeRelay(); break;
    }
    averageCurrent_mA = PowerCalculator.computeAverageCurrent(events, periodUs);
    notifyListeners();
  }

  // --- Specific Calculations ---

  void _recomputeHdt() {
    events = [];
    final intervalUs = hdtPeriodUs;
    periodUs = intervalUs;
    final halfPeriodUs = periodUs/2;

    // Use chip helpers that handle band fallback to avoid null assignment
    double rxI;
    double txI;
    try {
      rxI = chip.rxCurrentForBand(band);
    } catch (_) {
      rxI = chip.rxCurrent_mA;
    }
    try {
      txI = chip.txCurrentForPower(txPowerDbm, band);
    } catch (_) {
      txI = chip.txCurrentForPower(txPowerDbm);
    }

    final idleCurrent = chip.hdtIdleCurrent_mA;
    double t = 0;
    
    final double computedActive = computeHdtActiveUs();
    final double preRF_RX_Us = 70.0;
    final double postRF_RX_Us = 3.0;
    final double preRF_TX_Us = 40.0;
    final double postRF_TX_Us = 10.0;
    final double activeUs = math.min(computedActive, hdtPeriodUs);
    final double total_RX_ActiveUs = activeUs + preRF_RX_Us + postRF_RX_Us;
    final double total_TX_ActiveUs = activeUs + preRF_TX_Us + postRF_TX_Us;
    final double idle_RX_Us = math.max(0.0, hdtPeriodUs - total_RX_ActiveUs);
    final double idle_TX_Us = math.max(0.0, halfPeriodUs - total_TX_ActiveUs);

    for (int i = 0; i < hdtRepeats; i++) {
      if (hdtModule == HdtModule.sink) {
        events.add(PowerEvent(startUs: t, durationUs: total_RX_ActiveUs, currentMa: rxI, label: 'HDT RX', color: Colors.blue.shade400));
        t += total_RX_ActiveUs;
        if (idle_RX_Us > 0.0 ) {
          events.add(PowerEvent(startUs: t, durationUs: idle_RX_Us, currentMa: idleCurrent, label: 'Idle', color: Colors.green.shade200));
          t += idle_RX_Us;
        }
      } else {
        events.add(PowerEvent(startUs: t, durationUs: total_TX_ActiveUs, currentMa: txI, label: 'HDT TX', color: Colors.red.shade400));
        t += total_RX_ActiveUs;
        if (idle_TX_Us > 0.0 ) {
           events.add(PowerEvent(startUs: t, durationUs: idle_TX_Us, currentMa: idleCurrent, label: 'Idle', color: Colors.green.shade200));
           t += idle_TX_Us;
        }
        events.add(PowerEvent(startUs: t, durationUs: total_TX_ActiveUs, currentMa: txI, label: 'HDT TX', color: Colors.red.shade400));
        t += total_RX_ActiveUs;
        if (idle_TX_Us > 0.0 ) {
           events.add(PowerEvent(startUs: t, durationUs: idle_TX_Us, currentMa: idleCurrent, label: 'Idle', color: Colors.green.shade200));
           t += idle_TX_Us;
        }
      }
    }
    final remaining = math.max(0, intervalUs - t);
    if (remaining > 0) {
      events.add(PowerEvent(startUs: t, durationUs: remaining.toDouble(), currentMa: idleCurrent, label: 'Idle', color: Colors.green.shade200));
    }
  }

  void _recomputeBtSniff() {
    events = [];
    final intervalUs = sniffIntervalMs * 1000.0;
    periodUs = intervalUs;
    final rxI = chip.rxCurrent_mA;
    final postUs = chip.postProcess_us;
    final postI = chip.postCurrent_mA;
    final sleepI = chip.sleepCurrent_uA / 1000.0;

    double t = 0;
    PowerCalculator.addSetupPhases(events, t, chip);
    t += PowerCalculator.getSetupTotalUs(chip);

    events.add(PowerEvent(startUs: t, durationUs: sniffWindowUs, currentMa: rxI, label: 'RX Sniff', color: Colors.blue.shade400));
    t += sniffWindowUs;
    events.add(PowerEvent(startUs: t, durationUs: chip.tifs_us, currentMa: chip.tifsCurrent_mA, label: 'TIFS', color: Colors.orange.shade200));
    t += chip.tifs_us;
    
    final txI = chip.txCurrentForPower(txPowerDbm);
    events.add(PowerEvent(startUs: t, durationUs: sniffWindowUs, currentMa: txI, label: 'TX', color: Colors.red.shade400));
    t += sniffWindowUs;
    events.add(PowerEvent(startUs: t, durationUs: postUs, currentMa: postI, label: 'Post', color: Colors.purple.shade400));
    t += postUs;

    final remaining = math.max(0, intervalUs - t);
    if (remaining > 0) {
      events.add(PowerEvent(startUs: t, durationUs: remaining.toDouble(), currentMa: sleepI, label: 'Sleep', color: Colors.green.shade200));
    }
  }

  void _recomputeBtPage() {
    events = [];
    final intervalMs = (mode == Mode.bleConnectionCentral || mode == Mode.bleConnectionPeripheral) ? connIntervalMs : advIntervalMs;
    final intervalUs = intervalMs * 1000.0;
    periodUs = intervalUs;
    final rxI = chip.rxCurrent_mA;
    final postUs = chip.postProcess_us;
    final postI = chip.postCurrent_mA;
    final sleepI = chip.sleepCurrent_uA / 1000.0;

    double t = 0;
    PowerCalculator.addSetupPhases(events, t, chip);
    t += PowerCalculator.getSetupTotalUs(chip);

    events.add(PowerEvent(startUs: t, durationUs: sniffWindowUs, currentMa: rxI, label: 'Page RX', color: Colors.blue.shade600));
    t += sniffWindowUs;
    events.add(PowerEvent(startUs: t, durationUs: postUs, currentMa: postI, label: 'Post', color: Colors.purple.shade400));
    t += postUs;

    final remaining = math.max(0, intervalUs - t);
    if (remaining > 0) {
      events.add(PowerEvent(startUs: t, durationUs: remaining.toDouble(), currentMa: sleepI, label: 'Sleep', color: Colors.green.shade200));
    }
  }

  void _recomputeBtPagescan() {
    events = [];
    final intervalUs = sniffIntervalMs * 1000.0;
    periodUs = intervalUs;
    final rxI = chip.rxCurrent_mA;
    final postUs = chip.postProcess_us;
    final postI = chip.postCurrent_mA;
    final sleepI = chip.sleepCurrent_uA / 1000.0;

    double t = 0;
    PowerCalculator.addSetupPhases(events, t, chip);
    t += PowerCalculator.getSetupTotalUs(chip);

    final window = sniffWindowUs * 0.6; 
    for (int i = 0; i < channelsPerCycle; i++) {
      events.add(PowerEvent(startUs: t, durationUs: window, currentMa: rxI, label: 'PageScan RX CH${i+1}', color: Colors.indigo.shade400));
      t += window;
      events.add(PowerEvent(startUs: t, durationUs: postUs * 0.4, currentMa: postI, label: 'Post', color: Colors.purple.shade200));
      t += postUs * 0.4;
      if (i < channelsPerCycle - 1) {
        events.add(PowerEvent(startUs: t, durationUs: channelGapUs, currentMa: sleepI, label: 'Channel gap', color: Colors.green.shade200));
        t += channelGapUs;
      }
    }
    final remaining = math.max(0, intervalUs - t);
    if (remaining > 0) {
      events.add(PowerEvent(startUs: t, durationUs: remaining.toDouble(), currentMa: sleepI, label: 'Sleep', color: Colors.green.shade200));
    }
  }

  void _recomputeRelay() {
    events = [];
    final intervalUs = sniffIntervalMs * 1000.0;
    periodUs = intervalUs;
    final rxI = chip.rxCurrent_mA;
    final postUs = chip.postProcess_us;
    final postI = chip.postCurrent_mA;
    final sleepI = chip.sleepCurrent_uA / 1000.0;

    double t = 0;
    // Hop 1
    PowerCalculator.addSetupPhases(events, t, chip);
    t += PowerCalculator.getSetupTotalUs(chip);
    events.add(PowerEvent(startUs: t, durationUs: sniffWindowUs * 0.5, currentMa: rxI, label: 'Relay RX1', color: Colors.teal.shade400));
    t += sniffWindowUs * 0.5;
    events.add(PowerEvent(startUs: t, durationUs: postUs * 0.5, currentMa: postI, label: 'Post', color: Colors.purple.shade200));
    t += postUs * 0.5;

    events.add(PowerEvent(startUs: t, durationUs: relayHopGapUs, currentMa: sleepI, label: 'Relay gap', color: Colors.green.shade100));
    t += relayHopGapUs;

    // Hop 2
    PowerCalculator.addSetupPhases(events, t, chip);
    t += PowerCalculator.getSetupTotalUs(chip);
    events.add(PowerEvent(startUs: t, durationUs: sniffWindowUs * 0.5, currentMa: rxI, label: 'Relay RX2', color: Colors.teal.shade700));
    t += sniffWindowUs * 0.5;
    events.add(PowerEvent(startUs: t, durationUs: postUs * 0.5, currentMa: postI, label: 'Post', color: Colors.purple.shade200));
    t += postUs * 0.5;

    final remaining = math.max(0, intervalUs - t);
    if (remaining > 0) {
      events.add(PowerEvent(startUs: t, durationUs: remaining.toDouble(), currentMa: sleepI, label: 'Sleep', color: Colors.green.shade200));
    }
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