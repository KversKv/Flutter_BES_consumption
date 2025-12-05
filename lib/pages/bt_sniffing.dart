import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../widgets/config_panels.dart';
import '../widgets/chart_widgets.dart';
import '../widgets/kpi_widgets.dart';

// 注意：此页面在重构后的结构中可能不再被直接使用，
// 因为 BTPage 已经内联了 SniffingState 的 Provider。
// 但为了保持兼容性，这里进行简单适配。

class BTSniffingPage extends StatelessWidget {
  const BTSniffingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).btSniffingConfig,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Text(AppLocalizations.of(context).btSniffingPlaceholder),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context).sniffingIntervalLabel,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).powerWaveform,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 300,
                      child: UnifiedPowerChart(
                        events: appState.events,
                        periodUs: appState.periodUs,
                        maxCurrent: appState.maxCurrent_mA,
                        hideLowPowerGaps: appState.hideLowPowerGaps,
                        onToggleHideGaps: (v) => appState.setHideLowPowerGaps(v),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).kpiTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Text('${AppLocalizations.of(context).avgCurrentLabel} ${appState.averageCurrent_mA.toStringAsFixed(2)} mA'),
                    Text('${AppLocalizations.of(context).periodLabel} ${appState.periodUs.toStringAsFixed(2)} µs'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}