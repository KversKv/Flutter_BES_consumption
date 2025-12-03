import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../state/BT_state.dart';

class _KPI extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _KPI({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 24),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.labelMedium),
              Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          _KPI(title: '周期', value: '${app.period_ms.toStringAsFixed(1)} ms', icon: Icons.timelapse),
          _KPI(title: '平均电流', value: app.formatCurrentAuto(avg), icon: Icons.bolt),
          _KPI(title: '电池寿命(估)', value: '${days.isFinite ? days.toStringAsFixed(1) : '--'} 天', icon: Icons.battery_full),
          _KPI(title: '峰值电流', value: '${app.maxCurrent_mA.toStringAsFixed(2)} mA', icon: Icons.signal_cellular_alt),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          _KPI(title: '周期', value: '${st.period_ms.toStringAsFixed(1)} ms', icon: Icons.timelapse),
          _KPI(title: '平均电流', value: st.formatCurrentAuto(avg), icon: Icons.bolt),
          _KPI(title: '电池寿命(估)', value: '${days.isFinite ? days.toStringAsFixed(1) : '--'} 天', icon: Icons.battery_full),
          _KPI(title: '峰值电流', value: '${st.maxCurrent_mA.toStringAsFixed(2)} mA', icon: Icons.signal_cellular_alt),
        ],
      ),
    );
  }
}
