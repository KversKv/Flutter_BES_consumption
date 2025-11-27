// removed unused import

// ignore_for_file: non_constant_identifier_names

class BleChip {
  final String id;
  final String name;

  // 芯片参数（单位见注释）
  final double vbat; // V
  final double sleepCurrent_uA; // 休眠电流
  final double rxCurrent_mA; // 接收电流
  // 固定接收窗口（单位：us），现在每个芯片可以配置不同的值
  final double rxWindow_us;
  final double tifs_us; // TIFS，典型 150 us
  // TIFS 期间的电流（mA），各芯片可配置
  final double tifsCurrent_mA;

  // 发射功率档位（dBm -> mA）
  final List<double> txPowerLevelsDbm; // 可选的功率档位
  final Map<double, double> txCurrent_mA_forDbm; // 对应档位的发射电流

  // TX 结束后的后处理时长与电流
  final double postProcess_us;
  final double postCurrent_mA;

  // Setup 拆分阶段（时长 + 电流）
  final double preProcess_us;
  final double preProcessCurrent_mA;

  final double crystalRampUp_us;
  final double crystalRampUpCurrent_mA;

  final double standby_us;
  final double standbyCurrent_mA;

  final double startRadio_us;
  final double startRadioCurrent_mA;

  // BLE 广播通道间固定间隙（仅用于 CH37->CH38、CH38->CH39）
  final double advGap_us;
  final double advGapCurrent_mA;
  // 芯片简短描述（用于 UI 展示）
  final String description;
  // HDT 模式下的 IDLE 电流（mA），由芯片厂商给定
  final double hdtIdleCurrent_mA;
  // Optional per-band TX current maps and RX currents. Key example: '2.4G', '5G'
  final Map<String, Map<double, double>>? txCurrentByBand;
  final Map<String, double>? rxCurrentByBand;

  const BleChip({
    required this.id,
    required this.name,
    required this.vbat,
    required this.sleepCurrent_uA,
    required this.rxCurrent_mA,
    required this.rxWindow_us,
  required this.tifs_us,
  required this.tifsCurrent_mA,
    required this.txPowerLevelsDbm,
    required this.txCurrent_mA_forDbm,
    required this.postProcess_us,
    required this.postCurrent_mA,
    required this.preProcess_us,
    required this.preProcessCurrent_mA,
    required this.crystalRampUp_us,
    required this.crystalRampUpCurrent_mA,
    required this.standby_us,
    required this.standbyCurrent_mA,
    required this.startRadio_us,
    required this.startRadioCurrent_mA,
    required this.advGap_us,
    required this.advGapCurrent_mA,
    required this.description,
    required this.hdtIdleCurrent_mA,
    this.txCurrentByBand,
    this.rxCurrentByBand,
  });

  double txCurrentForPower(double txPowerDbm, [String? band]) {
    // If a band-specific map is provided and contains values, prefer it.
    if (band != null && txCurrentByBand != null && txCurrentByBand!.containsKey(band)) {
      final map = txCurrentByBand![band]!;
      if (map.containsKey(txPowerDbm)) return map[txPowerDbm]!;
      // fallback to closest key in band map
      double closest = map.keys.first;
      double minDiff = (txPowerDbm - closest).abs();
      for (final level in map.keys) {
        final diff = (txPowerDbm - level).abs();
        if (diff < minDiff) {
          closest = level;
          minDiff = diff;
        }
      }
      return map[closest]!;
    }

    if (txCurrent_mA_forDbm.containsKey(txPowerDbm)) {
      return txCurrent_mA_forDbm[txPowerDbm]!;
    }
    double closest = txPowerLevelsDbm.first;
    double minDiff = (txPowerDbm - closest).abs();
    for (final level in txPowerLevelsDbm) {
      final diff = (txPowerDbm - level).abs();
      if (diff < minDiff) {
        closest = level;
        minDiff = diff;
      }
    }
    return txCurrent_mA_forDbm[closest]!;
  }

  double rxCurrentForBand([String? band]) {
    if (band != null && rxCurrentByBand != null && rxCurrentByBand!.containsKey(band)) {
      return rxCurrentByBand![band]!;
    }
    return rxCurrent_mA;
  }

  double snapTxPower(double txPowerDbm) {
    double closest = txPowerLevelsDbm.first;
    double minDiff = (txPowerDbm - closest).abs();
    for (final level in txPowerLevelsDbm) {
      final diff = (txPowerDbm - level).abs();
      if (diff < minDiff) {
        closest = level;
        minDiff = diff;
      }
    }
    return closest;
  }
}
