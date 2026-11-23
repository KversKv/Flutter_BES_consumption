import 'package:bes_consumption/models/ble_chip.dart';
import 'package:bes_consumption/models/power_event.dart';
import 'package:bes_consumption/models/profile_params.dart';
import 'package:bes_consumption/services/power_calculator.dart';
import 'package:bes_consumption/widgets/ble_admin_preview.dart';
import 'package:bes_consumption/widgets/chart_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

BleChip _chip({double rxCurrent = 6, double txCurrent = 5}) {
  return BleChip.fromJson({
    'id': 'preview',
    'name': 'Preview chip',
    'sleepCurrent_uA': 2.0,
    'rxCurrent_mA': rxCurrent,
    'tifs_us': 150,
    'tifsCurrent_mA': 1.0,
    'txCurrent_mA_forDbm': {'0': txCurrent},
    'postProcess_us': 350,
    'postCurrent_mA': 2.0,
    'preProcess_us': 60,
    'preProcessCurrent_mA': 4.0,
    'crystalRampUp_us': 400,
    'crystalRampUpCurrent_mA': 1.5,
    'standby_us': 1072,
    'standbyCurrent_mA': 0.4,
    'startRadio_us': 130,
    'startRadioCurrent_mA': 3.0,
    'advGap_us': 62,
    'advGapCurrent_mA': 0.5,
  });
}

ProfileParams _params() {
  return ProfileParams(
    mode: Mode.bleConnectionPeripheral,
    phy: Phy.le1M,
    txPowerDbm: 0,
    advIntervalMs: 100,
    connIntervalMs: 200,
    payloadBytes: 3,
  );
}

BleCalculationResult _result(BleChip chip, ProfileParams params) {
  return PowerCalculator.calculateBle(
    chip: chip,
    params: params,
    useNordicModel: true,
  );
}

Widget _preview({
  BleChip? chip,
  ProfileParams? params,
  String? selectedStageId,
  List<BleAdminStageField> stageFields = const [],
  bool hasPreviewError = false,
  ValueChanged<PowerEvent>? onEventTap,
  BleAdminStageFieldChanged? onStageFieldChanged,
}) {
  final resolvedChip = chip ?? _chip();
  final resolvedParams = params ?? _params();
  return BleAdminPreview(
    chip: resolvedChip,
    params: resolvedParams,
    result: _result(resolvedChip, resolvedParams),
    useNordicModel: true,
    hideLowPowerGaps: false,
    hasPreviewError: hasPreviewError,
    batteryCapacityMah: 220,
    hdtModule: HdtModule.sink,
    hdtBand: '2.4G',
    selectedStageId: selectedStageId,
    stageFields: stageFields,
    selectedStageHasDerivedTiming: false,
    onParamsChanged: (_) {},
    onUseNordicModelChanged: (_) {},
    onHideLowPowerGapsChanged: (_) {},
    onBatteryCapacityChanged: (_) {},
    onHdtModuleChanged: (_) {},
    onHdtBandChanged: (_) {},
    onEventTap: onEventTap ?? (_) {},
    onStageFieldChanged: onStageFieldChanged ?? (_, __) {},
  );
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(width: 900, child: child),
        ),
      ),
    ),
  );
  await tester.pump();
}

String _formatCurrent(double currentMa) {
  if (currentMa < 1) return '${(currentMa * 1000).toStringAsFixed(2)} µA';
  return '${currentMa.toStringAsFixed(2)} mA';
}

void main() {
  testWidgets('legend selects a phase and edits the mapped field',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    String? selected;
    var fieldValue = '60';
    PowerEvent? tapped;
    List<String>? editedPath;
    await _pump(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          return _preview(
            selectedStageId: selected,
            stageFields: selected == null
                ? const []
                : [
                    BleAdminStageField(
                      path: const ['preProcess_us'],
                      value: fieldValue,
                    ),
                  ],
            onEventTap: (event) => setState(() {
              selected = event.stageId;
              tapped = event;
            }),
            onStageFieldChanged: (path, value) => setState(() {
              editedPath = path;
              fieldValue = value;
            }),
          );
        },
      ),
    );

    await tester.tap(find.text('Pre-processing'));
    await tester.pump();
    expect(tapped?.stageId, 'setup.preProcess');
    expect(find.text('Edit selected phase: Pre-processing'), findsOneWidget);

    final input = find.byKey(
      const ValueKey('ble-stage-field-preProcess_us'),
    );
    expect(input, findsOneWidget);
    await tester.enterText(input, '200');
    await tester.pump();
    expect(editedPath, ['preProcess_us']);
    expect(fieldValue, '200');
    expect(find.text('200'), findsOneWidget);
  });

  testWidgets('nested TX edit immediately updates chart data and KPI',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var txCurrent = 5.0;
    final params = _params();
    List<String>? editedPath;
    await _pump(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          final chip = _chip(txCurrent: txCurrent);
          return _preview(
            chip: chip,
            params: params,
            selectedStageId: 'tx',
            stageFields: [
              BleAdminStageField(
                path: const ['txCurrent_mA_forDbm', '0'],
                value: '$txCurrent',
                shared: true,
              ),
            ],
            onStageFieldChanged: (path, value) => setState(() {
              editedPath = path;
              txCurrent = double.parse(value);
            }),
          );
        },
      ),
    );

    final beforeChip = _chip(txCurrent: 5);
    final beforeResult = _result(beforeChip, params);
    final beforeAverage = PowerCalculator.computeAverageCurrent(
      beforeResult.events,
      beforeResult.periodUs,
    );
    expect(find.text(_formatCurrent(beforeAverage)), findsOneWidget);

    await tester.enterText(
      find.byKey(
        const ValueKey('ble-stage-field-txCurrent_mA_forDbm.0'),
      ),
      '10',
    );
    await tester.pump();

    expect(editedPath, ['txCurrent_mA_forDbm', '0']);
    final afterChip = _chip(txCurrent: 10);
    final afterResult = _result(afterChip, params);
    final afterAverage = PowerCalculator.computeAverageCurrent(
      afterResult.events,
      afterResult.periodUs,
    );
    expect(find.text(_formatCurrent(afterAverage)), findsOneWidget);
    expect(find.text('Current: 10.000 mA'), findsOneWidget);
  });

  testWidgets('timeline taps hit the corresponding stage rectangles',
      (tester) async {
    PowerEvent? selected;
    final events = [
      PowerEvent(
        startUs: 0,
        durationUs: 50,
        currentMa: 5,
        label: 'First',
        color: Colors.red,
        stageId: 'first',
      ),
      PowerEvent(
        startUs: 50,
        durationUs: 50,
        currentMa: 2,
        label: 'Second',
        color: Colors.blue,
        stageId: 'second',
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 300,
            child: TimelineChartInteractive(
              events: events,
              periodUs: 100,
              maxCurrent: 10,
              hideLowPowerGaps: false,
              onEventTap: (event) => selected = event,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final origin = tester.getTopLeft(find.byType(TimelineChartInteractive));
    await tester.tapAt(origin + const Offset(100, 200));
    await tester.pump();
    expect(selected?.stageId, 'first');
    await tester.tapAt(origin + const Offset(600, 230));
    await tester.pump();
    expect(selected?.stageId, 'second');
  });

  testWidgets('invalid draft warning preserves valid KPI content',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final chip = _chip();
    final params = _params();
    final result = _result(chip, params);
    final average = PowerCalculator.computeAverageCurrent(
      result.events,
      result.periodUs,
    );
    await _pump(tester, _preview(hasPreviewError: true));
    expect(
      find.text('Invalid draft input. Showing the last valid preview.'),
      findsOneWidget,
    );
    expect(find.text(_formatCurrent(average)), findsOneWidget);
  });
}
