import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/sniffing_state.dart';
import '../widgets/config_panels.dart';
import '../widgets/kpi_widgets.dart';
import '../widgets/chart_widgets.dart';

class BTPage extends StatelessWidget {
  const BTPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChangeNotifierProvider(
      create: (_) => BTState(),
      child: Consumer<BTState>( // 使用 Consumer 获取 context 中的 state
        builder: (context, sniffState, _) {
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
                      child: SniffingConfigPanel(),
                    ),
                  ),
                ),
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
                            // 使用统一的图表组件
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
        },
      ),
    );
  }
}