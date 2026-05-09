library;

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/earbuds/earbuds_metrics.dart';
import '../l10n/app_localizations.dart';
import '../models/earbuds.dart';
import '../services/earbuds_query.dart';
import '../state/earbuds_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

part 'earbuds_pages/earbuds_compare_shared.dart';
part 'earbuds_pages/earbuds_left_sidebar.dart';
part 'earbuds_pages/earbuds_metric_table_view.dart';

part 'earbuds_pages/earbuds_scene_tab.dart';
part 'earbuds_pages/earbuds_bt_tab.dart';
part 'earbuds_pages/earbuds_sleep_tab.dart';
part 'earbuds_pages/earbuds_mcu_run_tab.dart';
part 'earbuds_pages/earbuds_tx_sweep_tab.dart';
part 'earbuds_pages/earbuds_rx_sweep_tab.dart';
part 'earbuds_pages/earbuds_pa_tab.dart';

class EarbudsComparePage extends StatefulWidget {
  const EarbudsComparePage({super.key});

  @override
  State<EarbudsComparePage> createState() => _EarbudsComparePageState();
}

class _EarbudsComparePageState extends State<EarbudsComparePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    final es = context.read<EarbudsState>();
    _tabCtrl = TabController(
      length: 7,
      vsync: this,
      initialIndex: es.tabIndex,
    );
    _tabCtrl.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabCtrl.indexIsChanging) return;
    context.read<EarbudsState>().setTabIndex(_tabCtrl.index);
  }

  @override
  void dispose() {
    _tabCtrl.removeListener(_onTabChanged);
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final es = context.watch<EarbudsState>();
    if (_tabCtrl.index != es.tabIndex) {
      _tabCtrl.animateTo(es.tabIndex);
    }

    return Scaffold(
      body: Row(
        children: [
          const _LeftSidebar(),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: const [
                _SceneTab(),
                _KeepAliveWrapper(child: _BtTab()),
                _KeepAliveWrapper(child: _SleepTab()),
                _KeepAliveWrapper(child: _McuRunTab()),
                _KeepAliveWrapper(child: _TxSweepTab()),
                _KeepAliveWrapper(child: _RxSweepTab()),
                _KeepAliveWrapper(child: _PaTab()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
