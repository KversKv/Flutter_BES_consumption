part of '../earbuds_compare_page.dart';

class _LeftSidebar extends StatefulWidget {
  const _LeftSidebar();

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
          const _ConfigSection(),
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
  const _ConfigSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = AppLocalizations.of(context);
    final es = context.watch<EarbudsState>();

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
    final es = context.watch<EarbudsState>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final current = es.focusedChipId ?? (chips.isNotEmpty ? chips.first.id : null);

    return SizedBox(
      height: 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Chip: ',
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: current,
              isExpanded: true,
              decoration: InputDecoration(
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
          ),
        ],
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
