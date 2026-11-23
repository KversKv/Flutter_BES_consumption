import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/ble_chip.dart';
import '../models/power_event.dart';
import '../models/profile_params.dart';
import '../services/power_calculator.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'chart_widgets.dart';
import 'config_panel_frame.dart';
import 'duration_format.dart';
import 'kpi_widgets.dart';

typedef BleAdminStageFieldChanged = void Function(
  List<String> path,
  String value,
);

class BleAdminStageField {
  final List<String> path;
  final String value;
  final bool shared;

  const BleAdminStageField({
    required this.path,
    required this.value,
    this.shared = false,
  });
}

class BleAdminPreview extends StatelessWidget {
  final BleChip chip;
  final ProfileParams params;
  final BleCalculationResult result;
  final bool useNordicModel;
  final bool hideLowPowerGaps;
  final bool hasPreviewError;
  final double batteryCapacityMah;
  final HdtModule hdtModule;
  final String hdtBand;
  final String? selectedStageId;
  final List<BleAdminStageField> stageFields;
  final bool selectedStageHasDerivedTiming;
  final ValueChanged<ProfileParams> onParamsChanged;
  final ValueChanged<bool> onUseNordicModelChanged;
  final ValueChanged<bool> onHideLowPowerGapsChanged;
  final ValueChanged<double> onBatteryCapacityChanged;
  final ValueChanged<HdtModule> onHdtModuleChanged;
  final ValueChanged<String> onHdtBandChanged;
  final ValueChanged<PowerEvent> onEventTap;
  final BleAdminStageFieldChanged onStageFieldChanged;
  final Widget? parameterEditor;

  const BleAdminPreview({
    super.key,
    required this.chip,
    required this.params,
    required this.result,
    required this.useNordicModel,
    required this.hideLowPowerGaps,
    required this.hasPreviewError,
    required this.batteryCapacityMah,
    required this.hdtModule,
    required this.hdtBand,
    required this.selectedStageId,
    required this.stageFields,
    required this.selectedStageHasDerivedTiming,
    required this.onParamsChanged,
    required this.onUseNordicModelChanged,
    required this.onHideLowPowerGapsChanged,
    required this.onBatteryCapacityChanged,
    required this.onHdtModuleChanged,
    required this.onHdtBandChanged,
    required this.onEventTap,
    required this.onStageFieldChanged,
    this.parameterEditor,
  });

  @override
  Widget build(BuildContext context) {
    final editor = parameterEditor;
    if (editor != null) return _embeddedLayout(context, editor);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _previewControls(context),
        _resultsSection(context, chartHeight: 430),
        _stageSection(context),
      ],
    );
  }

  Widget _embeddedLayout(BuildContext context, Widget editor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final topHeight = constraints.maxHeight.isFinite
            ? (constraints.maxHeight * 0.58).clamp(360.0, 560.0)
            : 480.0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: topHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 2,
                    child: _PreviewScrollRegion(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _previewControls(context),
                          const SizedBox(height: AppSpacing.x4),
                          _stageSection(context),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x3),
                  Expanded(
                    flex: 3,
                    child: _resultsSection(context, fillHeight: true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x3),
            Expanded(child: _PreviewScrollRegion(child: editor)),
          ],
        );
      },
    );
  }

  Widget _previewControls(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConfigPanelTitle(
          title: t.adminBlePreview,
          icon: Icons.insights_outlined,
        ),
        const SizedBox(height: AppSpacing.x2),
        Text(
          t.adminBlePreviewHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: palette.textSecondary,
          ),
        ),
        if (hasPreviewError) ...[
          const SizedBox(height: AppSpacing.x3),
          Material(
            color: palette.danger.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.x3),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: palette.danger, size: 18),
                  const SizedBox(width: AppSpacing.x2),
                  Expanded(
                    child: Text(
                      t.adminBlePreviewInvalid,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.x4),
        ConfigSectionCard(
          title: t.adminBlePreviewScenario,
          icon: Icons.tune,
          children: _scenarioChildren(context),
        ),
      ],
    );
  }

  Widget _resultsSection(
    BuildContext context, {
    double? chartHeight,
    bool fillHeight = false,
  }) {
    final theme = Theme.of(context);
    final chart = Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: UnifiedPowerChart(
          events: result.events,
          periodUs: result.periodUs,
          maxCurrent: PowerCalculator.computeMaxCurrent(result.events),
          hideLowPowerGaps: hideLowPowerGaps,
          onToggleHideGaps: onHideLowPowerGapsChanged,
          useNordicModel: useNordicModel,
          onToggleModel: onUseNordicModelChanged,
          selectedStageId: selectedStageId,
          onEventTap: onEventTap,
        ),
      ),
    );
    if (fillHeight) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 4,
            child: _PreviewScrollRegion(
              child: KpiRow(metrics: _metrics(context)),
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
          Expanded(flex: 5, child: chart),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KpiRow(metrics: _metrics(context)),
        const SizedBox(height: AppSpacing.x4),
        SizedBox(height: chartHeight, child: chart),
      ],
    );
  }

  Widget _stageSection(BuildContext context) {
    final t = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final selectedEvent = _selectedEvent();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.x3),
        if (selectedEvent == null)
          Row(
            children: [
              Icon(Icons.touch_app_outlined, size: 18, color: palette.accent),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: Text(
                  t.adminBleStageHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                ),
              ),
            ],
          )
        else
          _stageEditor(context, selectedEvent),
      ],
    );
  }

  PowerEvent? _selectedEvent() {
    for (final event in result.events) {
      if (event.stageId == selectedStageId) return event;
    }
    return null;
  }

  List<Widget> _scenarioChildren(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isConnection = params.mode == Mode.bleConnectionCentral ||
        params.mode == Mode.bleConnectionPeripheral;
    final isAdvertising = params.mode == Mode.advertisingTxOnly ||
        params.mode == Mode.advertisingTxRx;
    final isHdt = params.mode == Mode.hdt;
    final txLevels = chip.txPowerLevelsDbm;
    final currentTx = chip.snapTxPower(params.txPowerDbm);
    final payloadMax = useNordicModel ? 2000.0 : 251.0;

    return [
      ConfigField(
        label: t.mode,
        child: _dropdown<Mode>(
          value: params.mode,
          items: [
            DropdownMenuItem(
              value: Mode.advertisingTxRx,
              child: Text(t.advertisingTxRx),
            ),
            DropdownMenuItem(
              value: Mode.advertisingTxOnly,
              child: Text(t.advertisingTxOnly),
            ),
            DropdownMenuItem(
              value: Mode.bleConnectionPeripheral,
              child: Text(t.bleConnectionPeripheral),
            ),
            DropdownMenuItem(
              value: Mode.bleConnectionCentral,
              child: Text(t.bleConnectionCentral),
            ),
            if (chip.supportsHDT)
              const DropdownMenuItem(value: Mode.hdt, child: Text('HDT')),
          ],
          onChanged: (value) => _updateParams((p) => p.mode = value),
        ),
      ),
      if (!isHdt)
        ConfigField(
          label: t.phy,
          child: SegmentedButton<Phy>(
            segments: const [
              ButtonSegment(value: Phy.le1M, label: Text('1M')),
              ButtonSegment(value: Phy.le2M, label: Text('2M')),
            ],
            selected: {params.phy},
            onSelectionChanged: (selection) =>
                _updateParams((p) => p.phy = selection.first),
          ),
        ),
      if (txLevels.isNotEmpty)
        ConfigField(
          label: t.txPowerLabel,
          child: _dropdown<double>(
            value: currentTx,
            items: txLevels
                .map(
                  (level) => DropdownMenuItem(
                    value: level,
                    child: Text('$level dBm'),
                  ),
                )
                .toList(),
            onChanged: (value) => _updateParams((p) => p.txPowerDbm = value),
          ),
        ),
      if (!isHdt) ...[
        ConfigField(
          label: t.payloadBytesLabel,
          value: '${params.payloadBytes.clamp(0, payloadMax.toInt())} bytes',
          child: Slider(
            value: params.payloadBytes.toDouble().clamp(0.0, payloadMax),
            min: 0,
            max: payloadMax,
            divisions: payloadMax.toInt(),
            onChanged: (value) =>
                _updateParams((p) => p.payloadBytes = value.round()),
          ),
        ),
        if (isAdvertising)
          ConfigField(
            label: t.advIntervalLabel,
            value: '${params.advIntervalMs.toStringAsFixed(0)} ms',
            child: Slider(
              value: params.advIntervalMs.clamp(20.0, 2000.0),
              min: 20,
              max: 2000,
              onChanged: (value) =>
                  _updateParams((p) => p.advIntervalMs = value),
            ),
          )
        else
          ConfigField(
            label: t.connIntervalLabel,
            value: '${params.connIntervalMs.toStringAsFixed(2)} ms',
            child: Slider(
              value: params.connIntervalMs.clamp(7.5, 4000.0),
              min: 7.5,
              max: 4000,
              onChanged: (value) =>
                  _updateParams((p) => p.connIntervalMs = value),
            ),
          ),
      ],
      if (useNordicModel && isConnection) ...[
        ConfigField(
          label: t.rxPayloadLabel,
          value: '${params.rxPayloadBytes} bytes',
          child: Slider(
            value: params.rxPayloadBytes.toDouble().clamp(0.0, 251.0),
            min: 0,
            max: 251,
            divisions: 251,
            onChanged: (value) =>
                _updateParams((p) => p.rxPayloadBytes = value.round()),
          ),
        ),
        ConfigSwitchTile(
          title: t.dleLabel,
          value: params.dle,
          onChanged: (value) => _updateParams((p) => p.dle = value),
        ),
        ConfigSwitchTile(
          title: t.celeLabel,
          value: params.eventLengthExt,
          onChanged: (value) => _updateParams((p) => p.eventLengthExt = value),
        ),
        ConfigField(
          label: t.slaveLatencyLabel,
          value: '${params.slaveLatency}',
          child: Slider(
            value: params.slaveLatency.toDouble().clamp(0.0, 159.0),
            min: 0,
            max: 159,
            divisions: 159,
            onChanged: (value) =>
                _updateParams((p) => p.slaveLatency = value.round()),
          ),
        ),
        ConfigField(
          label: t.centralPpmLabel,
          value: '${params.centralPpm}',
          child: Slider(
            value: params.centralPpm.toDouble().clamp(20.0, 500.0),
            min: 20,
            max: 500,
            onChanged: (value) =>
                _updateParams((p) => p.centralPpm = value.round()),
          ),
        ),
        ConfigField(
          label: t.peripheralPpmLabel,
          value: '${params.peripheralPpm}',
          child: Slider(
            value: params.peripheralPpm.toDouble().clamp(20.0, 500.0),
            min: 20,
            max: 500,
            onChanged: (value) =>
                _updateParams((p) => p.peripheralPpm = value.round()),
          ),
        ),
        ConfigField(
          label: t.lfClockLabel,
          child: SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(t.lfXo)),
              ButtonSegment(value: true, label: Text(t.lfRc)),
            ],
            selected: {params.lfRc},
            onSelectionChanged: (selection) =>
                _updateParams((p) => p.lfRc = selection.first),
          ),
        ),
      ],
      if (isHdt) ...[
        ConfigField(
          label: t.moduleRole,
          child: _dropdown<HdtModule>(
            value: hdtModule,
            items: [
              DropdownMenuItem(
                value: HdtModule.sink,
                child: Text(t.sink),
              ),
              DropdownMenuItem(
                value: HdtModule.source,
                child: Text(t.source),
              ),
            ],
            onChanged: onHdtModuleChanged,
          ),
        ),
        ConfigField(
          label: t.frequencyBand,
          child: _dropdown<String>(
            value: hdtBand,
            items: const [
              DropdownMenuItem(value: '2.4G', child: Text('2.4G')),
              DropdownMenuItem(value: '5G', child: Text('5G')),
            ],
            onChanged: onHdtBandChanged,
          ),
        ),
      ],
      ConfigField(
        label: t.batteryCapacityLabel,
        value: '${batteryCapacityMah.toStringAsFixed(0)} mAh',
        child: Slider(
          value: batteryCapacityMah.clamp(50.0, 1200.0),
          min: 50,
          max: 1200,
          divisions: 115,
          onChanged: onBatteryCapacityChanged,
        ),
      ),
    ];
  }

  Widget _dropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T> onChanged,
  }) {
    return SizedBox(
      width: double.infinity,
      child: DropdownButtonFormField<T>(
        key: ValueKey('$T-$value-${items.length}'),
        initialValue: value,
        decoration: const InputDecoration(isDense: true),
        items: items,
        onChanged: (selected) {
          if (selected != null) onChanged(selected);
        },
      ),
    );
  }

  List<KpiMetric> _metrics(BuildContext context) {
    final t = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final average = PowerCalculator.computeAverageCurrent(
      result.events,
      result.periodUs,
    );
    final hours = average <= 0 ? double.infinity : batteryCapacityMah / average;
    final days = hours / 24;
    final charge = PowerCalculator.computeEventCharge_uC(result.events);
    final throughput = PowerCalculator.computeBleThroughputBps(
      params,
      result.periodUs,
      params.payloadBytes,
      useNordicModel,
    );

    return [
      KpiMetric(
        title: t.kpiPeriod,
        value: '${(result.periodUs / 1000).toStringAsFixed(1)} ms',
        icon: Icons.timelapse,
        accent: palette.info,
      ),
      KpiMetric(
        title: t.kpiAvgCurrent,
        value: _formatCurrentAuto(average),
        icon: Icons.bolt,
        accent: palette.accent,
      ),
      KpiMetric(
        title: t.kpiSleepCurrent,
        value: '${chip.sleepCurrent_uA.toStringAsFixed(2)} uA',
        icon: Icons.bedtime,
        accent: palette.textSecondary,
      ),
      KpiMetric(
        title: t.kpiBatteryLifeEst,
        value:
            '${days.isFinite ? days.toStringAsFixed(1) : '--'} ${t.kpiDaysUnit}',
        icon: Icons.battery_full,
        accent: palette.success,
      ),
      KpiMetric(
        title: t.kpiPeakCurrent,
        value:
            '${PowerCalculator.computeMaxCurrent(result.events).toStringAsFixed(2)} mA',
        icon: Icons.signal_cellular_alt,
        accent: palette.warning,
      ),
      if (useNordicModel) ...[
        KpiMetric(
          title: t.kpiEventCharge,
          value: '${charge.toStringAsFixed(2)} µC',
          icon: Icons.electric_meter,
          accent: palette.info,
        ),
        KpiMetric(
          title: t.kpiTxThroughput,
          value: '${(throughput / 1000).toStringAsFixed(2)} kbps',
          icon: Icons.speed,
          accent: palette.accent,
        ),
      ],
    ];
  }

  Widget _stageEditor(BuildContext context, PowerEvent event) {
    final t = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    return ConfigSectionCard(
      title: '${t.adminBleStageEditor}: ${event.previewLabel ?? event.label}',
      icon: Icons.edit_outlined,
      accent: palette.warning,
      children: [
        Wrap(
          spacing: AppSpacing.x4,
          runSpacing: AppSpacing.x2,
          children: [
            Text('${t.chartLength}: ${formatDurationUsAuto(event.durationUs)}'),
            Text('${t.chartCurrent}: ${event.currentMa.toStringAsFixed(3)} mA'),
          ],
        ),
        if (selectedStageHasDerivedTiming)
          Text(
            t.adminBleStageDerived,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: palette.textSecondary,
                ),
          ),
        if (stageFields.isEmpty)
          Text(t.adminBleStageNoFields)
        else ...[
          if (stageFields.any((field) => field.shared))
            Row(
              children: [
                Icon(Icons.link, size: 16, color: palette.info),
                const SizedBox(width: AppSpacing.x2),
                Expanded(
                  child: Text(
                    t.adminBleStageShared,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.textSecondary,
                        ),
                  ),
                ),
              ],
            ),
          for (final field in stageFields)
            BleAdminStageFieldInput(
              key: ValueKey(field.path.join('/')),
              field: field,
              onChanged: onStageFieldChanged,
            ),
        ],
      ],
    );
  }

  ProfileParams _copyParams() {
    return ProfileParams(
      mode: params.mode,
      phy: params.phy,
      txPowerDbm: params.txPowerDbm,
      advIntervalMs: params.advIntervalMs,
      connIntervalMs: params.connIntervalMs,
      payloadBytes: params.payloadBytes,
      rxPayloadBytes: params.rxPayloadBytes,
      dle: params.dle,
      eventLengthExt: params.eventLengthExt,
      slaveLatency: params.slaveLatency,
      centralPpm: params.centralPpm,
      peripheralPpm: params.peripheralPpm,
      lfRc: params.lfRc,
    );
  }

  void _updateParams(void Function(ProfileParams params) update) {
    final copy = _copyParams();
    update(copy);
    onParamsChanged(copy);
  }

  static String _formatCurrentAuto(double currentMa) {
    if (currentMa < 1.0) {
      return '${(currentMa * 1000).toStringAsFixed(2)} µA';
    }
    return '${currentMa.toStringAsFixed(2)} mA';
  }
}

class BleAdminStageFieldInput extends StatefulWidget {
  final BleAdminStageField field;
  final BleAdminStageFieldChanged onChanged;

  const BleAdminStageFieldInput({
    super.key,
    required this.field,
    required this.onChanged,
  });

  @override
  State<BleAdminStageFieldInput> createState() =>
      _BleAdminStageFieldInputState();
}

class _BleAdminStageFieldInputState extends State<BleAdminStageFieldInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.field.value);
  }

  @override
  void didUpdateWidget(covariant BleAdminStageFieldInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.field.value != widget.field.value &&
        _controller.text != widget.field.value) {
      _controller.value = TextEditingValue(
        text: widget.field.value,
        selection: TextSelection.collapsed(offset: widget.field.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: ValueKey('ble-stage-field-${widget.field.path.join('.')}'),
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      decoration: InputDecoration(
        labelText: widget.field.path.join(' / '),
        isDense: true,
      ),
      onChanged: (value) => widget.onChanged(widget.field.path, value),
    );
  }
}

class _PreviewScrollRegion extends StatefulWidget {
  final Widget child;

  const _PreviewScrollRegion({required this.child});

  @override
  State<_PreviewScrollRegion> createState() => _PreviewScrollRegionState();
}

class _PreviewScrollRegionState extends State<_PreviewScrollRegion> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _controller,
      thumbVisibility: true,
      interactive: true,
      child: SingleChildScrollView(
        controller: _controller,
        padding: const EdgeInsets.only(right: AppSpacing.x2),
        child: widget.child,
      ),
    );
  }
}
