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
              getTooltipItems: (spots) => spots
                  .map((sp) => LineTooltipItem(
                        '${sp.x.toInt()} dBm\n${sp.y.toStringAsFixed(1)} mA',
                        TextStyle(
                          color: theme.colorScheme.onInverseSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
      legend: legend,
    );
  }
}
