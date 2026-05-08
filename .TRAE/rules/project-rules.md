# bes_consumption - TRAE IDE 项目规则

> 本文件为 TRAE IDE 在本工程中工作时必须遵循的项目规则（Always Applied）。
> 工程名以 `pubspec.yaml` 中的 `name: bes_consumption` 为准，历史遗留目录 `bes_comsuption` 为拼写错误，需要统一更名为 `bes_consumption`。

---

## 1. 项目概述

- **项目名称**：`bes_consumption`
- **项目类型**：Flutter 应用（`project_type: app`）
- **用途**：BES（Best-in-class Embedded System）系列芯片（BLE / BT / Wi-Fi）的
  **功耗（Power Consumption）仿真与可视化 Demo**，用于对比不同芯片、不同 Profile、不同场景下的功耗与续航表现。
- **支持平台**：Android、iOS、Windows、macOS、Linux、Web。
- **Dart SDK**：`>=3.6.0 <4.0.0`
- **包名 / AppId**：`com.example.bes_consumption`

---

## 2. 技术栈

- **框架**：Flutter（Material 3）
- **状态管理**：`provider: ^6.0.0`（`ChangeNotifierProvider` + 多个按模块拆分的 `*_state.dart`）
- **图表库**：`fl_chart: ^1.1.1`
- **国际化**：`flutter_localizations` + 自建轻量 `lib/l10n/app_localizations.dart`（支持 `en` / `zh`）
- **其他**：`english_words`
- **Lint**：`flutter_lints: ^2.0.0`，配置见 `analysis_options.yaml`

---

## 3. 目录结构（权威版本）

```text
bes_consumption/
├── .TRAE/rules/project-rules.md   # 本文件：TRAE 项目规则
├── .vscode/                       # VS Code / TRAE 调试与编辑器配置
├── android/                       # Android 平台工程（namespace: com.example.bes_consumption）
├── ios/                           # iOS 平台工程
├── linux/ macos/ windows/ web/    # 其他平台工程
├── lib/                           # Dart 主源码
│   ├── main.dart                  # 入口；通过 useChinese 切换 zh/en
│   ├── l10n/
│   │   └── app_localizations.dart # 本地化实现与 delegate
│   ├── config/                    # 芯片参数默认配置
│   │   ├── ble_chip_config.dart
│   │   ├── bt_chip_config.dart
│   │   └── wifi_chip_config.dart
│   ├── models/                    # 数据模型（不可变优先）
│   │   ├── ble_chip.dart
│   │   ├── bt_chip.dart
│   │   ├── wifi_chip.dart
│   │   ├── earbuds.dart
│   │   ├── power_event.dart
│   │   └── profile_params.dart
│   ├── state/                     # ChangeNotifier 状态
│   │   ├── app_state.dart
│   │   ├── bt_state.dart
│   │   ├── wifi_state.dart
│   │   └── sniffing_state.dart
│   ├── services/                  # 纯业务逻辑 / 计算
│   │   └── power_calculator.dart
│   ├── pages/                     # 页面（一页一文件）
│   │   ├── home_page.dart
│   │   ├── ble_case_page.dart
│   │   ├── bt_case_page.dart
│   │   ├── bt_page.dart
│   │   ├── bt_page_main.dart
│   │   ├── bt_pagescan.dart
│   │   ├── bt_sniffing.dart
│   │   ├── wifi_case_page.dart
│   │   └── earbuds_compare_page.dart
│   └── widgets/                   # 可复用 UI 组件
│       ├── kpi_widgets.dart
│       ├── chart_widgets.dart
│       ├── config_panels.dart
│       └── legend_hover_widgets.dart
├── test/
│   └── widget_test.dart
├── analysis_options.yaml
├── pubspec.yaml / pubspec.lock
└── README.md
```

---

## 4. 分层约定

1. **models**：纯数据，不依赖 Flutter（尽量不 import `material.dart`）。
2. **config**：静态常量 / 预置参数，返回 `models` 对象。
3. **services**：纯函数或无状态类，负责计算，不持有 UI 引用。
4. **state**：继承 `ChangeNotifier`，只在必要时 `notifyListeners()`；不直接持有 `BuildContext`。
5. **widgets**：无业务副作用的 UI 组件，通过参数接收数据。
6. **pages**：组合 widgets + 通过 `Provider.of` / `context.watch` 访问 state。
7. **l10n**：所有面向用户的可见文本必须走 `AppLocalizations.of(context)`，不得硬编码中文/英文字符串于 `pages` / `widgets` 中。

---

## 5. 命名与编码规范

- **文件名**：`snake_case.dart`。
- **类 / enum**：`UpperCamelCase`。
- **变量 / 方法**：`lowerCamelCase`；私有成员以 `_` 前缀。
- **常量**：`lowerCamelCase`（Dart 风格），全局常量可用 `const` / `static const`。
- **字符串**：优先使用单引号 `'...'`。
- **注释语言**：已有代码以中文为主，新增注释遵循就近原则，与所在文件保持一致。
- **不要**新增无意义注释；若用户未要求，不要修改既有注释。
- **Lint**：提交前应通过 `flutter analyze`；`analysis_options.yaml` 中已关闭若干规则，不得随意反向开启。

---

## 6. 国际化规则

- 新增用户可见文案必须：
  1. 在 `lib/l10n/app_localizations.dart` 同时补全 `en` 与 `zh` 两种条目；
  2. 在使用处通过 `AppLocalizations.of(context).xxx` 访问。
- 运行时语言由 `lib/main.dart` 中 `const bool useChinese` 控制，修改此开关不应破坏任一语言的完整性。

---

## 7. 状态管理规则

- 每个业务域一个 `ChangeNotifier`（如 `AppState` / `BtState` / `WifiState` / `SniffingState`）。
- 在 `MyApp` 顶层通过 `ChangeNotifierProvider` 或 `MultiProvider` 注入。
- 页面内读取：只读用 `context.watch<T>()` 或 `Consumer<T>`；事件触发用 `context.read<T>()`。
- 禁止在 `build` 方法中直接调用会触发 `notifyListeners()` 的方法。

---

## 8. 平台 / 构建

- **Android**：
  - `namespace` 与 `applicationId` 均为 `com.example.bes_consumption`；
  - Kotlin 源码路径：`android/app/src/main/kotlin/com/example/bes_consumption/MainActivity.kt`。
- **iOS / macOS / Linux / Windows / Web**：产品名均以 `bes_consumption` 为准，不得出现 `bes_comsuption` 拼写。
- 新增依赖必须写入 `pubspec.yaml` 并执行 `flutter pub get`。

---

## 9. 常用命令（PowerShell）

```powershell
# 安装依赖
flutter pub get

# 静态检查
flutter analyze

# 运行测试
flutter test

# 运行（默认设备）
flutter run

# 构建 Windows
flutter build windows

# 构建 Web
flutter build web
```

> 在 TRAE IDE 中如需启动长时间运行的进程（如 `flutter run`），必须使用非阻塞方式启动。

---

## 10. TRAE Agent 行为约束

1. **严格按用户指令工作**，不主动创建与任务无关的文件（尤其是 `*.md` 文档 / README）。
2. 编辑已存在文件优先于新建文件。
3. 修改前先通过 `SearchCodebase` / `Read` 了解上下文，避免破坏既有风格。
4. 新增代码不引入未在 `pubspec.yaml` 声明的依赖。
5. 涉及重命名 / 路径迁移时，必须同时更新：`pubspec.yaml`、`android/` 配置、各平台 Runner、`test/` 导入、`.vscode/launch.json`、`README.md` 等所有引用点。
6. **不得**将工程名拼写回 `bes_comsuption`；历史文本中出现均视为待修正项。
7. 回复语言：与用户最近一条消息保持一致。
