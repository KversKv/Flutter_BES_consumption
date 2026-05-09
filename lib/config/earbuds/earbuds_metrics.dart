import '../../l10n/app_localizations.dart';
import '../../models/earbuds.dart';

/// 指标分组（与页面 Tab 对应，TxSweep / RxSweep 因为是曲线图另行处理）。
enum MetricGroup { scene, bt, cpuConsumption, pa }

/// 单位标签（仅用于坐标轴和表格列头）。
enum MetricUnit { mA, uA, volt }

/// 单个指标的读取器 —— 以 mA / µA / V 的**原始数值**返回，由 UI 层处理单位与格式化。
typedef MetricReader = double? Function(EarbudsChip chip);

/// 单个指标对应的可选第二维度（例如 MCU Run 有 M55/M33 两条变体）。
/// 默认读取第一条变体；如需其他变体可以通过 `variantAware` 读取器按 label 选择。
class EarbudsMetric {
  final String key;
  final MetricGroup group;
  final MetricUnit unit;
  final MetricReader read;
  final String Function(AppLocalizations s) label;

  const EarbudsMetric({
    required this.key,
    required this.group,
    required this.unit,
    required this.read,
    required this.label,
  });
}

// --- Readers ----------------------------------------------------------------

double? _firstRun(EarbudsChip c, double? Function(RunCurrent r) get) {
  for (final r in c.mcuRun) {
    final v = get(r);
    if (v != null) return v;
  }
  return null;
}

// --- Metric definitions -----------------------------------------------------

const List<EarbudsMetric> _sceneMetrics = [
  EarbudsMetric(
    key: 'hotelcal', group: MetricGroup.scene, unit: MetricUnit.mA,
    read: _readHotelCal, label: _labelHotelCal,
  ),
  EarbudsMetric(
    key: 'mute', group: MetricGroup.scene, unit: MetricUnit.mA,
    read: _readMute, label: _labelMute,
  ),
  EarbudsMetric(
    key: 'noisepink', group: MetricGroup.scene, unit: MetricUnit.mA,
    read: _readNoisePink, label: _labelNoisePink,
  ),
  EarbudsMetric(
    key: '1khz', group: MetricGroup.scene, unit: MetricUnit.mA,
    read: _read1Khz, label: _label1Khz,
  ),
  EarbudsMetric(
    key: 'call', group: MetricGroup.scene, unit: MetricUnit.mA,
    read: _readCall, label: _labelCall,
  ),
  EarbudsMetric(
    key: 'sniffpage', group: MetricGroup.scene, unit: MetricUnit.mA,
    read: _readSniffPage, label: _labelSniffPage,
  ),
  EarbudsMetric(
    key: 'poweroff', group: MetricGroup.scene, unit: MetricUnit.uA,
    read: _readPowerOff, label: _labelPowerOff,
  ),
];

double? _readHotelCal(EarbudsChip c) => c.scene.hotelCal;
String _labelHotelCal(AppLocalizations s) => s.ebHotelCal;

double? _readMute(EarbudsChip c) => c.scene.mute;
String _labelMute(AppLocalizations s) => s.ebMetricMute;
double? _readNoisePink(EarbudsChip c) => c.scene.noisePink;
String _labelNoisePink(AppLocalizations s) => s.ebMetricNoisePink;
double? _read1Khz(EarbudsChip c) => c.scene.k1Hz;
String _label1Khz(AppLocalizations s) => s.ebMetric1Khz;
double? _readCall(EarbudsChip c) => c.scene.call;
String _labelCall(AppLocalizations s) => s.ebMetricCall;
double? _readSniffPage(EarbudsChip c) => c.scene.sniffPage;
String _labelSniffPage(AppLocalizations s) => s.ebMetricSniffPage;
// Power off: stored in mA, show in µA
double? _readPowerOff(EarbudsChip c) {
  final v = c.scene.powerOff;
  return v == null ? null : v * 1000.0;
}
String _labelPowerOff(AppLocalizations s) => s.ebMetricPowerOff;

const List<EarbudsMetric> _btMetrics = [
  EarbudsMetric(key: 'btbase', group: MetricGroup.bt, unit: MetricUnit.mA,
    read: _readBtBase, label: _labelBtBase),
  EarbudsMetric(key: 'bleadv', group: MetricGroup.bt, unit: MetricUnit.mA,
    read: _readBleAdv, label: _labelBleAdv),
  EarbudsMetric(key: 'bleconn200', group: MetricGroup.bt, unit: MetricUnit.mA,
    read: _readBleConn200, label: _labelBleConn200),
  EarbudsMetric(key: 'bleconn500', group: MetricGroup.bt, unit: MetricUnit.mA,
    read: _readBleConn500, label: _labelBleConn500),
  EarbudsMetric(key: 'btpagescan', group: MetricGroup.bt, unit: MetricUnit.mA,
    read: _readBtPagescan, label: _labelBtPagescan),
  EarbudsMetric(key: 'btsniff200', group: MetricGroup.bt, unit: MetricUnit.mA,
    read: _readBtSniff200, label: _labelBtSniff200),
  EarbudsMetric(key: 'btsniff500', group: MetricGroup.bt, unit: MetricUnit.mA,
    read: _readBtSniff500, label: _labelBtSniff500),
];

double? _readBtBase(EarbudsChip c) => c.bt.btBase;
String _labelBtBase(AppLocalizations s) => s.ebMetricBtBase;
double? _readBleAdv(EarbudsChip c) => c.bt.bleAdv500_9;
String _labelBleAdv(AppLocalizations s) => s.ebMetricBleAdv;
double? _readBleConn200(EarbudsChip c) => c.bt.bleConn200_0;
String _labelBleConn200(AppLocalizations s) => s.ebMetricBleConn200;
double? _readBleConn500(EarbudsChip c) => c.bt.bleConn500_0;
String _labelBleConn500(AppLocalizations s) => s.ebMetricBleConn500;
double? _readBtPagescan(EarbudsChip c) => c.bt.btPagescan9;
String _labelBtPagescan(AppLocalizations s) => s.ebMetricBtPagescan;
double? _readBtSniff200(EarbudsChip c) => c.bt.btSniff200_0;
String _labelBtSniff200(AppLocalizations s) => s.ebMetricBtSniff200;
double? _readBtSniff500(EarbudsChip c) => c.bt.btSniff500_0;
String _labelBtSniff500(AppLocalizations s) => s.ebMetricBtSniff500;

const List<EarbudsMetric> _cpuConsumptionMetrics = [
  EarbudsMetric(key: 'pd256', group: MetricGroup.cpuConsumption, unit: MetricUnit.uA,
    read: _readPd256, label: _labelPd256),
  EarbudsMetric(key: 'pdfull', group: MetricGroup.cpuConsumption, unit: MetricUnit.uA,
    read: _readPdFull, label: _labelPdFull),
  EarbudsMetric(key: 'deepsleep', group: MetricGroup.cpuConsumption, unit: MetricUnit.uA,
    read: _readDeep, label: _labelDeep),
  EarbudsMetric(key: 'vcorem', group: MetricGroup.cpuConsumption, unit: MetricUnit.volt,
    read: _readVcoreM, label: _labelVcoreM),
  EarbudsMetric(key: 'vcorel', group: MetricGroup.cpuConsumption, unit: MetricUnit.volt,
    read: _readVcoreL, label: _labelVcoreL),
  EarbudsMetric(key: 'vana', group: MetricGroup.cpuConsumption, unit: MetricUnit.volt,
    read: _readVana, label: _labelVana),
  EarbudsMetric(key: 'vhppa', group: MetricGroup.cpuConsumption, unit: MetricUnit.volt,
    read: _readVhppa, label: _labelVhppa),
  EarbudsMetric(key: 'wfi24', group: MetricGroup.cpuConsumption, unit: MetricUnit.mA,
    read: _readWfi24, label: _labelWfi24),
  EarbudsMetric(key: 'cm24', group: MetricGroup.cpuConsumption, unit: MetricUnit.mA,
    read: _readCm24, label: _labelCm24),
  EarbudsMetric(key: 'cm48', group: MetricGroup.cpuConsumption, unit: MetricUnit.mA,
    read: _readCm48, label: _labelCm48),
  EarbudsMetric(key: 'cm96', group: MetricGroup.cpuConsumption, unit: MetricUnit.mA,
    read: _readCm96, label: _labelCm96),
  EarbudsMetric(key: 'cm192', group: MetricGroup.cpuConsumption, unit: MetricUnit.mA,
    read: _readCm192, label: _labelCm192),
];

double? _readPd256(EarbudsChip c) => c.sleep.pdSleep256;
String _labelPd256(AppLocalizations s) => s.ebMetricPd256;
double? _readPdFull(EarbudsChip c) => c.sleep.pdSleepFull;
String _labelPdFull(AppLocalizations s) => s.ebMetricPdFull;
double? _readDeep(EarbudsChip c) => c.sleep.deepSleep;
String _labelDeep(AppLocalizations s) => s.ebMetricDeepSleep;
double? _readVcoreM(EarbudsChip c) => c.sleep.vcoreM;
String _labelVcoreM(AppLocalizations s) => s.ebMetricVcoreM;
double? _readVcoreL(EarbudsChip c) => c.sleep.vcoreL;
String _labelVcoreL(AppLocalizations s) => s.ebMetricVcoreL;
double? _readVana(EarbudsChip c) => c.sleep.vana;
String _labelVana(AppLocalizations s) => s.ebMetricVana;
double? _readVhppa(EarbudsChip c) => c.sleep.vhppa;
String _labelVhppa(AppLocalizations s) => s.ebMetricVhppa;

double? _readWfi24(EarbudsChip c) => _firstRun(c, (r) => r.wfi24M);
String _labelWfi24(AppLocalizations s) => s.ebMetricWfi24;
double? _readCm24(EarbudsChip c) => _firstRun(c, (r) => r.cm24M);
String _labelCm24(AppLocalizations s) => s.ebMetricCm24;
double? _readCm48(EarbudsChip c) => _firstRun(c, (r) => r.cm48M);
String _labelCm48(AppLocalizations s) => s.ebMetricCm48;
double? _readCm96(EarbudsChip c) => _firstRun(c, (r) => r.cm96M);
String _labelCm96(AppLocalizations s) => s.ebMetricCm96;
double? _readCm192(EarbudsChip c) => _firstRun(c, (r) => r.cm192M);
String _labelCm192(AppLocalizations s) => s.ebMetricCm192;

const List<EarbudsMetric> _paMetrics = [
  EarbudsMetric(key: 'pa0', group: MetricGroup.pa, unit: MetricUnit.mA,
    read: _readPa0, label: _labelPa0),
  EarbudsMetric(key: 'paneg20', group: MetricGroup.pa, unit: MetricUnit.mA,
    read: _readPaNeg20, label: _labelPaNeg20),
  EarbudsMetric(key: 'paneginf', group: MetricGroup.pa, unit: MetricUnit.mA,
    read: _readPaNegInf, label: _labelPaNegInf),
];

double? _readPa0(EarbudsChip c) => c.pa.db0;
String _labelPa0(AppLocalizations s) => s.ebMetricPa0;
double? _readPaNeg20(EarbudsChip c) => c.pa.dbNeg20;
String _labelPaNeg20(AppLocalizations s) => s.ebMetricPaNeg20;
double? _readPaNegInf(EarbudsChip c) => c.pa.dbNegInf;
String _labelPaNegInf(AppLocalizations s) => s.ebMetricPaNegInf;

/// 按分组获取指标定义列表。
List<EarbudsMetric> metricsOf(MetricGroup g) {
  switch (g) {
    case MetricGroup.scene: return _sceneMetrics;
    case MetricGroup.bt: return _btMetrics;
    case MetricGroup.cpuConsumption: return _cpuConsumptionMetrics;
    case MetricGroup.pa: return _paMetrics;
  }
}

/// 单位对应的 i18n 标签（Y 轴 / 数值尾缀）。
String unitLabel(MetricUnit u, AppLocalizations s) {
  switch (u) {
    case MetricUnit.mA: return s.ebUnitMa;
    case MetricUnit.uA: return s.ebUnitUa;
    case MetricUnit.volt: return s.ebUnitV;
  }
}

String yAxisLabel(MetricUnit u, AppLocalizations s) {
  switch (u) {
    case MetricUnit.mA: return s.ebChartYaxisMa;
    case MetricUnit.uA: return s.ebChartYaxisUa;
    case MetricUnit.volt: return s.ebChartYaxisV;
  }
}
