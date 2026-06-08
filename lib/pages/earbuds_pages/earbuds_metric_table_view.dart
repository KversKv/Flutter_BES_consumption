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

    final showNoisePinkDetail = widget.group == MetricGroup.scene &&
        metrics.length == 1 &&
        metrics.first.key == 'noisepink';

    return Column(
      children: [
        _CaseSelectorBar(group: widget.group, allMetrics: allMetrics),
        const SizedBox(height: AppSpacing.x2),
        if (!showNoisePinkDetail)
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
                      child: Table(
                        columnWidths: {
                          0: const FlexColumnWidth(2.4),
                          for (var i = 0; i < metrics.length; i++)
                            i + 1: const FixedColumnWidth(116),
                        },
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest
                                  .withValues(alpha: 0.35),
                            ),
                            children: [
                              _HeaderCell(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        s.ebChipInfo,
                                        style: headerStyle?.copyWith(
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                    if (_sortMetricIndex != null) ...[
                                      const SizedBox(width: AppSpacing.x1),
                                      Icon(
                                        _ascending
                                            ? Icons.arrow_upward_rounded
                                            : Icons.arrow_downward_rounded,
                                        size: 14,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              ...metrics.asMap().entries.map((entry) {
                                final i = entry.key;
                                final m = entry.value;
                                final active = _sortMetricIndex == i;
                                return _HeaderCell(
                                  alignEnd: true,
                                  onTap: () {
                                    setState(() {
                                      if (_sortMetricIndex == i) {
                                        _ascending = !_ascending;
                                      } else {
                                        _sortMetricIndex = i;
                                        _ascending = true;
                                      }
                                    });
                                  },
                                  child: _MetricHeader(
                                    title: m.label(s),
                                    unit: unitLabel(m.unit, s),
                                    active: active,
                                  ),
                                );
                              }),
                            ],
                          ),
                          ...chips.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final c = entry.value;
                            final colorIdx = es.selectedIds.indexOf(c.id);
                            final chipColor = palette.dataSeries[
                                colorIdx % palette.dataSeries.length];
                            return TableRow(
                              decoration: BoxDecoration(
                                color: idx.isEven
                                    ? Colors.transparent
                                    : cs.surfaceContainerHighest
                                        .withValues(alpha: 0.22),
                              ),
                              children: [
                                _BodyCell(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: chipColor,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: chipColor
                                                  .withValues(alpha: 0.35),
                                              blurRadius: 6,
                                              spreadRadius: 0.5,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.x3),
                                      Flexible(
                                        child: Text(
                                          'BES${c.id}',
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ...metrics.asMap().entries.map((me) {
                                  final m = me.value;
                                  final stat = metricStats[me.key];
                                  return _BodyCell(
                                    child: _HeatmapCell(
                                      value: m.read(c),
                                      min: stat.min,
                                      max: stat.max,
                                      unit: m.unit,
                                    ),
                                  );
                                }),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showNoisePinkDetail)
          Expanded(child: _NoisePinkDetailPanel(chips: chips)),
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
        horizontal: AppSpacing.x3,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.primary.withValues(alpha: 0.85)),
          const SizedBox(width: AppSpacing.x1),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final Widget child;
  final bool alignEnd;
  final VoidCallback? onTap;
  const _HeaderCell({
    required this.child,
    this.alignEnd = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3,
        vertical: AppSpacing.x3,
      ),
      child: Align(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: child,
      ),
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      child: content,
    );
  }
}

class _BodyCell extends StatelessWidget {
  final Widget child;
  const _BodyCell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3,
        vertical: AppSpacing.x3,
      ),
      child: child,
    );
  }
}

class _MetricHeader extends StatelessWidget {
  final String title;
  final String unit;
  final bool active;
  const _MetricHeader({
    required this.title,
    required this.unit,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          textAlign: TextAlign.right,
          softWrap: true,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: active ? cs.primary : cs.onSurface,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            unit,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
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
    Color? borderColor;
    Color textColor = cs.onSurface;

    if (min != null && max != null && max! > min!) {
      final ratio = (value! - min!) / (max! - min!);
      if (ratio <= 0.05) {
        bgColor = p.success.withValues(alpha: 0.14);
        borderColor = p.success.withValues(alpha: 0.4);
        textColor = p.success;
      } else if (ratio >= 0.95) {
        bgColor = p.danger.withValues(alpha: 0.14);
        borderColor = p.danger.withValues(alpha: 0.4);
        textColor = p.danger;
      } else if (ratio <= 0.25) {
        bgColor = p.success.withValues(alpha: 0.08);
        textColor = p.success.withValues(alpha: 0.92);
      } else if (ratio >= 0.75) {
        bgColor = p.warning.withValues(alpha: 0.1);
        textColor = p.warning;
      }
    }

    return Align(
      alignment: Alignment.centerRight,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: bgColor != null
            ? BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(999),
                border: borderColor != null
                    ? Border.all(color: borderColor, width: 1)
                    : null,
              )
            : null,
        child: Text(
          EarbudsQuery.format(value!),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
            letterSpacing: 0.2,
            color: textColor,
          ),
        ),
      ),
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

class _NoisePinkDetailPanel extends StatelessWidget {
  final List<EarbudsChip> chips;
  const _NoisePinkDetailPanel({required this.chips});

  static String _fmt(double? v) =>
      v != null ? EarbudsQuery.format(v) : '-';

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final palette = AppPalette.of(context);
    final es = context.watch<EarbudsState>();

    final hasAny =
        chips.any((c) => c.scene.noisePinkDetail != null);
    if (!hasAny) {
      return const SizedBox.shrink();
    }

    final headerStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
    );

    final isysValues = chips
        .map((c) => c.scene.noisePinkDetail?.isys)
        .whereType<double>()
        .toList();
    final double? isysMin =
        isysValues.isEmpty ? null : isysValues.reduce((a, b) => a < b ? a : b);
    final double? isysMax =
        isysValues.isEmpty ? null : isysValues.reduce((a, b) => a > b ? a : b);
    final isysColumnColor = cs.primary.withValues(alpha: 0.06);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x4,
        0,
        AppSpacing.x4,
        AppSpacing.x4,
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x4,
                vertical: AppSpacing.x3,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.bolt_rounded, size: 16, color: cs.primary),
                  const SizedBox(width: AppSpacing.x2),
                  Text(
                    s.ebNoisePinkDetailTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  cs.primaryContainer.withValues(alpha: 0.18),
                ),
                columnSpacing: 22,
                headingTextStyle: headerStyle,
                dataRowMinHeight: 44,
                dataRowMaxHeight: 52,
                columns: [
                  DataColumn(label: Text(s.ebChipInfo)),
                  _breakdownHeader('Vsys'),
                  _breakdownHeader('Vcore'),
                  _breakdownHeader('VcoreM'),
                  _breakdownHeader('VcoreL'),
                  _breakdownHeader('Vana'),
                  _breakdownHeader('Vhppa'),
                  DataColumn(
                    label: SizedBox(
                      width: _kBreakdownColWidth,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.x2,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            s.ebNpdIsys,
                            style: headerStyle?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  _breakdownHeader(s.ebNpdIcore),
                  _breakdownHeader('IcoreM'),
                  _breakdownHeader('IcoreL'),
                  _breakdownHeader(s.ebNpdIana),
                  _breakdownHeader(s.ebNpdIhppa),
                  _breakdownHeader(s.ebNpdIsysRemain),
                ],
                rows: chips.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final c = entry.value;
                  final d = c.scene.noisePinkDetail;
                  final colorIdx = es.selectedIds.indexOf(c.id);
                  final chipColor = palette.dataSeries[
                      colorIdx % palette.dataSeries.length];
                  return DataRow(
                    color: WidgetStateProperty.all(
                      idx.isEven
                          ? Colors.transparent
                          : cs.surfaceContainerHighest
                              .withValues(alpha: 0.3),
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
                      DataCell(_DetailValue(text: _fmt(d?.vsys))),
                      DataCell(_DetailValue(text: _fmt(d?.vcore))),
                      DataCell(_DetailValue(text: _fmt(d?.vcoreM))),
                      DataCell(_DetailValue(text: _fmt(d?.vcoreL))),
                      DataCell(_DetailValue(text: _fmt(d?.vana))),
                      DataCell(_DetailValue(text: _fmt(d?.vhppa))),
                      DataCell(_IsysCell(
                        text: _fmt(d?.isys),
                        value: d?.isys,
                        min: isysMin,
                        max: isysMax,
                        columnColor: isysColumnColor,
                      )),
                      DataCell(_DetailValue(text: _fmt(d?.icore))),
                      DataCell(_DetailValue(text: _fmt(d?.icoreM))),
                      DataCell(_DetailValue(text: _fmt(d?.icoreL))),
                      DataCell(_DetailValue(text: _fmt(d?.iana))),
                      DataCell(_DetailValue(text: _fmt(d?.ihppa))),
                      DataCell(_DetailValue(text: _fmt(d?.isysRemain))),
                    ],
                  );
                }).toList(),
              ),
            ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailValue extends StatelessWidget {
  final String text;
  const _DetailValue({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: _kBreakdownColWidth,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

const double _kBreakdownColWidth = 52;

DataColumn _breakdownHeader(String text) {
  return DataColumn(
    label: SizedBox(
      width: _kBreakdownColWidth,
      child: Text(text, textAlign: TextAlign.center),
    ),
  );
}

class _IsysCell extends StatelessWidget {
  final String text;
  final double? value;
  final double? min;
  final double? max;
  final Color columnColor;
  const _IsysCell({
    required this.text,
    required this.value,
    required this.min,
    required this.max,
    required this.columnColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final palette = AppPalette.of(context);

    final hasSpread = value != null &&
        min != null &&
        max != null &&
        (max! - min!).abs() > 1e-9;
    final isBest = hasSpread && value == min;
    final isWorst = hasSpread && value == max;

    Color? badgeColor;
    Color textColor = cs.onSurface;
    Color? borderColor;
    if (isBest) {
      badgeColor = palette.success.withValues(alpha: 0.16);
      textColor = palette.success;
      borderColor = palette.success.withValues(alpha: 0.45);
    } else if (isWorst) {
      badgeColor = palette.danger.withValues(alpha: 0.16);
      textColor = palette.danger;
      borderColor = palette.danger.withValues(alpha: 0.45);
    }

    final valueWidget = Container(
      padding: badgeColor != null
          ? const EdgeInsets.symmetric(horizontal: AppSpacing.x2, vertical: 2)
          : EdgeInsets.zero,
      decoration: badgeColor != null
          ? BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(999),
              border: borderColor != null
                  ? Border.all(color: borderColor)
                  : null,
            )
          : null,
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: (isBest || isWorst) ? FontWeight.w700 : FontWeight.w600,
          color: textColor,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );

    return Container(
      width: _kBreakdownColWidth,
      alignment: Alignment.center,
      color: columnColor,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x1),
      child: valueWidget,
    );
  }
}
