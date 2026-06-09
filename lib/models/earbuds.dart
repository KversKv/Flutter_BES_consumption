/// 耳机芯片功耗数据模型。
///
/// 设计原则：
/// - 纯数据，无 Flutter 依赖
/// - 所有电流单位统一：mA（毫安）；睡眠/ PowerOff 由于数量级极小仍保留 mA 原值，
///   UI 层在渲染时再换算 µA 并附单位标签
/// - 所有字段可空 `double?` 表示"该芯片此项未测/不适用"，UI 需处理 null
/// - 使用 `const` 构造函数便于生成树形数据，`sealed` 不必要因为扩展性靠组合
library;

/// 睡眠电流（Power-Down / Deep Sleep，单位 µA）
class SleepCurrent {
  final double? vcoreM; // V
  final double? vcoreL; // V
  final double? vana; // V
  final double? vhppa; // V
  final double? pdSleep256; // µA, Power-Down Sleep with 256KB SRAM retention
  final double? pdSleepFull; // µA, Power-Down Sleep with Full SRAM retention
  final double? deepSleep; // µA, Deep Sleep

  const SleepCurrent({
    this.vcoreM,
    this.vcoreL,
    this.vana,
    this.vhppa,
    this.pdSleep256,
    this.pdSleepFull,
    this.deepSleep,
  });

  Map<String, dynamic> toJson() => {
        'vcoreM': vcoreM,
        'vcoreL': vcoreL,
        'vana': vana,
        'vhppa': vhppa,
        'pdSleep256': pdSleep256,
        'pdSleepFull': pdSleepFull,
        'deepSleep': deepSleep,
      };

  factory SleepCurrent.fromJson(Map<String, dynamic> j) => SleepCurrent(
        vcoreM: _d(j['vcoreM']),
        vcoreL: _d(j['vcoreL']),
        vana: _d(j['vana']),
        vhppa: _d(j['vhppa']),
        pdSleep256: _d(j['pdSleep256']),
        pdSleepFull: _d(j['pdSleepFull']),
        deepSleep: _d(j['deepSleep']),
      );
}

/// MCU Run 电流（单位 mA，VSYS=3.8V）
class RunCurrent {
  final String label; // 'default' / 'M55' / 'M33' 等变体名
  final double? wfi24M;
  final double? cm24M;
  final double? cm48M;
  final double? cm96M;
  final double? cm192M;

  const RunCurrent({
    required this.label,
    this.wfi24M,
    this.cm24M,
    this.cm48M,
    this.cm96M,
    this.cm192M,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'wfi24M': wfi24M,
        'cm24M': cm24M,
        'cm48M': cm48M,
        'cm96M': cm96M,
        'cm192M': cm192M,
      };

  factory RunCurrent.fromJson(Map<String, dynamic> j) => RunCurrent(
        label: (j['label'] as String?) ?? '',
        wfi24M: _d(j['wfi24M']),
        cm24M: _d(j['cm24M']),
        cm48M: _d(j['cm48M']),
        cm96M: _d(j['cm96M']),
        cm192M: _d(j['cm192M']),
      );
}

/// 单芯片场景测试配置元信息
class SceneTestConfig {
  final String? testPhone;
  final double? vbat;
  final String? audioEncoder;
  final String? outputLoad;
  final String? audioOutputPower;
  final String? softwareVersion;
  final String? moduleVoltageDetail;

  const SceneTestConfig({
    this.testPhone,
    this.vbat,
    this.audioEncoder,
    this.outputLoad,
    this.audioOutputPower,
    this.softwareVersion,
    this.moduleVoltageDetail,
  });

  Map<String, dynamic> toJson() => {
        'testPhone': testPhone,
        'vbat': vbat,
        'audioEncoder': audioEncoder,
        'outputLoad': outputLoad,
        'audioOutputPower': audioOutputPower,
        'softwareVersion': softwareVersion,
        'moduleVoltageDetail': moduleVoltageDetail,
      };

  factory SceneTestConfig.fromJson(Map<String, dynamic> j) => SceneTestConfig(
        testPhone: j['testPhone'] as String?,
        vbat: _d(j['vbat']),
        audioEncoder: j['audioEncoder'] as String?,
        outputLoad: j['outputLoad'] as String?,
        audioOutputPower: j['audioOutputPower'] as String?,
        softwareVersion: j['softwareVersion'] as String?,
        moduleVoltageDetail: j['moduleVoltageDetail'] as String?,
      );
}

/// NoisePink 8/15 AAC 场景的电压与功耗拆分明细。
///
/// 电压单位：V；电流单位：mA。仅在该场景需要展示细分时填充。
class NoisePinkDetail {
  final double? vsys; // V, 系统电压
  final double? vcore; // V
  final double? vcoreM; // V
  final double? vcoreL; // V
  final double? vana; // V
  final double? vhppa; // V
  final double? isys; // mA, 系统总电流
  final double? icore; // mA
  final double? icoreM; // mA
  final double? icoreL; // mA
  final double? iana; // mA
  final double? ihppa; // mA
  final double? isysRemain; // mA, 系统剩余电流

  const NoisePinkDetail({
    this.vsys,
    this.vcore,
    this.vcoreM,
    this.vcoreL,
    this.vana,
    this.vhppa,
    this.isys,
    this.icore,
    this.icoreM,
    this.icoreL,
    this.iana,
    this.ihppa,
    this.isysRemain,
  });

  Map<String, dynamic> toJson() => {
        'vsys': vsys,
        'vcore': vcore,
        'vcoreM': vcoreM,
        'vcoreL': vcoreL,
        'vana': vana,
        'vhppa': vhppa,
        'isys': isys,
        'icore': icore,
        'icoreM': icoreM,
        'icoreL': icoreL,
        'iana': iana,
        'ihppa': ihppa,
        'isysRemain': isysRemain,
      };

  factory NoisePinkDetail.fromJson(Map<String, dynamic> j) => NoisePinkDetail(
        vsys: _d(j['vsys']),
        vcore: _d(j['vcore']),
        vcoreM: _d(j['vcoreM']),
        vcoreL: _d(j['vcoreL']),
        vana: _d(j['vana']),
        vhppa: _d(j['vhppa']),
        isys: _d(j['isys']),
        icore: _d(j['icore']),
        icoreM: _d(j['icoreM']),
        icoreL: _d(j['icoreL']),
        iana: _d(j['iana']),
        ihppa: _d(j['ihppa']),
        isysRemain: _d(j['isysRemain']),
      );
}

/// Earbuds 真机使用场景电流（mA, VSYS=3.8V）
class EarbudsScene {
  final double? hotelCal;
  final double? mute;
  final double? noisePink;
  final double? k1Hz;
  final double? call;
  final double? standby;
  final double? powerOff;

  final SceneTestConfig? testConfig;

  const EarbudsScene({
    this.hotelCal,
    this.mute,
    this.noisePink,
    this.k1Hz,
    this.call,
    this.standby,
    this.powerOff,
    this.testConfig,
  });

  Map<String, dynamic> toJson() => {
        'hotelCal': hotelCal,
        'mute': mute,
        'noisePink': noisePink,
        'k1Hz': k1Hz,
        'call': call,
        'standby': standby,
        'powerOff': powerOff,
        'testConfig': testConfig?.toJson(),
      };

  factory EarbudsScene.fromJson(Map<String, dynamic> j) => EarbudsScene(
        hotelCal: _d(j['hotelCal']),
        mute: _d(j['mute']),
        noisePink: _d(j['noisePink']),
        k1Hz: _d(j['k1Hz']),
        call: _d(j['call']),
        standby: _d(j['standby']),
        powerOff: _d(j['powerOff']),
        testConfig: j['testConfig'] == null
            ? null
            : SceneTestConfig.fromJson(
                Map<String, dynamic>.from(j['testConfig'] as Map)),
      );
}

/// TX 功率扫描（单个调制 / 配置的曲线）
class TxSweepVariant {
  final String label; // 例如 '3.3 + 1.7' / '2point' / 'polar'
  final Map<int, double> values; // dBm -> mA

  const TxSweepVariant({required this.label, required this.values});

  Map<String, dynamic> toJson() => {
        'label': label,
        'values': values.map((k, v) => MapEntry(k.toString(), v)),
      };

  factory TxSweepVariant.fromJson(Map<String, dynamic> j) => TxSweepVariant(
        label: (j['label'] as String?) ?? '',
        values: _intDoubleMap(j['values']),
      );
}

/// RX 增益扫描
class RxSweep {
  final Map<int, double> values; // gain -> mA
  final double? vana; // 对应 VANA 电压（仅 VANA 域）

  const RxSweep({required this.values, this.vana});

  Map<String, dynamic> toJson() => {
        'values': values.map((k, v) => MapEntry(k.toString(), v)),
        'vana': vana,
      };

  factory RxSweep.fromJson(Map<String, dynamic> j) => RxSweep(
        values: _intDoubleMap(j['values']),
        vana: _d(j['vana']),
      );
}

/// 芯片综合功耗档案。
///
/// 运行期数据从 `assets/data/earbuds_chips.json` 装载（见 `services/earbuds_chip_loader.dart`）。
/// 新增 / 修改芯片请直接编辑该 JSON 文件。
class EarbudsChip {
  final String id; // e.g. '1607'
  final String? process; // e.g. 'SS_N14' / 'tsmc6n'
  final bool massProduction;

  final SleepCurrent sleep;
  final List<RunCurrent> mcuRun;
  final EarbudsScene scene;
  final NoisePinkDetail? noisePinkDetail;
  final List<TxSweepVariant> txSweep;
  final RxSweep? rxVana; // RX Current in VANA 域
  final RxSweep? rxVsys; // RX Current in VSYS=3.8V 域

  const EarbudsChip({
    required this.id,
    this.process,
    required this.massProduction,
    this.sleep = const SleepCurrent(),
    this.mcuRun = const [],
    this.scene = const EarbudsScene(),
    this.noisePinkDetail,
    this.txSweep = const [],
    this.rxVana,
    this.rxVsys,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'process': process,
        'massProduction': massProduction,
        'sleep': sleep.toJson(),
        'mcuRun': _runCurrentMap(mcuRun),
        'scene': scene.toJson(),
        'noisePinkDetail': noisePinkDetail?.toJson(),
        'txSweep': _txSweepMap(txSweep),
        'rxVana': rxVana?.toJson(),
        'rxVsys': rxVsys?.toJson(),
      };

  factory EarbudsChip.fromJson(Map<String, dynamic> j) => EarbudsChip(
        id: (j['id'] as String?) ?? '',
        process: j['process'] as String?,
        massProduction: (j['massProduction'] as bool?) ?? false,
        sleep: j['sleep'] == null
            ? const SleepCurrent()
            : SleepCurrent.fromJson(
                Map<String, dynamic>.from(j['sleep'] as Map)),
        mcuRun: _runCurrentList(j['mcuRun']),
        scene: j['scene'] == null
            ? const EarbudsScene()
            : EarbudsScene.fromJson(
                Map<String, dynamic>.from(j['scene'] as Map)),
        noisePinkDetail: j['noisePinkDetail'] == null
            ? null
            : NoisePinkDetail.fromJson(
                Map<String, dynamic>.from(j['noisePinkDetail'] as Map)),
        txSweep: _txSweepList(j['txSweep']),
        rxVana: j['rxVana'] == null
            ? null
            : RxSweep.fromJson(Map<String, dynamic>.from(j['rxVana'] as Map)),
        rxVsys: j['rxVsys'] == null
            ? null
            : RxSweep.fromJson(Map<String, dynamic>.from(j['rxVsys'] as Map)),
      );
}

double? _d(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

Map<int, double> _intDoubleMap(dynamic v) {
  if (v is! Map) return <int, double>{};
  final out = <int, double>{};
  v.forEach((k, val) {
    final ki = k is int ? k : int.tryParse(k.toString());
    final vd = _d(val);
    if (ki != null && vd != null) out[ki] = vd;
  });
  return out;
}

Map<String, dynamic> _runCurrentMap(List<RunCurrent> values) {
  final out = <String, dynamic>{};
  for (var i = 0; i < values.length; i++) {
    final item = values[i];
    final label = item.label.trim().isEmpty ? 'variant_${i + 1}' : item.label;
    final data = item.toJson()..remove('label');
    out[_uniqueLabel(out, label)] = data;
  }
  return out;
}

List<RunCurrent> _runCurrentList(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((e) => RunCurrent.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
  if (value is Map) {
    final out = <RunCurrent>[];
    value.forEach((label, data) {
      if (data is! Map) return;
      final json = Map<String, dynamic>.from(data);
      json['label'] ??= label.toString();
      out.add(RunCurrent.fromJson(json));
    });
    return out;
  }
  return const [];
}

Map<String, dynamic> _txSweepMap(List<TxSweepVariant> values) {
  final out = <String, dynamic>{};
  for (var i = 0; i < values.length; i++) {
    final item = values[i];
    final label = item.label.trim().isEmpty ? 'variant_${i + 1}' : item.label;
    final data = item.toJson()..remove('label');
    out[_uniqueLabel(out, label)] = data;
  }
  return out;
}

List<TxSweepVariant> _txSweepList(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((e) => TxSweepVariant.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
  if (value is Map) {
    final out = <TxSweepVariant>[];
    value.forEach((label, data) {
      if (data is! Map) return;
      final json = Map<String, dynamic>.from(data);
      json['label'] ??= label.toString();
      out.add(TxSweepVariant.fromJson(json));
    });
    return out;
  }
  return const [];
}

String _uniqueLabel(Map<String, dynamic> existing, String label) {
  if (!existing.containsKey(label)) return label;
  var i = 2;
  while (existing.containsKey('${label}_$i')) {
    i++;
  }
  return '${label}_$i';
}
