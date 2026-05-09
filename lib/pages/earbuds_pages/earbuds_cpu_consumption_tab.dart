part of '../earbuds_compare_page.dart';

class _CpuConsumptionTab extends StatelessWidget {
  const _CpuConsumptionTab();

  @override
  Widget build(BuildContext context) {
    final es = context.watch<EarbudsState>();
    return es.sceneViewMode == EarbudsSceneViewMode.singleChip
        ? const _SingleChipMetricView(group: MetricGroup.cpuConsumption)
        : const _MetricTableView(group: MetricGroup.cpuConsumption);
  }
}
