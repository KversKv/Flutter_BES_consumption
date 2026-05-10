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
    final lines = <LineChartBarData>[];
    final legend = <_LegendItem>[];
    final barMeta = <_TxBarMeta>[];
    var colorIdx = 0;

    for (final c in chips) {
      for (final variant in c.txSweep) {
        final spots = <FlSpot>[];
        for (final dbm in dbmDomain) {
          final v = variant.values[dbm];
          if (v != null) spots.add(FlSpot(dbm.toDouble(), v));
        }
        if (spots.isEmpty) continue;
        final color = palette[colorIdx % palette.length];
        colorIdx++;
        lines.add(
          LineChartBarData(
            spots: spots,
            color: color,
            barWidth: 2.5,
            isCurved: false,
            dotData: const FlDotData(show: true),
          ),
        );
        legend.add(_LegendItem(
          color: color,
          text: 'BES${c.id} · ${variant.label}',
        ));
        barMeta.add(_TxBarMeta(chipId: c.id, variantLabel: variant.label));
      }
    }

    if (lines.isEmpty) {
      return _EmptyHint(hint: s.ebChipNotApplicable);
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
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x4,
          AppSpacing.x3,
          AppSpacing.x4,
          AppSpacing.x1,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                s.ebChartXaxisDbm,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              s.ebChartYaxisMa,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
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

class _TxBarMeta {
  final String chipId;
  final String variantLabel;
  const _TxBarMeta({required this.chipId, required this.variantLabel});
}
