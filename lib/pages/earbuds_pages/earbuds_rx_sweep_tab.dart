part of '../earbuds_compare_page.dart';

class _RxSweepTab extends StatelessWidget {
  const _RxSweepTab();

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final es = context.watch<EarbudsState>();
    final chips = es.selectedChips;

    if (chips.isEmpty) {
      return _EmptyHint(hint: s.ebSelectChipsHint);
    }

    final domainChoice = SegmentedButton<bool>(
      segments: [
        ButtonSegment(
          value: false,
          label: Text(s.ebRxVana, style: theme.textTheme.labelSmall),
        ),
        ButtonSegment(
          value: true,
          label: Text(s.ebRxVsys, style: theme.textTheme.labelSmall),
        ),
      ],
      selected: {es.rxUseVsys},
      onSelectionChanged: (set) => es.setRxUseVsys(set.first),
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );

    final viewToggle = _SweepViewToggle(
      mode: es.rxViewMode,
      onChanged: es.setRxViewMode,
    );

    final gainDomain = EarbudsQuery.rxGainDomain(chips, useVsys: es.rxUseVsys);
    if (gainDomain.isEmpty) {
      return Column(
        children: [
          _RxSweepHeader(
            domainChoice: domainChoice,
            viewToggle: viewToggle,
          ),
          Expanded(child: _EmptyHint(hint: s.ebChipNotApplicable)),
        ],
      );
    }

    final palette = AppPalette.of(context).dataSeries;
    final series = <_RxSeries>[];
    var colorIdx = 0;
    for (final c in chips) {
      final rx = es.rxUseVsys ? c.rxVsys : c.rxVana;
      if (rx == null) continue;
      final values = <int, double>{};
      for (final g in gainDomain) {
        final v = rx.values[g];
        if (v != null) values[g] = v;
      }
      if (values.isEmpty) continue;
      final color = palette[colorIdx % palette.length];
      colorIdx++;
      final suffix = (!es.rxUseVsys && rx.vana != null)
          ? ' (Vana=${rx.vana!.toStringAsFixed(2)}V)'
          : '';
      series.add(_RxSeries(
        chipId: c.id,
        color: color,
        suffix: suffix,
        values: values,
      ));
    }

    if (series.isEmpty) {
      return Column(
        children: [
          _RxSweepHeader(
            domainChoice: domainChoice,
            viewToggle: viewToggle,
          ),
          Expanded(child: _EmptyHint(hint: s.ebChipNotApplicable)),
        ],
      );
    }

    final header = _RxSweepHeader(
      domainChoice: domainChoice,
      viewToggle: viewToggle,
    );

    if (es.rxViewMode == EarbudsSweepViewMode.table) {
      return _RxSweepTableView(
        series: series,
        gainDomain: gainDomain,
        header: header,
      );
    }

    final lines = <LineChartBarData>[];
    final legend = <_LegendItem>[];
    final barMeta = <_RxBarMeta>[];
    for (final ser in series) {
      final spots = <FlSpot>[];
      for (final g in gainDomain) {
        final v = ser.values[g];
        if (v != null) spots.add(FlSpot(g.toDouble(), v));
      }
      lines.add(LineChartBarData(
        spots: spots,
        color: ser.color,
        barWidth: 2.5,
        dotData: const FlDotData(show: true),
      ));
      legend.add(_LegendItem(
        color: ser.color,
        text: 'BES${ser.chipId}${ser.suffix}',
      ));
      barMeta.add(_RxBarMeta(chipId: ser.chipId, suffix: ser.suffix));
    }

    var maxY = 0.0;
    for (final b in lines) {
      for (final sp in b.spots) {
        if (sp.y > maxY) maxY = sp.y;
      }
    }
    if (maxY == 0) maxY = 1;

    return _CurveTabShell(
      header: header,
      chart: LineChart(
        LineChartData(
          minX: gainDomain.first.toDouble(),
          maxX: gainDomain.last.toDouble(),
          minY: 0,
          maxY: maxY * 1.15,
          lineBarsData: lines,
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              axisNameWidget: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  s.ebChartYaxisMa,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              axisNameSize: 20,
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (v, _) => Text(
                  v.toStringAsFixed(1),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              axisNameWidget: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  s.ebChartXaxisGain,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              axisNameSize: 20,
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (v, _) => Text(
                  v.toStringAsFixed(0),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              maxContentWidth: 320,
              tooltipHorizontalAlignment: FLHorizontalAlignment.left,
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              getTooltipItems: (spots) {
                final baseStyle = TextStyle(
                  color: theme.colorScheme.onInverseSurface,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                  fontFamilyFallback: const [
                    'Menlo',
                    'Consolas',
                    'Courier New',
                  ],
                  height: 1.25,
                );
                final maxIdLen = spots.fold<int>(0, (acc, sp) {
                  final idx = sp.barIndex;
                  if (idx < 0 || idx >= barMeta.length) return acc;
                  final len = barMeta[idx].chipId.length;
                  return len > acc ? len : acc;
                });
                return List<LineTooltipItem>.generate(spots.length, (i) {
                  final sp = spots[i];
                  final idx = sp.barIndex;
                  final meta = (idx >= 0 && idx < barMeta.length)
                      ? barMeta[idx]
                      : null;
                  final idPart = meta == null
                      ? ''
                      : 'BES${meta.chipId.padRight(maxIdLen)}';
                  final suffix = meta?.suffix ?? '';
                  final body =
                      '$idPart:${sp.y.toStringAsFixed(2)}mA$suffix';
                  final text = i == 0
                      ? '${s.ebChartXaxisGain}: ${sp.x.toInt()}\n$body'
                      : body;
                  return LineTooltipItem(
                    text,
                    baseStyle,
                    textAlign: TextAlign.left,
                  );
                });
              },
            ),
          ),
        ),
      ),
      legend: legend,
    );
  }
}

class _RxSweepHeader extends StatelessWidget {
  final Widget domainChoice;
  final Widget viewToggle;
  const _RxSweepHeader({
    required this.domainChoice,
    required this.viewToggle,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x4,
        AppSpacing.x3,
        AppSpacing.x4,
        AppSpacing.x1,
      ),
      child: Row(
        children: [
          Text('${s.ebRxDomain}: ', style: theme.textTheme.bodyMedium),
          domainChoice,
          const Spacer(),
          viewToggle,
        ],
      ),
    );
  }
}

class _RxSweepTableView extends StatelessWidget {
  final List<_RxSeries> series;
  final List<int> gainDomain;
  final Widget header;
  const _RxSweepTableView({
    required this.series,
    required this.gainDomain,
    required this.header,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final headerStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
    );

    return Column(
      children: [
        header,
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x4,
              AppSpacing.x2,
              AppSpacing.x4,
              AppSpacing.x4,
            ),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      cs.primaryContainer.withValues(alpha: 0.18),
                    ),
                    columnSpacing: 22,
                    headingTextStyle: headerStyle,
                    headingRowHeight: 56,
                    dataRowMinHeight: 44,
                    dataRowMaxHeight: 52,
                    columns: [
                      DataColumn(label: Text(s.ebChartXaxisGain)),
                      ...series.map(
                        (ser) => DataColumn(
                          numeric: true,
                          label: SizedBox(
                            width: 120,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: ser.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.x1),
                                    Flexible(
                                      child: Text(
                                        'BES${ser.chipId}',
                                        textAlign: TextAlign.right,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (ser.suffix.isNotEmpty)
                                  Text(
                                    ser.suffix.trim(),
                                    textAlign: TextAlign.right,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    rows: List<DataRow>.generate(gainDomain.length, (idx) {
                      final g = gainDomain[idx];
                      return DataRow(
                        color: WidgetStateProperty.all(
                          idx.isEven
                              ? Colors.transparent
                              : cs.surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                        ),
                        cells: [
                          DataCell(
                            Text(
                              '$g',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          ...series.map((ser) {
                            final v = ser.values[g];
                            return DataCell(
                              SizedBox(
                                width: 120,
                                child: Text(
                                  v == null ? '-' : v.toStringAsFixed(2),
                                  textAlign: TextAlign.right,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RxSeries {
  final String chipId;
  final Color color;
  final String suffix;
  final Map<int, double> values;
  const _RxSeries({
    required this.chipId,
    required this.color,
    required this.suffix,
    required this.values,
  });
}

class _RxBarMeta {
  final String chipId;
  final String suffix;
  const _RxBarMeta({required this.chipId, required this.suffix});
}
