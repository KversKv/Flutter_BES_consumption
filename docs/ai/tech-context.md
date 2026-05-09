# Tech Context

## 技术栈（事实）
| 层面 | 选型 |
|---|---|
| 框架 | Flutter (Material 3) |
| 语言 | Dart `>=3.6.0 <4.0.0` |
| 状态管理 | `provider ^6.0.0`（`ChangeNotifier` + `MultiProvider`） |
| 图表 | `fl_chart ^1.1.1` |
| 国际化 | `flutter_localizations` + 自建 `lib/l10n/app_localizations.dart`（zh/en） |
| 工具 | `english_words ^4.0.0` |
| Lint | `flutter_lints ^2.0.0`（见 `analysis_options.yaml`） |

## 分层架构
```
models  ← 纯数据，不 import material
config  ← 静态预置参数 / 芯片注册表
services← 纯函数计算（power_calculator / earbuds_query）
state   ← ChangeNotifier（app_state / bt_state / wifi_state / sniffing_state / earbuds_state / theme_controller）
widgets ← 无业务副作用的 UI 组件（kpi/chart/config/legend_hover）
pages   ← 组合 widgets + 读写 state
l10n    ← AppLocalizations（所有可见文本入口）
theme   ← AppTheme / AppColors / AppSpacing
```
**依赖方向严格向下**，禁止 widgets/pages 被 services/models 引用。

## 平台约束
- Android：`namespace` / `applicationId` = `com.example.bes_consumption`；Kotlin 路径 `android/app/src/main/kotlin/com/example/bes_consumption/MainActivity.kt`。
- iOS / macOS / Linux / Windows / Web：产品名统一 `bes_consumption`。
- [事实] 历史遗留拼写 `bes_comsuption` 已视为待修正项；新增代码严禁回退。

## 构建与运行（PowerShell）
```powershell
flutter pub get
flutter analyze
flutter test
flutter run                 # 默认设备
flutter build windows
flutter build web
```

## 关键文件
- 入口：[lib/main.dart](../../lib/main.dart)
- 主题：[lib/theme/app_theme.dart](../../lib/theme/app_theme.dart)
- 芯片注册表：[lib/config/earbuds/earbuds_chip_registry.dart](../../lib/config/earbuds/earbuds_chip_registry.dart)
- 功耗算法：[lib/services/power_calculator.dart](../../lib/services/power_calculator.dart)
- i18n：[lib/l10n/app_localizations.dart](../../lib/l10n/app_localizations.dart)

## 已知未引入
- 无 HTTP / DIO / 数据库 / 代码生成（freezed/json_serializable）依赖。若后续需要，先在 `task-log.md` 记录动机再加入。
