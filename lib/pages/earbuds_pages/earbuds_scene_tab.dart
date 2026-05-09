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
