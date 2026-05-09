import 'dart:math' as math;

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

class EarbudsComparePage extends StatefulWidget {
  const EarbudsComparePage({super.key});

  @override
  State<EarbudsComparePage> createState() => _EarbudsComparePageState();
}

class _EarbudsComparePageState extends State<EarbudsComparePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    final es = context.read<EarbudsState>();
    _tabCtrl = TabController(
      length: 7,
      vsync: this,
      initialIndex: es.tabIndex,
    );
    _tabCtrl.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabCtrl.indexIsChanging) return;
    context.read<EarbudsState>().setTabIndex(_tabCtrl.index);
  }

  @override
  void dispose() {
    _tabCtrl.removeListener(_onTabChanged);
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final es = context.watch<EarbudsState>();
    if (_tabCtrl.index != es.tabIndex) {
      _tabCtrl.animateTo(es.tabIndex);
    }

    return Scaffold(
      body: Row(
        children: [
          _LeftSidebar(tabCtrl: _tabCtrl),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: const [
                _SceneTab(),
                _KeepAliveWrapper(child: _MetricTableView(group: MetricGroup.bt)),
                _KeepAliveWrapper(child: _MetricTableView(group: MetricGroup.sleep)),
                _KeepAliveWrapper(child: _MetricTableView(group: MetricGroup.mcuRun)),
                _KeepAliveWrapper(child: _TxSweepTab()),
                _KeepAliveWrapper(child: _RxSweepTab()),
                _KeepAliveWrapper(child: _MetricTableView(group: MetricGroup.pa)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeftSidebar extends StatefulWidget {
  final TabController tabCtrl;
  const _LeftSidebar({required this.tabCtrl});

  @override
  State<_LeftSidebar> createState() => _LeftSidebarState();
}

class _LeftSidebarState extends State<_LeftSidebar> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final p = AppPalette.of(context);
    final s = AppLocalizations.of(context);
    final es = context.watch<EarbudsState>();
    final allChips = es.visibleChips;
    final filtered = _search.isEmpty
        ? allChips
        : allChips.where((c) => c.id.toLowerCase().contains(_search.toLowerCase())).toList();

    return Container(
      width: 268,
      decoration: BoxDecoration(
        color: p.bgElevated1,
        border: Border(
          right: BorderSide(color: p.borderSubtle),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ConfigSection(tabCtrl: widget.tabCtrl),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x3,
              AppSpacing.x3,
              AppSpacing.x3,
              AppSpacing.x2,
            ),
            child: _SelectionOverviewCard(es: es),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x3),
            child: SizedBox(
              height: 36,
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: s.ebSearchChip,
                  prefixIcon: const Icon(Icons.search, size: 16),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.x2,
                    vertical: AppSpacing.x2,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x3),
            child: Row(
              children: [
                Expanded(
                  child: FilterChip(
                    selected: es.massProductionOnly,
                    label: Text(
                      s.ebFilterMassOnly,
                      style: theme.textTheme.labelSmall,
                    ),
                    avatar: es.massProductionOnly
                        ? const Icon(Icons.check_rounded, size: 14)
                        : const Icon(Icons.filter_alt_outlined, size: 14),
                    onSelected: (_) => es.toggleMassProductionOnly(),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.only(left: 2, right: 4),
                  ),
                ),
                if (es.selectedIds.isNotEmpty)
                  InkWell(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    onTap: () => es.clearSelection(),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.clear_all_rounded,
                        size: 16,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x2),
          const Divider(height: 1),
          _ChipInfoHeader(es: es),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.x1),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final chip = filtered[i];
                final selected = es.isSelected(chip.id);
                final colorIdx = es.selectedIds.indexOf(chip.id);
                final palette = AppPalette.of(context).dataSeries;
                final chipColor = colorIdx >= 0
                    ? palette[colorIdx % palette.length]
                    : null;

                return _ChipListTile(
                  chip: chip,
                  selected: selected,
                  chipColor: chipColor,
                  onTap: () {
                    final ok = es.toggleSelected(chip.id);
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

class _SelectionOverviewCard extends StatelessWidget {
  final EarbudsState es;
  const _SelectionOverviewCard({required this.es});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final p = AppPalette.of(context);
    final s = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            p.accentMuted.withValues(alpha: 0.9),
            cs.surfaceContainerHigh,
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: p.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: p.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(Icons.insights_rounded, color: p.accent, size: 18),
              ),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.ebSummary,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      s.ebSelectedCount(es.selectedIds.length),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          Row(
            children: [
              Expanded(
                child: _SidebarStat(
                  label: s.ebChipInfo,
                  value: '${es.visibleChips.length}',
                  accent: p.info,
                ),
              ),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: _SidebarStat(
                  label: s.ebMass,
                  value: '${es.visibleChips.where((c) => c.massProduction).length}',
                  accent: p.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SidebarStat extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  const _SidebarStat({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x2,
        vertical: AppSpacing.x2,
      ),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigSection extends StatelessWidget {
  final TabController tabCtrl;
  const _ConfigSection({required this.tabCtrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = AppLocalizations.of(context);
    final es = context.watch<EarbudsState>();

    final tabLabels = [
      s.ebTabScene,
      s.ebTabBt,
      s.ebTabSleep,
      s.ebTabRun,
      s.ebTabTx,
      s.ebTabRx,
      s.ebTabPa,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x3,
        AppSpacing.x3,
        AppSpacing.x3,
        AppSpacing.x2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 16, color: cs.primary),
              const SizedBox(width: AppSpacing.x1),
              Text(
                s.ebConfig,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            s.ebViewMode,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.x1),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<EarbudsSceneViewMode>(
              segments: [
                ButtonSegment(
                  value: EarbudsSceneViewMode.singleChip,
                  label: Text(s.ebViewSingle, style: theme.textTheme.labelSmall),
                  icon: const Icon(Icons.view_agenda_outlined, size: 14),
                ),
                ButtonSegment(
                  value: EarbudsSceneViewMode.comparison,
                  label: Text(s.ebViewCompare, style: theme.textTheme.labelSmall),
                  icon: const Icon(Icons.compare_arrows, size: 14),
                ),
              ],
              selected: {es.sceneViewMode},
              onSelectionChanged: (set) => es.setSceneViewMode(set.first),
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          if (es.sceneViewMode == EarbudsSceneViewMode.singleChip &&
              es.tabIndex == 0) ...[
            const SizedBox(height: AppSpacing.x2),
            _FocusedChipDropdown(chips: es.visibleChips),
          ],
          const SizedBox(height: AppSpacing.x3),
          Text(
            s.ebContent,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.x1),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: List.generate(tabLabels.length, (i) {
              final active = es.tabIndex == i;
              return ChoiceChip(
                label: Text(
                  tabLabels[i],
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                selected: active,
                onSelected: (_) => es.setTabIndex(i),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _FocusedChipDropdown extends StatelessWidget {
  final List<EarbudsChip> chips;
  const _FocusedChipDropdown({required this.chips});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final es = context.watch<EarbudsState>();
    final theme = Theme.of(context);

    final current = es.focusedChipId ?? (chips.isNotEmpty ? chips.first.id : null);

    return SizedBox(
      height: 36,
      child: DropdownButtonFormField<String>(
        initialValue: current,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: s.ebTestObject,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x2,
            vertical: AppSpacing.x1,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
        ),
        style: theme.textTheme.bodySmall,
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
    );
  }
}

class _ChipInfoHeader extends StatelessWidget {
  final EarbudsState es;
  const _ChipInfoHeader({required this.es});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x3,
        AppSpacing.x2,
        AppSpacing.x3,
        AppSpacing.x1,
      ),
      child: Row(
        children: [
          Icon(Icons.memory_rounded, size: 16, color: cs.primary),
          const SizedBox(width: AppSpacing.x1),
          Text(
            s.ebChipInfo,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x2,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              '${es.selectedIds.length}/${EarbudsState.kMaxSelected}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipListTile extends StatelessWidget {
  final EarbudsChip chip;
  final bool selected;
  final Color? chipColor;
  final VoidCallback onTap;

  const _ChipListTile({
    required this.chip,
    required this.selected,
    required this.chipColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final p = AppPalette.of(context);

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x2,
          vertical: 2,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x3,
          vertical: AppSpacing.x2,
        ),
        decoration: BoxDecoration(
          color: selected
              ? (chipColor ?? cs.primaryContainer).withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: selected
                ? (chipColor ?? cs.primary).withValues(alpha: 0.35)
                : p.borderSubtle.withValues(alpha: 0.4),
          ),
          boxShadow: selected ? AppElevation.card : null,
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: (chipColor ?? cs.primary).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Center(
                child: chipColor != null
                    ? Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: chipColor,
                          shape: BoxShape.circle,
                        ),
                      )
                    : Icon(Icons.memory_rounded, size: 14, color: cs.primary),
              ),
            ),
            const SizedBox(width: AppSpacing.x2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BES${chip.id}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    chip.process ?? chip.core ?? '-',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (chip.massProduction)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x1,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppPalette.of(context).success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  AppLocalizations.of(context).ebYes,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppPalette.of(context).success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SceneTab extends StatelessWidget {
  const _SceneTab();

  @override
  Widget build(BuildContext context) {
    final es = context.watch<EarbudsState>();
    return es.sceneViewMode == EarbudsSceneViewMode.comparison
        ? const _ComparisonSceneView()
        : const _SingleChipSceneView();
  }
}

class _ComparisonSceneView extends StatelessWidget {
  const _ComparisonSceneView();

  @override
  Widget build(BuildContext context) {
    final es = context.watch<EarbudsState>();
    final chips = es.selectedChips;

    return Column(
      children: [
        if (chips.length >= 2)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x4,
              AppSpacing.x3,
              AppSpacing.x4,
              AppSpacing.x2,
            ),
            child: _SceneOverviewPanel(chips: chips),
          ),
        Expanded(child: _MetricTableView(group: MetricGroup.scene)),
      ],
    );
  }
}

class _SceneOverviewPanel extends StatelessWidget {
  final List<EarbudsChip> chips;
  const _SceneOverviewPanel({required this.chips});

  @override
  Widget build(BuildContext context) {
    final metrics = metricsOf(MetricGroup.scene);
    final stats = _computeMetricStats(chips, metrics);

    return SizedBox(
      height: 360,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 7,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.x4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.radar_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.x2),
                        Text(
                          AppLocalizations.of(context).ebRadarTitle,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    Expanded(child: _SceneRadarChart(chips: chips)),
                    const SizedBox(height: AppSpacing.x2),
                    _RadarLegend(
                      chips: chips,
                      palette: AppPalette.of(context).dataSeries,
                      selectedIds: context.watch<EarbudsState>().selectedIds,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            flex: 5,
            child: _SceneInsightPanel(
              chips: chips,
              metrics: metrics,
              stats: stats,
            ),
          ),
        ],
      ),
    );
  }
}

class _SceneRadarChart extends StatelessWidget {
  final List<EarbudsChip> chips;
  const _SceneRadarChart({required this.chips});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final palette = AppPalette.of(context);
    final metrics = metricsOf(MetricGroup.scene);
    final stats = _computeMetricStats(chips, metrics);

    final dataSets = <RadarDataSet>[];
    for (var chipIndex = 0; chipIndex < chips.length; chipIndex++) {
      final chip = chips[chipIndex];
      final color = palette.dataSeries[chipIndex % palette.dataSeries.length];
      final entries = <RadarEntry>[];
      for (var i = 0; i < metrics.length; i++) {
        final metric = metrics[i];
        final stat = stats[i];
        final value = metric.read(chip);
        final normalized = _normalizeRadarValue(value, stat);
        entries.add(RadarEntry(value: normalized));
      }
      dataSets.add(
        RadarDataSet(
          fillColor: color.withValues(alpha: 0.12),
          borderColor: color,
          entryRadius: 2.5,
          borderWidth: 2,
          dataEntries: entries,
        ),
      );
    }

    return RadarChart(
      RadarChartData(
        radarBackgroundColor: Colors.transparent,
        radarBorderData: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.25)),
        tickCount: 4,
        ticksTextStyle: theme.textTheme.labelSmall?.copyWith(
          color: cs.onSurfaceVariant,
          fontSize: 10,
        ),
        tickBorderData: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.18)),
        gridBorderData: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.22)),
        titlePositionPercentageOffset: 0.18,
        getTitle: (index, angle) {
          final metric = metrics[index];
          return RadarChartTitle(
            text: metric.label(s),
            angle: angle,
          );
        },
        titleTextStyle: theme.textTheme.labelSmall?.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        dataSets: dataSets,
      ),
      duration: const Duration(milliseconds: 250),
    );
  }

  double _normalizeRadarValue(double? value, _MetricStat stat) {
    if (value == null || stat.min == null || stat.max == null) return 0.2;
    if (stat.max == stat.min) return 0.7;
    final ratio = (value - stat.min!) / (stat.max! - stat.min!);
    return 0.2 + (1 - ratio) * 0.8;
  }
}

class _SceneInsightPanel extends StatelessWidget {
  final List<EarbudsChip> chips;
  final List<EarbudsMetric> metrics;
  final List<_MetricStat> stats;

  const _SceneInsightPanel({
    required this.chips,
    required this.metrics,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final p = AppPalette.of(context);

    final topMetrics = metrics.length > 4 ? metrics.sublist(0, 4) : metrics;
    final topStats = stats.length > 4 ? stats.sublist(0, 4) : stats;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_graph_rounded, size: 16, color: cs.primary),
                const SizedBox(width: AppSpacing.x1),
                Text(
                  s.ebSummary,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x3),
            Wrap(
              spacing: AppSpacing.x2,
              runSpacing: AppSpacing.x2,
              children: [
                _InsightBadge(
                  label: s.ebBest,
                  value: _bestChipLabel(chips, metrics.first),
                  accent: p.success,
                ),
                _InsightBadge(
                  label: s.ebWorst,
                  value: _worstChipLabel(chips, metrics.first),
                  accent: p.danger,
                ),
                _InsightBadge(
                  label: s.ebBaseline,
                  value: 'BES${chips.first.id}',
                  accent: p.info,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x3),
            Expanded(
              child: ListView.separated(
                itemCount: topMetrics.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.x2),
                itemBuilder: (context, index) {
                  final metric = topMetrics[index];
                  final stat = topStats[index];
                  return _InsightMetricTile(
                    label: metric.label(s),
                    unit: unitLabel(metric.unit, s),
                    best: stat.min,
                    avg: stat.avg,
                    worst: stat.max,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _bestChipLabel(List<EarbudsChip> chips, EarbudsMetric metric) {
    EarbudsChip? bestChip;
    double? bestValue;
    for (final chip in chips) {
      final value = metric.read(chip);
      if (value == null) continue;
      if (bestValue == null || value < bestValue) {
        bestValue = value;
        bestChip = chip;
      }
    }
    return bestChip != null ? 'BES${bestChip.id}' : '-';
  }

  String _worstChipLabel(List<EarbudsChip> chips, EarbudsMetric metric) {
    EarbudsChip? worstChip;
    double? worstValue;
    for (final chip in chips) {
      final value = metric.read(chip);
      if (value == null) continue;
      if (worstValue == null || value > worstValue) {
        worstValue = value;
        worstChip = chip;
      }
    }
    return worstChip != null ? 'BES${worstChip.id}' : '-';
  }
}

class _InsightBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  const _InsightBadge({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3,
        vertical: AppSpacing.x2,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightMetricTile extends StatelessWidget {
  final String label;
  final String unit;
  final double? best;
  final double? avg;
  final double? worst;

  const _InsightMetricTile({
    required this.label,
    required this.unit,
    required this.best,
    required this.avg,
    required this.worst,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final p = AppPalette.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
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
          const SizedBox(height: AppSpacing.x2),
          Row(
            children: [
              Expanded(
                child: _MetricPill(
                  label: 'MIN',
                  value: best,
                  color: p.success,
                ),
              ),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: _MetricPill(
                  label: 'AVG',
                  value: avg,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: _MetricPill(
                  label: 'MAX',
                  value: worst,
                  color: p.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final double? value;
  final Color color;
  const _MetricPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x2,
        vertical: AppSpacing.x2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
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
      ),
    );
  }
}

class _RadarLegend extends StatelessWidget {
  final List<EarbudsChip> chips;
  final List<Color> palette;
  final List<String> selectedIds;
  const _RadarLegend({required this.chips, required this.palette, required this.selectedIds});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Wrap(
      spacing: AppSpacing.x3,
      runSpacing: AppSpacing.x1,
      children: chips.map((c) {
        final idx = selectedIds.indexOf(c.id);
        final color = palette[idx % palette.length];
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x2,
            vertical: AppSpacing.x1,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Text(
                'BES${c.id}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
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
                        s.ebSingleDac,
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
          _SceneMetaTable(chip: chip, cfg: cfg),
          const SizedBox(height: AppSpacing.x4),
          _SceneDataTable(chip: chip, scene: scene),
        ],
      ),
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
            Wrap(
              spacing: AppSpacing.x3,
              runSpacing: AppSpacing.x3,
              children: rows
                  .map(
                    (r) => SizedBox(
                      width: 260,
                      child: _MetaInfoCard(label: r.label, value: r.value),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaInfoCard extends StatelessWidget {
  final String label;
  final String value;
  const _MetaInfoCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.x1),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.table_chart_rounded, size: 16, color: cs.primary),
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
                headingRowColor: WidgetStateProperty.all(headerBg),
                columnSpacing: 24,
                headingTextStyle: headerStyle,
                dataTextStyle: cellStyle,
                dataRowMinHeight: 44,
                dataRowMaxHeight: 52,
                columns: [
                  DataColumn(label: Text(s.ebProject)),
                  DataColumn(label: Text(s.ebTestMusic)),
                  DataColumn(label: Text(s.ebVolumeReq)),
                  DataColumn(label: Text(s.ebAncOff), numeric: true),
                  if (hasAncOn)
                    DataColumn(label: Text(s.ebAncOn), numeric: true),
                ],
                rows: [
                  _buildRow(
                    s.ebTestCase1,
                    s.ebHotelCal,
                    s.ebVol1325,
                    scene.hotelCal,
                    scene.hotelCalAncOn,
                    hasAncOn,
                    groupStyle,
                    cellStyle,
                  ),
                  _buildRow(
                    null,
                    s.ebPlay1Khz,
                    s.ebVol2525,
                    scene.k1Hz,
                    scene.k1HzAncOn,
                    hasAncOn,
                    groupStyle,
                    cellStyle,
                  ),
                  _buildRow(
                    null,
                    s.ebMuteCurrent,
                    s.ebVol025,
                    scene.mute,
                    scene.muteAncOn,
                    hasAncOn,
                    groupStyle,
                    cellStyle,
                  ),
                  _buildRow(
                    null,
                    s.ebPinkNoise,
                    s.ebVol1325,
                    scene.noisePink,
                    scene.noisePinkAncOn,
                    hasAncOn,
                    groupStyle,
                    cellStyle,
                  ),
                  _buildRow(
                    s.ebTestCase2,
                    s.ebPhoneCall,
                    s.ebVol10086,
                    scene.call,
                    scene.callAncOn,
                    hasAncOn,
                    groupStyle,
                    cellStyle,
                  ),
                  _buildRow(
                    s.ebTestCase3,
                    s.ebPowerOffCurrent,
                    s.ebShutdown,
                    scene.powerOff,
                    scene.powerOffAncOn,
                    hasAncOn,
                    groupStyle,
                    cellStyle,
                  ),
                  _buildRow(
                    null,
                    s.ebStandby,
                    s.ebConnectNoBehavior,
                    scene.sniffPage,
                    scene.sniffPageAncOn,
                    hasAncOn,
                    groupStyle,
                    cellStyle,
                  ),
                ],
              ),
            ),
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
        DataCell(
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              ancOff != null ? EarbudsQuery.format(ancOff) : '-',
              style: cellStyle?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (hasAncOn)
          DataCell(
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                ancOn != null ? EarbudsQuery.format(ancOn) : '-',
                style: cellStyle?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }
}

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
    final palette = AppPalette.of(context);
    final headerStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
    );

    final metricStats = _computeMetricStats(chips, metrics);

    return Column(
      children: [
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
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: type == _StatType.min
                      ? AppPalette.of(context).success
                      : type == _StatType.max
                          ? AppPalette.of(context).danger
                          : cs.onSurfaceVariant,
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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

class _TxSweepTab extends StatelessWidget {
  const _TxSweepTab();

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return _EmptyHint(hint: s.ebNoData);
  }
}

class _RxSweepTab extends StatelessWidget {
  const _RxSweepTab();

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return _EmptyHint(hint: s.ebNoData);
  }
}