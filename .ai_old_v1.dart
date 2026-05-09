import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/earbuds/earbuds_metrics.dart';
import '../l10n/app_localizations.dart';
import '../models/earbuds.dart';
import '../services/earbuds_query.dart';
import '../state/earbuds_state.dart';

/// Earbuds 芯片功耗综合对比页。
///
/// 采用 `TabBar` 组织 7 个数据维度：
/// - Earbuds Scene / BT & BLE / Sleep / MCU Run / Audio PA → DataTable
///   （行 = 芯片，列 = 该分组下全部指标，列头点击切换排序）
/// - TX Sweep / RX Sweep → 多折线 LineChart（横轴为 dBm / Gain）
///
/// 所有数据来自 `kAllChips` (via `EarbudsState`)；本页不负责持久化或 IO。
class EarbudsComparePage extends StatelessWidget {
  const EarbudsComparePage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return DefaultTabController(
      length: 7,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.ebTitle),
          centerTitle: true,
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: s.ebTabScene),
              Tab(text: s.ebTabBt),
              Tab(text: s.ebTabSleep),
              Tab(text: s.ebTabRun),
              Tab(text: s.ebTabTx),
              Tab(text: s.ebTabRx),
              Tab(text: s.ebTabPa),
            ],
            onTap: (i) {
              final es = context.read<EarbudsState>();
              const groups = [
                MetricGroup.scene,
                MetricGroup.bt,
                MetricGroup.sleep,
                MetricGroup.mcuRun,
                null, // tx
                null, // rx
                MetricGroup.pa,
              ];
              final g = groups[i];
              if (g != null) es.setGroup(g);
            },
          ),
        ),
        body: const _PageBody(),
      ),
    );
  }
}

class _PageBody extends StatelessWidget {
  const _PageBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _FilterBar(),
        const Divider(height: 1),
        const _ChipSelector(),
        const Divider(height: 1),
        Expanded(
          child: TabBarView(
            children: [
              _MetricTableTab(group: MetricGroup.scene),
              _MetricTableTab(group: MetricGroup.bt),
              _MetricTableTab(group: MetricGroup.sleep),
              _MetricTableTab(group: MetricGroup.mcuRun),
              const _TxSweepTab(),
              const _RxSweepTab(),
              _MetricTableTab(group: MetricGroup.pa),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Filter bar (mass-prod / clear)
// =============================================================================
class _FilterBar extends StatelessWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final es = context.watch<EarbudsState>();
    final selectedCount = es.selectedIds.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          FilterChip(
            selected: es.massProductionOnly,
            label: Text(s.ebFilterMassOnly),
            onSelected: (_) => es.toggleMassProductionOnly(),
          ),
          if (selectedCount > 0)
            ActionChip(
              avatar: const Icon(Icons.clear, size: 18),
              label: Text(s.ebSelectedCount(selectedCount)),
              onPressed: () => es.clearSelection(),
            )
          else
            Text(
              s.ebSelectChipsHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// Chip selector (chip pool → click to toggle)
// =============================================================================
class _ChipSelector extends StatelessWidget {
  const _ChipSelector();

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final es = context.watch<EarbudsState>();
    final chips = es.visibleChips;

    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final c = chips[i];
          final selected = es.isSelected(c.id);
          return FilterChip(
            selected: selected,
            label: Text(c.id),
            onSelected: (_) {
              final ok = es.toggleSelected(c.id);
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(s.ebSelectionFull),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}

// =============================================================================
// Metric table tab (Scene / BT / Sleep / MCU Run / PA)
// 以表格呈现：行 = 芯片，列 = 当前分组下全部指标。
// 点击列头切换排序列 + 方向；N/A 始终沉底。
// =============================================================================
class _MetricTableTab extends StatefulWidget {
  final MetricGroup group;
  const _MetricTableTab({required this.group});

  @override
  State<_MetricTableTab> createState() => _MetricTableTabState();
}

class _MetricTableTabState extends State<_MetricTableTab> {
  int? _sortMetricIndex;
  bool _ascending = true;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final es = context.watch<EarbudsState>();
    final metrics = metricsOf(widget.group);
    var chips = List<EarbudsChip>.of(es.selectedChips);

    if (chips.isEmpty) {
      return _EmptyHint(hint: s.ebSelectChipsHint);
    }

    if (_sortMetricIndex != null) {
      final metric = metrics[_sortMetricIndex!];
      chips = EarbudsQuery.sortByMetric(chips, metric, ascending: _ascending);
    }

    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          sortColumnIndex:
              _sortMetricIndex == null ? null : _sortMetricIndex! + 1,
          sortAscending: _ascending,
          headingTextStyle: headerStyle,
          columnSpacing: 24,
          columns: [
            DataColumn(label: Text(s.chipId)),
            ...List.generate(metrics.length, (i) {
              final m = metrics[i];
              return DataColumn(
                numeric: true,
                label: Tooltip(
                  message: m.label(s),
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
          rows: chips.map((c) {
            return DataRow(
              cells: [
                DataCell(Text(
                  c.id,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                )),
                ...metrics.map((m) {
                  final v = m.read(c);
                  return DataCell(Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      v == null
                          ? s.ebChipNotApplicable
                          : EarbudsQuery.format(v),
                    ),
                  ));
                }),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// =============================================================================
// TX Sweep tab
// =============================================================================
class _TxSweepTab extends StatelessWidget {
  const _TxSweepTab();

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final es = context.watch<EarbudsState>();
    final chips = es.selectedChips;

    if (chips.isEmpty) {
      return _EmptyHint(hint: s.ebSelectChipsHint);
    }

    final dbmDomain = EarbudsQuery.txDbmDomain(chips);
    if (dbmDomain.isEmpty) {
      return _EmptyHint(hint: s.ebChipNotApplicable);
    }

    final palette = _palette(context);
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
          text: '${c.id} · ${variant.label}',
        ));
      }
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
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                s.ebChartXaxisDbm,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              s.ebChartYaxisMa,
              style: Theme.of(context).textTheme.bodySmall,
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
                  style: Theme.of(context).textTheme.bodySmall,
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
                  style: Theme.of(context).textTheme.bodySmall,
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
                          color: Theme.of(context).colorScheme.onInverseSurface,
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

// =============================================================================
// RX Sweep tab
// =============================================================================
class _RxSweepTab extends StatelessWidget {
  const _RxSweepTab();

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final es = context.watch<EarbudsState>();
    final chips = es.selectedChips;

    if (chips.isEmpty) {
      return _EmptyHint(hint: s.ebSelectChipsHint);
    }

    final domainChoice = SegmentedButton<bool>(
      segments: [
        ButtonSegment(value: false, label: Text(s.ebRxVana)),
        ButtonSegment(value: true, label: Text(s.ebRxVsys)),
      ],
      selected: {es.rxUseVsys},
      onSelectionChanged: (set) => es.setRxUseVsys(set.first),
    );

    final gainDomain = EarbudsQuery.rxGainDomain(chips, useVsys: es.rxUseVsys);
    if (gainDomain.isEmpty) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [Text('${s.ebRxDomain}: '), domainChoice]),
          ),
          Expanded(child: _EmptyHint(hint: s.ebChipNotApplicable)),
        ],
      );
    }

    final palette = _palette(context);
    final lines = <LineChartBarData>[];
    final legend = <_LegendItem>[];
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
      legend.add(_LegendItem(color: color, text: '${c.id}$suffix'));
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
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
        child: Row(
          children: [
            Text('${s.ebRxDomain}: '),
            domainChoice,
            const Spacer(),
            Text(
              s.ebChartYaxisMa,
              style: Theme.of(context).textTheme.bodySmall,
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
                  style: Theme.of(context).textTheme.bodySmall,
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
                  style: Theme.of(context).textTheme.bodySmall,
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
                        '${s.ebChartXaxisGain}: ${sp.x.toInt()}\n${sp.y.toStringAsFixed(2)} mA',
                        TextStyle(
                          color: Theme.of(context).colorScheme.onInverseSurface,
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

// =============================================================================
// Shared widgets
// =============================================================================

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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
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
                    Text(e.text, style: Theme.of(context).textTheme.bodySmall),
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

class _EmptyHint extends StatelessWidget {
  final String hint;
  const _EmptyHint({required this.hint});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        hint,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).hintColor,
            ),
      ),
    );
  }
}

List<Color> _palette(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return [
    cs.primary,
    cs.tertiary,
    cs.secondary,
    cs.error,
    Colors.teal,
    Colors.orange,
    Colors.purple,
    Colors.blueGrey,
  ];
}
