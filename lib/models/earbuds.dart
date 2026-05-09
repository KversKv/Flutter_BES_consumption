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
}

/// Earbuds 真机使用场景电流（mA, VSYS=3.8V）
class EarbudsScene {
  final double? mute;
  final double? noisePink; // NoisePink 8/15 AAC
  final double? k1Hz; // 1kHz -6dB 15/15 AAC
  final double? call; // Call 8/15
  final double? sniffPage; // 500ms sniff & 1.28s Page
  final double? powerOff;

  const EarbudsScene({
    this.mute,
    this.noisePink,
    this.k1Hz,
    this.call,
    this.sniffPage,
    this.powerOff,
  });
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
}

/// TX 功率扫描（单个调制 / 配置的曲线）
class TxSweepVariant {
  final String label; // 例如 '3.3 + 1.7' / '2point' / 'polar'
  final Map<int, double> values; // dBm -> mA

  const TxSweepVariant({required this.label, required this.values});
}

/// RX 增益扫描
class RxSweep {
  final Map<int, double> values; // gain -> mA
  final double? vana; // 对应 VANA 电压（仅 VANA 域）

  const RxSweep({required this.values, this.vana});
}

/// Audio PA 电流（mA，单边/耳机典型值）
class AudioPa {
  final double? db0; // 0dB 信号
  final double? dbNeg20; // -20dB 信号
  final double? dbNegInf; // -∞dB（静音底噪）

  const AudioPa({this.db0, this.dbNeg20, this.dbNegInf});
}

/// 芯片综合功耗档案。
///
/// 每颗芯片一个 `const EarbudsChip(...)`，建议放到 `lib/config/earbuds/chips/` 下一文件一芯片，
/// 再由 `earbuds_chip_registry.dart` 聚合成 `kAllChips`。
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
}
