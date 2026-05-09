import '../config/earbuds/earbuds_metrics.dart';
import '../models/earbuds.dart';

/// 纯查询 / 计算函数集合 —— 不依赖 Flutter。
class EarbudsQuery {
  /// 过滤：是否仅保留量产配置。
  static List<EarbudsChip> filter(
    List<EarbudsChip> chips, {
    required bool massProductionOnly,
  }) {
    if (!massProductionOnly) return chips;
    return chips.where((c) => c.massProduction).toList(growable: false);
  }

  /// 对给定指标，按数值升/降序排序；null 值始终排到末尾。
  static List<EarbudsChip> sortByMetric(
    List<EarbudsChip> chips,
    EarbudsMetric metric, {
    required bool ascending,
  }) {
    final copy = List<EarbudsChip>.of(chips);
    copy.sort((a, b) {
      final va = metric.read(a);
      final vb = metric.read(b);
      if (va == null && vb == null) return 0;
      if (va == null) return 1;
      if (vb == null) return -1;
      return ascending ? va.compareTo(vb) : vb.compareTo(va);
    });
    return copy;
  }

  /// 在给定的芯片列表中：列出所有 TX Sweep 变体覆盖的 dBm 集合并升序。
  static List<int> txDbmDomain(List<EarbudsChip> chips) {
    final set = <int>{};
    for (final c in chips) {
      for (final v in c.txSweep) {
        set.addAll(v.values.keys);
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  /// 在给定的芯片列表中：RX Sweep 覆盖的 gain 集合升序。
  static List<int> rxGainDomain(
    List<EarbudsChip> chips, {
    required bool useVsys,
  }) {
    final set = <int>{};
    for (final c in chips) {
      final rx = useVsys ? c.rxVsys : c.rxVana;
      if (rx == null) continue;
      set.addAll(rx.values.keys);
    }
    final list = set.toList()..sort();
    return list;
  }

  /// 数值格式化（UI 辅助）
  static String format(double? v, {int fractionDigits = 2}) {
    if (v == null) return '-';
    if (v == 0) return '0';
    final abs = v.abs();
    if (abs >= 100) return v.toStringAsFixed(0);
    if (abs >= 10) return v.toStringAsFixed(1);
    return v.toStringAsFixed(fractionDigits);
  }
}
