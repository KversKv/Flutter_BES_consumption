part of '../earbuds_compare_page.dart';

class _BtTab extends StatelessWidget {
  const _BtTab();

  @override
  Widget build(BuildContext context) {
    final es = context.watch<EarbudsState>();
    return es.sceneViewMode == EarbudsSceneViewMode.singleChip
        ? const _SingleChipMetricView(group: MetricGroup.bt)
        : const _MetricTableView(group: MetricGroup.bt);
  }
}
