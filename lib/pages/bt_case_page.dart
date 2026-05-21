import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../state/bt_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/config_panels.dart';
import '../widgets/kpi_widgets.dart';
import '../widgets/chart_widgets.dart';

class BTPage extends StatefulWidget {
  const BTPage({super.key});

  @override
  State<BTPage> createState() => _BTPageState();
}

class _BTPageState extends State<BTPage> {
  bool _panelExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final sniffState = context.watch<BTState>();

    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: _panelExpanded ? 380 : 0,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: _panelExpanded ? palette.borderSubtle : Colors.transparent,
              ),
            ),
          ),
          child: _panelExpanded
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: SniffingConfigPanel(),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        _CollapseToggle(
          expanded: _panelExpanded,
          onToggle: () => setState(() => _panelExpanded = !_panelExpanded),
          tooltip: _panelExpanded ? l10n.collapsePanel : l10n.expandPanel,
        ),
        Expanded(
          child: Column(
            children: [
              const SizedBox(height: 8),
              const KPIRowSniffing(),
              const SizedBox(height: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: UnifiedPowerChart(
                        events: sniffState.events,
                        periodUs: sniffState.periodUs,
                        maxCurrent: sniffState.maxCurrent_mA,
                        hideLowPowerGaps: sniffState.hideLowPowerGaps,
                        onToggleHideGaps: (val) => sniffState.setHideLowPowerGaps(val),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CollapseToggle extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final String tooltip;

  const _CollapseToggle({
    required this.expanded,
    required this.onToggle,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return SizedBox(
      width: 20,
      child: Align(
        alignment: Alignment.center,
        child: Tooltip(
          message: tooltip,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            onTap: onToggle,
            child: Container(
              width: 20,
              height: 48,
              decoration: BoxDecoration(
                color: palette.bgElevated2,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: palette.borderSubtle),
              ),
              child: Icon(
                expanded ? Icons.chevron_left : Icons.chevron_right,
                size: 14,
                color: palette.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}