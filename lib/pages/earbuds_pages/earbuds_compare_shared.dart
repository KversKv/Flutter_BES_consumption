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

/// 通用单芯片视图：展示某个 group 下，被选中芯片的所有 metric 数据。
class _SingleChipMetricView extends StatelessWidget {
  final MetricGroup group;
  const _SingleChipMetricView({required this.group});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final es = context.watch<EarbudsState>();
    final chips = es.visibleChips;

    if (chips.isEmpty) {
      return _EmptyHint(hint: s.ebSelectChipsHint);
    }

    final chip = es.focusedChip ?? chips.first;
    final metrics = metricsOf(group);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x4,
              vertical: AppSpacing.x4,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.primaryContainer.withValues(alpha: 0.35),
                  cs.surfaceContainerHigh,
                ],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(Icons.headphones_rounded, color: cs.primary),
                ),
                const SizedBox(width: AppSpacing.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BES${chip.id}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _groupTitle(group, s),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (chip.process != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.x3,
                      vertical: AppSpacing.x2,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surface.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Text(
                      chip.process!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.x4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.table_chart_rounded,
                          size: 16, color: cs.primary),
                      const SizedBox(width: AppSpacing.x2),
                      Text(
                        s.ebMeasurement,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        cs.primaryContainer.withValues(alpha: 0.2),
                      ),
                      columnSpacing: 24,
                      headingTextStyle: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      dataRowMinHeight: 44,
                      dataRowMaxHeight: 52,
                      columns: [
                        DataColumn(label: Text(s.ebProject)),
                        DataColumn(
                          label: Text(s.ebMeasurement),
                          numeric: true,
                        ),
                        const DataColumn(label: Text('Unit')),
                      ],
                      rows: metrics.map((m) {
                        final v = m.read(chip);
                        return DataRow(
                          cells: [
                            DataCell(Text(m.label(s))),
                            DataCell(
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  v != null ? EarbudsQuery.format(v) : '-',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            DataCell(Text(unitLabel(m.unit, s))),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _groupTitle(MetricGroup g, AppLocalizations s) {
    switch (g) {
      case MetricGroup.scene:
        return s.ebTabScene;
      case MetricGroup.cpuConsumption:
        return s.ebTabCpuConsumption;
    }
  }
}

/// 通用曲线 Tab 外壳：header + chart + legend。
class _CurveTabShell extends StatelessWidget {
  final Widget header;
  final Widget chart;
  final List<_LegendItem> legend;
  const _CurveTabShell({
    required this.header,
    required this.chart,
    required this.legend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        header,
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x4,
              AppSpacing.x2,
              AppSpacing.x4,
              AppSpacing.x2,
            ),
            child: chart,
          ),
        ),
        _Legend(items: legend),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final List<_LegendItem> items;
  const _Legend({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x4,
        AppSpacing.x1,
        AppSpacing.x4,
        AppSpacing.x3,
      ),
      child: Wrap(
        spacing: AppSpacing.x3,
        runSpacing: AppSpacing.x1,
        children: items
            .map((e) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: e.color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(e.text, style: theme.textTheme.bodySmall),
                  ],
                ))
            .toList(),
      ),
    );
  }
}

class _LegendItem {
  final Color color;
  final String text;
  const _LegendItem({required this.color, required this.text});
}

/// TX / RX Sweep Tab 右上角的 视图切换按钮（曲线 / 表格）。
class _SweepViewToggle extends StatelessWidget {
  final EarbudsSweepViewMode mode;
  final ValueChanged<EarbudsSweepViewMode> onChanged;
  const _SweepViewToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SegmentedButton<EarbudsSweepViewMode>(
      segments: [
        ButtonSegment(
          value: EarbudsSweepViewMode.curve,
          icon: const Icon(Icons.show_chart_rounded, size: 16),
          label: Text(s.ebSweepViewCurve, style: theme.textTheme.labelSmall),
        ),
        ButtonSegment(
          value: EarbudsSweepViewMode.table,
          icon: const Icon(Icons.table_rows_rounded, size: 16),
          label: Text(s.ebSweepViewTable, style: theme.textTheme.labelSmall),
        ),
      ],
      selected: {mode},
      onSelectionChanged: (set) => onChanged(set.first),
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
