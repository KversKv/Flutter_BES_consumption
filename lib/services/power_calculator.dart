import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/ble_chip.dart';
import '../models/power_event.dart';
import '../models/profile_params.dart';

/// 纯业务逻辑服务类，负责通用的功耗计算和Setup阶段生成
class PowerCalculator {
  
  /// 添加通用的 Setup 阶段 (适用于 BLE 和 BT)
  static void addSetupPhases(List<PowerEvent> list, double startT, dynamic chip) {
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

  /// 计算 Setup 总时长
  static double getSetupTotalUs(dynamic chip) {
    return chip.preProcess_us +
        chip.crystalRampUp_us +
        chip.standby_us +
        chip.startRadio_us;
  }

  /// 计算平均电流
  static double computeAverageCurrent(List<PowerEvent> events, double periodUs) {
    if (periodUs <= 0 || events.isEmpty) return 0;
    double sum = 0;
    for (final e in events) {
      sum += e.currentMa * e.durationUs;
    }
    return sum / periodUs;
  }

  /// 计算峰值电流
  static double computeMaxCurrent(List<PowerEvent> events) {
    if (events.isEmpty) return 0;
    double m = 0;
    for (final e in events) {
      m = math.max(m, e.currentMa);
    }
    return m;
  }

  // --- BLE 辅助计算 ---

  static double _usPerByte(Phy phy) {
    switch (phy) {
      case Phy.le1M: return 8;
      case Phy.le2M: return 4;
      case Phy.leCodedS8: return 64;
    }
  }

  static double txTimeUs(int payloadBytes, Phy phy) {
    final overheadBytes = 10;
    final totalBytes = payloadBytes + overheadBytes;
    return totalBytes * _usPerByte(phy);
  }

  /// 生成 BLE 广播周期事件
  static List<PowerEvent> generateBleAdvertising({
    required BleChip chip,
    required ProfileParams params,
    required double periodUs,
  }) {
    List<PowerEvent> events = [];
    final txUs = txTimeUs(params.payloadBytes, params.phy);
    final txI = chip.txCurrentForPower(params.txPowerDbm);
    final postUs = chip.postProcess_us;
    final postI = chip.postCurrent_mA;
    final sleepI = chip.sleepCurrent_uA / 1000.0;

    double t = 0;

    // 1. Setup
    addSetupPhases(events, t, chip);
    t += getSetupTotalUs(chip);

    // 2. 广播三个信道
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

      if (i < 2) {
        // Gap
        events.add(PowerEvent(
          startUs: t,
          durationUs: chip.advGap_us,
          currentMa: chip.advGapCurrent_mA,
          label: 'ADV_GAP',
          color: Colors.green.shade200,
        ));
        t += chip.advGap_us;
      } else {
        // Post
        events.add(PowerEvent(
          startUs: t,
          durationUs: postUs,
          currentMa: postI,
          label: 'Post',
          color: Colors.purple.shade400,
        ));
        t += postUs;
      }
    }

    // 3. Sleep
    final remaining = math.max(0, periodUs - t);
    if (remaining > 0) {
      events.add(PowerEvent(
        startUs: t,
        durationUs: remaining.toDouble(),
        currentMa: sleepI,
        label: 'Sleep',
        color: Colors.green.shade200,
      ));
    }
    return events;
  }

  /// 生成 BLE 连接周期事件
  static List<PowerEvent> generateBleConnected({
    required BleChip chip,
    required ProfileParams params,
    required double periodUs,
    required double rxWindowUs,
    required double rxCurrentMa,
  }) {
    List<PowerEvent> events = [];
    final rxI = rxCurrentMa > 0 ? rxCurrentMa : chip.rxCurrent_mA;
    final txI = chip.txCurrentForPower(params.txPowerDbm);
    final postUs = chip.postProcess_us;
    final postI = chip.postCurrent_mA;
    final sleepI = chip.sleepCurrent_uA / 1000.0;
    
    final finalRxUs = rxWindowUs > 0 ? rxWindowUs : chip.rxWindow_us;
    final tifs = chip.tifs_us;
    final txUs = txTimeUs(params.payloadBytes, params.phy);

    double t = 0;

    // Setup
    addSetupPhases(events, t, chip);
    t += getSetupTotalUs(chip);

    // RX
    events.add(PowerEvent(
      startUs: t,
      durationUs: finalRxUs,
      currentMa: rxI,
      label: 'RX',
      color: Colors.blue.shade400,
    ));
    t += finalRxUs;

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

    // Sleep
    final remaining = math.max(0, periodUs - t);
    if (remaining > 0) {
      events.add(PowerEvent(
        startUs: t,
        durationUs: remaining.toDouble(),
        currentMa: sleepI,
        label: 'Sleep',
        color: Colors.green.shade200,
      ));
    }
    return events;
  }
}