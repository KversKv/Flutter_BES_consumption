import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../state/sniffing_state.dart';
import '../widgets/config_panels.dart';
import '../widgets/kpi_widgets.dart';
import '../widgets/chart_widgets.dart';
import 'bt_sniffing.dart';
import 'bt_page_main.dart';
import 'bt_pagescan.dart';

enum BTCase { sniffing, page, pageScan }

class BTPage extends StatefulWidget {
  const BTPage({Key? key}) : super(key: key);

  @override
  State<BTPage> createState() => _BTPageState();
}

class _BTPageState extends State<BTPage> {
  BTCase selectedCase = BTCase.sniffing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BT 模式'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Case 选择器（类似 BLE 页面风格）
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCaseButton(BTCase.sniffing, 'BT Sniffing'),
                  const SizedBox(width: 8),
                  _buildCaseButton(BTCase.page, 'BT Page'),
                  const SizedBox(width: 8),
                  _buildCaseButton(BTCase.pageScan, 'BT PageScan'),
                ],
              ),
            ),
          ),
          // 内容区域
          Expanded(
            child: _buildCaseContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildCaseButton(BTCase btCase, String label) {
    final isSelected = selectedCase == btCase;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          selectedCase = btCase;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.blue,
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }

  Widget _buildCaseContent() {
    switch (selectedCase) {
      case BTCase.sniffing:
        // Provide a SniffingState for the sniffing layout so the config panel
        // (which now supports BT chips) can be used inside BT page.
        return ChangeNotifierProvider(
          create: (_) {
            final s = SniffingState();
            // ensure provider starts in BT sniffing mode (explicit)
            s.setCase(SniffCase.btSniff);
            return s;
          },
          child: Builder(builder: (context) {
            final theme = Theme.of(context);
            return Row(
              children: [
                SizedBox(
                  width: 380,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SniffingConfigPanel(),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      KPIRowSniffing(),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Card(
                            elevation: 0,
                            color: theme.colorScheme.surfaceContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: ChartWithOptionsSniff(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        );
      case BTCase.page:
        return const BTPageMain();
      case BTCase.pageScan:
        return const BTPageScan();
    }
  }
}