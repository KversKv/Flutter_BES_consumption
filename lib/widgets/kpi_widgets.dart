import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import '../state/bt_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class _KPI extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? accent;

  const _KPI({
    required this.title,
    required this.value,
    required this.icon,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final Color accentColor = accent ?? palette.accent;

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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.28),
              ),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.x3),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: palette.textMuted,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class KPIRowAppState extends StatelessWidget {
  const KPIRowAppState();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final avg = app.averageCurrent_mA;
    final hours = app.batteryLife_hours;
    final days = hours / 24.0;
    final palette = AppPalette.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
      child: Wrap(
        spacing: AppSpacing.x3,
        runSpacing: AppSpacing.x3,
        children: [
          _KPI(
            title: AppLocalizations.of(context).kpiPeriod,
            value: '${app.period_ms.toStringAsFixed(1)} ms',
            icon: Icons.timelapse,
            accent: palette.info,
          ),
          _KPI(
            title: AppLocalizations.of(context).kpiAvgCurrent,
            value: app.formatCurrentAuto(avg),
            icon: Icons.bolt,
            accent: palette.accent,
          ),
          _KPI(
            title: AppLocalizations.of(context).kpiSleepCurrent,
            value: '${app.sleepCurrent_uA.toStringAsFixed(2)} uA',
            icon: Icons.bedtime,
            accent: palette.textSecondary,
          ),
          _KPI(
            title: AppLocalizations.of(context).kpiBatteryLifeEst,
            value: '${days.isFinite ? days.toStringAsFixed(1) : '--'} 天',
            icon: Icons.battery_full,
            accent: palette.success,
          ),
          _KPI(
            title: AppLocalizations.of(context).kpiPeakCurrent,
            value: '${app.maxCurrent_mA.toStringAsFixed(2)} mA',
            icon: Icons.signal_cellular_alt,
            accent: palette.warning,
          ),
        ],
      ),
    );
  }
}

class KPIRowSniffing extends StatelessWidget {
  const KPIRowSniffing();

  @override
  Widget build(BuildContext context) {
    final st = context.watch<BTState>();
    final avg = st.averageCurrent_mA;
    final hours = st.batteryLife_hours;
    final days = hours / 24.0;
    final palette = AppPalette.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
      child: Wrap(
        spacing: AppSpacing.x3,
        runSpacing: AppSpacing.x3,
        children: [
          _KPI(
            title: AppLocalizations.of(context).kpiPeriod,
            value: '${st.period_ms.toStringAsFixed(1)} ms',
            icon: Icons.timelapse,
            accent: palette.info,
          ),
          _KPI(
            title: AppLocalizations.of(context).kpiAvgCurrent,
            value: st.formatCurrentAuto(avg),
            icon: Icons.bolt,
            accent: palette.accent,
          ),
          _KPI(
            title: AppLocalizations.of(context).kpiBatteryLifeEst,
            value: '${days.isFinite ? days.toStringAsFixed(1) : '--'} 天',
            icon: Icons.battery_full,
            accent: palette.success,
          ),
          _KPI(
            title: AppLocalizations.of(context).kpiPeakCurrent,
            value: '${st.maxCurrent_mA.toStringAsFixed(2)} mA',
            icon: Icons.signal_cellular_alt,
            accent: palette.warning,
          ),
        ],
      ),
    );
  }
}
