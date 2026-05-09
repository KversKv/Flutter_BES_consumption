part of '../earbuds_compare_page.dart';

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
    final es = context.watch<EarbudsState>();
    final metrics = es.selectedMetricsOf(MetricGroup.scene);
    if (metrics.isEmpty) {
      return const SizedBox.shrink();
    }
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
    final es = context.watch<EarbudsState>();
    var metrics = es.selectedMetricsOf(MetricGroup.scene);
    // RadarChart 至少需要 3 个维度才能正常渲染
    if (metrics.length < 3) {
      metrics = metricsOf(MetricGroup.scene);
    }
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
            _MetaInfoList(rows: rows),
          ],
        ),
      ),
    );
  }
}

class _MetaInfoList extends StatelessWidget {
  final List<_MetaRow> rows;
  const _MetaInfoList({required this.rows});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dividerColor = cs.outlineVariant.withValues(alpha: 0.25);

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              decoration: BoxDecoration(
                border: i == rows.length - 1
                    ? null
                    : Border(
                        bottom: BorderSide(color: dividerColor, width: 1),
                      ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x4,
                vertical: AppSpacing.x3,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 160,
                    child: Text(
                      rows[i].label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x3),
                  Expanded(
                    child: Text(
                      rows[i].value,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
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

    final groups = <_TestCaseGroup>[
      _TestCaseGroup(
        title: s.ebTestCase1,
        rows: [
          _TestCaseRow(s.ebHotelCal, s.ebVol1325, scene.hotelCal, scene.hotelCalAncOn),
          _TestCaseRow(s.ebPlay1Khz, s.ebVol2525, scene.k1Hz, scene.k1HzAncOn),
          _TestCaseRow(s.ebMuteCurrent, s.ebVol025, scene.mute, scene.muteAncOn),
          _TestCaseRow(s.ebPinkNoise, s.ebVol1325, scene.noisePink, scene.noisePinkAncOn),
        ],
      ),
      _TestCaseGroup(
        title: s.ebTestCase2,
        rows: [
          _TestCaseRow(s.ebPhoneCall, s.ebVol10086, scene.call, scene.callAncOn),
        ],
      ),
      _TestCaseGroup(
        title: s.ebTestCase3,
        rows: [
          _TestCaseRow(s.ebPowerOffCurrent, s.ebShutdown, scene.powerOff, scene.powerOffAncOn),
          _TestCaseRow(s.ebStandby, s.ebConnectNoBehavior, scene.sniffPage, scene.sniffPageAncOn),
        ],
      ),
    ];

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
            _GroupedSceneTable(
              groups: groups,
              hasAncOn: hasAncOn,
            ),
          ],
        ),
      ),
    );
  }
}

class _TestCaseGroup {
  final String title;
  final List<_TestCaseRow> rows;
  const _TestCaseGroup({required this.title, required this.rows});
}

class _TestCaseRow {
  final String music;
  final String volume;
  final double? ancOff;
  final double? ancOn;
  const _TestCaseRow(this.music, this.volume, this.ancOff, this.ancOn);
}

class _GroupedSceneTable extends StatelessWidget {
  final List<_TestCaseGroup> groups;
  final bool hasAncOn;
  const _GroupedSceneTable({required this.groups, required this.hasAncOn});

  static const double _kGroupColWidth = 120;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final headerBg = cs.primaryContainer.withValues(alpha: 0.2);
    final headerStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final cellStyle = theme.textTheme.bodyMedium;
    final groupStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: cs.primary,
    );
    final borderColor = cs.outlineVariant.withValues(alpha: 0.35);
    final groupBg = cs.primaryContainer.withValues(alpha: 0.12);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(s, headerBg, headerStyle, borderColor),
            for (var i = 0; i < groups.length; i++)
              _buildGroup(
                group: groups[i],
                isLast: i == groups.length - 1,
                cellStyle: cellStyle,
                groupStyle: groupStyle,
                groupBg: groupBg,
                borderColor: borderColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    AppLocalizations s,
    Color bg,
    TextStyle? style,
    Color borderColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _kGroupColWidth,
            child: _cellPad(
              child: Text(s.ebProject, style: style),
            ),
          ),
          _vDivider(borderColor),
          Expanded(flex: 2, child: _cellPad(child: Text(s.ebTestMusic, style: style))),
          _vDivider(borderColor),
          Expanded(flex: 2, child: _cellPad(child: Text(s.ebVolumeReq, style: style))),
          _vDivider(borderColor),
          Expanded(
            flex: 2,
            child: _cellPad(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(s.ebAncOff, style: style),
              ),
            ),
          ),
          if (hasAncOn) ...[
            _vDivider(borderColor),
            Expanded(
              flex: 2,
              child: _cellPad(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(s.ebAncOn, style: style),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGroup({
    required _TestCaseGroup group,
    required bool isLast,
    required TextStyle? cellStyle,
    required TextStyle? groupStyle,
    required Color groupBg,
    required Color borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: _kGroupColWidth,
              child: ColoredBox(
                color: groupBg,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.x3,
                    vertical: AppSpacing.x3,
                  ),
                  child: Center(
                    child: Text(
                      group.title,
                      style: groupStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            _vDivider(borderColor),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < group.rows.length; i++)
                    Container(
                      decoration: BoxDecoration(
                        border: i == group.rows.length - 1
                            ? null
                            : Border(
                                bottom: BorderSide(
                                  color: borderColor,
                                  width: 1,
                                ),
                              ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _cellPad(
                              child: Text(group.rows[i].music, style: cellStyle),
                            ),
                          ),
                          _vDivider(borderColor),
                          Expanded(
                            flex: 2,
                            child: _cellPad(
                              child: Text(group.rows[i].volume, style: cellStyle),
                            ),
                          ),
                          _vDivider(borderColor),
                          Expanded(
                            flex: 2,
                            child: _cellPad(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  group.rows[i].ancOff != null
                                      ? EarbudsQuery.format(group.rows[i].ancOff!)
                                      : '-',
                                  style: cellStyle?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (hasAncOn) ...[
                            _vDivider(borderColor),
                            Expanded(
                              flex: 2,
                              child: _cellPad(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    group.rows[i].ancOn != null
                                        ? EarbudsQuery.format(group.rows[i].ancOn!)
                                        : '-',
                                    style: cellStyle?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cellPad({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3,
        vertical: AppSpacing.x3,
      ),
      child: child,
    );
  }

  Widget _vDivider(Color color) {
    return Container(width: 1, color: color);
  }
}
