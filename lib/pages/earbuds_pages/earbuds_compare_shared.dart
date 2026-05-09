part of '../earbuds_compare_page.dart';

class _MetricStat {
  final double? min;
  final double? max;
  final double? avg;

  const _MetricStat({
    required this.min,
    required this.max,
    required this.avg,
  });
}

List<_MetricStat> _computeMetricStats(
  List<EarbudsChip> chips,
  List<EarbudsMetric> metrics,
) {
  return metrics.map((metric) {
    final values = chips.map(metric.read).whereType<double>().toList();
    if (values.isEmpty) {
      return const _MetricStat(min: null, max: null, avg: null);
    }
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final avgValue = values.reduce((a, b) => a + b) / values.length;
    return _MetricStat(min: minValue, max: maxValue, avg: avgValue);
  }).toList();
}

class _EmptyHint extends StatelessWidget {
  final String hint;
  const _EmptyHint({required this.hint});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x4,
          vertical: AppSpacing.x3,
        ),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: Text(
          hint,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
