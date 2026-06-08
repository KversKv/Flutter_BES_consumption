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
    return Column(
      children: [
        Expanded(child: _MetricTableView(group: MetricGroup.scene)),
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
