import 'package:flutter/material.dart';
import 'ble_case_page.dart';
import 'bt_home_page.dart';
import 'earbuds_compare_page.dart'; // ✅ 新增导入
import 'wifi_home_page.dart'; // ✅ 新增导入
import '../l10n/app_localizations.dart';

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
        page = const BTPage();
        break;
      case 2:
        page = const EarbudsComparePage(); // ✅ 新增页
        break;
      case 3:
        page = const WifiPage();
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
                  destinations: [
                    NavigationRailDestination(
                      icon: const Icon(Icons.show_chart),
                      label: Text(AppLocalizations.of(context).navBle),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.bluetooth),
                      label: Text(AppLocalizations.of(context).navBt),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.headphones),
                      label: Text(AppLocalizations.of(context).navEarbuds),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.wifi),
                      label: Text(AppLocalizations.of(context).navWifi),
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
