part of '../earbuds_compare_page.dart';

class _CpuConsumptionTab extends StatelessWidget {
  const _CpuConsumptionTab();

  @override
  Widget build(BuildContext context) {
    return const _MetricTableView(group: MetricGroup.cpuConsumption);
  }
}
