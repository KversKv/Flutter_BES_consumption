import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ble_case_page.dart';
import 'bt_case_page.dart';
import 'earbuds_compare_page.dart';
import 'wifi_case_page.dart';
import '../l10n/app_localizations.dart';
import '../navigation/app_url_state.dart';
import '../state/app_state.dart';
import '../state/bt_state.dart';
import '../state/earbuds_state.dart';
import '../state/theme_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class MyHomePage extends StatefulWidget {
  final int initialIndex;
  final Uri? initialUri;

  const MyHomePage({
    super.key,
    this.initialIndex = 0,
    this.initialUri,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const int _pageCount = 4;
  late int selectedIndex;
  final List<bool> _visited = List<bool>.filled(_pageCount, false);
  final List<Widget?> _pages = List<Widget?>.filled(_pageCount, null);
  AppState? _appState;
  BTState? _btState;
  EarbudsState? _earbudsState;
  bool _didApplyInitialUrl = false;
  String? _lastSyncedUrl;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex.clamp(0, _pageCount - 1).toInt();
    _visited[selectedIndex] = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = context.read<AppState>();
    final btState = context.read<BTState>();
    final earbudsState = context.read<EarbudsState>();

    if (_appState != appState) {
      _appState?.removeListener(_syncActiveUrl);
      _appState = appState..addListener(_syncActiveUrl);
    }
    if (_btState != btState) {
      _btState?.removeListener(_syncActiveUrl);
      _btState = btState..addListener(_syncActiveUrl);
    }
    if (_earbudsState != earbudsState) {
      _earbudsState?.removeListener(_syncActiveUrl);
      _earbudsState = earbudsState..addListener(_syncActiveUrl);
    }

    if (!_didApplyInitialUrl) {
      _didApplyInitialUrl = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _applyInitialUrl();
        _syncActiveUrl();
      });
    }
  }

  @override
  void dispose() {
    _appState?.removeListener(_syncActiveUrl);
    _btState?.removeListener(_syncActiveUrl);
    _earbudsState?.removeListener(_syncActiveUrl);
    super.dispose();
  }

  void _applyInitialUrl() {
    final uri = widget.initialUri;
    if (uri == null) return;
    switch (selectedIndex) {
      case 0:
        AppUrlState.applyBle(context.read<AppState>(), uri);
        break;
      case 1:
        AppUrlState.applyBt(context.read<BTState>(), uri);
        break;
      case 2:
        AppUrlState.applyEarbuds(context.read<EarbudsState>(), uri);
        break;
    }
  }

  Widget _pageAt(int index) {
    return _pages[index] ??= switch (index) {
      0 => const BleCasePage(),
      1 => const BTPage(),
      2 => const EarbudsComparePage(),
      3 => WifiPage(initialUri: widget.initialUri),
      _ => const SizedBox.shrink(),
    };
  }

  void _selectPage(int index) {
    if (index == selectedIndex) return;
    Navigator.of(context).pushReplacementNamed(AppUrlState.pathForPage(index));
  }

  void _syncActiveUrl() {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) return;
    final uri = switch (selectedIndex) {
      0 => AppUrlState.uriForBle(context.read<AppState>()),
      1 => AppUrlState.uriForBt(context.read<BTState>()),
      2 => AppUrlState.uriForEarbuds(context.read<EarbudsState>()),
      _ => AppUrlState.uriForPage(selectedIndex),
    };
    final next = uri.toString();
    if (next == _lastSyncedUrl) return;
    _lastSyncedUrl = next;
    AppUrlState.replaceBrowserUrl(uri);
  }

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
                  onSelect: _selectPage,
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: selectedIndex,
                  children: List.generate(
                    _pageCount,
                    (i) => _visited[i] ? _pageAt(i) : const SizedBox.shrink(),
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
            child: _NavList(
              isWide: isWide,
              selectedIndex: selectedIndex,
              onSelect: onSelect,
            ),
          ),
          const Divider(height: 1),
          _VersionFooter(isWide: isWide),
        ],
      ),
    );
  }
}

/// 自定义垂直导航列表;Earbuds 项支持鼠标悬浮弹出二级菜单。
class _NavList extends StatelessWidget {
  final bool isWide;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _NavList({
    required this.isWide,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = <_NavItemData>[
      _NavItemData(icon: Icons.show_chart, label: l10n.navBle),
      _NavItemData(icon: Icons.bluetooth, label: l10n.navBt),
      _NavItemData(
        icon: Icons.headphones,
        label: l10n.navEarbuds,
        hasSubMenu: true,
      ),
      _NavItemData(icon: Icons.wifi, label: l10n.navWifi),
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x2),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        if (item.hasSubMenu) {
          return _EarbudsNavItem(
            isWide: isWide,
            item: item,
            selected: selectedIndex == i,
            onSelect: () => onSelect(i),
          );
        }
        return _NavItem(
          isWide: isWide,
          item: item,
          selected: selectedIndex == i,
          onTap: () => onSelect(i),
        );
      },
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;
  final bool hasSubMenu;
  const _NavItemData({
    required this.icon,
    required this.label,
    this.hasSubMenu = false,
  });
}

class _NavItem extends StatelessWidget {
  final bool isWide;
  final _NavItemData item;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.isWide,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final color = selected ? palette.accent : palette.textSecondary;
    final bg =
        selected ? palette.accent.withValues(alpha: 0.10) : Colors.transparent;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? AppSpacing.x2 : AppSpacing.x1,
        vertical: 2,
      ),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? AppSpacing.x3 : AppSpacing.x2,
                  vertical: AppSpacing.x2,
                ),
                child: isWide
                    ? Row(
                        children: [
                          Icon(item.icon, size: 20, color: color),
                          const SizedBox(width: AppSpacing.x3),
                          Expanded(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: color,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(item.icon, size: 22, color: color),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 10,
                              color: color,
                              fontWeight:
                                  selected ? FontWeight.w600 : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
              ),
              if (selected)
                Positioned(
                  left: 0,
                  top: isWide ? 8 : 6,
                  bottom: isWide ? 8 : 6,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: palette.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Earbuds 导航项:鼠标悬浮弹出二级菜单。
class _EarbudsNavItem extends StatefulWidget {
  final bool isWide;
  final _NavItemData item;
  final bool selected;
  final VoidCallback onSelect;

  const _EarbudsNavItem({
    required this.isWide,
    required this.item,
    required this.selected,
    required this.onSelect,
  });

  @override
  State<_EarbudsNavItem> createState() => _EarbudsNavItemState();
}

class _EarbudsNavItemState extends State<_EarbudsNavItem> {
  final MenuController _menuCtrl = MenuController();
  Timer? _closeTimer;

  static const Duration _closeDelay = Duration(milliseconds: 220);

  @override
  void dispose() {
    _closeTimer?.cancel();
    super.dispose();
  }

  void _cancelClose() {
    _closeTimer?.cancel();
    _closeTimer = null;
  }

  void _scheduleClose() {
    _closeTimer?.cancel();
    _closeTimer = Timer(_closeDelay, () {
      if (mounted && _menuCtrl.isOpen) _menuCtrl.close();
    });
  }

  void _openNow() {
    _cancelClose();
    if (!_menuCtrl.isOpen) _menuCtrl.open();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);

    final tabLabels = [
      l10n.ebTabScene,
      l10n.ebTabBt,
      l10n.ebTabCpuConsumption,
      l10n.ebTabTx,
      l10n.ebTabRx,
      l10n.ebTabPa,
    ];
    final tabIcons = [
      Icons.dashboard_outlined,
      Icons.bluetooth,
      Icons.memory_rounded,
      Icons.upload_rounded,
      Icons.download_rounded,
      Icons.power_rounded,
    ];

    return MouseRegion(
      onEnter: (_) => _openNow(),
      onExit: (_) => _scheduleClose(),
      child: MenuAnchor(
        controller: _menuCtrl,
        alignmentOffset: Offset(widget.isWide ? 10 : 6, 0),
        style: MenuStyle(
          alignment: Alignment.topRight,
          backgroundColor: WidgetStateProperty.all(palette.bgElevated2),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          shadowColor: WidgetStateProperty.all(
            palette.isDark
                ? Colors.black.withValues(alpha: 0.45)
                : Colors.black.withValues(alpha: 0.12),
          ),
          elevation: WidgetStateProperty.all(palette.isDark ? 14 : 10),
          padding: WidgetStateProperty.all(EdgeInsets.zero),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              side: BorderSide(color: palette.borderSubtle),
            ),
          ),
        ),
        menuChildren: [
          MouseRegion(
            onEnter: (_) => _cancelClose(),
            onExit: (_) => _scheduleClose(),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 220),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.x4,
                      AppSpacing.x3,
                      AppSpacing.x4,
                      AppSpacing.x2,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.headphones,
                          size: 14,
                          color: palette.accent,
                        ),
                        const SizedBox(width: AppSpacing.x2),
                        Text(
                          l10n.navEarbuds,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: palette.textMuted,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: palette.borderSubtle,
                  ),
                  const SizedBox(height: AppSpacing.x1),
                  ...List.generate(tabLabels.length, (i) {
                    return Consumer<EarbudsState>(
                      builder: (context, es, _) {
                        final active = es.tabIndex == i;
                        return _EarbudsMenuTile(
                          icon: tabIcons[i],
                          label: tabLabels[i],
                          active: active,
                          onTap: () {
                            es.setTabIndex(i);
                            widget.onSelect();
                            _cancelClose();
                            _menuCtrl.close();
                          },
                        );
                      },
                    );
                  }),
                  const SizedBox(height: AppSpacing.x1),
                ],
              ),
            ),
          ),
        ],
        child: _NavItem(
          isWide: widget.isWide,
          item: widget.item,
          selected: widget.selected,
          onTap: widget.onSelect,
        ),
      ),
    );
  }
}

/// Earbuds 二级菜单单项:对齐 NavItem 视觉(accent + bgElevated 风格)。
class _EarbudsMenuTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _EarbudsMenuTile({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  State<_EarbudsMenuTile> createState() => _EarbudsMenuTileState();
}

class _EarbudsMenuTileState extends State<_EarbudsMenuTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);

    final Color fg;
    final Color bg;
    final FontWeight weight;
    if (widget.active) {
      fg = palette.accent;
      bg = palette.accent.withValues(alpha: 0.14);
      weight = FontWeight.w600;
    } else if (_hover) {
      fg = palette.textPrimary;
      bg = palette.bgElevated3.withValues(alpha: 0.85);
      weight = FontWeight.w500;
    } else {
      fg = palette.textSecondary;
      bg = Colors.transparent;
      weight = FontWeight.w500;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Semantics(
          button: true,
          selected: widget.active,
          label: widget.label,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x3,
                vertical: AppSpacing.x2,
              ),
              constraints: const BoxConstraints(minHeight: 36),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  if (widget.active)
                    Container(
                      width: 3,
                      height: 16,
                      margin: const EdgeInsets.only(right: AppSpacing.x2),
                      decoration: BoxDecoration(
                        color: palette.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )
                  else
                    const SizedBox(width: AppSpacing.x2 + 3),
                  Icon(widget.icon, size: 16, color: fg),
                  const SizedBox(width: AppSpacing.x3),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        fontWeight: weight,
                        color: fg,
                        letterSpacing: 0.1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.active)
                    Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: palette.accent,
                    ),
                ],
              ),
            ),
          ),
        ),
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
            const SizedBox(width: AppSpacing.x2),
            const _ThemeToggleButton(),
          ] else ...[
            const SizedBox(width: AppSpacing.x2),
            const _ThemeToggleButton(),
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
