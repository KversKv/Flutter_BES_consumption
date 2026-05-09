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
  final String? testDate;
  final double? vbat;
  final String? audioEncoder;
  final String? outputLoad;
  final String? audioOutputPower;
  final String? softwareVersion;
  final String? moduleVoltageDetail;

  const SceneTestConfig({
    this.testPhone,
    this.testDate,
    this.vbat,
    this.audioEncoder,
    this.outputLoad,
    this.audioOutputPower,
    this.softwareVersion,
    this.moduleVoltageDetail,
  });

  Map<String, dynamic> toJson() => {
        'testPhone': testPhone,
        'testDate': testDate,
        'vbat': vbat,
        'audioEncoder': audioEncoder,
        'outputLoad': outputLoad,
        'audioOutputPower': audioOutputPower,
        'softwareVersion': softwareVersion,
        'moduleVoltageDetail': moduleVoltageDetail,
      };

  factory SceneTestConfig.fromJson(Map<String, dynamic> j) => SceneTestConfig(
        testPhone: j['testPhone'] as String?,
        testDate: j['testDate'] as String?,
        vbat: _d(j['vbat']),
        audioEncoder: j['audioEncoder'] as String?,
        outputLoad: j['outputLoad'] as String?,
        audioOutputPower: j['audioOutputPower'] as String?,
        softwareVersion: j['softwareVersion'] as String?,
        moduleVoltageDetail: j['moduleVoltageDetail'] as String?,
      );
}

/// Earbuds 真机使用场景电流（mA, VSYS=3.8V）
class EarbudsScene {
  final double? hotelCal;
  final double? mute;
  final double? noisePink;
  final double? k1Hz;
  final double? call;
  final double? sniffPage;
  final double? powerOff;

  final double? hotelCalAncOn;
  final double? muteAncOn;
  final double? noisePinkAncOn;
  final double? k1HzAncOn;
  final double? callAncOn;
  final double? sniffPageAncOn;
  final double? powerOffAncOn;

  final SceneTestConfig? testConfig;

  const EarbudsScene({
    this.hotelCal,
    this.mute,
    this.noisePink,
    this.k1Hz,
    this.call,
    this.sniffPage,
    this.powerOff,
    this.hotelCalAncOn,
    this.muteAncOn,
    this.noisePinkAncOn,
    this.k1HzAncOn,
    this.callAncOn,
    this.sniffPageAncOn,
    this.powerOffAncOn,
    this.testConfig,
  });

  Map<String, dynamic> toJson() => {
        'hotelCal': hotelCal,
        'mute': mute,
        'noisePink': noisePink,
        'k1Hz': k1Hz,
        'call': call,
        'sniffPage': sniffPage,
        'powerOff': powerOff,
        'hotelCalAncOn': hotelCalAncOn,
        'muteAncOn': muteAncOn,
        'noisePinkAncOn': noisePinkAncOn,
        'k1HzAncOn': k1HzAncOn,
        'callAncOn': callAncOn,
        'sniffPageAncOn': sniffPageAncOn,
        'powerOffAncOn': powerOffAncOn,
        'testConfig': testConfig?.toJson(),
      };

  factory EarbudsScene.fromJson(Map<String, dynamic> j) => EarbudsScene(
        hotelCal: _d(j['hotelCal']),
        mute: _d(j['mute']),
        noisePink: _d(j['noisePink']),
        k1Hz: _d(j['k1Hz']),
        call: _d(j['call']),
        sniffPage: _d(j['sniffPage']),
        powerOff: _d(j['powerOff']),
        hotelCalAncOn: _d(j['hotelCalAncOn']),
        muteAncOn: _d(j['muteAncOn']),
        noisePinkAncOn: _d(j['noisePinkAncOn']),
        k1HzAncOn: _d(j['k1HzAncOn']),
        callAncOn: _d(j['callAncOn']),
        sniffPageAncOn: _d(j['sniffPageAncOn']),
        powerOffAncOn: _d(j['powerOffAncOn']),
        testConfig: j['testConfig'] == null
            ? null
            : SceneTestConfig.fromJson(
                Map<String, dynamic>.from(j['testConfig'] as Map)),
      );
}

/// BT & BLE 场景电流（mA）
class BtScene {
  final double? btBase; // BT Base Current
  final double? bleAdv500_9; // BLE ADV 500ms 9dBm
  final double? bleConn200_0; // BLE Connect 200ms 0dBm
  final double? bleConn500_0; // BLE Connect 500ms 0dBm
  final double? btPagescan9; // BT Pagescan 1.28s 9dBm
  final double? btSniff200_0; // BT Sniff 200ms 0dBm
  final double? btSniff500_0; // BT Sniff 500ms 0dBm

  const BtScene({
    this.btBase,
    this.bleAdv500_9,
    this.bleConn200_0,
    this.bleConn500_0,
    this.btPagescan9,
    this.btSniff200_0,
    this.btSniff500_0,
  });

  Map<String, dynamic> toJson() => {
        'btBase': btBase,
        'bleAdv500_9': bleAdv500_9,
        'bleConn200_0': bleConn200_0,
        'bleConn500_0': bleConn500_0,
        'btPagescan9': btPagescan9,
        'btSniff200_0': btSniff200_0,
        'btSniff500_0': btSniff500_0,
      };

  factory BtScene.fromJson(Map<String, dynamic> j) => BtScene(
        btBase: _d(j['btBase']),
        bleAdv500_9: _d(j['bleAdv500_9']),
        bleConn200_0: _d(j['bleConn200_0']),
        bleConn500_0: _d(j['bleConn500_0']),
        btPagescan9: _d(j['btPagescan9']),
        btSniff200_0: _d(j['btSniff200_0']),
        btSniff500_0: _d(j['btSniff500_0']),
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

/// Audio PA 电流（mA，单边/耳机典型值）
class AudioPa {
  final double? db0; // 0dB 信号
  final double? dbNeg20; // -20dB 信号
  final double? dbNegInf; // -∞dB（静音底噪）

  const AudioPa({this.db0, this.dbNeg20, this.dbNegInf});

  Map<String, dynamic> toJson() => {
        'db0': db0,
        'dbNeg20': dbNeg20,
        'dbNegInf': dbNegInf,
      };

  factory AudioPa.fromJson(Map<String, dynamic> j) => AudioPa(
        db0: _d(j['db0']),
        dbNeg20: _d(j['dbNeg20']),
        dbNegInf: _d(j['dbNegInf']),
      );
}

/// 芯片综合功耗档案。
///
/// 运行期数据从 `assets/data/earbuds_chips.json` 装载（见 `services/earbuds_chip_loader.dart`）。
/// 历史 const 定义仍在 `lib/config/earbuds/chips/`，但已 `@Deprecated`，
/// 仅供 `tool/dump_chips_json.dart` 重新导出 JSON 时使用。
class EarbudsChip {
  final String id; // e.g. '1607'
  final String? process; // e.g. 'SS_N14' / 'tsmc6n'
  final String? core; // e.g. 'M55*3 + U55 + BTC'
  final double? fullRamKb; // Full RAM size in KB
  final bool massProduction;

  final SleepCurrent sleep;
  final List<RunCurrent> mcuRun;
  final EarbudsScene scene;
  final BtScene bt;
  final List<TxSweepVariant> txSweep;
  final RxSweep? rxVana; // RX Current in VANA 域
  final RxSweep? rxVsys; // RX Current in VSYS=3.8V 域
  final AudioPa pa;

  const EarbudsChip({
    required this.id,
    this.process,
    this.core,
    this.fullRamKb,
    required this.massProduction,
    this.sleep = const SleepCurrent(),
    this.mcuRun = const [],
    this.scene = const EarbudsScene(),
    this.bt = const BtScene(),
    this.txSweep = const [],
    this.rxVana,
    this.rxVsys,
    this.pa = const AudioPa(),
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'process': process,
        'core': core,
        'fullRamKb': fullRamKb,
        'massProduction': massProduction,
        'sleep': sleep.toJson(),
        'mcuRun': mcuRun.map((e) => e.toJson()).toList(),
        'scene': scene.toJson(),
        'bt': bt.toJson(),
        'txSweep': txSweep.map((e) => e.toJson()).toList(),
        'rxVana': rxVana?.toJson(),
        'rxVsys': rxVsys?.toJson(),
        'pa': pa.toJson(),
      };

  factory EarbudsChip.fromJson(Map<String, dynamic> j) => EarbudsChip(
        id: (j['id'] as String?) ?? '',
        process: j['process'] as String?,
        core: j['core'] as String?,
        fullRamKb: _d(j['fullRamKb']),
        massProduction: (j['massProduction'] as bool?) ?? false,
        sleep: j['sleep'] == null
            ? const SleepCurrent()
            : SleepCurrent.fromJson(
                Map<String, dynamic>.from(j['sleep'] as Map)),
        mcuRun: (j['mcuRun'] as List?)
                ?.map((e) =>
                    RunCurrent.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
        scene: j['scene'] == null
            ? const EarbudsScene()
            : EarbudsScene.fromJson(
                Map<String, dynamic>.from(j['scene'] as Map)),
        bt: j['bt'] == null
            ? const BtScene()
            : BtScene.fromJson(Map<String, dynamic>.from(j['bt'] as Map)),
        txSweep: (j['txSweep'] as List?)
                ?.map((e) => TxSweepVariant.fromJson(
                    Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
        rxVana: j['rxVana'] == null
            ? null
            : RxSweep.fromJson(Map<String, dynamic>.from(j['rxVana'] as Map)),
        rxVsys: j['rxVsys'] == null
            ? null
            : RxSweep.fromJson(Map<String, dynamic>.from(j['rxVsys'] as Map)),
        pa: j['pa'] == null
            ? const AudioPa()
            : AudioPa.fromJson(Map<String, dynamic>.from(j['pa'] as Map)),
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
