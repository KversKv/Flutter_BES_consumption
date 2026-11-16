// ignore_for_file: prefer_const_declarations, no_leading_underscores_for_local_identifiers, non_constant_identifier_names

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
  }

  /// 计算 Setup 总时长
  static double getSetupTotalUs(dynamic chip) {
    return chip.preProcess_us +
        chip.crystalRampUp_us +
        chip.standby_us ;
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

  // --- BLE 辅助计算（Nordic OPP 模型；电流取自芯片数据） ---

  static double _usPerByte(Phy phy) {
    switch (phy) {
      case Phy.le1M: return 8;
      case Phy.le2M: return 4;
    }
  }

  /// 空口时间 = (开销 + payload) × 8 / rate；开销 10B@1M / 11B@2M，
  /// 广播额外 +6B AdvA 与固定 6us。
  static double airtimeUs(int payloadBytes, Phy phy, {bool adv = false}) {
    final overheadBytes = (phy == Phy.le1M ? 10 : 11) + (adv ? 6 : 0);
    return (overheadBytes + payloadBytes) * _usPerByte(phy) + (adv ? 6 : 0);
  }

  static int llPduMax(bool dle) => dle ? 251 : 27;

  /// 按 LL PDU 上限拆包；CELE off 时每事件钳位到一个 PDU。
  static List<int> splitPayload(int payloadBytes, bool dle, bool cele) {
    final pdu = llPduMax(dle);
    var remaining = cele ? payloadBytes : math.min(payloadBytes, pdu);
    if (remaining <= 0) return const [0];
    final packets = <int>[];
    while (remaining > 0) {
      final n = math.min(remaining, pdu);
      packets.add(n);
      remaining -= n;
    }
    return packets;
  }

  /// 接收窗扩展 = (central_ppm + slave_ppm) × T_eff + 固定偏移；
  /// LFRC 强制 slave_ppm=500。
  static double windowWideningUs(ProfileParams params, double periodUs) {
    final slavePpm = params.lfRc ? 500 : params.peripheralPpm;
    return (params.centralPpm + slavePpm) * periodUs / 1e6 + 32;
  }

  /// 每个含 payload 的 RX 包触发的 CPU 处理时长（Nordic 实测常数）。
  static const double rxProcessUs = 227;

  static const double _advRxWindowUs = 59;
  static const double _advChannelGapUs = 62;
  static const double _nonconChannelGapUs = 58;

  /// 事件电荷（µC）= Σ I·Δt，不含 Sleep。
  static double computeEventCharge_uC(List<PowerEvent> events) {
    double sum = 0;
    for (final e in events) {
      if (e.label == 'Sleep') continue;
      sum += e.currentMa * e.durationUs;
    }
    return sum / 1000.0;
  }

  static void _addTailAndSleep(
      List<PowerEvent> events, double t, double periodUs, BleChip chip) {
    if (chip.tailStandby_us > 0) {
      events.add(PowerEvent(
        startUs: t,
        durationUs: chip.tailStandby_us,
        currentMa: chip.standbyCurrent_mA,
        label: 'Standby',
        color: Colors.orange.shade200,
      ));
      t += chip.tailStandby_us;
    }
    final remaining = math.max(0, periodUs - t);
    if (remaining > 0) {
      events.add(PowerEvent(
        startUs: t,
        durationUs: remaining.toDouble(),
        currentMa: chip.sleepCurrent_uA / 1000.0,
        label: 'Sleep',
        color: Colors.green.shade200,
      ));
    }
  }

  /// 生成 BLE 广播周期事件（TX/RX）。
  /// periodUs 由状态层按 (advInterval + 5ms advDelay) 传入；Start radio 仅一次。
  static List<PowerEvent> generateBleAdvertisingTxRx({
    required BleChip chip,
    required ProfileParams params,
    required double periodUs,
    required double rxCurrentMa,
  }) {
    final events = <PowerEvent>[];
    final txUs = airtimeUs(params.payloadBytes, params.phy, adv: true);
    final rxI = rxCurrentMa > 0 ? rxCurrentMa : chip.rxCurrent_mA;
    final txI = chip.txCurrentForPower(params.txPowerDbm);

    double t = 0;
    addSetupPhases(events, t, chip);
    t += getSetupTotalUs(chip);
    events.add(PowerEvent(
      startUs: t,
      durationUs: chip.startRadio_us,
      currentMa: chip.startRadioCurrent_mA,
      label: 'Start radio',
      color: Colors.orange.shade600,
    ));
    t += chip.startRadio_us;

    for (int i = 0; i < 3; i++) {
      events.add(PowerEvent(
        startUs: t,
        durationUs: txUs,
        currentMa: txI,
        label: 'ADV CH${37 + i} TX',
        color: Colors.red.shade400,
      ));
      t += txUs;
      events.add(PowerEvent(
        startUs: t,
        durationUs: chip.tifs_us,
        currentMa: chip.tifsCurrent_mA,
        label: 'TIFS',
        color: Colors.amber.shade300,
      ));
      t += chip.tifs_us;
      events.add(PowerEvent(
        startUs: t,
        durationUs: _advRxWindowUs,
        currentMa: rxI,
        label: 'RX',
        color: Colors.blue.shade400,
      ));
      t += _advRxWindowUs;
      if (i < 2) {
        events.add(PowerEvent(
          startUs: t,
          durationUs: _advChannelGapUs,
          currentMa: chip.advGapCurrent_mA,
          label: 'ADV_GAP',
          color: Colors.green.shade200,
        ));
        t += _advChannelGapUs;
      }
    }

    events.add(PowerEvent(
      startUs: t,
      durationUs: chip.postProcess_us,
      currentMa: chip.postCurrent_mA,
      label: 'Post',
      color: Colors.purple.shade400,
    ));
    t += chip.postProcess_us;
    _addTailAndSleep(events, t, periodUs, chip);
    return events;
  }

  /// 生成 BLE 广播周期事件（仅 TX）。
  static List<PowerEvent> generateBleAdvertisingTxOnly({
    required BleChip chip,
    required ProfileParams params,
    required double periodUs,
  }) {
    final events = <PowerEvent>[];
    final txUs = airtimeUs(params.payloadBytes, params.phy, adv: true);
    final txI = chip.txCurrentForPower(params.txPowerDbm);

    double t = 0;
    addSetupPhases(events, t, chip);
    t += getSetupTotalUs(chip);
    events.add(PowerEvent(
      startUs: t,
      durationUs: chip.startRadio_us,
      currentMa: chip.startRadioCurrent_mA,
      label: 'Start radio',
      color: Colors.orange.shade600,
    ));
    t += chip.startRadio_us;

    for (int i = 0; i < 3; i++) {
      events.add(PowerEvent(
        startUs: t,
        durationUs: txUs,
        currentMa: txI,
        label: 'ADV CH${37 + i} TX',
        color: Colors.red.shade400,
      ));
      t += txUs;
      if (i < 2) {
        events.add(PowerEvent(
          startUs: t,
          durationUs: _nonconChannelGapUs,
          currentMa: chip.advGapCurrent_mA,
          label: 'ADV_GAP',
          color: Colors.green.shade200,
        ));
        t += _nonconChannelGapUs;
      }
    }

    events.add(PowerEvent(
      startUs: t,
      durationUs: chip.postProcess_us,
      currentMa: chip.postCurrent_mA,
      label: 'Post',
      color: Colors.purple.shade400,
    ));
    t += chip.postProcess_us;
    _addTailAndSleep(events, t, periodUs, chip);
    return events;
  }

  /// 生成 BLE 连接周期事件（peripheral）。
  /// periodUs 由状态层按 (slaveLatency+1) × connInterval 传入。
  static List<PowerEvent> generateBleConnectedPeripheral({
    required BleChip chip,
    required ProfileParams params,
    required double periodUs,
    required double rxCurrentMa,
  }) {
    return _generateBleConnected(
      chip: chip,
      params: params,
      periodUs: periodUs,
      rxCurrentMa: rxCurrentMa,
      peripheral: true,
    );
  }

  /// 生成 BLE 连接周期事件（central，无窗扩展，TX 在前）。
  static List<PowerEvent> generateBleConnectedCentral({
    required BleChip chip,
    required ProfileParams params,
    required double periodUs,
    required double rxCurrentMa,
  }) {
    return _generateBleConnected(
      chip: chip,
      params: params,
      periodUs: periodUs,
      rxCurrentMa: rxCurrentMa,
      peripheral: false,
    );
  }

  static List<PowerEvent> _generateBleConnected({
    required BleChip chip,
    required ProfileParams params,
    required double periodUs,
    required double rxCurrentMa,
    required bool peripheral,
  }) {
    final events = <PowerEvent>[];
    final rxI = rxCurrentMa > 0 ? rxCurrentMa : chip.rxCurrent_mA;
    final txI = chip.txCurrentForPower(params.txPowerDbm);
    final cpuI = chip.postCurrent_mA;

    final txPackets =
        splitPayload(params.payloadBytes, params.dle, params.eventLengthExt);
    final rxPackets =
        splitPayload(params.rxPayloadBytes, params.dle, params.eventLengthExt);
    final n = math.max(txPackets.length, rxPackets.length);

    double t = 0;
    addSetupPhases(events, t, chip);
    t += getSetupTotalUs(chip);
    events.add(PowerEvent(
      startUs: t,
      durationUs: chip.startRadio_us,
      currentMa: chip.startRadioCurrent_mA,
      label: 'Start radio',
      color: Colors.orange.shade600,
    ));
    t += chip.startRadio_us;

    if (peripheral) {
      final wUs = windowWideningUs(params, periodUs);
      events.add(PowerEvent(
        startUs: t,
        durationUs: wUs,
        currentMa: rxI,
        label: 'Window widening',
        color: Colors.green.shade300,
      ));
      t += wUs;
    }

    double maxOverlap = 0;
    bool anyRx = false;
    for (int i = 0; i < n; i++) {
      final txB = i < txPackets.length ? txPackets[i] : 0;
      final rxB = i < rxPackets.length ? rxPackets[i] : 0;
      final txUs = airtimeUs(txB, params.phy);
      final rxUs = airtimeUs(rxB, params.phy);
      // RX 含 payload 时 CPU 处理与随后 TX 重叠（peripheral 实测行为）。
      final overlap =
          peripheral && rxB > 0 ? math.min(txUs, rxProcessUs) : 0.0;
      if (rxB > 0) anyRx = true;
      maxOverlap = math.max(maxOverlap, overlap);

      void addSwitch(double current) {
        events.add(PowerEvent(
          startUs: t,
          durationUs: chip.tifs_us,
          currentMa: current,
          label: 'TIFS',
          color: Colors.amber.shade300,
        ));
        t += chip.tifs_us;
      }

      void addRx() {
        events.add(PowerEvent(
          startUs: t,
          durationUs: rxUs,
          currentMa: rxI,
          label: 'RX',
          color: Colors.blue.shade400,
        ));
        t += rxUs;
      }

      void addTx() {
        if (overlap > 0) {
          events.add(PowerEvent(
            startUs: t,
            durationUs: overlap,
            currentMa: txI + cpuI,
            label: 'TX + CPU',
            color: Colors.red.shade300,
          ));
          t += overlap;
        }
        final rest = txUs - overlap;
        if (rest > 0) {
          events.add(PowerEvent(
            startUs: t,
            durationUs: rest,
            currentMa: txI,
            label: 'TX',
            color: Colors.red.shade400,
          ));
          t += rest;
        }
      }

      if (peripheral) {
        addRx();
        addSwitch(rxB > 0 ? rxI : chip.tifsCurrent_mA);
        addTx();
        if (i < n - 1) addSwitch(chip.tifsCurrent_mA);
      } else {
        addTx();
        addSwitch(chip.tifsCurrent_mA);
        addRx();
        if (i < n - 1) addSwitch(rxB > 0 ? rxI : chip.tifsCurrent_mA);
      }
    }

    final postExtra = anyRx ? math.max(0, rxProcessUs - maxOverlap) : 0.0;
    events.add(PowerEvent(
      startUs: t,
      durationUs: chip.postProcess_us + postExtra,
      currentMa: chip.postCurrent_mA,
      label: 'Post',
      color: Colors.purple.shade400,
    ));
    t += chip.postProcess_us + postExtra;
    _addTailAndSleep(events, t, periodUs, chip);
    return events;
  }

  // --- Legacy BLE 模型（切换开关关闭时使用，保留原始算法） ---

  static double _legacyTxTimeUs(int payloadBytes, Phy phy) {
    final overheadBytes = 10;
    final totalBytes = payloadBytes + overheadBytes;
    return totalBytes * _usPerByte(phy);
  }

  /// Legacy 广播周期事件（TX/RX）：TX 固定 225.28us、RX 固定 100us、
  /// 每信道 Start radio、间隙取 chip.advGap_us。
  static List<PowerEvent> generateBleAdvertisingTxRxLegacy({
    required BleChip chip,
    required ProfileParams params,
    required double periodUs,
    required double rxCurrentMa,
  }) {
    List<PowerEvent> events = [];
    final txUs = 225.28;
    final rxI = rxCurrentMa > 0 ? rxCurrentMa : chip.rxCurrent_mA;
    final txI = chip.txCurrentForPower(params.txPowerDbm);
    final postUs = chip.postProcess_us;
    final postI = chip.postCurrent_mA;
    final sleepI = chip.sleepCurrent_uA / 1000.0;
    final tifs = chip.tifs_us;
    final finalRxUs = 100.0; // 固定 100us 的 RX 窗口

    double t = 0;

    // 1. Setup
    addSetupPhases(events, t, chip);
    t += getSetupTotalUs(chip);

    // 2. 广播三个信道
    List<String> ch = ['ADV CH37', 'ADV CH38', 'ADV CH39'];
    for (int i = 0; i < 3; i++) {
      events.add(PowerEvent(
        startUs: t,
        durationUs: chip.startRadio_us,
        currentMa: chip.startRadioCurrent_mA,
        label: 'Start radio',
        color: Colors.orange.shade600,
      ));
      t += chip.startRadio_us;
      // TX
      events.add(PowerEvent(
        startUs: t,
        durationUs: txUs,
        currentMa: txI,
        label: '${ch[i]} TX',
        color: Colors.red.shade400,
      ));
      t += txUs;
      // TIFS
      events.add(PowerEvent(
        startUs: t,
        durationUs: tifs,
        currentMa: chip.tifsCurrent_mA,
        label: 'TIFS',
        color: Colors.amber.shade300,
      ));
      t += tifs;

      // RX
      events.add(PowerEvent(
        startUs: t,
        durationUs: finalRxUs,
        currentMa: rxI,
        label: 'RX',
        color: Colors.blue.shade400,
      ));
      t += finalRxUs;
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

  /// Legacy 广播周期事件（仅 TX）。
  static List<PowerEvent> generateBleAdvertisingTxOnlyLegacy({
    required BleChip chip,
    required ProfileParams params,
    required double periodUs,
  }) {
    List<PowerEvent> events = [];
    final txUs = _legacyTxTimeUs(params.payloadBytes, params.phy);
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

  /// Legacy 连接周期事件（peripheral）：固定 RX 窗、无 Start radio/窗扩展。
  static List<PowerEvent> generateBleConnectedPeripheralLegacy({
    required BleChip chip,
    required ProfileParams params,
    required double periodUs,
    required double rxWindowUs,
    required double rxCurrentMa,
  }) {
    return _legacyConnected(
      chip: chip,
      params: params,
      periodUs: periodUs,
      rxWindowUs: rxWindowUs,
      rxCurrentMa: rxCurrentMa,
      txFirst: false,
    );
  }

  /// Legacy 连接周期事件（central）：TX 在前。
  static List<PowerEvent> generateBleConnectedCentralLegacy({
    required BleChip chip,
    required ProfileParams params,
    required double periodUs,
    required double rxWindowUs,
    required double rxCurrentMa,
  }) {
    return _legacyConnected(
      chip: chip,
      params: params,
      periodUs: periodUs,
      rxWindowUs: rxWindowUs,
      rxCurrentMa: rxCurrentMa,
      txFirst: true,
    );
  }

  static List<PowerEvent> _legacyConnected({
    required BleChip chip,
    required ProfileParams params,
    required double periodUs,
    required double rxWindowUs,
    required double rxCurrentMa,
    required bool txFirst,
  }) {
    List<PowerEvent> events = [];
    final rxI = rxCurrentMa > 0 ? rxCurrentMa : chip.rxCurrent_mA;
    final txI = chip.txCurrentForPower(params.txPowerDbm);
    final postUs = chip.postProcess_us;
    final postI = chip.postCurrent_mA;
    final sleepI = chip.sleepCurrent_uA / 1000.0;

    final finalRxUs = rxWindowUs > 0 ? rxWindowUs : chip.rxWindow_us;
    final tifs = chip.tifs_us;
    final txUs = _legacyTxTimeUs(params.payloadBytes, params.phy);

    double t = 0;

    // Setup
    addSetupPhases(events, t, chip);
    t += getSetupTotalUs(chip);

    void addRx() {
      events.add(PowerEvent(
        startUs: t,
        durationUs: finalRxUs,
        currentMa: rxI,
        label: 'RX',
        color: Colors.blue.shade400,
      ));
      t += finalRxUs;
    }

    void addTifs() {
      events.add(PowerEvent(
        startUs: t,
        durationUs: tifs,
        currentMa: chip.tifsCurrent_mA,
        label: 'TIFS',
        color: Colors.amber.shade300,
      ));
      t += tifs;
    }

    void addTx() {
      events.add(PowerEvent(
        startUs: t,
        durationUs: txUs,
        currentMa: txI,
        label: 'TX',
        color: Colors.red.shade400,
      ));
      t += txUs;
    }

    if (txFirst) {
      addTx();
      addTifs();
      addRx();
    } else {
      addRx();
      addTifs();
      addTx();
    }

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

  /// 生成 HDT 模式的事件序列（借鉴 BTState 中的实现）
  static List<PowerEvent> generateHdt({
    required BleChip chip,
    required double periodUs,
    required double txPowerDbm,
    String band = '2.4G',
    int repeats = 1,
    bool moduleSink = true,
    double hdtPhyRateMbps = 15.0,
    int hdtPayloadBytes = 144,
    int hdtPayloadHeaderBytes = 16,
    int hdtCrcBits = 32,
    int hdtMicBits = 64,
    int hdtZeroPaddingBits = 0,
  }) {
    List<PowerEvent> events = [];
    final double intervalUs = periodUs;
    final double halfPeriodUs = intervalUs / 2.0;

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

    double _fixedOverheadAtRate() {
      const double fixedAt15 = 44.0;
      return fixedAt15 * (15.0 / hdtPhyRateMbps);
    }

    double _pduAirtimeUs() {
      final int pduBits = (hdtPayloadBytes + hdtPayloadHeaderBytes) * 8 + hdtCrcBits + hdtMicBits + hdtZeroPaddingBits;
      return pduBits / hdtPhyRateMbps;
    }

    final double computedActive = _fixedOverheadAtRate() + _pduAirtimeUs();
    final double prerfRxUs = 70.0;
    final double postrfRxUs = 3.0;
    final double prerfTxUs = 40.0;
    final double postrfTxUs = 10.0;
    final double activeUs = math.min(computedActive, periodUs);
    final double totalRxActiveus = activeUs + prerfRxUs + postrfRxUs;
    final double totalTxActiveus = activeUs + prerfTxUs + postrfTxUs;
    final double idleRxUs = math.max(0.0, periodUs - totalRxActiveus);
    final double idleTxUs = math.max(0.0, halfPeriodUs - totalTxActiveus);

    for (int i = 0; i < repeats; i++) {
      if (moduleSink) {
        events.add(PowerEvent(startUs: t, durationUs: totalRxActiveus, currentMa: rxI, label: 'HDT RX', color: Colors.blue.shade400));
        t += totalRxActiveus;
        if (idleRxUs > 0.0) {
          events.add(PowerEvent(startUs: t, durationUs: idleRxUs, currentMa: idleCurrent, label: 'Idle', color: Colors.green.shade200));
          t += idleRxUs;
        }
      } else {
        events.add(PowerEvent(startUs: t, durationUs: totalTxActiveus, currentMa: txI, label: 'HDT TX', color: Colors.red.shade400));
        t += totalRxActiveus;
        if (idleTxUs > 0.0) {
          events.add(PowerEvent(startUs: t, durationUs: idleTxUs, currentMa: idleCurrent, label: 'Idle', color: Colors.green.shade200));
          t += idleTxUs;
        }
        events.add(PowerEvent(startUs: t, durationUs: totalTxActiveus, currentMa: txI, label: 'HDT TX', color: Colors.red.shade400));
        t += totalRxActiveus;
        if (idleTxUs > 0.0) {
          events.add(PowerEvent(startUs: t, durationUs: idleTxUs, currentMa: idleCurrent, label: 'Idle', color: Colors.green.shade200));
          t += idleTxUs;
        }
      }
    }

    final remaining = math.max(0.0, intervalUs - t);
    if (remaining > 0) {
      events.add(PowerEvent(startUs: t, durationUs: remaining.toDouble(), currentMa: idleCurrent, label: 'Idle', color: Colors.green.shade200));
    }

    return events;
  }
}
