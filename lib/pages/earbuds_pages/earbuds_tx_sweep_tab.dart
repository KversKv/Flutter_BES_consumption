part of '../earbuds_compare_page.dart';

class _TxSweepTab extends StatelessWidget {
  const _TxSweepTab();

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final es = context.watch<EarbudsState>();
    final chips = es.selectedChips;

    if (chips.isEmpty) {
      return _EmptyHint(hint: s.ebSelectChipsHint);
    }

    final dbmDomain = EarbudsQuery.txDbmDomain(chips);
    if (dbmDomain.isEmpty) {
      return _EmptyHint(hint: s.ebChipNotApplicable);
    }

    final palette = AppPalette.of(context).dataSeries;
    final series = <_TxSeries>[];
    var colorIdx = 0;
    for (final c in chips) {
      for (final variant in c.txSweep) {
        final values = <int, double>{};
        for (final dbm in dbmDomain) {
          final v = variant.values[dbm];
          if (v != null) values[dbm] = v;
        }
        if (values.isEmpty) continue;
        series.add(_TxSeries(
          chipId: c.id,
          variantLabel: variant.label,
          color: palette[colorIdx % palette.length],
          values: values,
        ));
        colorIdx++;
      }
    }

    if (series.isEmpty) {
      return _EmptyHint(hint: s.ebChipNotApplicable);
    }

    final viewToggle = _SweepViewToggle(
      mode: es.txViewMode,
      onChanged: es.setTxViewMode,
    );

    if (es.txViewMode == EarbudsSweepViewMode.table) {
      return _TxSweepTableView(
        series: series,
        dbmDomain: dbmDomain,
        header: _TxSweepHeader(viewToggle: viewToggle),
      );
    }

    final lines = <LineChartBarData>[];
    final legend = <_LegendItem>[];
    final barMeta = <_TxBarMeta>[];
    for (final ser in series) {
      final spots = <FlSpot>[];
      for (final dbm in dbmDomain) {
        final v = ser.values[dbm];
        if (v != null) spots.add(FlSpot(dbm.toDouble(), v));
      }
      lines.add(
        LineChartBarData(
          spots: spots,
          color: ser.color,
          barWidth: 2.5,
          isCurved: false,
          dotData: const FlDotData(show: true),
        ),
      );
      legend.add(_LegendItem(
        color: ser.color,
        text: 'BES${ser.chipId} · ${ser.variantLabel}',
      ));
      barMeta.add(
        _TxBarMeta(chipId: ser.chipId, variantLabel: ser.variantLabel),
      );
    }

    final minX = dbmDomain.first.toDouble();
    final maxX = dbmDomain.last.toDouble();
    var maxY = 0.0;
    for (final b in lines) {
      for (final sp in b.spots) {
        if (sp.y > maxY) maxY = sp.y;
      }
    }
    if (maxY == 0) maxY = 1;

    return _CurveTabShell(
      header: _TxSweepHeader(viewToggle: viewToggle),
      chart: LineChart(
        LineChartData(
          minX: minX,
          maxX: maxX,
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
                  v.toStringAsFixed(0),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              axisNameWidget: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  s.ebChartXaxisDbm,
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
                final tooltipColor = theme.colorScheme.onInverseSurface;
                final baseStyle = TextStyle(
                  color: tooltipColor,
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
                  final suffix = meta != null &&
                          meta.variantLabel.toUpperCase().startsWith('VPA=')
                      ? ' (${meta.variantLabel})'
                      : '';
                  final body =
                      '$idPart:${sp.y.toStringAsFixed(1)}mA$suffix';
                  final text = i == 0
                      ? 'TX Power: ${sp.x.toInt()}dBm\n$body'
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

class _TxSweepHeader extends StatelessWidget {
  final Widget viewToggle;
  const _TxSweepHeader({required this.viewToggle});

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
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Text(
              s.ebTabTx,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: viewToggle,
          ),
        ],
      ),
    );
  }
}

class _TxSweepTableView extends StatelessWidget {
  final List<_TxSeries> series;
  final List<int> dbmDomain;
  final Widget header;
  const _TxSweepTableView({
    required this.series,
    required this.dbmDomain,
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
                      DataColumn(label: Text(s.ebChartXaxisDbm)),
                      ...series.map(
                        (ser) => DataColumn(
                          numeric: true,
                          label: SizedBox(
                            width: 108,
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
                                Text(
                                  '(${ser.variantLabel})',
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
                    rows: List<DataRow>.generate(dbmDomain.length, (idx) {
                      final dbm = dbmDomain[idx];
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
                              '${dbm}dBm',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          ...series.map((ser) {
                            final v = ser.values[dbm];
                            return DataCell(
                              SizedBox(
                                width: 108,
                                child: Text(
                                  v == null ? '-' : v.toStringAsFixed(1),
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

class _TxSeries {
  final String chipId;
  final String variantLabel;
  final Color color;
  final Map<int, double> values;
  const _TxSeries({
    required this.chipId,
    required this.variantLabel,
    required this.color,
    required this.values,
  });
}

class _TxBarMeta {
  final String chipId;
  final String variantLabel;
  const _TxBarMeta({required this.chipId, required this.variantLabel});
}
