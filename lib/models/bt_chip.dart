// ignore_for_file: non_constant_identifier_names

class BtChip {
  final String id;
  final String name;

  // 芯片参数（单位见注释）
  final double vbat; // V
  final double sleepCurrent_uA; // 休眠电流
  final double rxCurrent_mA; // 接收电流
  final double? rxCurrent_mA_HDT_2G4;
  final double? rxCurrent_mA_HDT_5G;
  final double rxExtWindow_us;
  final double Rmin_us;
  final double AttemptWaitTimeUS;
  final double clockDriftPpm;
  final BtDefaultConfig? defaultConfig;
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

  // 广播通道间固定间隙
  final double advGap_us;
  final double advGapCurrent_mA;
  final String description;
  // Optional per-band TX current maps and RX currents. Key example: '2.4G', '5G'
  final Map<String, Map<double, double>>? txCurrentByBand;
  final Map<String, double>? rxCurrentByBand;

  const BtChip({
    required this.id,
    required this.name,
    required this.vbat,
    required this.sleepCurrent_uA,
    required this.rxCurrent_mA,
    this.rxExtWindow_us = 780.0,
    this.Rmin_us = 88.0,
    this.AttemptWaitTimeUS = 450.0,
    this.clockDriftPpm = 50.0,
    this.defaultConfig,
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
    this.rxCurrent_mA_HDT_2G4,
    this.rxCurrent_mA_HDT_5G,
    this.txCurrentByBand,
    this.rxCurrentByBand,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'vbat': vbat,
        'sleepCurrent_uA': sleepCurrent_uA,
        'rxCurrent_mA': rxCurrent_mA,
        'rxCurrent_mA_HDT_2G4': rxCurrent_mA_HDT_2G4,
        'rxCurrent_mA_HDT_5G': rxCurrent_mA_HDT_5G,
        'rxExtWindow_us': rxExtWindow_us,
        'Rmin_us': Rmin_us,
        'AttemptWaitTimeUS': AttemptWaitTimeUS,
        'clockDriftPpm': clockDriftPpm,
        'defaultConfig': effectiveDefaultConfig.toJson(),
        'tifs_us': tifs_us,
        'tifsCurrent_mA': tifsCurrent_mA,
        'txPowerLevelsDbm': txPowerLevelsDbm,
        'txCurrent_mA_forDbm':
            txCurrent_mA_forDbm.map((k, v) => MapEntry(k.toString(), v)),
        'postProcess_us': postProcess_us,
        'postCurrent_mA': postCurrent_mA,
        'preProcess_us': preProcess_us,
        'preProcessCurrent_mA': preProcessCurrent_mA,
        'crystalRampUp_us': crystalRampUp_us,
        'crystalRampUpCurrent_mA': crystalRampUpCurrent_mA,
        'standby_us': standby_us,
        'standbyCurrent_mA': standbyCurrent_mA,
        'startRadio_us': startRadio_us,
        'startRadioCurrent_mA': startRadioCurrent_mA,
        'advGap_us': advGap_us,
        'advGapCurrent_mA': advGapCurrent_mA,
        'description': description,
        'txCurrentByBand': txCurrentByBand?.map(
          (band, values) => MapEntry(
            band,
            values.map((k, v) => MapEntry(k.toString(), v)),
          ),
        ),
        'rxCurrentByBand': rxCurrentByBand,
      };

  factory BtChip.fromJson(Map<String, dynamic> j) => BtChip(
        id: (j['id'] as String?) ?? '',
        name: (j['name'] as String?) ?? '',
        vbat: _d(j['vbat']) ?? 0,
        sleepCurrent_uA: _d(j['sleepCurrent_uA']) ?? 0,
        rxCurrent_mA: _d(j['rxCurrent_mA']) ?? 0,
        rxCurrent_mA_HDT_2G4: _d(j['rxCurrent_mA_HDT_2G4']),
        rxCurrent_mA_HDT_5G: _d(j['rxCurrent_mA_HDT_5G']),
        rxExtWindow_us: _d(j['rxExtWindow_us']) ?? 780.0,
        Rmin_us: _d(j['Rmin_us']) ?? 88.0,
        AttemptWaitTimeUS: _d(j['AttemptWaitTimeUS']) ?? 450.0,
        clockDriftPpm: _d(j['clockDriftPpm']) ?? 50.0,
        defaultConfig: BtDefaultConfig.fromJson(j['defaultConfig']),
        tifs_us: _d(j['tifs_us']) ?? 0,
        tifsCurrent_mA: _d(j['tifsCurrent_mA']) ?? 0,
        txPowerLevelsDbm: _doubleList(j['txPowerLevelsDbm']),
        txCurrent_mA_forDbm: _doubleDoubleMap(j['txCurrent_mA_forDbm']),
        postProcess_us: _d(j['postProcess_us']) ?? 0,
        postCurrent_mA: _d(j['postCurrent_mA']) ?? 0,
        preProcess_us: _d(j['preProcess_us']) ?? 0,
        preProcessCurrent_mA: _d(j['preProcessCurrent_mA']) ?? 0,
        crystalRampUp_us: _d(j['crystalRampUp_us']) ?? 0,
        crystalRampUpCurrent_mA: _d(j['crystalRampUpCurrent_mA']) ?? 0,
        standby_us: _d(j['standby_us']) ?? 0,
        standbyCurrent_mA: _d(j['standbyCurrent_mA']) ?? 0,
        startRadio_us: _d(j['startRadio_us']) ?? 0,
        startRadioCurrent_mA: _d(j['startRadioCurrent_mA']) ?? 0,
        advGap_us: _d(j['advGap_us']) ?? 0,
        advGapCurrent_mA: _d(j['advGapCurrent_mA']) ?? 0,
        description: (j['description'] as String?) ?? '',
        txCurrentByBand: _bandMap(j['txCurrentByBand']),
        rxCurrentByBand: _stringDoubleMap(j['rxCurrentByBand']),
      );

  BtDefaultConfig get effectiveDefaultConfig =>
      defaultConfig ??
      BtDefaultConfig(
        attempt: 1,
        preProcessLength_us: preProcess_us,
        crystalRampUpLength_us: crystalRampUp_us,
        standbyLength_us: standby_us,
        windowWideningLength_us: 25.0,
        mainRxLength_us: rxExtWindow_us + Rmin_us,
        tifsLength_us: tifs_us,
        txLength_us: Rmin_us,
        postProcessLength_us: postProcess_us,
      );

  double txCurrentForPower(double txPowerDbm, [String? band]) {
    if (band != null &&
        txCurrentByBand != null &&
        txCurrentByBand!.containsKey(band)) {
      final map = txCurrentByBand![band]!;
      if (map.containsKey(txPowerDbm)) return map[txPowerDbm]!;
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
    if (band != null &&
        rxCurrentByBand != null &&
        rxCurrentByBand!.containsKey(band)) {
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

class BtDefaultConfig {
  final int attempt;
  final double preProcessLength_us;
  final double crystalRampUpLength_us;
  final double standbyLength_us;
  final double windowWideningLength_us;
  final double mainRxLength_us;
  final double tifsLength_us;
  final double txLength_us;
  final double postProcessLength_us;

  const BtDefaultConfig({
    this.attempt = 1,
    required this.preProcessLength_us,
    required this.crystalRampUpLength_us,
    required this.standbyLength_us,
    required this.windowWideningLength_us,
    required this.mainRxLength_us,
    required this.tifsLength_us,
    required this.txLength_us,
    required this.postProcessLength_us,
  });

  Map<String, dynamic> toJson() => {
        'attempt': attempt,
        'preProcessLength_us': preProcessLength_us,
        'crystalRampUpLength_us': crystalRampUpLength_us,
        'standbyLength_us': standbyLength_us,
        'windowWideningLength_us': windowWideningLength_us,
        'mainRxLength_us': mainRxLength_us,
        'tifsLength_us': tifsLength_us,
        'txLength_us': txLength_us,
        'postProcessLength_us': postProcessLength_us,
      };

  static BtDefaultConfig? fromJson(dynamic value) {
    if (value is! Map) return null;
    return BtDefaultConfig(
      attempt: (_d(value['attempt']) ?? 1).round(),
      preProcessLength_us: _d(value['preProcessLength_us']) ?? 0,
      crystalRampUpLength_us: _d(value['crystalRampUpLength_us']) ?? 0,
      standbyLength_us: _d(value['standbyLength_us']) ?? 0,
      windowWideningLength_us: _d(value['windowWideningLength_us']) ?? 0,
      mainRxLength_us: _d(value['mainRxLength_us']) ?? 0,
      tifsLength_us: _d(value['tifsLength_us']) ?? 0,
      txLength_us: _d(value['txLength_us']) ?? 0,
      postProcessLength_us: _d(value['postProcessLength_us']) ?? 0,
    );
  }
}

double? _d(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

List<double> _doubleList(dynamic v) {
  if (v is! List) return const [];
  return v.map(_d).whereType<double>().toList(growable: false);
}

Map<double, double> _doubleDoubleMap(dynamic v) {
  if (v is! Map) return <double, double>{};
  final out = <double, double>{};
  v.forEach((k, val) {
    final key = _d(k);
    final value = _d(val);
    if (key != null && value != null) out[key] = value;
  });
  return out;
}

Map<String, double>? _stringDoubleMap(dynamic v) {
  if (v is! Map) return null;
  final out = <String, double>{};
  v.forEach((k, val) {
    final value = _d(val);
    if (value != null) out[k.toString()] = value;
  });
  return out.isEmpty ? null : out;
}

Map<String, Map<double, double>>? _bandMap(dynamic v) {
  if (v is! Map) return null;
  final out = <String, Map<double, double>>{};
  v.forEach((band, values) {
    final mapped = _doubleDoubleMap(values);
    if (mapped.isNotEmpty) out[band.toString()] = mapped;
  });
  return out.isEmpty ? null : out;
}
