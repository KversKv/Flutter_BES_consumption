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

    final gainDomain = EarbudsQuery.rxGainDomain(chips, useVsys: es.rxUseVsys);
    if (gainDomain.isEmpty) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.x3),
            child: Row(
              children: [Text('${s.ebRxDomain}: '), domainChoice],
            ),
          ),
          Expanded(child: _EmptyHint(hint: s.ebChipNotApplicable)),
        ],
      );
    }

    final palette = AppPalette.of(context).dataSeries;
    final lines = <LineChartBarData>[];
    final legend = <_LegendItem>[];
    final barMeta = <_RxBarMeta>[];
    var colorIdx = 0;

    for (final c in chips) {
      final rx = es.rxUseVsys ? c.rxVsys : c.rxVana;
      if (rx == null) continue;
      final spots = <FlSpot>[];
      for (final g in gainDomain) {
        final v = rx.values[g];
        if (v != null) spots.add(FlSpot(g.toDouble(), v));
      }
      if (spots.isEmpty) continue;
      final color = palette[colorIdx % palette.length];
      colorIdx++;
      lines.add(LineChartBarData(
        spots: spots,
        color: color,
        barWidth: 2.5,
        dotData: const FlDotData(show: true),
      ));
      final suffix = (!es.rxUseVsys && rx.vana != null)
          ? ' (Vana=${rx.vana!.toStringAsFixed(2)}V)'
          : '';
      legend.add(_LegendItem(color: color, text: 'BES${c.id}$suffix'));
      barMeta.add(_RxBarMeta(chipId: c.id, suffix: suffix));
    }

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
            Text('${s.ebRxDomain}: ', style: theme.textTheme.bodyMedium),
            domainChoice,
            const Spacer(),
            Text(
              s.ebChartYaxisMa,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
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

class _RxBarMeta {
  final String chipId;
  final String suffix;
  const _RxBarMeta({required this.chipId, required this.suffix});
}
