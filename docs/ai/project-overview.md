# Project Overview · bes_consumption

## 一句话定位
[事实] 面向 BES 系列芯片（BLE / BT / Wi-Fi / TWS 耳机）的**功耗仿真与可视化 Demo**，用 Flutter 在多端演示不同 Profile/场景下的电流、平均功耗与续航。

## 快速索引
- 入口：`lib/main.dart`（`MultiProvider` 注入 `AppState / EarbudsState / ThemeController`）
- 主页：`lib/pages/home_page.dart`
- 场景页：`ble_case_page.dart` / `bt_case_page.dart` / `wifi_case_page.dart` / `earbuds_compare_page.dart` / `bt_sniffing.dart`
- 核心算法：`lib/services/power_calculator.dart` · `lib/services/earbuds_query.dart`
- 芯片数据：`assets/data/chips/{earbuds,ble,bt,wifi}/`；Earbuds 装载器 `lib/services/earbuds_chip_loader.dart`；页面域仓储 `lib/services/config/config_repository.dart`
- 主题：`lib/theme/app_theme.dart` + `app_colors.dart` + `app_spacing.dart`
- i18n：`lib/l10n/app_localizations.dart`（zh / en）

## 支持平台
Android · iOS · Windows · macOS · Linux · Web（6 端工程均已就绪）。

## 关键版本
- Dart SDK: `>=3.6.0 <4.0.0`
- Flutter：Material 3
- 依赖：`provider ^6.0.0`、`fl_chart ^1.1.1`、`english_words ^4.0.0`、`flutter_localizations`
- Lint：`flutter_lints ^2.0.0`

## 当前阶段
见 [current-focus.md](./current-focus.md)。
