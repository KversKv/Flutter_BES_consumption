import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 需要引入 provider 来获取数据
import '../state/app_state.dart';
import '../widgets/config_panels.dart';
import '../widgets/kpi_widgets.dart';
import '../widgets/chart_widgets.dart';

class BleCasePage extends StatelessWidget {
  const BleCasePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 监听数据源
    final appState = context.watch<AppState>();

    return Row(
      children: [
        SizedBox(
          width: 380,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: ConfigPanel(),
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              const SizedBox(height: 8),
              const KPIRowAppState(),
              const SizedBox(height: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      // 使用统一的图表组件
                      child: UnifiedPowerChart(
                        events: appState.events,
                        periodUs: appState.periodUs,
                        maxCurrent: appState.maxCurrent_mA,
                        hideLowPowerGaps: appState.hideLowPowerGaps,
                        onToggleHideGaps: (val) => appState.setHideLowPowerGaps(val),
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