// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/ble_chip.dart';
import '../models/power_event.dart';
import 'app_state.dart';

class SniffingState extends ChangeNotifier {
  final List<BleChip> chips = AppState().chips;

  late String selectedChipId;

  double sniffIntervalMs = 100.0;
  double sniffWindowUs = 2000.0;
  int channelsPerCycle = 3;
  double channelGapUs = 5000.0;

  List<PowerEvent> events = [];
  double periodUs = 0;
  double averageCurrent_mA = 0;
  double batteryCapacity_mAh = 220;
  bool hideLowPowerGaps = true;

  SniffingState() {
    selectedChipId = chips.first.id;
    recompute();
  }

  BleChip get chip => chips.firstWhere((c) => c.id == selectedChipId);

  void setChip(String id) {
    selectedChipId = id;
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
    channelsPerCycle = n.clamp(1, 3);
    recompute();
  }

  void setChannelGapUs(double us) {
    channelGapUs = us.clamp(0.0, 100000.0);
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

  void recompute() {
    events = [];
    final intervalUs = sniffIntervalMs * 1000.0;
    periodUs = intervalUs;

    final rxI = chip.rxCurrent_mA;
    final postUs = chip.postProcess_us;
    final postI = chip.postCurrent_mA;
    final sleepI = chip.sleepCurrent_uA / 1000.0;

    double t = 0;
    for (int i = 0; i < channelsPerCycle; i++) {
      // Setup phases（侦听开始时）
      _addSetupPhases(events, t, chip);
      t += _setupTotalUsChip(chip);

      // RX Sniff
      events.add(PowerEvent(
        startUs: t,
        durationUs: sniffWindowUs,
        currentMa: rxI,
        label: 'RX Sniff',
        color: Colors.blue.shade400,
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

      if (i < channelsPerCycle - 1) {
        events.add(PowerEvent(
          startUs: t,
          durationUs: channelGapUs,
          currentMa: sleepI,
          label: 'Gap',
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
