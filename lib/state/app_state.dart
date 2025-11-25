// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/ble_chip.dart';
import '../models/power_event.dart';
import '../models/profile_params.dart';

class AppState extends ChangeNotifier {
  final List<BleChip> chips = [

    BleChip(
      id: 'BES2720YP',
      name: 'BES2720YP',
      vbat: 3.8,
      sleepCurrent_uA: 116.5,
      rxCurrent_mA: 5.11,
      rxWindow_us: 184.32,
      tifs_us: 150,
      tifsCurrent_mA: 2.953,
      txPowerLevelsDbm: [
        -10, -9, -8, -7, -6, -5, -4, -3, -2, -1,
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
        10, 11, 12, 13, 14, 15
      ],
      txCurrent_mA_forDbm: {
        -10: 15.0,
        -9: 15.0,
        -8: 15.0,
        -7: 16.0,
        -6: 17.0,
        -5: 18.0,
        -4: 19.0,
        -3: 20.0,
        -2: 22.0,
        -1: 22.0,
        0: 18.282,
        1: 24.0,
        2: 25.0,
        3: 26.0,
        4: 27.0,
        5: 28.0,
        6: 29.0,
        7: 31.0,
        8: 32.0,
        9: 35.0,
        10: 33.0,
        11: 37.0,
        12: 41.0,
        13: 45.0,
        14: 49.0,
        15: 54.0,
      },
      // Setup拆分（总计约 2744us）
      preProcess_us: 143.36,
      preProcessCurrent_mA: 2.053,
      crystalRampUp_us: 819.2,
      crystalRampUpCurrent_mA: 0.59,
      standby_us: 1188.0,
      standbyCurrent_mA: 1.280,
      startRadio_us: 122.88,
      startRadioCurrent_mA: 1.987,
      postProcess_us: 471.04,
      postCurrent_mA: 1.554,
      // 广播通道间固定 ADV GAP（示例：5ms，电流取近似低功耗）
      advGap_us: 100.0,
      advGapCurrent_mA: 1.5, // 1.5mA
      description: 'BES2720YP: high performance SOC for BT&BLE.',
    ),
    
    BleChip(
      id: 'BES2713B',
      name: 'BES2713B',
      vbat: 3,
      sleepCurrent_uA: 3.5,
      rxCurrent_mA: 5.2,
      rxWindow_us: 120.0,
      tifs_us: 150,
      tifsCurrent_mA: 2.55,
      txPowerLevelsDbm: [
        0, 8
      ],
      txCurrent_mA_forDbm: {
        0: 5.1,
        8: 12.03,
      },
      postProcess_us: 590.0,
      postCurrent_mA: 1.03,
      // Setup拆分（总计约 2744us）
      preProcess_us: 286.72,
      preProcessCurrent_mA: 2.02,
      crystalRampUp_us: 635.0,
      crystalRampUpCurrent_mA: 0.78,
      standby_us: 1229.0,
      standbyCurrent_mA: 2.726,
      startRadio_us: 82.92,
      startRadioCurrent_mA: 2.17,
      // 广播通道间固定 ADV GAP（示例：5ms，电流取近似低功耗）
      advGap_us: 100.0,
      advGapCurrent_mA: 2.55, // 1.5mA
      description: 'BES2713B: low-power BLE transceiver, demo parameters.',
    ),

    BleChip(
      id: 'BES6100HP_SIMU',
      name: 'BES6100HP_SIMU',
      vbat: 3.8,
      sleepCurrent_uA: 70.0,
      rxCurrent_mA: 5.5,
      rxWindow_us: 120.0,
      tifs_us: 150,
      tifsCurrent_mA: 1.5,
      txPowerLevelsDbm: [
        0, 8
      ],
      txCurrent_mA_forDbm: {
        0: 9,
        8: 25,
      },
      postProcess_us: 590.0,
      postCurrent_mA: 1.03,
      // Setup拆分（总计约 2744us）
      preProcess_us: 30.0,
      preProcessCurrent_mA: 3.0,
      crystalRampUp_us: 500.0,
      crystalRampUpCurrent_mA: 0.6,
      standby_us: 1400.0,
      standbyCurrent_mA: 1.6,
      startRadio_us: 344.0,
      startRadioCurrent_mA: 1.6,
      // 广播通道间固定 ADV GAP（示例：5ms，电流取近似低功耗）
      advGap_us: 100.0,
      advGapCurrent_mA: 1.5, // 1.5mA
      description: 'BES6100HP_SIMU: low-power BLE transceiver, SIMU parameters.',
    ),

    BleChip(
      id: 'BES2720IMP',
      name: 'BES2720IMP',
      vbat: 3.8,
      sleepCurrent_uA: 25.0,
      rxCurrent_mA: 9.0,
      rxWindow_us: 300.0,
      tifs_us: 150,
      tifsCurrent_mA: 1.5,
      txPowerLevelsDbm: [
        -10, -9, -8, -7, -6, -5, -4, -3, -2, -1,
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
        10, 11, 12, 13, 14, 15
      ],
      txCurrent_mA_forDbm: {
        -10: 15.0,
        -9: 15.0,
        -8: 15.0,
        -7: 16.0,
        -6: 17.0,
        -5: 18.0,
        -4: 19.0,
        -3: 20.0,
        -2: 22.0,
        -1: 22.0,
        0: 23.0,
        1: 24.0,
        2: 25.0,
        3: 26.0,
        4: 27.0,
        5: 28.0,
        6: 29.0,
        7: 31.0,
        8: 32.0,
        9: 35.0,
        10: 33.0,
        11: 37.0,
        12: 41.0,
        13: 45.0,
        14: 49.0,
        15: 54.0,
      },
      postProcess_us: 1000.0,
      postCurrent_mA: 1.05,
      // Setup拆分（总计约 2744us）
      preProcess_us: 50.0,
      preProcessCurrent_mA: 5.0,
      crystalRampUp_us: 1200.0,
      crystalRampUpCurrent_mA: 0.65,
      standby_us: 1250.0,
      standbyCurrent_mA: 1,
      startRadio_us: 344.0,
      startRadioCurrent_mA: 1.05,
      // 广播通道间固定 ADV GAP（示例：5ms，电流取近似低功耗）
      advGap_us: 100.0,
      advGapCurrent_mA: 1.5, // 1.5mA
      description: 'BES2720IMP: low-power BLE transceiver, demo parameters.',
    ),

    BleChip(
      id: 'BES2700IMP',
      name: 'BES2700IMP',
      vbat: 3.8,
      sleepCurrent_uA: 18.2,
      rxCurrent_mA: 5.3,
      rxWindow_us: 200.0,
      txPowerLevelsDbm: [
        -10, -9, -8, -7, -6, -5, -4, -3, -2, -1,
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
        10, 11, 12, 13, 14, 15
      ],
      txCurrent_mA_forDbm: {
        -10: 5.0,
        -9:  5.0,
        -8: 5.0,
        -7: 6.0,
        -6: 7.0,
        -5: 8.0,
        -4: 9.0,
        -3: 10.0,
        -2: 11.0,
        -1: 12.0,
        0: 13.0,
        1: 14.0,
        2: 15.0,
        3: 16.0,
        4: 17.0,
        5: 18.0,
        6: 19.0,
        7: 31.0,
        8: 32.0,
        9: 35.0,
        10: 33.0,
        11: 37.0,
        12: 41.0,
        13: 45.0,
        14: 49.0,
        15: 54.0,
      },

        // Setup拆分（总计约 2744us）
        preProcess_us: 174.1,
        preProcessCurrent_mA: 1.233,
        crystalRampUp_us: 1403.0,
        crystalRampUpCurrent_mA: 0.35,
        standby_us: 1618.0,
        standbyCurrent_mA: 0.723,
        startRadio_us: 205.0,
        startRadioCurrent_mA: 0.98,
        tifs_us: 150.0,
        tifsCurrent_mA: 2.004,
        // 广播通道间固定 ADV GAP（示例：5ms，电流取近似低功耗）
        advGap_us: 150.0,
        advGapCurrent_mA: 2.004, // 2.004mA
        postProcess_us: 900.0,
        postCurrent_mA: 0.7,
        description: 'BES2700IMP: 1503 : The most outstanding low-power chip to date from BES.',
      ),



    BleChip(
      id: 'BES2610WD',
      name: 'BES2610WD',
      vbat: 3.8,
      txPowerLevelsDbm: [
        -4, -3, -2, -1,
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
        10, 11, 12
      ],
      txCurrent_mA_forDbm: {
        -4: 13.2,
        -3: 13.4,
        -2: 13.7,
        -1: 13.8,
        0: 14.2,
        1: 14.6,
        2: 15.3,
        3: 15.9,
        4: 16.2,
        5: 16.7,
        6: 17.5,
        7: 18.0,
        8: 24.0,
        9: 25.0,
        10: 27.0,
        11: 29.0,
        12: 30.0,
      },

      sleepCurrent_uA: 27.5,
      // Setup拆分（总计约 2744us）
      preProcess_us: 10.0,
      preProcessCurrent_mA: 5.0,
      crystalRampUp_us: 600.0,
      crystalRampUpCurrent_mA: 0.65,
      standby_us: 1038,
      standbyCurrent_mA: 1.591,
      startRadio_us: 100.0,
      startRadioCurrent_mA: 1.591,
      rxCurrent_mA: 5.834,
      rxWindow_us: 300.0,
      tifs_us: 150,
      tifsCurrent_mA: 1.591,
      // 广播通道间固定 ADV GAP（示例：5ms，电流取近似低功耗）
      advGap_us: 5000.0,
      advGapCurrent_mA: 0.025, // 25 µA
      
      postProcess_us: 512.0,
      postCurrent_mA: 1.29,
      description: 'BES2610WD: compact BLE SoC, balanced RX/TX currents.',

    ),

    BleChip(
      id: 'BES2720BP',
      name: 'BES2720BP',
      vbat: 3.8,
      sleepCurrent_uA: 40.0,
      rxCurrent_mA: 8.0,
      rxWindow_us: 300.0,
      tifs_us: 150,
      tifsCurrent_mA: 0.2 * 8.0,
      txPowerLevelsDbm: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
        10, 11, 12, 13, 14],
      txCurrent_mA_forDbm: {    
        14: 40.0,
        13: 35.0,
        12: 31.0,
        11: 27.0,
        10: 24.0,
        9:  21.0,
        8:  18.7,
        7:  17.6,
        6:  16.5,
        5:  15.8,
        4:  11.0,
        3:  10.7,
        2:  10.5,
        1:  10.3,
        0:  10.1,
      },
      postProcess_us: 1000.0,
      postCurrent_mA: 4.0,
      // Setup拆分（总计约 130us）
      preProcess_us: 20.0,
      preProcessCurrent_mA: 8.0,
      crystalRampUp_us: 60.0,
      crystalRampUpCurrent_mA: 8.5,
      standby_us: 30.0,
      standbyCurrent_mA: 7.0,
      startRadio_us: 20.0,
      startRadioCurrent_mA: 9.0,
      advGap_us: 5000.0,
      advGapCurrent_mA: 0.040, // 40 µA
      description: 'BES_2800BP: low-power BLE chip, example parameters.',
    ),


    BleChip(
      id: 'BES2800BP',
      name: 'BES2800BP',
      vbat: 3.8,
      sleepCurrent_uA: 40.0,
      rxCurrent_mA: 8.0,
      rxWindow_us: 300.0,
  tifs_us: 150,
  tifsCurrent_mA: 0.2 * 8.0,
      txPowerLevelsDbm: [-20, -12, -8, -4, 0, 4, 8],
      txCurrent_mA_forDbm: {
        -20: 3.0,
        -12: 3.8,
        -8: 4.2,
        -4: 4.8,
        0: 5.3,
        4: 7.0,
        8: 9.0,
      },
      postProcess_us: 1000.0,
      postCurrent_mA: 4.0,
      // Setup拆分（总计约 130us）
      preProcess_us: 20.0,
      preProcessCurrent_mA: 8.0,
      crystalRampUp_us: 60.0,
      crystalRampUpCurrent_mA: 8.5,
      standby_us: 30.0,
      standbyCurrent_mA: 7.0,
      startRadio_us: 20.0,
      startRadioCurrent_mA: 9.0,
      advGap_us: 5000.0,
      advGapCurrent_mA: 0.040, // 40 µA
      description: 'BES_2800BP: low-power BLE chip, example parameters.',
    ),
    BleChip(
      id: 'nrf52832',
      name: 'nRF52832 (demo)',
      vbat: 3.0,
      sleepCurrent_uA: 1.8,
      rxCurrent_mA: 5.5,
      rxWindow_us: 300.0,
  tifs_us: 150,
  tifsCurrent_mA: 0.2 * 5.5,
      txPowerLevelsDbm: [-20, -16, -12, -8, -4, 0, 4],
      txCurrent_mA_forDbm: {
        -20: 3.4,
        -16: 3.6,
        -12: 3.9,
        -8: 4.2,
        -4: 4.8,
        0: 5.3,
        4: 7.5,
      },
      postProcess_us: 1000.0,
      postCurrent_mA: 3.0,
      // Setup拆分（总计约 130us）
      preProcess_us: 20.0,
      preProcessCurrent_mA: 5.5,
      crystalRampUp_us: 60.0,
      crystalRampUpCurrent_mA: 6.0,
      standby_us: 30.0,
      standbyCurrent_mA: 4.5,
      startRadio_us: 20.0,
      startRadioCurrent_mA: 6.5,
      advGap_us: 5000.0,
      advGapCurrent_mA: 0.0018, // 1.8 µA
      description: 'nRF52832: Nordic demo profile, for comparison.',
    ),
    BleChip(
      id: 'bes2600',
      name: 'BES2600 (demo)',
      vbat: 3.0,
      sleepCurrent_uA: 2.0,
      rxCurrent_mA: 6.0,
      rxWindow_us: 300.0,
      tifs_us: 150,
      tifsCurrent_mA: 0.2 * 6.0,
      txPowerLevelsDbm: [-20, -12, -8, -4, 0, 4, 8],
      txCurrent_mA_forDbm: {
        -20: 3.2,
        -12: 3.9,
        -8: 4.5,
        -4: 5.2,
        0: 5.8,
        4: 7.4,
        8: 9.2,
      },
      postProcess_us: 1000.0,
      postCurrent_mA: 3.2,
      // Setup拆分（总计约 150us）
      preProcess_us: 20.0,
      preProcessCurrent_mA: 6.0,
      crystalRampUp_us: 70.0,
      crystalRampUpCurrent_mA: 6.5,
      standby_us: 40.0,
      standbyCurrent_mA: 5.0,
      startRadio_us: 20.0,
      startRadioCurrent_mA: 7.0,
      advGap_us: 5000.0,
      advGapCurrent_mA: 0.0020, // 2.0 µA
      description: 'BES2600: demo parameters for power analysis.',
    ),
  ];

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
