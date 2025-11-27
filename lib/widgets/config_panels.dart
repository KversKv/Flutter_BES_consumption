import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../state/sniffing_state.dart';
import '../models/profile_params.dart';

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
    // Try to sync SniffingState with AppState if provider is present.
    final app = context.watch<AppState>();
    try {
      final sniffState = context.read<SniffingState>();
      sniffState.setMode(app.params.mode);
      sniffState.setConnIntervalMs(app.params.connIntervalMs);
      sniffState.setAdvIntervalMs(app.params.advIntervalMs);
      sniffState.setTxPower(app.params.txPowerDbm);
    } catch (_) {
      // Provider<SniffingState> not found above this widget; ignore sync.
    }
    final levels = app.chip.txPowerLevelsDbm;
    final currentTx = app.chip.snapTxPower(app.params.txPowerDbm);

    if (app.params.mode == Mode.connected) {
      _setConnText(app.params.connIntervalMs);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('配置', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),

        Text('芯片'),
        const SizedBox(height: 6),
        DropdownButton<String>(
          value: app.selectedChipId,
          isExpanded: true,
          items: app.chips
              .map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) context.read<AppState>().setChip(v);
          },
        ),
        const SizedBox(height: 12),

        Text('模式'),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<Mode>(
            segments: const [
              ButtonSegment(value: Mode.connected, label: Text('连接')),
              ButtonSegment(value: Mode.advertising, label: Text('广播')),
            ],
            selected: {app.params.mode},
            onSelectionChanged: (s) {
              context.read<AppState>().setMode(s.first);
            },
          ),
        ),
        const SizedBox(height: 12),

        Text('PHY'),
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

        Text('发射功率 (dBm): $currentTx'),
        const SizedBox(height: 6),
        DropdownButton<double>(
          value: currentTx,
          isExpanded: true,
          items: levels
              .map((lv) => DropdownMenuItem(
                    value: lv,
                    child: Text(lv.toString()),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) context.read<AppState>().setTxPower(v);
          },
        ),
        const SizedBox(height: 12),

        Text('负载字节数: ${app.params.payloadBytes}'),
        Slider(
          value: app.params.payloadBytes.toDouble(),
          min: 0,
          max: 251,
          divisions: 251,
          onChanged: (v) => context.read<AppState>().setPayloadBytes(v.round()),
        ),
        const SizedBox(height: 12),

        if (app.params.mode == Mode.advertising)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('广播间隔 (ms): ${app.params.advIntervalMs.toStringAsFixed(0)}'),
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
                  const Text('连接间隔 (ms)'),
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
                      // Allow free typing; only apply quantization on submit or editing complete.
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
        const SizedBox(height: 12),

        Text('电池容量 (mAh): ${app.batteryCapacity_mAh.toStringAsFixed(0)}'),
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
    final st = context.watch<SniffingState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('配置', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),

        Text('芯片'),
        const SizedBox(height: 6),
        Builder(builder: (ctx) {
          final isBtCase = st.caseType == SniffCase.btSniff ||
              st.caseType == SniffCase.btPage ||
              st.caseType == SniffCase.btPagescan;
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
              if (v != null) context.read<SniffingState>().setChip(v);
            },
          );
        }),
        const SizedBox(height: 12),

        Text('侦听用例'),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<SniffCase>(
            segments: const [
              ButtonSegment(value: SniffCase.btSniff, label: Text('BT sniff')),
              ButtonSegment(value: SniffCase.btPage, label: Text('BT page')),
              ButtonSegment(value: SniffCase.btPagescan, label: Text('BT pagescan')),
              ButtonSegment(value: SniffCase.hdt, label: Text('HDT')),
              ButtonSegment(value: SniffCase.relay, label: Text('Relay')),
            ],
            selected: {st.caseType},
            onSelectionChanged: (s) => context.read<SniffingState>().setCase(s.first),
          ),
        ),
        const SizedBox(height: 12),

        // 新增：发射功率选择（与 BLE 配置面板一致的交互）
        Builder(builder: (ctx) {
          final levels = st.chip.txPowerLevelsDbm;
          final currentTx = st.chip.snapTxPower(st.txPowerDbm);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('发射功率 (dBm): $currentTx'),
              const SizedBox(height: 6),
              DropdownButton<double>(
                value: currentTx,
                isExpanded: true,
                items: (levels as List<dynamic>)
                    .map<DropdownMenuItem<double>>((lv) => DropdownMenuItem<double>(
                          value: lv as double,
                          child: Text(lv.toString()),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) context.read<SniffingState>().setTxPower(v);
                },
              ),
              const SizedBox(height: 12),
            ],
          );
        }),

        // Case-specific panel
        Builder(builder: (ctx) {
          switch (st.caseType) {
            case SniffCase.btSniff:
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const SizedBox(height: 6),
                  Text('HDT 周期 (µs): ${st.hdtPeriodUs.toStringAsFixed(0)}'),
                  const SizedBox(height: 6),
                  Text('（由代码变量指定，默认 500 µs，不可交互修改）', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  Text('侦听窗口 (µs): ${st.sniffWindowUs.toStringAsFixed(0)}'),
                  Slider(
                    value: st.sniffWindowUs.clamp(50.0, 3000.0),
                    min: 50.0,
                    max: 3000.0,
                    onChanged: (v) => context.read<SniffingState>().setSniffWindowUs(v),
                  ),
                ],
              );

            case SniffCase.btPage:
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BT Page'),
                  const SizedBox(height: 6),
                  Text('侦听间隔 (ms): ${st.sniffIntervalMs.toStringAsFixed(2)}'),
                  Slider(
                    value: st.sniffIntervalMs,
                    min: 10,
                    max: 5000,
                    onChanged: (v) => context.read<SniffingState>().setSniffIntervalMs(v),
                  ),
                  const SizedBox(height: 12),
                  Text('侦听窗口 (µs): ${st.sniffWindowUs.toStringAsFixed(0)}'),
                  Slider(
                    value: st.sniffWindowUs.clamp(50.0, 50000.0),
                    min: 50.0,
                    max: 50000.0,
                    onChanged: (v) => context.read<SniffingState>().setSniffWindowUs(v),
                  ),
                ],
              );

            case SniffCase.btPagescan:
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BT PageScan'),
                  const SizedBox(height: 6),
                  Text('侦听间隔 (ms): ${st.sniffIntervalMs.toStringAsFixed(2)}'),
                  Slider(
                    value: st.sniffIntervalMs,
                    min: 10,
                    max: 5000,
                    onChanged: (v) => context.read<SniffingState>().setSniffIntervalMs(v),
                  ),
                  const SizedBox(height: 12),
                  Text('侦听窗口 (µs): ${st.sniffWindowUs.toStringAsFixed(0)}'),
                  Slider(
                    value: st.sniffWindowUs.clamp(50.0, 50000.0),
                    min: 50.0,
                    max: 50000.0,
                    onChanged: (v) => context.read<SniffingState>().setSniffWindowUs(v),
                  ),
                  const SizedBox(height: 12),
                  Text('侦听信道数: ${st.channelsPerCycle}'),
                  Slider(
                    value: st.channelsPerCycle.toDouble(),
                    min: 1,
                    max: 3,
                    divisions: 2,
                    onChanged: (v) => context.read<SniffingState>().setChannels(v.round()),
                  ),
                  const SizedBox(height: 12),
                  Text('信道间隙 (µs): ${st.channelGapUs.toStringAsFixed(0)}'),
                  const SizedBox(height: 6),
                  Text('（由代码变量指定，默认 150 µs，不可交互修改）', style: Theme.of(context).textTheme.bodySmall),
                ],
              );

            case SniffCase.hdt:
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text('模块角色'),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<HdtModule>(
                      segments: const [
                        ButtonSegment(value: HdtModule.sink, label: Text('Sink')),
                        ButtonSegment(value: HdtModule.source, label: Text('Source')),
                      ],
                      selected: {st.hdtModule},
                      onSelectionChanged: (s) => context.read<SniffingState>().setHdtModule(s.first),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('HDT PHY 速率 (Mbps): ${st.hdtPhyRateMbps.toStringAsFixed(0)}'),
                  const SizedBox(height: 6),
                  DropdownButton<double>(
                    value: st.hdtPhyRateMbps,
                    isExpanded: true,
                    items: List.generate(14, (i) => (i + 2).toDouble())
                        .map((v) => DropdownMenuItem(value: v, child: Text('${v.toStringAsFixed(0)}')))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) context.read<SniffingState>().setHdtPhyRate(v);
                    },
                  ),
                  const SizedBox(height: 12),
                  Text('HDT repeats: ${st.hdtRepeats}'),
                  Slider(
                    value: st.hdtRepeats.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    onChanged: (v) => context.read<SniffingState>().setHdtRepeats(v.round()),
                  ),
                ],
              );

            case SniffCase.relay:
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Relay'),
                  const SizedBox(height: 6),
                  Text('侦听间隔 (ms): ${st.sniffIntervalMs.toStringAsFixed(2)}'),
                  Slider(
                    value: st.sniffIntervalMs,
                    min: 10,
                    max: 5000,
                    onChanged: (v) => context.read<SniffingState>().setSniffIntervalMs(v),
                  ),
                  const SizedBox(height: 12),
                  Text('侦听窗口 (µs): ${st.sniffWindowUs.toStringAsFixed(0)}'),
                  Slider(
                    value: st.sniffWindowUs.clamp(50.0, 50000.0),
                    min: 50.0,
                    max: 50000.0,
                    onChanged: (v) => context.read<SniffingState>().setSniffWindowUs(v),
                  ),
                  const SizedBox(height: 12),
                  Text('Relay hop gap (µs): ${st.relayHopGapUs.toStringAsFixed(0)}'),
                  Slider(
                    value: st.relayHopGapUs.clamp(0.0, 100000.0),
                    min: 0.0,
                    max: 100000.0,
                    onChanged: (v) => context.read<SniffingState>().setRelayHopGapUs(v),
                  ),
                ],
              );
          }
        }),
        const SizedBox(height: 12),

        Text('电池容量 (mAh): ${st.batteryCapacity_mAh.toStringAsFixed(0)}'),
        Slider(
          value: st.batteryCapacity_mAh,
          min: 50,
          max: 1200,
          divisions: 115,
          onChanged: (v) => context.read<SniffingState>().setBatteryCapacity(v),
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
            Text('芯片规格与特点', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _specItem('型号', chip.name),
                _specItem('VBAT', '${chip.vbat} V'),
                _specItem('Sleep', '${chip.sleepCurrent_uA} µA'),
                _specItem('RX', '${chip.rxCurrent_mA} mA'),
                _specItem('RX Window', '${chip.rxWindow_us} µs'),
                _specItem('Description', '${chip.description}'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '说明：显示芯片的关键参数，便于快速比较。',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _specItem(String title, String value) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
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
