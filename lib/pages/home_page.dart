import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ble_case_page.dart';
import 'bt_case_page.dart';
import 'wifi_case_page.dart';
import '../l10n/app_localizations.dart';
import '../state/theme_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int selectedIndex = 0;

  static const _pages = <Widget>[
    BleCasePage(),
    BTPage(),
    WifiPage(),
    Placeholder(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= 1100;

        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: _SideNav(
                  isWide: isWide,
                  selectedIndex: selectedIndex,
                  onSelect: (v) => setState(() => selectedIndex = v),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    IndexedStack(
                      index: selectedIndex,
                      children: _pages,
                    ),
                    const Positioned(
                      top: AppSpacing.x3,
                      right: AppSpacing.x3,
                      child: SafeArea(child: _ThemeToggleButton()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 左侧品牌 + 导航栏
class _SideNav extends StatelessWidget {
  final bool isWide;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _SideNav({
    required this.isWide,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final double railWidth = isWide ? 240 : 72;

    return Container(
      width: railWidth,
      decoration: BoxDecoration(
        color: palette.bgElevated1,
        border: Border(
          right: BorderSide(color: palette.borderSubtle),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BrandHeader(isWide: isWide),
          const Divider(height: 1),
          Expanded(
            child: NavigationRail(
              backgroundColor: Colors.transparent,
              extended: isWide,
              minExtendedWidth: railWidth,
              selectedIndex: selectedIndex,
              onDestinationSelected: onSelect,
              labelType: isWide
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(Icons.show_chart),
                  selectedIcon: Icon(Icons.show_chart, color: palette.accent),
                  label: Text(l10n.navBle),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.bluetooth),
                  selectedIcon: Icon(Icons.bluetooth, color: palette.accent),
                  label: Text(l10n.navBt),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.headphones),
                  selectedIcon: Icon(Icons.headphones, color: palette.accent),
                  label: Text(l10n.navEarbuds),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.wifi),
                  selectedIcon: Icon(Icons.wifi, color: palette.accent),
                  label: Text(l10n.navWifi),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _VersionFooter(isWide: isWide),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  final bool isWide;
  const _BrandHeader({required this.isWide});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? AppSpacing.x4 : AppSpacing.x2,
        vertical: AppSpacing.x4,
      ),
      child: Row(
        mainAxisAlignment:
            isWide ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [palette.accent, const Color(0xFF818CF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(Icons.bolt, color: palette.accentOn, size: 20),
          ),
          if (isWide) ...[
            const SizedBox(width: AppSpacing.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'BES Consumption',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                      letterSpacing: 0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Power Simulation',
                    style: TextStyle(
                      fontSize: 11,
                      color: palette.textMuted,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VersionFooter extends StatelessWidget {
  final bool isWide;
  const _VersionFooter({required this.isWide});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3,
        vertical: AppSpacing.x3,
      ),
      child: Row(
        mainAxisAlignment:
            isWide ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: palette.success,
              shape: BoxShape.circle,
            ),
          ),
          if (isWide) ...[
            const SizedBox(width: AppSpacing.x2),
            Text(
              'Demo v1.0',
              style: TextStyle(
                fontSize: 11,
                color: palette.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 右上角主题切换按钮：system → dark → light → system 三态循环。
class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context) {
    final themeCtrl = context.watch<ThemeController>();
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);

    late final IconData icon;
    late final String tooltip;
    switch (themeCtrl.mode) {
      case ThemeMode.system:
        icon = Icons.brightness_auto;
        tooltip = l10n.themeToggleSystem;
        break;
      case ThemeMode.dark:
        icon = Icons.dark_mode;
        tooltip = l10n.themeToggleDark;
        break;
      case ThemeMode.light:
        icon = Icons.light_mode;
        tooltip = l10n.themeToggleLight;
        break;
    }

    return Material(
      color: palette.bgElevated2.withValues(alpha: 0.85),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: palette.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, size: 20, color: palette.textPrimary),
        onPressed: () => context.read<ThemeController>().cycle(),
      ),
    );
  }
}
