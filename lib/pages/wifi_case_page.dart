import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../navigation/app_url_state.dart';
import '../state/wifi_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/chart_widgets.dart';
import '../widgets/config_panel_frame.dart';
import '../widgets/config_panels.dart';

class WifiPage extends StatelessWidget {
  final Uri? initialUri;

  const WifiPage({super.key, this.initialUri});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final state = WIFIState();
        final uri = initialUri;
        if (uri != null) {
          AppUrlState.applyWifi(state, uri);
        }
        return state;
      },
      child: const _WifiCaseView(),
    );
  }
}

class _WifiCaseView extends StatefulWidget {
  const _WifiCaseView();

  @override
  State<_WifiCaseView> createState() => _WifiCaseViewState();
}

class _WifiCaseViewState extends State<_WifiCaseView> {
  bool _panelExpanded = true;
  WIFIState? _wifiState;
  String? _lastSyncedUrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final wifiState = context.read<WIFIState>();
    if (_wifiState != wifiState) {
      _wifiState?.removeListener(_syncUrl);
      _wifiState = wifiState..addListener(_syncUrl);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncUrl();
      });
    }
  }

  @override
  void dispose() {
    _wifiState?.removeListener(_syncUrl);
    super.dispose();
  }

  void _syncUrl() {
    final state = _wifiState;
    if (!mounted || state == null) return;
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) return;
    final uri = AppUrlState.uriForWifi(state);
    final next = uri.toString();
    if (next == _lastSyncedUrl) return;
    _lastSyncedUrl = next;
    AppUrlState.replaceBrowserUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final wifi = context.watch<WIFIState>();

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
                color:
                    _panelExpanded ? palette.borderSubtle : Colors.transparent,
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
                      child: _WifiConfigPanel(),
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
              const _WifiKpiRow(),
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
                        events: wifi.events,
                        periodUs: wifi.periodUs,
                        maxCurrent: wifi.maxCurrent_mA,
                        hideLowPowerGaps: wifi.hideLowPowerGaps,
                        onToggleHideGaps: (val) =>
                            wifi.setHideLowPowerGaps(val),
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

class _WifiConfigPanel extends StatelessWidget {
  const _WifiConfigPanel();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final st = context.watch<WIFIState>();
    final palette = AppPalette.of(context);
    final chip = st.chip;
    final levels = chip.txPowerLevelsDbm.cast<double>();
    final currentTx = chip.snapTxPower(st.txPowerDbm);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConfigPanelTitle(title: l10n.config),
        const SizedBox(height: AppSpacing.x3),
        ConfigSectionCard(
          title: l10n.configSectionDevice,
          icon: Icons.memory,
          accent: palette.info,
          children: [
            ConfigField(
              label: l10n.chip,
              child: DropdownButton<String>(
                value: st.selectedChipId,
                isExpanded: true,
                items: st.wifiChips
                    .map<DropdownMenuItem<String>>(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) context.read<WIFIState>().setChip(v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x3),
        ConfigSectionCard(
          title: l10n.configSectionCase,
          icon: Icons.route,
          accent: palette.accent,
          children: [
            ConfigField(
              label: l10n.listeningCase,
              child: DropdownButton<SniffCase>(
                value: st.caseType,
                isExpanded: true,
                items: [
                  const DropdownMenuItem(
                      value: SniffCase.hdt, child: Text('HDT')),
                  DropdownMenuItem(
                      value: SniffCase.btSniff, child: Text(l10n.btSniff)),
                  DropdownMenuItem(
                      value: SniffCase.btPage, child: Text(l10n.btPage)),
                  DropdownMenuItem(
                    value: SniffCase.btPagescan,
                    child: Text(l10n.btPagescan),
                  ),
                  DropdownMenuItem(
                      value: SniffCase.relay, child: Text(l10n.relay)),
                ],
                onChanged: (v) {
                  if (v != null) context.read<WIFIState>().setCase(v);
                },
              ),
            ),
            ConfigField(
              label: l10n.frequencyBand,
              value: st.band,
              child: DropdownButton<String>(
                value: st.band,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: '2.4G', child: Text('2.4G')),
                  DropdownMenuItem(value: '5G', child: Text('5G')),
                ],
                onChanged: (v) {
                  if (v != null) context.read<WIFIState>().setBand(v);
                },
              ),
            ),
            ConfigField(
              label: l10n.txPowerLabel,
              value: currentTx.toString(),
              child: DropdownButton<double>(
                value: currentTx,
                isExpanded: true,
                items: levels
                    .map<DropdownMenuItem<double>>(
                      (lv) => DropdownMenuItem<double>(
                        value: lv,
                        child: Text(lv.toString()),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) context.read<WIFIState>().setTxPower(v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x3),
        ConfigSectionCard(
          title: l10n.configSectionTiming,
          icon: Icons.timer,
          accent: palette.warning,
          children: [
            if (st.caseType == SniffCase.hdt) ...[
              ConfigField(
                label: l10n.hdtPeriod,
                value: '${st.hdtPeriodUs.toStringAsFixed(0)} us',
                child: Slider(
                  value: st.hdtPeriodUs.clamp(100.0, 5000.0).toDouble(),
                  min: 100,
                  max: 5000,
                  onChanged: (v) => context.read<WIFIState>().setHdtPeriodUs(v),
                ),
              ),
              ConfigField(
                label: l10n.hdtPhyRate,
                value: '${st.hdtPhyRateMbps.toStringAsFixed(1)} Mbps',
                child: Slider(
                  value: st.hdtPhyRateMbps.clamp(2.0, 15.0).toDouble(),
                  min: 2,
                  max: 15,
                  divisions: 13,
                  onChanged: (v) => context.read<WIFIState>().setHdtPhyRate(v),
                ),
              ),
            ] else ...[
              ConfigField(
                label: l10n.listeningInterval,
                value: '${st.sniffIntervalMs.toStringAsFixed(0)} ms',
                child: Slider(
                  value: st.sniffIntervalMs.clamp(10.0, 5000.0).toDouble(),
                  min: 10,
                  max: 5000,
                  onChanged: (v) =>
                      context.read<WIFIState>().setSniffIntervalMs(v),
                ),
              ),
              ConfigField(
                label: l10n.listeningWindow,
                value: '${st.sniffWindowUs.toStringAsFixed(0)} us',
                child: Slider(
                  value: st.sniffWindowUs.clamp(50.0, 50000.0).toDouble(),
                  min: 50,
                  max: 50000,
                  onChanged: (v) =>
                      context.read<WIFIState>().setSniffWindowUs(v),
                ),
              ),
            ],
            if (st.caseType == SniffCase.btPagescan)
              ConfigField(
                label: l10n.channelsLabel,
                value: '${st.channelsPerCycle}',
                child: Slider(
                  value: st.channelsPerCycle.toDouble(),
                  min: 1,
                  max: 3,
                  divisions: 2,
                  onChanged: (v) =>
                      context.read<WIFIState>().setChannels(v.round()),
                ),
              ),
            if (st.caseType == SniffCase.relay)
              ConfigField(
                label: l10n.relayHopGap,
                value: '${st.relayHopGapUs.toStringAsFixed(0)} us',
                child: Slider(
                  value: st.relayHopGapUs.clamp(0.0, 100000.0).toDouble(),
                  min: 0,
                  max: 100000,
                  onChanged: (v) =>
                      context.read<WIFIState>().setRelayHopGapUs(v),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.x3),
        ConfigSectionCard(
          title: l10n.configSectionPower,
          icon: Icons.battery_charging_full,
          accent: palette.success,
          children: [
            ConfigField(
              label: l10n.batteryCapacityLabel,
              value: '${st.batteryCapacity_mAh.toStringAsFixed(0)} mAh',
              child: Slider(
                value: st.batteryCapacity_mAh,
                min: 50,
                max: 1200,
                divisions: 115,
                onChanged: (v) =>
                    context.read<WIFIState>().setBatteryCapacity(v),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x3),
        ChipInfoCard(chip: chip),
      ],
    );
  }
}

class _WifiKpiRow extends StatelessWidget {
  const _WifiKpiRow();

  @override
  Widget build(BuildContext context) {
    final st = context.watch<WIFIState>();
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final hours = st.batteryLife_hours;
    final days = hours / 24;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
      child: Wrap(
        spacing: AppSpacing.x3,
        runSpacing: AppSpacing.x3,
        children: [
          _WifiKpi(
            title: l10n.kpiPeriod,
            value: '${st.period_ms.toStringAsFixed(1)} ms',
            icon: Icons.timelapse,
            accent: palette.info,
          ),
          _WifiKpi(
            title: l10n.kpiAvgCurrent,
            value: st.formatCurrentAuto(st.averageCurrent_mA),
            icon: Icons.bolt,
            accent: palette.accent,
          ),
          _WifiKpi(
            title: l10n.kpiBatteryLifeEst,
            value: '${days.isFinite ? days.toStringAsFixed(1) : '--'} d',
            icon: Icons.battery_full,
            accent: palette.success,
          ),
          _WifiKpi(
            title: l10n.kpiPeakCurrent,
            value: '${st.maxCurrent_mA.toStringAsFixed(2)} mA',
            icon: Icons.signal_cellular_alt,
            accent: palette.warning,
          ),
        ],
      ),
    );
  }
}

class _WifiKpi extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  const _WifiKpi({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 180),
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.x3,
        horizontal: AppSpacing.x4,
      ),
      decoration: BoxDecoration(
        color: palette.bgElevated2,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: palette.borderSubtle),
        boxShadow: AppElevation.card,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(width: AppSpacing.x3),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: palette.textMuted,
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
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
