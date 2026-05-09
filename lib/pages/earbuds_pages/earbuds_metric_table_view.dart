part of '../earbuds_compare_page.dart';

class _MetricTableView extends StatefulWidget {
  final MetricGroup group;
  const _MetricTableView({required this.group});

  @override
  State<_MetricTableView> createState() => _MetricTableViewState();
}

class _MetricTableViewState extends State<_MetricTableView>
    with AutomaticKeepAliveClientMixin {
  int? _sortMetricIndex;
  bool _ascending = true;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = AppLocalizations.of(context);
    final es = context.watch<EarbudsState>();
    final allMetrics = metricsOf(widget.group);
    final metrics = es.selectedMetricsOf(widget.group);
    var chips = List<EarbudsChip>.of(es.selectedChips);

    if (chips.isEmpty) {
      return _EmptyHint(hint: s.ebSelectChipsHint);
    }

    if (metrics.isEmpty) {
      return _EmptyHint(hint: s.ebSelectChipsHint);
    }

    if (_sortMetricIndex != null && _sortMetricIndex! < metrics.length) {
      final metric = metrics[_sortMetricIndex!];
      chips = EarbudsQuery.sortByMetric(chips, metric, ascending: _ascending);
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final palette = AppPalette.of(context);
    final headerStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
    );

    final metricStats = _computeMetricStats(chips, metrics);

    return Column(
      children: [
        _CaseSelectorBar(group: widget.group, allMetrics: allMetrics),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x4,
            AppSpacing.x3,
            AppSpacing.x4,
            AppSpacing.x2,
          ),
          child: _MetricDashboardHeader(
            chips: chips,
            metrics: metrics,
            stats: metricStats,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x4,
              0,
              AppSpacing.x4,
              AppSpacing.x4,
            ),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _MetricTableToolbar(
                    metricCount: metrics.length,
                    chipCount: chips.length,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            cs.primaryContainer.withValues(alpha: 0.18),
                          ),
                          columnSpacing: 22,
                          headingTextStyle: headerStyle,
                          dataRowMinHeight: 48,
                          dataRowMaxHeight: 56,
                          sortColumnIndex: _sortMetricIndex != null
                              ? _sortMetricIndex! + 1
                              : null,
                          sortAscending: _ascending,
                          columns: [
                            DataColumn(label: Text(s.ebChipInfo)),
                            ...metrics.asMap().entries.map((entry) {
                              final i = entry.key;
                              final m = entry.value;
                              return DataColumn(
                                numeric: true,
                                label: SizedBox(
                                  width: 120,
                                  child: Text(
                                    '${m.label(s)}\n(${unitLabel(m.unit, s)})',
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                onSort: (colIndex, asc) {
                                  setState(() {
                                    _sortMetricIndex = i;
                                    _ascending = asc;
                                  });
                                },
                              );
                            }),
                          ],
                          rows: [
                            ...chips.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final c = entry.value;
                              final colorIdx = es.selectedIds.indexOf(c.id);
                              final chipColor = palette.dataSeries[
                                  colorIdx % palette.dataSeries.length];
                              return DataRow(
                                color: WidgetStateProperty.all(
                                  idx.isEven
                                      ? Colors.transparent
                                      : cs.surfaceContainerHighest.withValues(alpha: 0.3),
                                ),
                                cells: [
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: chipColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.x2),
                                        Text(
                                          'BES${c.id}',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ...metrics.map((m) {
                                    final stat = metricStats[metrics.indexOf(m)];
                                    return DataCell(
                                      SizedBox(
                                        width: 120,
                                        child: _HeatmapCell(
                                          value: m.read(c),
                                          min: stat.min,
                                          max: stat.max,
                                          unit: m.unit,
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              );
                            }),
                            _buildSummaryRow(s.ebBest, metricStats, _StatType.min, cs, theme),
                            _buildSummaryRow(s.ebWorst, metricStats, _StatType.max, cs, theme),
                            _buildSummaryRow(s.ebAvg, metricStats, _StatType.avg, cs, theme),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  DataRow _buildSummaryRow(
    String label,
    List<_MetricStat> stats,
    _StatType type,
    ColorScheme cs,
    ThemeData theme,
  ) {
    final bgColor = cs.surfaceContainerHigh.withValues(alpha: 0.5);
    return DataRow(
      color: WidgetStateProperty.all(bgColor),
      cells: [
        DataCell(
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        ...stats.map((stat) {
          final v = switch (type) {
            _StatType.min => stat.min,
            _StatType.max => stat.max,
            _StatType.avg => stat.avg,
          };
          return DataCell(
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                v != null ? EarbudsQuery.format(v) : '-',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _MetricDashboardHeader extends StatelessWidget {
  final List<EarbudsChip> chips;
  final List<EarbudsMetric> metrics;
  final List<_MetricStat> stats;

  const _MetricDashboardHeader({
    required this.chips,
    required this.metrics,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: _SummaryRow(chips: chips, metrics: metrics, stats: stats),
        ),
        const SizedBox(width: AppSpacing.x3),
        Expanded(
          flex: 4,
          child: _MetricSpreadCard(metrics: metrics, stats: stats),
        ),
      ],
    );
  }
}

class _MetricTableToolbar extends StatelessWidget {
  final int metricCount;
  final int chipCount;
  const _MetricTableToolbar({
    required this.metricCount,
    required this.chipCount,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x4,
        vertical: AppSpacing.x3,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2)),
        ),
      ),
      child: Wrap(
        spacing: AppSpacing.x2,
        runSpacing: AppSpacing.x2,
        children: [
          _ToolbarChip(
            icon: Icons.table_rows_rounded,
            label: '$chipCount Chips',
          ),
          _ToolbarChip(
            icon: Icons.stacked_bar_chart_rounded,
            label: '$metricCount Metrics',
          ),
          _ToolbarChip(
            icon: Icons.sort_rounded,
            label: 'Sortable',
          ),
        ],
      ),
    );
  }
}

class _ToolbarChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ToolbarChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x2,
        vertical: AppSpacing.x1,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: AppSpacing.x1),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatmapCell extends StatelessWidget {
  final double? value;
  final double? min;
  final double? max;
  final MetricUnit unit;

  const _HeatmapCell({
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = AppPalette.of(context);

    if (value == null) {
      return Align(
        alignment: Alignment.centerRight,
        child: Text(
          '-',
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      );
    }

    Color? bgColor;
    Color textColor = cs.onSurface;

    if (min != null && max != null && max! > min!) {
      final ratio = (value! - min!) / (max! - min!);
      if (ratio <= 0.05) {
        bgColor = p.success.withValues(alpha: 0.15);
        textColor = p.success;
      } else if (ratio >= 0.95) {
        bgColor = p.danger.withValues(alpha: 0.15);
        textColor = p.danger;
      } else if (ratio <= 0.25) {
        bgColor = p.success.withValues(alpha: 0.08);
      } else if (ratio >= 0.75) {
        bgColor = p.warning.withValues(alpha: 0.1);
      }
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: bgColor != null
            ? BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(4),
              )
            : null,
        child: Text(
          EarbudsQuery.format(value!),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final List<EarbudsChip> chips;
  final List<EarbudsMetric> metrics;
  final List<_MetricStat> stats;

  const _SummaryRow({
    required this.chips,
    required this.metrics,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = AppPalette.of(context);

    final displayMetrics = metrics.length > 5 ? metrics.sublist(0, 5) : metrics;
    final displayStats = stats.length > 5 ? stats.sublist(0, 5) : stats;

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: displayMetrics.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.x2),
        itemBuilder: (context, i) {
          final m = displayMetrics[i];
          final stat = displayStats[i];
          return _KpiCard(
            label: m.label(s),
            unit: unitLabel(m.unit, s),
            best: stat.min,
            avg: stat.avg,
            worst: stat.max,
            successColor: p.success,
            dangerColor: p.danger,
          );
        },
      ),
    );
  }
}

class _MetricSpreadCard extends StatelessWidget {
  final List<EarbudsMetric> metrics;
  final List<_MetricStat> stats;
  const _MetricSpreadCard({required this.metrics, required this.stats});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final items = <_SpreadItem>[];
    for (var i = 0; i < metrics.length; i++) {
      final stat = stats[i];
      if (stat.min == null || stat.max == null) continue;
      items.add(
        _SpreadItem(
          label: metrics[i].label(s),
          spread: stat.max! - stat.min!,
          unit: unitLabel(metrics[i].unit, s),
        ),
      );
    }
    items.sort((a, b) => b.spread.compareTo(a.spread));
    final display = items.take(3).toList();

    return Container(
      height: 92,
      padding: const EdgeInsets.all(AppSpacing.x3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: display.isEmpty
          ? Center(
              child: Text(
                s.ebNoData,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: display
                  .map(
                    (item) => Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.x2),
                          Text(
                            '${EarbudsQuery.format(item.spread)} ${item.unit}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _SpreadItem {
  final String label;
  final double spread;
  final String unit;
  const _SpreadItem({
    required this.label,
    required this.spread,
    required this.unit,
  });
}

enum _StatType { min, max, avg }

class _KpiCard extends StatelessWidget {
  final String label;
  final String unit;
  final double? best;
  final double? avg;
  final double? worst;
  final Color successColor;
  final Color dangerColor;

  const _KpiCard({
    required this.label,
    required this.unit,
    required this.best,
    required this.avg,
    required this.worst,
    required this.successColor,
    required this.dangerColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: 220,
      padding: const EdgeInsets.all(AppSpacing.x3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.x2),
              Text(
                unit,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Best',
                  value: best,
                  color: successColor,
                ),
              ),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: _MiniStat(
                  label: 'Avg',
                  value: avg,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: _MiniStat(
                  label: 'Worst',
                  value: worst,
                  color: dangerColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double? value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value != null ? EarbudsQuery.format(value!) : '-',
          style: theme.textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _CaseSelectorBar extends StatelessWidget {
  final MetricGroup group;
  final List<EarbudsMetric> allMetrics;
  const _CaseSelectorBar({required this.group, required this.allMetrics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = AppLocalizations.of(context);
    final es = context.watch<EarbudsState>();

    final selectedCount =
        allMetrics.where((m) => es.isMetricSelected(group, m.key)).length;
    final isAllSelected = selectedCount == allMetrics.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x4,
        AppSpacing.x3,
        AppSpacing.x4,
        AppSpacing.x2,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist_rounded, size: 16, color: cs.primary),
              const SizedBox(width: AppSpacing.x2),
              Text(
                'Cases',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.x2),
              Text(
                '$selectedCount / ${allMetrics.length}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: isAllSelected
                    ? null
                    : () => es.selectAllMetrics(group),
                icon: const Icon(Icons.done_all_rounded, size: 16),
                label: const Text('All'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.x2,
                    vertical: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x2),
          Wrap(
            spacing: AppSpacing.x2,
            runSpacing: AppSpacing.x1,
            children: allMetrics.map((m) {
              final selected = es.isMetricSelected(group, m.key);
              return FilterChip(
                selected: selected,
                label: Text(
                  m.label(s),
                  style: theme.textTheme.labelSmall,
                ),
                onSelected: (_) => es.toggleMetric(group, m.key),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
