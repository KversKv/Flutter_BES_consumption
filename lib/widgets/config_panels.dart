import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../state/bt_state.dart';
import '../models/profile_params.dart' show Mode, Phy;
import '../l10n/app_localizations.dart';

class ConfigPanel extends StatefulWidget {
  const ConfigPanel({super.key});
  @override
  State<ConfigPanel> createState() => _ConfigPanelState();
}

class _ConfigPanelState extends State<ConfigPanel> {
  final TextEditingController _connIntervalCtrl = TextEditingController();
  bool _syncingConn = false;

  static const double _connMin = 7.5;
  static const double _connMax = 4000.0;
  static const double _connStep = 0.625;

  @override
  void dispose() {
    _connIntervalCtrl.dispose();
    super.dispose();
  }

  double _quantizeConn(double v) {
    final clamped = v.clamp(_connMin, _connMax);
    final snapped = (clamped / _connStep).round() * _connStep;
    return double.parse(snapped.toStringAsFixed(2));
  }

  void _setConnText(double value) {
    final s = value.toStringAsFixed(2);
    if (_connIntervalCtrl.text != s) {
      _syncingConn = true;
      _connIntervalCtrl.text = s;
      _connIntervalCtrl.selection =
          TextSelection.fromPosition(TextPosition(offset: _connIntervalCtrl.text.length));
      _syncingConn = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Try to sync BTState with AppState if provider is present.
    final theme = Theme.of(context);
    Widget sectionCard({required String title, required Widget child, required Color color}) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      );
    }
    final app = context.watch<AppState>();
    List<double> levels;
    double currentTx;
    levels = app.chip.txPowerLevelsDbm.cast<double>();
    currentTx = app.chip.snapTxPower(app.params.txPowerDbm);

    if (app.params.mode == Mode.bleConnectionCentral ||
        app.params.mode == Mode.bleConnectionPeripheral) {
      _setConnText(app.params.connIntervalMs);
    }

    final btState = context.watch<BTState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context).config, style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),

        // Chip settings card (single bordered section)
        sectionCard(
          title: 'Chip settings',
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context).chip),
              const SizedBox(height: 6),
              DropdownMenu<String>(
                initialSelection: app.selectedChipId,
                expandedInsets: EdgeInsets.zero,
                dropdownMenuEntries: app.chips
                    .map((c) => DropdownMenuEntry(
                          value: c.id,
                          label: c.name,
                        ))
                    .toList(),
                onSelected: (v) {
                  if (v != null) context.read<AppState>().setChip(v);
                },
              ),
              const SizedBox(height: 12),
              Text('Voltage: ${btState.supplyVoltage_V.toStringAsFixed(2)} V'),
              Slider(
                value: btState.supplyVoltage_V,
                min: 1.8,
                max: 5.5,
                divisions: 37,
                onChanged: (v) => context.read<BTState>().setSupplyVoltage(v),
              ),
            ],
          ),
        ),

        // BLE settings card (single bordered section)
        sectionCard(
          title: 'BLE settings',
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context).mode),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: DropdownMenu<Mode>(
                  initialSelection: app.params.mode,
                  expandedInsets: EdgeInsets.zero,
                  dropdownMenuEntries: [
                    DropdownMenuEntry(value: Mode.advertisingTxRx, label: AppLocalizations.of(context).advertisingTxRx),
                    DropdownMenuEntry(value: Mode.advertisingTxOnly, label: AppLocalizations.of(context).advertisingTxOnly),
                    DropdownMenuEntry(value: Mode.bleConnectionPeripheral, label: AppLocalizations.of(context).bleConnectionPeripheral),
                    DropdownMenuEntry(value: Mode.bleConnectionCentral, label: AppLocalizations.of(context).bleConnectionCentral),
                    if (app.chip.supportsHDT) DropdownMenuEntry(value: Mode.hdt, label: 'HDT'),
                  ],
                  onSelected: (v) {
                    if (v != null) context.read<AppState>().setMode(v);
                  },
                ),
              ),
              const SizedBox(height: 12),

              Text('${AppLocalizations.of(context).txPowerLabel} $currentTx'),
              const SizedBox(height: 6),
              DropdownMenu<double>(
                initialSelection: currentTx,
                expandedInsets: EdgeInsets.zero,
                dropdownMenuEntries: levels
                    .map((lv) => DropdownMenuEntry(
                          value: lv,
                          label: lv.toString(),
                        ))
                    .toList(),
                onSelected: (v) {
                  if (v != null) context.read<AppState>().setTxPower(v);
                },
              ),
              const SizedBox(height: 12),

              Text('${AppLocalizations.of(context).payloadBytesLabel} ${app.params.payloadBytes}'),
              Slider(
                value: app.params.payloadBytes.toDouble(),
                min: 0,
                max: 251,
                divisions: 251,
                onChanged: (v) => context.read<AppState>().setPayloadBytes(v.round()),
              ),
              const SizedBox(height: 12),

              // Interval controls (advertising vs connection)
              if (app.params.mode == Mode.advertisingTxOnly || app.params.mode == Mode.advertisingTxRx)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${AppLocalizations.of(context).advIntervalLabel} ${app.params.advIntervalMs.toStringAsFixed(0)}'),
                    Slider(
                      value: app.params.advIntervalMs,
                      min: 20,
                      max: 2000,
                      divisions: 198,
                      onChanged: (v) => context.read<AppState>().setAdvInterval(v),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(AppLocalizations.of(context).connIntervalLabel),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _connIntervalCtrl,
                            // Use a numeric keyboard with decimal support and filter input to digits and dot.
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9\.]'))],
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                              suffixText: 'ms',
                              hintText: '7.5 ~ 4000',
                            ),
                            textAlign: TextAlign.right,
                            onChanged: (txt) {
                              if (_syncingConn) return;
                            },
                            onSubmitted: (txt) {
                              if (_syncingConn) return;
                              final v = double.tryParse(txt.trim());
                              if (v != null) {
                                final snapped = _quantizeConn(v);
                                context.read<AppState>().setConnInterval(snapped);
                                _setConnText(snapped);
                              } else {
                                _setConnText(app.params.connIntervalMs);
                              }
                              FocusScope.of(context).unfocus();
                            },
                            onEditingComplete: () {
                              if (_syncingConn) return;
                              final txt = _connIntervalCtrl.text;
                              final v = double.tryParse(txt.trim());
                              if (v != null) {
                                final snapped = _quantizeConn(v);
                                context.read<AppState>().setConnInterval(snapped);
                                _setConnText(snapped);
                              } else {
                                _setConnText(app.params.connIntervalMs);
                              }
                              FocusScope.of(context).unfocus();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Slider(
                      value: app.params.connIntervalMs,
                      min: _connMin,
                      max: _connMax,
                      onChanged: (v) {
                        final snapped = _quantizeConn(v);
                        context.read<AppState>().setConnInterval(snapped);
                        _setConnText(snapped);
                      },
                    ),
                  ],
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Advanced card (visible for connection modes and HDT)
        if (app.params.mode == Mode.bleConnectionCentral || app.params.mode == Mode.bleConnectionPeripheral || app.params.mode == Mode.hdt)
          sectionCard(
            title: 'Advanced',
            color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.06),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context).phy),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<Phy>(
                    segments: const [
                      ButtonSegment(value: Phy.le1M, label: Text('1M')),
                      ButtonSegment(value: Phy.le2M, label: Text('2M')),
                      ButtonSegment(value: Phy.leCodedS8, label: Text('Coded S=8')),
                    ],
                    selected: {app.params.phy},
                    onSelectionChanged: (s) {
                      context.read<AppState>().setPhy(s.first);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                // When BLE mode is HDT, expose HDT-specific role and band here
                if (app.params.mode == Mode.hdt)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context).moduleRole),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: DropdownButton<HdtModule>(
                          value: btState.hdtModule,
                          isExpanded: true,
                          items: [
                            DropdownMenuItem(value: HdtModule.sink, child: Text(AppLocalizations.of(context).sink)),
                            DropdownMenuItem(value: HdtModule.source, child: Text(AppLocalizations.of(context).source)),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            context.read<BTState>().setHdtModule(v);
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(AppLocalizations.of(context).frequencyBand),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: DropdownButton<String>(
                          value: btState.band,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: '2.4G', child: Text('2.4G')),
                            DropdownMenuItem(value: '5G', child: Text('5G')),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            context.read<BTState>().setBand(v);
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
              ],
            ),
          ),

        const SizedBox(height: 12),

        Text('${AppLocalizations.of(context).batteryCapacityLabel} ${app.batteryCapacity_mAh.toStringAsFixed(0)}'),
        Slider(
          value: app.batteryCapacity_mAh,
          min: 50,
          max: 1200,
          divisions: 115,
          onChanged: (v) => context.read<AppState>().setBatteryCapacity(v),
        ),
        const SizedBox(height: 12),
        ChipInfoCard(chip: app.chip),
      ],
    );
  }
}

class SniffingConfigPanel extends StatelessWidget {
  const SniffingConfigPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final st = context.watch<BTState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context).config, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),

        Text(AppLocalizations.of(context).chip),
        const SizedBox(height: 6),
        Builder(builder: (ctx) {
          final isBtCase = st.caseType == BTCase.btSniff ||
              st.caseType == BTCase.btPage ||
              st.caseType == BTCase.btPagescan;
          final chipsList = isBtCase ? st.btChips : st.bleChips;
          return DropdownButton<String>(
            value: st.selectedChipId,
            isExpanded: true,
            items: chipsList
              .map<DropdownMenuItem<String>>((c) => DropdownMenuItem<String>(
                  value: (c as dynamic).id as String,
                  child: Text((c as dynamic).name as String),
                ))
              .toList(),
            onChanged: (v) {
              if (v != null) context.read<BTState>().setChip(v);
            },
          );
        }),
        const SizedBox(height: 12),

        Text(AppLocalizations.of(context).listeningCase),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: DropdownButton<BTCase>(
            value: st.caseType,
            isExpanded: true,
              items: [
                DropdownMenuItem(value: BTCase.btSniff, child: Text(AppLocalizations.of(context).btSniff)),
                DropdownMenuItem(value: BTCase.btPage, child: Text(AppLocalizations.of(context).btPage)),
                DropdownMenuItem(value: BTCase.btPagescan, child: Text(AppLocalizations.of(context).btPagescan)),
                DropdownMenuItem(value: BTCase.relay, child: const Text('Relay')),
              ],
            onChanged: (v) {
              if (v != null) context.read<BTState>().setCase(v);
            },
          ),
        ),
        const SizedBox(height: 12),

        // 发射功率选择（与 BLE 配置面板一致的交互）
        Builder(builder: (ctx) {
          final List<double> levels = st.chip.txPowerLevelsDbm.cast<double>();
          final double currentTx = st.chip.snapTxPower(st.txPowerDbm);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${AppLocalizations.of(context).txPowerLabel} $currentTx'),
              const SizedBox(height: 6),
              DropdownButton<double>(
                value: currentTx,
                isExpanded: true,
                items: levels
                    .map<DropdownMenuItem<double>>((lv) => DropdownMenuItem<double>(
                          value: lv,
                          child: Text(lv.toString()),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) context.read<BTState>().setTxPower(v);
                },
              ),
              const SizedBox(height: 12),
            ],
          );
        }),

        // Case-specific panel
        Builder(builder: (ctx) {
          switch (st.caseType) {
            case BTCase.btSniff:
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const SizedBox(height: 6),
                    Text('${AppLocalizations.of(context).hdtPeriod} ${st.hdtPeriodUs.toStringAsFixed(0)}'),
                      const SizedBox(height: 6),
                      Text('${AppLocalizations.of(context).listeningWindow} ${st.sniffWindowUs.toStringAsFixed(0)}'),
                  Slider(
                    value: st.sniffWindowUs.clamp(50.0, 3000.0),
                    min: 50.0,
                    max: 3000.0,
                    onChanged: (v) => context.read<BTState>().setSniffWindowUs(v),
                  ),
                ],
              );

            case BTCase.btPage:
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context).btPage),
                  const SizedBox(height: 6),
                  Text('${AppLocalizations.of(context).listeningInterval} ${st.sniffIntervalMs.toStringAsFixed(2)}'),
                  Slider(
                    value: st.sniffIntervalMs,
                    min: 10,
                    max: 5000,
                    onChanged: (v) => context.read<BTState>().setSniffIntervalMs(v),
                  ),
                  const SizedBox(height: 12),
                  Text('${AppLocalizations.of(context).listeningWindow} ${st.sniffWindowUs.toStringAsFixed(0)}'),
                  Slider(
                    value: st.sniffWindowUs.clamp(50.0, 50000.0),
                    min: 50.0,
                    max: 50000.0,
                    onChanged: (v) => context.read<BTState>().setSniffWindowUs(v),
                  ),
                ],
              );

            case BTCase.btPagescan:
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context).btPagescan),
                  const SizedBox(height: 6),
                  Text('${AppLocalizations.of(context).listeningInterval} ${st.sniffIntervalMs.toStringAsFixed(2)}'),
                  Slider(
                    value: st.sniffIntervalMs,
                    min: 10,
                    max: 5000,
                    onChanged: (v) => context.read<BTState>().setSniffIntervalMs(v),
                  ),
                  const SizedBox(height: 12),
                  Text('${AppLocalizations.of(context).listeningWindow} ${st.sniffWindowUs.toStringAsFixed(0)}'),
                  Slider(
                    value: st.sniffWindowUs.clamp(50.0, 50000.0),
                    min: 50.0,
                    max: 50000.0,
                    onChanged: (v) => context.read<BTState>().setSniffWindowUs(v),
                  ),
                  const SizedBox(height: 12),
                  Text('${AppLocalizations.of(context).channelsLabel} ${st.channelsPerCycle}'),
                  Slider(
                    value: st.channelsPerCycle.toDouble(),
                    min: 1,
                    max: 3,
                    divisions: 2,
                    onChanged: (v) => context.read<BTState>().setChannels(v.round()),
                  ),
                  const SizedBox(height: 12),
                  Text('${AppLocalizations.of(context).channelGap} ${st.channelGapUs.toStringAsFixed(0)}'),
                  const SizedBox(height: 6),
                  Text(AppLocalizations.of(context).defaultNote, style: Theme.of(context).textTheme.bodySmall),
                ],
              );


            case BTCase.relay:
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context).relay),
                  const SizedBox(height: 6),
                  Text('${AppLocalizations.of(context).listeningInterval} ${st.sniffIntervalMs.toStringAsFixed(2)}'),
                  Slider(
                    value: st.sniffIntervalMs,
                    min: 10,
                    max: 5000,
                    onChanged: (v) => context.read<BTState>().setSniffIntervalMs(v),
                  ),
                  const SizedBox(height: 12),
                  Text('${AppLocalizations.of(context).listeningWindow} ${st.sniffWindowUs.toStringAsFixed(0)}'),
                  Slider(
                    value: st.sniffWindowUs.clamp(50.0, 50000.0),
                    min: 50.0,
                    max: 50000.0,
                    onChanged: (v) => context.read<BTState>().setSniffWindowUs(v),
                  ),
                  const SizedBox(height: 12),
                  Text('${AppLocalizations.of(context).relayHopGap} ${st.relayHopGapUs.toStringAsFixed(0)}'),
                  Slider(
                    value: st.relayHopGapUs.clamp(0.0, 100000.0),
                    min: 0.0,
                    max: 100000.0,
                    onChanged: (v) => context.read<BTState>().setRelayHopGapUs(v),
                  ),
                ],
              );
          }
        }),
        const SizedBox(height: 12),

        Text('${AppLocalizations.of(context).batteryCapacityLabel} ${st.batteryCapacity_mAh.toStringAsFixed(0)}'),
        Slider(
          value: st.batteryCapacity_mAh,
          min: 50,
          max: 1200,
          divisions: 115,
          onChanged: (v) => context.read<BTState>().setBatteryCapacity(v),
        ),
        const SizedBox(height: 12),
        ChipInfoCard(chip: st.chip),
      ],
    );
  }
}

class ChipInfoCard extends StatelessWidget {
  final dynamic chip; // BleChip type (import avoided to keep file small)
  const ChipInfoCard({super.key, required this.chip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).chipSpecsTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _specItem(context, AppLocalizations.of(context).model, chip.name),
                _specItem(context, AppLocalizations.of(context).vbat, '${chip.vbat} V'),
                // _specItem('Sleep', '${chip.sleepCurrent_uA} µA'),
                _specItem(context, AppLocalizations.of(context).rx, '${chip.rxCurrent_mA} mA'),
                _specItem(context, AppLocalizations.of(context).tx, '${chip.txCurrent_mA_forDbm[chip.txPowerLevelsDbm.first]} mA'),
                _specItem(context, AppLocalizations.of(context).descriptionLabel, '${chip.description}'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).chipSpecsDescription,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _specItem(BuildContext context, String title, String value) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}



// class description extends StatelessWidget {
//   const description({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Text(
//       'The tool is based on a model of measured values, and is not showing the actual measurement. The results are therefore estimates of the expected value. It is meant for evaluation purposes only, and will not give the exact numbers in every use case. Testing shows that the estimated average current is typically within 5% of the actual value for the reference parts. The device to device variations will add to this inaccuracy. Please refer to the nRF52 Product Specification for expected min/max values for the different current components.',
//       style: theme.textTheme.bodySmall,
//     );
//   }
// }
