import 'package:flutter/foundation.dart';

import '../config/earbuds/earbuds_metrics.dart';
import '../models/earbuds.dart';
import '../services/earbuds_repository.dart';

/// 排序方向
enum EarbudsSortDir { original, asc, desc }

/// Earbuds Scene 视图模式
enum EarbudsSceneViewMode { singleChip, comparison }

/// TX / RX Sweep 呈现方式
enum EarbudsSweepViewMode { curve, table }

/// Earbuds 对比页面的交互状态。
class EarbudsState extends ChangeNotifier {
  EarbudsState() {
    EarbudsRepository.instance.addListener(_onRepoChanged);
    final defaults =
        EarbudsRepository.instance.chips.where((c) => c.massProduction).take(3);
    for (final c in defaults) {
      _selected.add(c.id);
    }
    final all = EarbudsRepository.instance.chips;
    if (all.isNotEmpty) {
      _focusedChipId = all.first.id;
    }
  }

  @override
  void dispose() {
    EarbudsRepository.instance.removeListener(_onRepoChanged);
    super.dispose();
  }

  void _onRepoChanged() {
    final all = EarbudsRepository.instance.chips;
    final ids = all.map((c) => c.id).toSet();
    _selected.removeWhere((id) => !ids.contains(id));
    if (_focusedChipId != null && !ids.contains(_focusedChipId)) {
      _focusedChipId = all.isNotEmpty ? all.first.id : null;
    }
    notifyListeners();
  }

  /// 全部已建模芯片（数据源），页面只读。
  List<EarbudsChip> get allChips => EarbudsRepository.instance.chips;

  // 当前选中的 Tab（指标分组）。
  MetricGroup _group = MetricGroup.scene;
  MetricGroup get group => _group;

  // Bar 图主 tab 下"当前聚焦"的指标；默认第一项。
  final Map<MetricGroup, int> _metricIdx = {};

  int metricIndex(MetricGroup g) => _metricIdx[g] ?? 0;
  EarbudsMetric currentMetric(MetricGroup g) => metricsOf(g)[metricIndex(g)];

  void setGroup(MetricGroup g) {
    if (_group == g) return;
    _group = g;
    notifyListeners();
  }

  void setMetricIndex(MetricGroup g, int idx) {
    final list = metricsOf(g);
    if (idx < 0 || idx >= list.length) return;
    if (_metricIdx[g] == idx) return;
    _metricIdx[g] = idx;
    notifyListeners();
  }

  // 筛选：仅量产。
  bool _massProductionOnly = false;
  bool get massProductionOnly => _massProductionOnly;
  void toggleMassProductionOnly() {
    _massProductionOnly = !_massProductionOnly;
    // 清理已选但被过滤掉的芯片
    if (_massProductionOnly) {
      _selected.removeWhere((id) {
        final chip = _chipById(id);
        return chip == null || !chip.massProduction;
      });
    }
    notifyListeners();
  }

  // 排序。
  EarbudsSortDir _sortDir = EarbudsSortDir.original;
  EarbudsSortDir get sortDir => _sortDir;
  void cycleSort() {
    _sortDir = switch (_sortDir) {
      EarbudsSortDir.original => EarbudsSortDir.asc,
      EarbudsSortDir.asc => EarbudsSortDir.desc,
      EarbudsSortDir.desc => EarbudsSortDir.original,
    };
    notifyListeners();
  }

  // 选中的芯片（按用户点击顺序保留）。
  final List<String> _selected = [];
  List<String> get selectedIds => List.unmodifiable(_selected);

  bool isSelected(String id) => _selected.contains(id);

  /// 切换选中状态；不再限制最大数量，恒返回 true。
  bool toggleSelected(String id) {
    if (_selected.contains(id)) {
      _selected.remove(id);
    } else {
      _selected.add(id);
    }
    notifyListeners();
    return true;
  }

  void clearSelection() {
    if (_selected.isEmpty) return;
    _selected.clear();
    notifyListeners();
  }

  /// RX Sweep 电源域选择。
  bool _rxUseVsys = false; // false=VANA, true=VSYS
  bool get rxUseVsys => _rxUseVsys;
  void setRxUseVsys(bool v) {
    if (_rxUseVsys == v) return;
    _rxUseVsys = v;
    notifyListeners();
  }

  /// TX Sweep 视图模式（曲线 / 表格），默认曲线。
  EarbudsSweepViewMode _txViewMode = EarbudsSweepViewMode.curve;
  EarbudsSweepViewMode get txViewMode => _txViewMode;
  void setTxViewMode(EarbudsSweepViewMode mode) {
    if (_txViewMode == mode) return;
    _txViewMode = mode;
    notifyListeners();
  }

  /// RX Sweep 视图模式（曲线 / 表格），默认曲线。
  EarbudsSweepViewMode _rxViewMode = EarbudsSweepViewMode.curve;
  EarbudsSweepViewMode get rxViewMode => _rxViewMode;
  void setRxViewMode(EarbudsSweepViewMode mode) {
    if (_rxViewMode == mode) return;
    _rxViewMode = mode;
    notifyListeners();
  }

  // --- Scene 视图模式 --------------------------------------------------------

  EarbudsSceneViewMode _sceneViewMode = EarbudsSceneViewMode.singleChip;
  EarbudsSceneViewMode get sceneViewMode => _sceneViewMode;
  void setSceneViewMode(EarbudsSceneViewMode mode) {
    if (_sceneViewMode == mode) return;
    _sceneViewMode = mode;
    notifyListeners();
  }

  /// 当前 Tab 是否支持视图模式切换（Single Chip / Comparison）。
  /// 仅 Earbuds Scene(0) / BT&BLE(1) / CPU Consumption(2) 三个 tab 支持。
  bool get currentTabSupportsViewMode =>
      _tabIndex == 0 || _tabIndex == 1 || _tabIndex == 2;

  // --- Comparison 模式：选中的对比 case (按 metric key 区分) ------------------

  /// 每个 group 当前选中的 metric key 集合。
  /// null 表示尚未初始化 / 默认全选。
  final Map<MetricGroup, Set<String>> _selectedMetricKeys = {};

  Set<String> _ensureMetricKeys(MetricGroup g) {
    final cached = _selectedMetricKeys[g];
    if (cached != null) return cached;
    final defaults = _defaultMetricKeys(g);
    _selectedMetricKeys[g] = defaults;
    return defaults;
  }

  /// 各 group 的默认勾选 case。Scene 默认只对比 NoisePink 8/15 AAC，其余全选。
  Set<String> _defaultMetricKeys(MetricGroup g) {
    if (g == MetricGroup.scene) {
      const noisePinkKey = 'noisepink';
      final hasNoisePink = metricsOf(g).any((m) => m.key == noisePinkKey);
      if (hasNoisePink) return {noisePinkKey};
    }
    return metricsOf(g).map((m) => m.key).toSet();
  }

  bool isMetricSelected(MetricGroup g, String key) =>
      _ensureMetricKeys(g).contains(key);

  void toggleMetric(MetricGroup g, String key) {
    final set = _ensureMetricKeys(g);
    if (set.contains(key)) {
      // 至少保留一个 case，避免出现空表格
      if (set.length <= 1) return;
      set.remove(key);
    } else {
      set.add(key);
    }
    notifyListeners();
  }

  void selectAllMetrics(MetricGroup g) {
    final all = metricsOf(g).map((m) => m.key).toSet();
    _selectedMetricKeys[g] = all;
    notifyListeners();
  }

  /// 根据当前 group 已选 keys，对原始 metrics 进行过滤（保持原始顺序）。
  List<EarbudsMetric> selectedMetricsOf(MetricGroup g) {
    final keys = _ensureMetricKeys(g);
    return metricsOf(g).where((m) => keys.contains(m.key)).toList(growable: false);
  }

  // --- Tab 索引 (左侧面板控制) -----------------------------------------------

  int _tabIndex = 0;
  int get tabIndex => _tabIndex;
  void setTabIndex(int idx) {
    if (idx < 0 || idx > 5) return;
    if (_tabIndex == idx) return;
    _tabIndex = idx;
    const groups = [
      MetricGroup.scene,
      MetricGroup.bt,
      MetricGroup.cpuConsumption,
      null,
      null,
      MetricGroup.pa,
    ];
    final g = groups[idx];
    if (g != null) _group = g;
    notifyListeners();
  }

  String? _focusedChipId;
  String? get focusedChipId => _focusedChipId;
  EarbudsChip? get focusedChip {
    final id = _focusedChipId;
    if (id == null) return null;
    return _chipById(id);
  }

  void setFocusedChip(String id) {
    if (_focusedChipId == id) return;
    _focusedChipId = id;
    notifyListeners();
  }

  // --- Derived helpers ------------------------------------------------------

  EarbudsChip? _chipById(String id) {
    for (final c in allChips) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// 当前（应用筛选后的）可选芯片池。
  List<EarbudsChip> get visibleChips {
    if (!_massProductionOnly) return allChips;
    return allChips.where((c) => c.massProduction).toList(growable: false);
  }

  /// 当前选中的芯片对象列表（保留点击顺序）。
  List<EarbudsChip> get selectedChips {
    final out = <EarbudsChip>[];
    for (final id in _selected) {
      final c = _chipById(id);
      if (c != null) out.add(c);
    }
    return out;
  }
}
