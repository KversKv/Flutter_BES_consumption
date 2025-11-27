// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/ble_chip.dart';
import '../models/power_event.dart';
import '../models/profile_params.dart';
import '../config/ble_chip_config.dart';

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
      mode: Mode.connected,
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

  /// Toggle the hideLowPowerGaps flag (used by UI toggle checkbox)
  void toggleHideLowPower() {
    hideLowPowerGaps = !hideLowPowerGaps;
    notifyListeners();
  }

  double _usPerByte(Phy phy) {
    switch (phy) {
      case Phy.le1M:
        return 8;
      case Phy.le2M:
        return 4;
      case Phy.leCodedS8:
        return 64;
    }
  }

  double _txTimeUs(int payloadBytes, Phy phy) {
    final overheadBytes = 10;
    final totalBytes = payloadBytes + overheadBytes;
    return totalBytes * _usPerByte(phy);
  }

  void recompute() {
    if (params.mode == Mode.advertising) {
      _generateAdvertisingCycle();
    } else {
      _generateConnectedCycle();
    }
    _computeAverageCurrent();
    notifyListeners();
  }

  void _addSetupPhases(List<PowerEvent> list, double startT) {
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

  double _setupTotalUs() {
    return chip.preProcess_us +
        chip.crystalRampUp_us +
        chip.standby_us +
        chip.startRadio_us;
  }

  double _generateAdvertisingCycle() {
    events = [];
    final intervalUs = (params.advIntervalMs * 1000).clamp(20000, 3_000_000).toDouble();
    periodUs = intervalUs;

    final txUs = _txTimeUs(params.payloadBytes, params.phy);
    final txI = chip.txCurrentForPower(params.txPowerDbm);
    final postUs = chip.postProcess_us;
    final postI = chip.postCurrent_mA;
    final sleepI = chip.sleepCurrent_uA / 1000.0;

    double t = 0;

    // 仅第一次 TX 前进行 Setup 阶段
    _addSetupPhases(events, t);
    t += _setupTotalUs();

    // 广播三个信道：CH37/38/39
    List<String> ch = ['ADV CH37', 'ADV CH38', 'ADV CH39'];
    for (int i = 0; i < 3; i++) {
      // TX
      events.add(PowerEvent(
        startUs: t,
        durationUs: txUs,
        currentMa: txI,
        label: '${ch[i]} TX',
        color: Colors.red.shade400,
      ));
      t += txUs;

      // 如果不是最后一个信道，在 TX 后插入短间隙（ADV_GAP）；
      // 只有在最后一次 TX 完成后才执行 Post 处理。
      if (i < 2) {
        events.add(PowerEvent(
          startUs: t,
          durationUs: chip.advGap_us,
          currentMa: chip.advGapCurrent_mA,
          label: 'ADV_GAP',
          color: Colors.green.shade200,
        ));
        t += chip.advGap_us;
      } else {
        // 最后一次 TX，做 Post
        events.add(PowerEvent(
          startUs: t,
          durationUs: postUs,
          currentMa: postI,
          // label: '${ch[i]} Post',
          label: 'Post',
          color: Colors.purple.shade400,
        ));
        t += postUs;
      }
    }

    // 剩余时间睡眠
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

    return t;
  }

  void _generateConnectedCycle() {
    events = [];
    final intervalUs = (params.connIntervalMs * 1000).clamp(7500, 4_000_000).toDouble();
    periodUs = intervalUs;

    final rxI = rxCurrentConnected_mA > 0 ? rxCurrentConnected_mA : chip.rxCurrent_mA;
    final txI = chip.txCurrentForPower(params.txPowerDbm);
    final postUs = chip.postProcess_us;
    final postI = chip.postCurrent_mA;
    final sleepI = chip.sleepCurrent_uA / 1000.0;

  final rxUs = rxWindowConnectedUs > 0 ? rxWindowConnectedUs : chip.rxWindow_us;
    final tifs = chip.tifs_us;
    final txUs = _txTimeUs(params.payloadBytes, params.phy);

    double t = 0;

    // Setup phases（连接事件的开始）
    _addSetupPhases(events, t);
    t += _setupTotalUs();

    // RX
    events.add(PowerEvent(
      startUs: t,
      durationUs: rxUs,
      currentMa: rxI,
      label: 'RX',
      color: Colors.blue.shade400,
    ));
    t += rxUs;

    // TIFS
    events.add(PowerEvent(
      startUs: t,
      durationUs: tifs,
      currentMa: chip.tifsCurrent_mA,
      label: 'TIFS',
      color: Colors.amber.shade300,
    ));
    t += tifs;

    // TX
    events.add(PowerEvent(
      startUs: t,
      durationUs: txUs,
      currentMa: txI,
      label: 'TX',
      color: Colors.red.shade400,
    ));
    t += txUs;

    // Post
    events.add(PowerEvent(
      startUs: t,
      durationUs: postUs,
      currentMa: postI,
      label: 'Post',
      color: Colors.purple.shade400,
    ));
    t += postUs;

    // 睡眠
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
