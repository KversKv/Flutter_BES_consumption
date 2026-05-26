// removed unused import

// ignore_for_file: non_constant_identifier_names

class BleChip {
  final String id;
  final String name;

  // 芯片参数（单位见注释）
  final double vbat; // V
  final double sleepCurrent_uA; // 休眠电流
  final double rxCurrent_mA; // 接收电流
  final double rxCurrent_mA_HDT_2G4;
  final double rxCurrent_mA_HDT_5G;
  // 固定接收窗口（单位：us），现在每个芯片可以配置不同的值
  final double rxWindow_us;
  final double tifs_us; // TIFS，典型 150 us
  // TIFS 期间的电流（mA），各芯片可配置
  final double tifsCurrent_mA;

  // 发射功率档位（dBm -> mA）
  final List<double> _txPowerLevelsDbmFallback;
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
  // 是否支持 HDT 模式
  final bool supportsHDT;
  // Optional per-band TX current maps and RX currents. Key example: '2.4G', '5G'
  final Map<String, Map<double, double>>? txCurrentByBand;
  final Map<String, double>? rxCurrentByBand;

  const BleChip({
    required this.id,
    required this.name,
    required this.vbat,
    required this.sleepCurrent_uA,
    required this.rxCurrent_mA,
    required this.rxCurrent_mA_HDT_2G4,
    required this.rxCurrent_mA_HDT_5G,
    required this.rxWindow_us,
    required this.tifs_us,
    required this.tifsCurrent_mA,
    List<double> txPowerLevelsDbm = const [],
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
    this.supportsHDT = false,
    this.txCurrentByBand,
    this.rxCurrentByBand,
  }) : _txPowerLevelsDbmFallback = txPowerLevelsDbm;

  List<double> get txPowerLevelsDbm {
    final levels = txCurrent_mA_forDbm.keys.toList()..sort();
    if (levels.isNotEmpty) return List<double>.unmodifiable(levels);
    return List<double>.unmodifiable(_txPowerLevelsDbmFallback);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'vbat': vbat,
        'sleepCurrent_uA': sleepCurrent_uA,
        'rxCurrent_mA': rxCurrent_mA,
        'rxCurrent_mA_HDT_2G4': rxCurrent_mA_HDT_2G4,
        'rxCurrent_mA_HDT_5G': rxCurrent_mA_HDT_5G,
        'rxWindow_us': rxWindow_us,
        'tifs_us': tifs_us,
        'tifsCurrent_mA': tifsCurrent_mA,
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
        'hdtIdleCurrent_mA': hdtIdleCurrent_mA,
        'supportsHDT': supportsHDT,
        'txCurrentByBand': txCurrentByBand?.map(
          (band, values) => MapEntry(
            band,
            values.map((k, v) => MapEntry(k.toString(), v)),
          ),
        ),
        'rxCurrentByBand': rxCurrentByBand,
      };

  factory BleChip.fromJson(Map<String, dynamic> j) => BleChip(
        id: (j['id'] as String?) ?? '',
        name: (j['name'] as String?) ?? '',
        vbat: _d(j['vbat']) ?? 0,
        sleepCurrent_uA: _d(j['sleepCurrent_uA']) ?? 0,
        rxCurrent_mA: _d(j['rxCurrent_mA']) ?? 0,
        rxCurrent_mA_HDT_2G4: _d(j['rxCurrent_mA_HDT_2G4']) ?? 0,
        rxCurrent_mA_HDT_5G: _d(j['rxCurrent_mA_HDT_5G']) ?? 0,
        rxWindow_us: _d(j['rxWindow_us']) ?? 0,
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
        hdtIdleCurrent_mA: _d(j['hdtIdleCurrent_mA']) ?? 0,
        supportsHDT: (j['supportsHDT'] as bool?) ?? false,
        txCurrentByBand: _bandMap(j['txCurrentByBand']),
        rxCurrentByBand: _stringDoubleMap(j['rxCurrentByBand']),
      );

  double txCurrentForPower(double txPowerDbm, [String? band]) {
    // If a band-specific map is provided and contains values, prefer it.
    if (band != null &&
        txCurrentByBand != null &&
        txCurrentByBand!.containsKey(band)) {
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

    if (txCurrent_mA_forDbm.isEmpty) return 0;
    if (txCurrent_mA_forDbm.containsKey(txPowerDbm)) {
      return txCurrent_mA_forDbm[txPowerDbm]!;
    }
    double closest = txCurrent_mA_forDbm.keys.first;
    double minDiff = (txPowerDbm - closest).abs();
    for (final level in txCurrent_mA_forDbm.keys) {
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
    final levels = txPowerLevelsDbm;
    if (levels.isEmpty) return txPowerDbm;
    double closest = levels.first;
    double minDiff = (txPowerDbm - closest).abs();
    for (final level in levels) {
      final diff = (txPowerDbm - level).abs();
      if (diff < minDiff) {
        closest = level;
        minDiff = diff;
      }
    }
    return closest;
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
