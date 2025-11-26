// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/ble_chip.dart';
import '../models/power_event.dart';
import 'app_state.dart';
import '../models/profile_params.dart';

enum SniffCase { btSniff, btPage, btPagescan, hdt, relay }

/// For HDT case, choose whether this node behaves as host (only TX/IDLE)
/// or device (only RX/IDLE).
enum HdtModule { host, device }

class SniffingState extends ChangeNotifier {
  final List<BleChip> chips = AppState().chips;

  late String selectedChipId;

  double sniffIntervalMs = 100.0;
  double sniffWindowUs = 2000.0;
  int channelsPerCycle = 3;
  double channelGapUs = 150.0;
  int hdtRepeats = 1;
  // HDT module role: host (TX-only) or device (RX-only)
  HdtModule hdtModule = HdtModule.device;
  double relayHopGapUs = 1000.0;
  // HDT fixed period in microseconds (active+idle total). Configured in code.
  double hdtPeriodUs = 500.0;
  // HDT PHY and packet parameters (configurable: PHY rate via UI, others by code)
  double hdtPhyRateMbps = 15.0; // allowed 2..15
  int hdtPayloadBytes = 144;
  int hdtPayloadHeaderBytes = 16;
  int hdtCrcBits = 32;
  int hdtMicBits = 64;
  int hdtZeroPaddingBits = 0;


  /// Compute the expected airtime (µs) for the fixed overhead (STS/GI/LTS/CTRL HDR/Trailer).
  /// We use the values provided for 15 Mbps (total ~44 µs) and scale inversely with PHY rate.
  double _fixedOverheadUsAtRate() {
    const double fixedAt15 = 44.0; // µs at 15 Mbps
    return fixedAt15 * (15.0 / hdtPhyRateMbps);
  }

  /// Compute PDU airtime (µs) for the configured payload and PHY rate.
  double _pduAirtimeUs() {
    final int pduBits = (hdtPayloadBytes + hdtPayloadHeaderBytes) * 8 + hdtCrcBits + hdtMicBits + hdtZeroPaddingBits;
    // bits / Mbps gives µs
    return pduBits / hdtPhyRateMbps;
  }

  /// Compute the HDT active window (µs) = fixed overhead + PDU airtime
  double computeHdtActiveUs() {
    final fixed = _fixedOverheadUsAtRate();
    final pdu = _pduAirtimeUs();
    return fixed + pdu;
  }

  void setHdtPhyRate(double mbps) {
    hdtPhyRateMbps = mbps.clamp(2.0, 15.0);
    recompute();
  }
  // TX power used for modeling TX current in sniffing cases (default to 0dBm if available)
  double txPowerDbm = 0.0;
  // Mode and mode-specific intervals
  Mode mode = Mode.advertising;
  double connIntervalMs = 200.0;
  double advIntervalMs = 100.0;
  SniffCase caseType = SniffCase.btSniff;

  BleChip get chip => chips.firstWhere((c) => c.id == selectedChipId);

  List<PowerEvent> events = [];
  double periodUs = 0;
  double averageCurrent_mA = 0;
  double batteryCapacity_mAh = 220;
  bool hideLowPowerGaps = true;

  SniffingState() {
    selectedChipId = chips.first.id;
    recompute();
  }

  void setTxPower(double dbm) {
    txPowerDbm = dbm;
    recompute();
  }

  void setMode(Mode m) {
    mode = m;
    recompute();
  }

  void setConnIntervalMs(double ms) {
    connIntervalMs = ms;
    recompute();
  }

  void setAdvIntervalMs(double ms) {
    advIntervalMs = ms;
    recompute();
  }

  void setChip(String id) {
    selectedChipId = id;
    recompute();
  }

  void setCase(SniffCase c) {
    caseType = c;
    recompute();
  }

  void setSniffIntervalMs(double ms) {
    sniffIntervalMs = ms.clamp(10.0, 5000.0);
    recompute();
  }

  void setSniffWindowUs(double us) {
    sniffWindowUs = us.clamp(50.0, 50000.0);
    recompute();
  }

  void setChannels(int n) {
    channelsPerCycle = n.clamp(1, 3).toInt();
    recompute();
  }

  void setHdtModule(HdtModule m) {
    hdtModule = m;
    recompute();
  }

  void setHdtRepeats(int n) {
    hdtRepeats = n.clamp(1, 10).toInt();
    recompute();
  }

  void setRelayHopGapUs(double us) {
    relayHopGapUs = us.clamp(0.0, 100000.0);
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

  void _recomputeHdt() {
    // HDT: fixed pattern — each repeat is exactly 250us (active) + 250us (idle).
    // Host: active=TX, Device: active=RX. No setup/post phases included here.
    events = [];
    // Use code-configured HDT period (µs)
    final intervalUs = hdtPeriodUs;
    periodUs = intervalUs;

    final rxI = chip.rxCurrent_mA;
    final txI = chip.txCurrentForPower(txPowerDbm);
    // HDT idle current: use per-chip configured HDT idle current (no fallback)
    final idleCurrent = chip.hdtIdleCurrent_mA;

    double t = 0;
    final repeats = hdtRepeats;
    // Active window computed from PHY and packet params
    final double computedActive = computeHdtActiveUs();
    // Ensure active doesn't exceed period; if it does we cap to period
    final double activeUs = math.min(computedActive, hdtPeriodUs);
    final double idleUs = math.max(0.0, hdtPeriodUs - activeUs);

    for (int i = 0; i < repeats; i++) {
      if (hdtModule == HdtModule.device) {
        // Device: RX then IDLE
        events.add(PowerEvent(
          startUs: t,
          durationUs: activeUs,
          currentMa: rxI,
          label: 'HDT RX',
          color: Colors.blue.shade400,
        ));
      } else {
        // Host: TX then IDLE
        events.add(PowerEvent(
          startUs: t,
          durationUs: activeUs,
          currentMa: txI,
          label: 'HDT TX',
          color: Colors.red.shade400,
        ));
      }
      t += activeUs;

      // Idle after the active window
      if (idleUs > 0.0) {
        events.add(PowerEvent(
          startUs: t,
          durationUs: idleUs,
          currentMa: idleCurrent,
          label: 'Idle',
          color: Colors.green.shade200,
        ));
      }
      t += idleUs;
    }

    final remaining = math.max(0, intervalUs - t);
    if (remaining > 0) {
      events.add(PowerEvent(
        startUs: t,
        durationUs: remaining.toDouble(),
        currentMa: idleCurrent,
        label: 'Idle',
        color: Colors.green.shade200,
      ));
    }

    _computeAverageCurrent();
    notifyListeners();
  }

  void recompute() {
    // Dispatch to case-specific recompute routines
    switch (caseType) {
      case SniffCase.btSniff:
        _recomputeBtSniff();
        break;
      case SniffCase.btPage:
        _recomputeBtPage();
        break;
      case SniffCase.btPagescan:
        _recomputeBtPagescan();
        break;
      case SniffCase.hdt:
        _recomputeHdt();
        break;
      case SniffCase.relay:
        _recomputeRelay();
        break;
    }
  }

  void _recomputeBtSniff() {
    // Sniffing: single TRX per period (one setup + one RX + one Post, then Sleep)
    events = [];
    final intervalUs = sniffIntervalMs * 1000.0;
    periodUs = intervalUs;

    final rxI = chip.rxCurrent_mA;
    final postUs = chip.postProcess_us;
    final postI = chip.postCurrent_mA;
    final sleepI = chip.sleepCurrent_uA / 1000.0;

    double t = 0;
    _addSetupPhases(events, t, chip);
    t += _setupTotalUsChip(chip);

    events.add(PowerEvent(
      startUs: t,
      durationUs: sniffWindowUs,
      currentMa: rxI,
      label: 'RX Sniff',
      color: Colors.blue.shade400,
    ));
    t += sniffWindowUs;

    // TIFS (RX->TX turn-around)
    events.add(PowerEvent(
      startUs: t,
      durationUs: chip.tifs_us,
      currentMa: chip.tifsCurrent_mA,
      label: 'TIFS',
      color: Colors.orange.shade200,
    ));
    t += chip.tifs_us;

    // TX (part of TRX after RX)
    final txI = chip.txCurrentForPower(txPowerDbm);
    events.add(PowerEvent(
      startUs: t,
      durationUs: sniffWindowUs,
      currentMa: txI,
      label: 'TX',
      color: Colors.red.shade400,
    ));
    t += sniffWindowUs;

    // Post-processing after TX
    events.add(PowerEvent(
      startUs: t,
      durationUs: postUs,
      currentMa: postI,
      label: 'Post',
      color: Colors.purple.shade400,
    ));
    t += postUs;

    final remaining = math.max(0, intervalUs - t);
    if (remaining > 0) {
      events.add(PowerEvent(
        startUs: t,
        durationUs: remaining.toDouble(),
        currentMa: sleepI,
        label: 'Sleep',
        color: Colors.green.shade200,
      ));
    }

    _computeAverageCurrent();
    notifyListeners();
  }

  void _recomputeBtPage() {
    // BT Page: single-channel page-like scan per interval
    events = [];
    // Choose interval based on current mode: connected uses connection interval, advertising uses adv interval
    final intervalMs = (mode == Mode.connected) ? connIntervalMs : advIntervalMs;
    final intervalUs = intervalMs * 1000.0;
    periodUs = intervalUs;

    final rxI = chip.rxCurrent_mA;
    final postUs = chip.postProcess_us;
    final postI = chip.postCurrent_mA;
    final sleepI = chip.sleepCurrent_uA / 1000.0;

    double t = 0;
    // single setup
    _addSetupPhases(events, t, chip);
    t += _setupTotalUsChip(chip);

    // One RX window (page) per period
    events.add(PowerEvent(
      startUs: t,
      durationUs: sniffWindowUs,
      currentMa: rxI,
      label: 'Page RX',
      color: Colors.blue.shade600,
    ));
    t += sniffWindowUs;

    // Post
    events.add(PowerEvent(
      startUs: t,
      durationUs: postUs,
      currentMa: postI,
      label: 'Post',
      color: Colors.purple.shade400,
    ));
    t += postUs;

    final remaining = math.max(0, intervalUs - t);
    if (remaining > 0) {
      events.add(PowerEvent(
        startUs: t,
        durationUs: remaining.toDouble(),
        currentMa: sleepI,
        label: 'Sleep',
        color: Colors.green.shade200,
      ));
    }

    _computeAverageCurrent();
    notifyListeners();
  }

  void _recomputeBtPagescan() {
    // BT PageScan: one wakeup/setup, then scan channels with short RX windows
    events = [];
    final intervalUs = sniffIntervalMs * 1000.0;
    periodUs = intervalUs;

    final rxI = chip.rxCurrent_mA;
    final postUs = chip.postProcess_us;
    final postI = chip.postCurrent_mA;
    final sleepI = chip.sleepCurrent_uA / 1000.0;

    double t = 0;
    // Single setup at the start of the pagescan
    _addSetupPhases(events, t, chip);
    t += _setupTotalUsChip(chip);

    final window = sniffWindowUs * 0.6; // pagescan shorter per-channel window

    for (int i = 0; i < channelsPerCycle; i++) {
      // RX on channel i
      events.add(PowerEvent(
        startUs: t,
        durationUs: window,
        currentMa: rxI,
        label: 'PageScan RX CH${i+1}',
        color: Colors.indigo.shade400,
      ));
      t += window;

      // Small post-processing per channel (shorter)
      events.add(PowerEvent(
        startUs: t,
        durationUs: postUs * 0.4,
        currentMa: postI,
        label: 'Post',
        color: Colors.purple.shade200,
      ));
      t += postUs * 0.4;

      // Fixed gap between channels (do not re-run full setup)
      if (i < channelsPerCycle - 1) {
        events.add(PowerEvent(
          startUs: t,
          durationUs: channelGapUs,
          currentMa: sleepI,
          label: 'Channel gap',
          color: Colors.green.shade200,
        ));
        t += channelGapUs;
      }
    }

    final remaining = math.max(0, intervalUs - t);
    if (remaining > 0) {
      events.add(PowerEvent(
        startUs: t,
        durationUs: remaining.toDouble(),
        currentMa: sleepI,
        label: 'Sleep',
        color: Colors.green.shade200,
      ));
    }

    _computeAverageCurrent();
    notifyListeners();
  }

  

  void _recomputeRelay() {
    // Relay: two quick RX hops with short gaps to mimic relay behavior
    events = [];
    final intervalUs = sniffIntervalMs * 1000.0;
    periodUs = intervalUs;

    final rxI = chip.rxCurrent_mA;
    final postUs = chip.postProcess_us;
    final postI = chip.postCurrent_mA;
    final sleepI = chip.sleepCurrent_uA / 1000.0;

    double t = 0;
    // First hop
    _addSetupPhases(events, t, chip);
    t += _setupTotalUsChip(chip);
    events.add(PowerEvent(
      startUs: t,
      durationUs: sniffWindowUs * 0.5,
      currentMa: rxI,
      label: 'Relay RX1',
      color: Colors.teal.shade400,
    ));
    t += sniffWindowUs * 0.5;
    events.add(PowerEvent(
      startUs: t,
      durationUs: postUs * 0.5,
      currentMa: postI,
      label: 'Post',
      color: Colors.purple.shade200,
    ));
    t += postUs * 0.5;

    // Small internal gap
    events.add(PowerEvent(
      startUs: t,
      durationUs: relayHopGapUs,
      currentMa: sleepI,
      label: 'Relay gap',
      color: Colors.green.shade100,
    ));
    t += relayHopGapUs;

    // Second hop
    _addSetupPhases(events, t, chip);
    t += _setupTotalUsChip(chip);
    events.add(PowerEvent(
      startUs: t,
      durationUs: sniffWindowUs * 0.5,
      currentMa: rxI,
      label: 'Relay RX2',
      color: Colors.teal.shade700,
    ));
    t += sniffWindowUs * 0.5;
    events.add(PowerEvent(
      startUs: t,
      durationUs: postUs * 0.5,
      currentMa: postI,
      label: 'Post',
      color: Colors.purple.shade200,
    ));
    t += postUs * 0.5;

    final remaining = math.max(0, intervalUs - t);
    if (remaining > 0) {
      events.add(PowerEvent(
        startUs: t,
        durationUs: remaining.toDouble(),
        currentMa: sleepI,
        label: 'Sleep',
        color: Colors.green.shade200,
      ));
    }

    _computeAverageCurrent();
    notifyListeners();
  }

  // Sniffing 的 setup 拆分
  void _addSetupPhases(List<PowerEvent> list, double startT, BleChip chip) {
    double t = startT;
    list.add(PowerEvent(
      startUs: t,
      durationUs: chip.preProcess_us,
      currentMa: chip.preProcessCurrent_mA,
      label: 'Pre-processing',
      color: Colors.orange.shade300,
    ));
    t += chip.preProcess_us;

    list.add(PowerEvent(
      startUs: t,
      durationUs: chip.crystalRampUp_us,
      currentMa: chip.crystalRampUpCurrent_mA,
      label: 'Crystal ramp-up',
      color: Colors.orange.shade400,
    ));
    t += chip.crystalRampUp_us;

    list.add(PowerEvent(
      startUs: t,
      durationUs: chip.standby_us,
      currentMa: chip.standbyCurrent_mA,
      label: 'Standby',
      color: Colors.orange.shade200,
    ));
    t += chip.standby_us;

    list.add(PowerEvent(
      startUs: t,
      durationUs: chip.startRadio_us,
      currentMa: chip.startRadioCurrent_mA,
      label: 'Start radio',
      color: Colors.orange.shade600,
    ));
  }

  double _setupTotalUsChip(BleChip chip) {
    return chip.preProcess_us +
        chip.crystalRampUp_us +
        chip.standby_us +
        chip.startRadio_us;
  }

  void _computeAverageCurrent() {
    if (periodUs <= 0 || events.isEmpty) {
      averageCurrent_mA = 0;
      return;
    }
    double sum = 0;
    for (final e in events) {
      sum += e.currentMa * e.durationUs;
    }
    averageCurrent_mA = sum / periodUs;
    
  }

  double get batteryLife_hours {
    if (averageCurrent_mA <= 0) return double.infinity;
    return batteryCapacity_mAh / averageCurrent_mA;
  }

  double get maxCurrent_mA {
    double m = 0;
    for (final e in events) {
      m = math.max(m, e.currentMa);
    }
    return m;
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
