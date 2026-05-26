// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/ble_chip.dart';
import '../models/bt_chip.dart';
import '../models/power_event.dart';
import '../models/profile_params.dart' show Mode, Phy;
import '../services/config/config_repository.dart';
import '../services/power_calculator.dart';

enum BTCase { btSniff, btPage, btPagescan, relay }

enum HdtModule { source, sink }

enum BtPacketType {
  dm1,
  edr2Dh1,
}

extension BtPacketTypeSpec on BtPacketType {
  String get label {
    switch (this) {
      case BtPacketType.dm1:
        return 'DM1';
      case BtPacketType.edr2Dh1:
        return '2-DH1';
    }
  }

  int get slots {
    switch (this) {
      case BtPacketType.dm1:
      case BtPacketType.edr2Dh1:
        return 1;
    }
  }

  double get payloadRateMbps {
    switch (this) {
      case BtPacketType.dm1:
        return 1.0;
      case BtPacketType.edr2Dh1:
        return 2.0;
    }
  }
}

class BTState extends ChangeNotifier {
  static const List<BtPacketType> packetTypes = BtPacketType.values;

  final List<BleChip> bleChips = ConfigRepository.instance.bleChips;
  final List<BtChip> btChips = ConfigRepository.instance.btChips;

  late String selectedChipId;

  double sniffIntervalMs = 500.0;
  double sniffWindowUs = 80.0;
  int channelsPerCycle = 3;
  double channelGapUs = 150.0;
  int hdtRepeats = 1;
  HdtModule hdtModule = HdtModule.sink;
  double relayHopGapUs = 1000.0;

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

  // --- BT timing settings ---
  static const double slotUs = 625.0;
  int connectIntervalSlots = 800;
  int attemptCount = 1;
  double clockDriftPpm = 50.0;
  int rxPayloadBytes = 0;
  int txPayloadBytes = 0;
  BtPacketType packetType = BtPacketType.dm1;
  bool useDefaultConfig = true;

  double get connectIntervalMs => connectIntervalSlots * slotUs / 1000.0;
  double get _connectIntervalUs => connectIntervalSlots * slotUs;
  double get _packetMaxUs => packetType.slots * slotUs;
  double get _rxPayloadUs => rxPayloadBytes * 8.0 / packetType.payloadRateMbps;
  double get _txPayloadUs => txPayloadBytes * 8.0 / packetType.payloadRateMbps;
  double get _rxExtWindowUs => (chip as dynamic).rxExtWindow_us as double;
  double get _rxMinUs => (chip as dynamic).Rmin_us as double;
  double get _attemptWaitUs => (chip as dynamic).AttemptWaitTimeUS as double;
  double get _guardUs => _connectIntervalUs * clockDriftPpm / 1000000.0;
  int get _extraRxAttempts => math.max(0, attemptCount - 1);
  double get _rxPacketDurationUs =>
      math.min(_rxMinUs + _rxPayloadUs, _packetMaxUs);
  double get _mainRxDurationUs => _rxExtWindowUs + _rxPacketDurationUs;
  double get _rxDurationUs => _rxPacketDurationUs;
  double get _txDurationUs => math.min(_rxMinUs + _txPayloadUs, _packetMaxUs);

  // --- BLE settings ---
  Mode mode = Mode.advertisingTxRx;
  int blePayloadBytes = 20;
  double connIntervalMs = 200.0;
  double advIntervalMs = 100.0;
  BTCase caseType = BTCase.btSniff;

  dynamic get chip {
    final isBtCase = caseType == BTCase.btSniff ||
        caseType == BTCase.btPage ||
        caseType == BTCase.btPagescan ||
        caseType == BTCase.relay;
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
        caseType == BTCase.relay;
    selectedChipId = isBtCase ? btChips.first.id : bleChips.first.id;
    _syncBtDefaultsFromChip();
    recompute();
  }

  // --- Setters (unchanged mostly) ---

  void setTxPower(double dbm) {
    txPowerDbm = dbm;
    recompute();
  }

  void setBand(String b) {
    if (b != band) {
      band = b;
      recompute();
    }
  }

  void setMode(Mode m) {
    mode = m;
    recompute();
  }

  void setBlePayload(int bytes) {
    blePayloadBytes = bytes.clamp(0, 1024).toInt();
    recompute();
  }

  void setSupplyVoltage(double v) {
    supplyVoltage_V = v.clamp(1.8, 5.5);
    notifyListeners();
  }

  void setConnIntervalMs(double ms) {
    connIntervalMs = ms;
    recompute();
  }

  void setConnectIntervalSlots(int slots) {
    connectIntervalSlots = slots.clamp(16, 8000).toInt();
    recompute();
  }

  void setConnectIntervalMs(double ms) {
    final slots = (ms * 1000.0 / slotUs).round();
    setConnectIntervalSlots(slots);
  }

  void setAdvIntervalMs(double ms) {
    advIntervalMs = ms;
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

  void setAttemptCount(int n) {
    attemptCount = n.clamp(1, 16).toInt();
    recompute();
  }

  void setClockDriftPpm(double ppm) {
    clockDriftPpm = ppm.clamp(20.0, 500.0);
    recompute();
  }

  void setRxPayloadBytes(int bytes) {
    rxPayloadBytes = bytes.clamp(0, 1024).toInt();
    recompute();
  }

  void setTxPayloadBytes(int bytes) {
    txPayloadBytes = bytes.clamp(0, 1024).toInt();
    recompute();
  }

  void setPacketType(BtPacketType type) {
    packetType = type;
    recompute();
  }

  void setUseDefaultConfig(bool enabled) {
    useDefaultConfig = enabled;
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

  void setHdtPhyRate(double mbps) {
    hdtPhyRateMbps = mbps.clamp(2.0, 15.0);
    recompute();
  }

  void setChip(String id) {
    selectedChipId = id;
    _syncBtDefaultsFromChip();
    recompute();
  }

  void setCase(BTCase c) {
    caseType = c;
    if (caseType == BTCase.btSniff ||
        caseType == BTCase.btPage ||
        caseType == BTCase.btPagescan ||
        caseType == BTCase.relay) {
      if (!btChips.any((b) => b.id == selectedChipId)) {
        selectedChipId = btChips.first.id;
      }
    } else {
      if (!bleChips.any((b) => b.id == selectedChipId)) {
        selectedChipId = bleChips.first.id;
      }
    }
    _syncBtDefaultsFromChip();
    recompute();
  }

  void _syncBtDefaultsFromChip() {
    final current = chip;
    if (current is BtChip) {
      clockDriftPpm = current.clockDriftPpm;
      supplyVoltage_V = current.vbat.clamp(1.8, 5.5).toDouble();
    }
  }

  void setHideLowPowerGaps(bool hide) {
    hideLowPowerGaps = hide;
    notifyListeners();
  }

  // Advanced visibility and PHY
  Phy phy = Phy.le1M;
  bool get showAdvanced {
    return (mode == Mode.bleConnectionCentral ||
        mode == Mode.bleConnectionPeripheral);
  }

  void setPhy(Phy p) {
    phy = p;
    recompute();
  }

  // --- Calculation Helpers ---

  double _fixedOverheadUsAtRate() {
    const double fixedAt15 = 44.0;
    return fixedAt15 * (15.0 / hdtPhyRateMbps);
  }

  double _pduAirtimeUs() {
    final int pduBits = (hdtPayloadBytes + hdtPayloadHeaderBytes) * 8 +
        hdtCrcBits +
        hdtMicBits +
        hdtZeroPaddingBits;
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
      case BTCase.btSniff:
        _recomputeBtSniff();
        break;
      case BTCase.btPage:
        _recomputeBtPage();
        break;
      case BTCase.btPagescan:
        _recomputeBtPagescan();
        break;

      case BTCase.relay:
        _recomputeRelay();
        break;
    }
    averageCurrent_mA = PowerCalculator.computeAverageCurrent(events, periodUs);
    notifyListeners();
  }

  void _addWindowWidening(
    double startUs,
    double rxI,
    String suffix, {
    String? previewLabel,
    double? totalLengthUs,
    double? radioRxLengthUs,
  }) {
    final guardUs = _guardUs;
    if (guardUs <= 0) return;
    events.add(PowerEvent(
        startUs: startUs,
        durationUs: guardUs,
        currentMa: rxI,
        label: 'Window widening$suffix',
        color: Colors.cyan.shade300,
        previewLabel: previewLabel,
        totalLengthUs: totalLengthUs,
        windowWideningLengthUs: guardUs,
        occupiedLengthUs: radioRxLengthUs));
  }

  void _recomputeBtSniff() {
    if (useDefaultConfig && chip is BtChip) {
      _recomputeBtSniffDefault();
      return;
    }

    events = [];
    final intervalUs = _connectIntervalUs;
    periodUs = intervalUs;
    final rxI = chip.rxCurrent_mA;
    final postUs = chip.postProcess_us;
    final postI = chip.postCurrent_mA;
    final sleepI = chip.sleepCurrent_uA / 1000.0;
    final rxDurationUs = _mainRxDurationUs;
    final txDurationUs = _txDurationUs;

    double t = 0;
    PowerCalculator.addSetupPhases(events, t, chip);
    t += PowerCalculator.getSetupTotalUs(chip);

    final totalRxLengthUs = _guardUs + rxDurationUs;
    _addWindowWidening(
      t,
      rxI,
      '',
      previewLabel: 'Main RX',
      totalLengthUs: totalRxLengthUs,
      radioRxLengthUs: rxDurationUs,
    );
    t += _guardUs;
    events.add(PowerEvent(
        startUs: t,
        durationUs: rxDurationUs,
        currentMa: rxI,
        label: 'Main RX',
        color: Colors.blue.shade400,
        previewLabel: 'Main RX',
        totalLengthUs: totalRxLengthUs,
        windowWideningLengthUs: _guardUs,
        occupiedLengthUs: rxDurationUs));
    t += rxDurationUs;
    events.add(PowerEvent(
        startUs: t,
        durationUs: chip.tifs_us,
        currentMa: chip.tifsCurrent_mA,
        label: 'TIFS',
        color: Colors.orange.shade200));
    t += chip.tifs_us;

    final txI = chip.txCurrentForPower(txPowerDbm);
    events.add(PowerEvent(
        startUs: t,
        durationUs: txDurationUs,
        currentMa: txI,
        label: 'TX',
        color: Colors.red.shade400));
    t += txDurationUs;

    for (int i = 0; i < _extraRxAttempts; i++) {
      final suffix = _extraRxAttempts > 1 ? ' ${i + 1}' : '';
      events.add(PowerEvent(
          startUs: t,
          durationUs: _attemptWaitUs,
          currentMa: chip.standbyCurrent_mA,
          label: 'Attempt wait standby$suffix',
          color: Colors.orange.shade200));
      t += _attemptWaitUs;
      events.add(PowerEvent(
          startUs: t,
          durationUs: _rxMinUs,
          currentMa: rxI,
          label: 'RXmin$suffix',
          color: Colors.blue.shade200));
      t += _rxMinUs;
    }
    events.add(PowerEvent(
        startUs: t,
        durationUs: postUs,
        currentMa: postI,
        label: 'Post',
        color: Colors.purple.shade400));
    t += postUs;

    final remaining = math.max(0, intervalUs - t);
    if (remaining > 0) {
      events.add(PowerEvent(
          startUs: t,
          durationUs: remaining.toDouble(),
          currentMa: sleepI,
          label: 'Sleep',
          color: Colors.green.shade200));
    }
  }

  void _recomputeBtSniffDefault() {
    events = [];
    final btChip = chip as BtChip;
    final config = btChip.effectiveDefaultConfig;
    final intervalUs = _connectIntervalUs;
    periodUs = intervalUs;
    final rxI = btChip.rxCurrent_mA;
    final sleepI = btChip.sleepCurrent_uA / 1000.0;
    final txI = btChip.txCurrentForPower(txPowerDbm);

    double t = 0;
    events.add(PowerEvent(
      startUs: t,
      durationUs: config.preProcessLength_us,
      currentMa: btChip.preProcessCurrent_mA,
      label: 'Pre-processing',
      color: Colors.orange.shade300,
    ));
    t += config.preProcessLength_us;

    events.add(PowerEvent(
      startUs: t,
      durationUs: config.crystalRampUpLength_us,
      currentMa: btChip.crystalRampUpCurrent_mA,
      label: 'Crystal ramp-up',
      color: Colors.orange.shade400,
    ));
    t += config.crystalRampUpLength_us;

    events.add(PowerEvent(
      startUs: t,
      durationUs: config.standbyLength_us,
      currentMa: btChip.standbyCurrent_mA,
      label: 'Standby',
      color: Colors.orange.shade200,
    ));
    t += config.standbyLength_us;

    final totalRxLengthUs =
        config.windowWideningLength_us + config.mainRxLength_us;
    events.add(PowerEvent(
      startUs: t,
      durationUs: config.windowWideningLength_us,
      currentMa: rxI,
      label: 'Window widening',
      color: Colors.cyan.shade300,
      previewLabel: 'Main RX',
      totalLengthUs: totalRxLengthUs,
      windowWideningLengthUs: config.windowWideningLength_us,
      occupiedLengthUs: config.mainRxLength_us,
    ));
    t += config.windowWideningLength_us;

    events.add(PowerEvent(
      startUs: t,
      durationUs: config.mainRxLength_us,
      currentMa: rxI,
      label: 'Main RX',
      color: Colors.blue.shade400,
      previewLabel: 'Main RX',
      totalLengthUs: totalRxLengthUs,
      windowWideningLengthUs: config.windowWideningLength_us,
      occupiedLengthUs: config.mainRxLength_us,
    ));
    t += config.mainRxLength_us;

    events.add(PowerEvent(
      startUs: t,
      durationUs: config.tifsLength_us,
      currentMa: btChip.tifsCurrent_mA,
      label: 'TIFS',
      color: Colors.orange.shade200,
    ));
    t += config.tifsLength_us;

    events.add(PowerEvent(
      startUs: t,
      durationUs: config.txLength_us,
      currentMa: txI,
      label: 'TX',
      color: Colors.red.shade400,
    ));
    t += config.txLength_us;

    events.add(PowerEvent(
      startUs: t,
      durationUs: config.postProcessLength_us,
      currentMa: btChip.postCurrent_mA,
      label: 'Post',
      color: Colors.purple.shade400,
    ));
    t += config.postProcessLength_us;

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
  }

  void _recomputeBtPage() {
    events = [];
    final intervalUs = _connectIntervalUs;
    periodUs = intervalUs;
    final rxI = chip.rxCurrent_mA;
    final postUs = chip.postProcess_us;
    final postI = chip.postCurrent_mA;
    final sleepI = chip.sleepCurrent_uA / 1000.0;
    final rxDurationUs = _rxDurationUs;

    double t = 0;
    PowerCalculator.addSetupPhases(events, t, chip);
    t += PowerCalculator.getSetupTotalUs(chip);

    for (int i = 0; i < attemptCount; i++) {
      final suffix = attemptCount > 1 ? ' ${i + 1}' : '';
      _addWindowWidening(t, rxI, suffix);
      t += _guardUs;
      events.add(PowerEvent(
          startUs: t,
          durationUs: rxDurationUs,
          currentMa: rxI,
          label: 'Page RX$suffix',
          color: Colors.blue.shade600));
      t += rxDurationUs;
      events.add(PowerEvent(
          startUs: t,
          durationUs: postUs,
          currentMa: postI,
          label: 'Post',
          color: Colors.purple.shade400));
      t += postUs;
    }

    final remaining = math.max(0, intervalUs - t);
    if (remaining > 0) {
      events.add(PowerEvent(
          startUs: t,
          durationUs: remaining.toDouble(),
          currentMa: sleepI,
          label: 'Sleep',
          color: Colors.green.shade200));
    }
  }

  void _recomputeBtPagescan() {
    events = [];
    final intervalUs = _connectIntervalUs;
    periodUs = intervalUs;
    final rxI = chip.rxCurrent_mA;
    final postUs = chip.postProcess_us;
    final postI = chip.postCurrent_mA;
    final sleepI = chip.sleepCurrent_uA / 1000.0;
    final window = _rxDurationUs * 0.6;

    double t = 0;
    PowerCalculator.addSetupPhases(events, t, chip);
    t += PowerCalculator.getSetupTotalUs(chip);

    for (int attempt = 0; attempt < attemptCount; attempt++) {
      for (int i = 0; i < channelsPerCycle; i++) {
        final suffix = attemptCount > 1 ? ' A${attempt + 1}' : '';
        _addWindowWidening(t, rxI, suffix);
        t += _guardUs;
        events.add(PowerEvent(
            startUs: t,
            durationUs: window,
            currentMa: rxI,
            label: 'PageScan RX CH${i + 1}$suffix',
            color: Colors.indigo.shade400));
        t += window;
        events.add(PowerEvent(
            startUs: t,
            durationUs: postUs * 0.4,
            currentMa: postI,
            label: 'Post',
            color: Colors.purple.shade200));
        t += postUs * 0.4;
        if (i < channelsPerCycle - 1) {
          events.add(PowerEvent(
              startUs: t,
              durationUs: channelGapUs,
              currentMa: sleepI,
              label: 'Channel gap',
              color: Colors.green.shade200));
          t += channelGapUs;
        }
      }
    }
    final remaining = math.max(0, intervalUs - t);
    if (remaining > 0) {
      events.add(PowerEvent(
          startUs: t,
          durationUs: remaining.toDouble(),
          currentMa: sleepI,
          label: 'Sleep',
          color: Colors.green.shade200));
    }
  }

  void _recomputeRelay() {
    events = [];
    final intervalUs = _connectIntervalUs;
    periodUs = intervalUs;
    final rxI = chip.rxCurrent_mA;
    final postUs = chip.postProcess_us;
    final postI = chip.postCurrent_mA;
    final sleepI = chip.sleepCurrent_uA / 1000.0;
    final rxDurationUs = _rxDurationUs;

    double t = 0;
    for (int i = 0; i < attemptCount; i++) {
      final suffix = attemptCount > 1 ? ' ${i + 1}' : '';
      PowerCalculator.addSetupPhases(events, t, chip);
      t += PowerCalculator.getSetupTotalUs(chip);
      _addWindowWidening(t, rxI, ' RX1$suffix');
      t += _guardUs;
      events.add(PowerEvent(
          startUs: t,
          durationUs: rxDurationUs * 0.5,
          currentMa: rxI,
          label: 'Relay RX1$suffix',
          color: Colors.teal.shade400));
      t += rxDurationUs * 0.5;
      events.add(PowerEvent(
          startUs: t,
          durationUs: postUs * 0.5,
          currentMa: postI,
          label: 'Post',
          color: Colors.purple.shade200));
      t += postUs * 0.5;

      events.add(PowerEvent(
          startUs: t,
          durationUs: relayHopGapUs,
          currentMa: sleepI,
          label: 'Relay gap',
          color: Colors.green.shade100));
      t += relayHopGapUs;

      PowerCalculator.addSetupPhases(events, t, chip);
      t += PowerCalculator.getSetupTotalUs(chip);
      _addWindowWidening(t, rxI, ' RX2$suffix');
      t += _guardUs;
      events.add(PowerEvent(
          startUs: t,
          durationUs: rxDurationUs * 0.5,
          currentMa: rxI,
          label: 'Relay RX2$suffix',
          color: Colors.teal.shade700));
      t += rxDurationUs * 0.5;
      events.add(PowerEvent(
          startUs: t,
          durationUs: postUs * 0.5,
          currentMa: postI,
          label: 'Post',
          color: Colors.purple.shade200));
      t += postUs * 0.5;
    }

    final remaining = math.max(0, intervalUs - t);
    if (remaining > 0) {
      events.add(PowerEvent(
          startUs: t,
          durationUs: remaining.toDouble(),
          currentMa: sleepI,
          label: 'Sleep',
          color: Colors.green.shade200));
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
