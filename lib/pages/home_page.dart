import 'package:flutter/material.dart';
import 'ble_case_page.dart';
import 'sniffing_page.dart';
import 'earbuds_compare_page.dart'; // ✅ 新增导入

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // ===== 根据索引选择页面 =====
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = const BleCasePage();
        break;
      case 1:
        page = const SniffingPage();
        break;
      case 2:
        page = const EarbudsComparePage(); // ✅ 新增页
        break;
      default:
        page = const BleCasePage();
    }

    // ===== 页面布局 =====
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= 1100;

        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  extended: isWide,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) {
                    setState(() {
                      selectedIndex = value;
                    });
                  },
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.show_chart),
                      label: Text('BLE CASE'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.wifi_tethering),
                      label: Text('BT CASE'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.headphones),
                      label: Text('Earbuds 功耗对比'), // ✅ 新增菜单项
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: page,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
