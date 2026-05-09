import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/earbuds/earbuds_metrics.dart';
import '../l10n/app_localizations.dart';
import '../models/earbuds.dart';
import '../services/earbuds_query.dart';
import '../state/earbuds_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class EarbudsComparePage extends StatelessWidget {
  const EarbudsComparePage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return DefaultTabController(
      length: 7,
      child: Scaffold(
        body: Column(
          children: [
            _Header(title: s.ebTitle),
            const Expanded(child: _PageBody()),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  const _Header({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x6, AppSpacing.x4, AppSpacing.x6, AppSpacing.x2,
            ),
            child: Row(
              children: [
                Icon(Icons.memory_rounded, color: cs.primary, size: 22),
                const SizedBox(width: AppSpacing.x2),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: theme.textTheme.labelLarge,
            indicatorSize: TabBarIndicatorSize.label,
            dividerHeight: 0,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
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
                null,
                null,
                MetricGroup.pa,
              ];
              final g = groups[i];
              if (g != null) es.setGroup(g);
            },
          ),
        ],
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
        const _ToolBar(),
        Expanded(
          child: TabBarView(
            children: [
              const _SceneTab(),
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

class _ToolBar extends StatelessWidget {
  const _ToolBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = AppLocalizations.of(context);
    final es = context.watch<EarbudsState>();
    final chips = es.visibleChips;
    final selectedCount = es.selectedIds.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x4, AppSpacing.x3, AppSpacing.x4, AppSpacing.x3,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FilterChip(
                selected: es.massProductionOnly,
                label: Text(s.ebFilterMassOnly),
                avatar: es.massProductionOnly
                    ? const Icon(Icons.check_rounded, size: 16)
                    : const Icon(Icons.filter_alt_outlined, size: 16),
                onSelected: (_) => es.toggleMassProductionOnly(),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: AppSpacing.x2),
              if (selectedCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.x2, vertical: AppSpacing.x1,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    '$selectedCount / ${EarbudsState.kMaxSelected}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.x2),
                InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  onTap: () => es.clearSelection(),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.x1),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.clear_all_rounded,
                            size: 16, color: cs.onSurfaceVariant),
                        const SizedBox(width: 2),
                        Text(
                          s.ebSelectedCount(selectedCount),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else
                Text(
                  s.ebSelectChipsHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x2),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: chips.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.x2),
              itemBuilder: (context, i) {
                final c = chips[i];
                final selected = es.isSelected(c.id);
                return _ChipTag(
                  label: c.id,
                  selected: selected,
                  onTap: () {
                    final ok = es.toggleSelected(c.id);
                    if (!ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(s.ebSelectionFull),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipTag extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ChipTag({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Material(
      color: selected ? cs.primaryContainer : cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x3, vertical: AppSpacing.x2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: selected
                  ? cs.primary.withValues(alpha: 0.6)
                  : cs.outlineVariant.withValues(alpha: 0.5),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check_circle_rounded,
                    size: 14, color: cs.primary),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected ? cs.primary : cs.onSurface,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Scene tab
// =============================================================================
class _SceneTab extends StatelessWidget {
  const _SceneTab();

  @override
  Widget build(BuildContext context) {
    final es = context.watch<EarbudsState>();
    if (es.sceneViewMode == EarbudsSceneViewMode.singleChip) {
      return const _SingleChipSceneView();
    }
    return const _ComparisonSceneView();
  }
}

class _ComparisonSceneView extends StatelessWidget {
  const _ComparisonSceneView();

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final es = context.watch<EarbudsState>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x4, AppSpacing.x3, AppSpacing.x4, 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SegmentedButton<EarbudsSceneViewMode>(
                segments: [
                  ButtonSegment(
                    value: EarbudsSceneViewMode.singleChip,
                    label: Text(s.ebViewSingle),
                    icon: const Icon(Icons.view_agenda_outlined, size: 18),
                  ),
                  ButtonSegment(
                    value: EarbudsSceneViewMode.comparison,
                    label: Text(s.ebViewCompare),
                    icon: const Icon(Icons.compare_arrows, size: 18),
                  ),
                ],
                selected: {es.sceneViewMode},
                onSelectionChanged: (set) => es.setSceneViewMode(set.first),
              ),
            ],
          ),
        ),
        Expanded(child: _MetricTableTab(group: MetricGroup.scene)),
      ],
    );
  }
}

class _SingleChipSceneView extends StatelessWidget {
  const _SingleChipSceneView();

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final es = context.watch<EarbudsState>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final chips = es.visibleChips;

    if (chips.isEmpty) {
      return _EmptyHint(hint: s.ebSelectChipsHint);
    }

    final chip = es.focusedChip ?? chips.first;
    final scene = chip.scene;
    final cfg = scene.testConfig;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SceneViewModeBar(chipId: chip.id, chips: chips),
          const SizedBox(height: AppSpacing.x4),
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.x3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.primaryContainer.withValues(alpha: 0.3),
                  cs.primaryContainer.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Text(
              s.ebSingleDac,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          _SceneMetaTable(chip: chip, cfg: cfg),
          const SizedBox(height: AppSpacing.x4),
          _SceneDataTable(chip: chip, scene: scene),
        ],
      ),
    );
  }
}

class _SceneViewModeBar extends StatelessWidget {
  final String chipId;
  final List<EarbudsChip> chips;
  const _SceneViewModeBar({required this.chipId, required this.chips});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final es = context.read<EarbudsState>();

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: chipId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: s.ebTestObject,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x3, vertical: AppSpacing.x2,
              ),
            ),
            items: chips.map((c) {
              return DropdownMenuItem(
                value: c.id,
                child: Text('BES${c.id}'),
              );
            }).toList(),
            onChanged: (id) {
              if (id != null) es.setFocusedChip(id);
            },
          ),
        ),
        const SizedBox(width: AppSpacing.x3),
        SegmentedButton<EarbudsSceneViewMode>(
          segments: [
            ButtonSegment(
              value: EarbudsSceneViewMode.singleChip,
              label: Text(s.ebViewSingle),
              icon: const Icon(Icons.view_agenda_outlined, size: 18),
            ),
            ButtonSegment(
              value: EarbudsSceneViewMode.comparison,
              label: Text(s.ebViewCompare),
              icon: const Icon(Icons.compare_arrows, size: 18),
            ),
          ],
          selected: {es.sceneViewMode},
          onSelectionChanged: (set) => es.setSceneViewMode(set.first),
        ),
      ],
    );
  }
}

class _SceneMetaTable extends StatelessWidget {
  final EarbudsChip chip;
  final SceneTestConfig? cfg;
  const _SceneMetaTable({required this.chip, required this.cfg});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final rows = <_MetaRow>[
      _MetaRow(s.ebTestObject, 'BES${chip.id}'),
      if (cfg?.softwareVersion != null)
        _MetaRow(s.ebSoftwareVersion, cfg!.softwareVersion!),
      _MetaRow(
        s.ebModuleVoltage,
        cfg?.moduleVoltageDetail ??
            (cfg?.vbat != null ? 'vbat=${cfg!.vbat}v' : 'vbat=3.8v'),
      ),
      if (cfg?.outputLoad != null) _MetaRow(s.ebOutputLoad, cfg!.outputLoad!),
      if (cfg?.audioOutputPower != null)
        _MetaRow(s.ebAudioOutputPower, cfg!.audioOutputPower!),
      if (cfg?.testPhone != null) _MetaRow(s.ebTestPhone, cfg!.testPhone!),
      if (cfg?.audioEncoder != null)
        _MetaRow(s.ebAudioEncoder, cfg!.audioEncoder!),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings_outlined, size: 16, color: cs.primary),
                const SizedBox(width: AppSpacing.x2),
                Text(
                  s.ebTestObject,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: cs.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x3),
            ...rows.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.x1),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 140,
                        child: Text(
                          r.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          r.value,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _MetaRow {
  final String label;
  final String value;
  const _MetaRow(this.label, this.value);
}

class _SceneDataTable extends StatelessWidget {
  final EarbudsChip chip;
  final EarbudsScene scene;
  const _SceneDataTable({required this.chip, required this.scene});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final hasAncOn = scene.hotelCalAncOn != null ||
        scene.muteAncOn != null ||
        scene.noisePinkAncOn != null ||
        scene.k1HzAncOn != null ||
        scene.callAncOn != null ||
        scene.powerOffAncOn != null ||
        scene.sniffPageAncOn != null;

    final headerBg = cs.primaryContainer.withValues(alpha: 0.2);
    final headerStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final cellStyle = theme.textTheme.bodyMedium;
    final groupStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: cs.primary,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(headerBg),
          columnSpacing: 24,
          headingTextStyle: headerStyle,
          dataTextStyle: cellStyle,
          dataRowMinHeight: 40,
          dataRowMaxHeight: 48,
          columns: [
            DataColumn(label: Text(s.ebProject)),
            DataColumn(label: Text(s.ebTestMusic)),
            DataColumn(label: Text(s.ebVolumeReq)),
            DataColumn(label: Text(s.ebAncOff), numeric: true),
            if (hasAncOn)
              DataColumn(label: Text(s.ebAncOn), numeric: true),
          ],
          rows: [
            _buildRow(s.ebTestCase1, s.ebHotelCal, s.ebVol1325,
                scene.hotelCal, scene.hotelCalAncOn, hasAncOn, groupStyle, cellStyle),
            _buildRow(null, s.ebPlay1Khz, s.ebVol2525,
                scene.k1Hz, scene.k1HzAncOn, hasAncOn, groupStyle, cellStyle),
            _buildRow(null, s.ebMuteCurrent, s.ebVol025,
                scene.mute, scene.muteAncOn, hasAncOn, groupStyle, cellStyle),
            _buildRow(null, s.ebPinkNoise, s.ebVol1325,
                scene.noisePink, scene.noisePinkAncOn, hasAncOn, groupStyle, cellStyle),
            _buildRow(s.ebTestCase2, s.ebPhoneCall, s.ebVol10086,
                scene.call, scene.callAncOn, hasAncOn, groupStyle, cellStyle),
            _buildRow(s.ebTestCase3, s.ebPowerOffCurrent, s.ebShutdown,
                scene.powerOff, scene.powerOffAncOn, hasAncOn, groupStyle, cellStyle),
            _buildRow(null, s.ebStandby, s.ebConnectNoBehavior,
                scene.sniffPage, scene.sniffPageAncOn, hasAncOn, groupStyle, cellStyle),
          ],
        ),
      ),
    );
  }

  DataRow _buildRow(
    String? group,
    String music,
    String volume,
    double? ancOff,
    double? ancOn,
    bool hasAncOn,
    TextStyle? groupStyle,
    TextStyle? cellStyle,
  ) {
    return DataRow(
      cells: [
        DataCell(Text(group ?? '', style: groupStyle)),
        DataCell(Text(music)),
        DataCell(Text(volume)),
        DataCell(Align(
          alignment: Alignment.centerRight,
          child: Text(
            ancOff != null ? EarbudsQuery.format(ancOff) : '-',
            style: cellStyle?.copyWith(fontWeight: FontWeight.w600),
          ),
        )),
        if (hasAncOn)
          DataCell(Align(
            alignment: Alignment.centerRight,
            child: Text(
              ancOn != null ? EarbudsQuery.format(ancOn) : '-',
              style: cellStyle?.copyWith(fontWeight: FontWeight.w600),
            ),
          )),
      ],
    );
  }
}

// =============================================================================
// Metric table tab
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
    final cs = theme.colorScheme;
    final headerStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.x4),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSpacing.x4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              sortColumnIndex:
                  _sortMetricIndex == null ? null : _sortMetricIndex! + 1,
              sortAscending: _ascending,
              headingTextStyle: headerStyle,
              headingRowColor: WidgetStateProperty.all(
                cs.primaryContainer.withValues(alpha: 0.15),
              ),
              columnSpacing: 24,
              dataRowMinHeight: 40,
              dataRowMaxHeight: 48,
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
              rows: chips.asMap().entries.map((entry) {
                final idx = entry.key;
                final c = entry.value;
                return DataRow(
                  color: WidgetStateProperty.all(
                    idx.isEven
                        ? Colors.transparent
                        : cs.surfaceContainerHighest.withValues(alpha: 0.3),
                  ),
                  cells: [
                    DataCell(Text(
                      c.id,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    )),
                    ...metrics.map((m) {
                      final v = m.read(c);
                      return DataCell(Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          v == null
                              ? s.ebChipNotApplicable
                              : EarbudsQuery.format(v),
                          style: TextStyle(
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: v == null ? cs.onSurfaceVariant : null,
                          ),
                        ),
                      ));
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
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
            isCurved: true,
            curveSmoothness: 0.2,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 3,
                color: color,
                strokeWidth: 1.5,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.06),
            ),
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

    return _ChartShell(
      titleIcon: Icons.upload_rounded,
      title: s.ebChartXaxisDbm,
      subtitle: s.ebChartYaxisMa,
      chart: _buildLineChart(
        context,
        lines: lines,
        minX: minX,
        maxX: maxX,
        maxY: maxY * 1.15,
        xFormatter: (v) => v.toStringAsFixed(0),
        yFormatter: (v) => v.toStringAsFixed(0),
        tooltipFormatter: (sp) => '${sp.x.toInt()} dBm\n${sp.y.toStringAsFixed(1)} mA',
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
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.x4),
        child: Column(
          children: [
            Row(children: [Text('${s.ebRxDomain}: '), domainChoice]),
            const Expanded(child: _EmptyHint(hint: '')),
          ],
        ),
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
        isCurved: true,
        curveSmoothness: 0.2,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
            radius: 3,
            color: color,
            strokeWidth: 1.5,
            strokeColor: Colors.white,
          ),
        ),
        belowBarData: BarAreaData(
          show: true,
          color: color.withValues(alpha: 0.06),
        ),
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

    return _ChartShell(
      titleIcon: Icons.download_rounded,
      title: s.ebRxDomain,
      subtitle: s.ebChartYaxisMa,
      headerTrailing: domainChoice,
      chart: _buildLineChart(
        context,
        lines: lines,
        minX: gainDomain.first.toDouble(),
        maxX: gainDomain.last.toDouble(),
        maxY: maxY * 1.15,
        xFormatter: (v) => v.toStringAsFixed(0),
        yFormatter: (v) => v.toStringAsFixed(1),
        tooltipFormatter: (sp) =>
            '${s.ebChartXaxisGain}: ${sp.x.toInt()}\n${sp.y.toStringAsFixed(2)} mA',
      ),
      legend: legend,
    );
  }
}

// =============================================================================
// Shared chart builder
// =============================================================================
Widget _buildLineChart(
  BuildContext context, {
  required List<LineChartBarData> lines,
  required double minX,
  required double maxX,
  required double maxY,
  required String Function(double) xFormatter,
  required String Function(double) yFormatter,
  required String Function(FlSpot) tooltipFormatter,
}) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  final p = AppPalette.of(context);

  return LineChart(
    LineChartData(
      minX: minX,
      maxX: maxX,
      minY: 0,
      maxY: maxY,
      lineBarsData: lines,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: maxY / 5,
        getDrawingHorizontalLine: (_) => FlLine(
          color: p.chartGrid,
          strokeWidth: 0.8,
        ),
        getDrawingVerticalLine: (_) => FlLine(
          color: p.chartGrid,
          strokeWidth: 0.5,
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          left: BorderSide(color: p.chartAxis, width: 1),
          bottom: BorderSide(color: p.chartAxis, width: 1),
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 44,
            getTitlesWidget: (v, _) => Text(
              yFormatter(v),
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: 1,
            getTitlesWidget: (v, _) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                xFormatter(v),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
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
                    tooltipFormatter(sp.bar.spots[sp.spotIndex]),
                    TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ))
              .toList(),
        ),
      ),
    ),
  );
}

// =============================================================================
// Shared widgets
// =============================================================================

class _ChartShell extends StatelessWidget {
  final IconData titleIcon;
  final String title;
  final String subtitle;
  final Widget? headerTrailing;
  final Widget chart;
  final List<_LegendItem> legend;
  const _ChartShell({
    required this.titleIcon,
    required this.title,
    required this.subtitle,
    this.headerTrailing,
    required this.chart,
    required this.legend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.x4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(titleIcon, size: 18, color: cs.primary),
                  const SizedBox(width: AppSpacing.x2),
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.x2, vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      subtitle,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (headerTrailing != null) ...[
                    const Spacer(),
                    headerTrailing!,
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.x4),
              Expanded(child: chart),
              const SizedBox(height: AppSpacing.x3),
              _Legend(items: legend),
            ],
          ),
        ),
      ),
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
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3, vertical: AppSpacing.x2,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Wrap(
        spacing: AppSpacing.x4,
        runSpacing: AppSpacing.x2,
        children: items
            .map((e) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: e.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x1),
                    Text(
                      e.text,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.x5),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.touch_app_outlined,
              size: 32,
              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          Text(
            hint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

List<Color> _palette(BuildContext context) {
  final p = AppPalette.of(context);
  return p.dataSeries;
}
