# Project Memory · bes_consumption

> 长期记忆单文件。**按职责分章节**（overview / facts / decisions / constraints / pitfalls / progress / open-questions）。只记沉淀后的结论，不记流水；变化时**原地改写**而非追加。
>
> 标注：`[事实]` 仓库可验证 · `[决策]` 主动选择 · `[约束]` 外部或不可轻改的限制 · `[坑]` 已踩过 · `[待验证]` 暂定。

---

## 1. Overview · 目的与维护原则

### 目的
让后续 AI / 人工维护者在**最少 token** 下获得本项目的长期结论，避免反复试探、反复提问、反复踩坑。

### 适用范围
- 跨任务复用的稳定结论（事实 / 决策 / 约束 / 坑）
- 对未来仍有价值的里程碑
- 未解决但已识别的开放问题

### 不适用范围（去别处写）
- 单次任务过程 / 调试细节 → `docs/ai/task-log.md`
- 临时 TODO / 迭代冲刺 → `docs/ai/current-focus.md`
- 代码片段 / 函数实现 → 代码本身即事实源
- 未验证想法 → 最多在本文 §7 open-questions 留一行

### 维护原则
1. **只写结论，不写过程**。
2. **原地更新** 优先于追加；决策被推翻时改写原条目，并在 `task-log.md` 记录日期与原因。
3. **每条尽量单行**，超过 2 行必须提炼要点。
4. **标签前缀**：`[事实] / [决策] / [约束] / [坑] / [待验证]`。
5. **分章节下沉**：事实进 §2，决策进 §3，约束进 §4，坑进 §5；不混放。
6. **季度 review**：合并重复条目，删除已不成立的条目。

### 更新时机
| 触发 | 写入章节 |
|---|---|
| 产生可验证的稳定事实 | §2 Facts |
| 做出技术 / 架构 / 规范决策 | §3 Decisions |
| 识别到 SDK / Lint / 平台 / 合规限制 | §4 Constraints |
| 踩坑 / 发现禁区 | §5 Pitfalls |
| 完成大模块 / 架构阶段 | §6 Progress |
| 识别到不确定但可能影响后续 | §7 Open Questions |

### 跨项目迁移
本文件设计为"**单文件可提取单元**"。接入新项目时：
- 整体复制 `.ai/memory.md` 到新仓库 → 保留章节结构
- 清空"项目特定"条目（包名 / 芯片清单 / 历史拼写遗留等）
- 保留"通用工程决策"（provider 模式 / 分层方向 / i18n 规范等）

---

## 2. Facts · 长期稳定事实

### 工程基础
- [事实] 工程名：`bes_consumption`；历史拼写 `bes_comsuption` 为待修正遗留（散布于六端工程与 `pubspec.yaml`）
- [事实] 包名 / ApplicationId：`com.example.bes_consumption`
- [事实] 版本：`0.0.1+1`（`pubspec.yaml`）
- [事实] Dart SDK 区间：`>=3.6.0 <4.0.0`

### 平台支持
- [事实] 六端工程齐全：Android / iOS / Windows / macOS / Linux / Web
- [事实] Android Kotlin 源码路径：`android/app/src/main/kotlin/com/example/bes_consumption/MainActivity.kt`

### 依赖
- [事实] 运行时：`flutter`、`flutter_localizations`、`flutter_web_plugins`、`provider ^6.0.0`、`fl_chart ^1.1.1`、`shared_preferences ^2.2.0`、`english_words ^4.0.0`
- [事实] 开发：`flutter_test`、`flutter_lints ^2.0.0`
- [事实] 未使用：HTTP 库 / SQL 数据库 / `freezed` / `json_serializable` / Riverpod / Bloc

### 代码结构
- [事实] 分层：`lib/{models,config,services,state,widgets,pages,theme,l10n}`
- [事实] 入口：`lib/main.dart`，顶层 `MultiProvider` 注入 `AppState / EarbudsState / ThemeController`
- [事实] 功耗计算：`lib/services/power_calculator.dart` + `lib/services/earbuds_query.dart`（纯函数）
- [事实] 芯片数据：`assets/data/earbuds_chips.json`，预置 16 款（id 1306 ~ 1702）
- [事实] 状态类：`app_state / bt_state / wifi_state / sniffing_state / earbuds_state / theme_controller`
- [事实] 页面：`home_page / ble_case_page / bt_case_page / bt_page / bt_page_main / bt_pagescan / bt_sniffing / wifi_case_page / earbuds_compare_page / admin_page`
- [事实] 路由：`/` → `MyHomePage`；`/admin` → `AdminPage`（Web 启用 `usePathUrlStrategy`）
- [事实] 运行时可变芯片仓储：`lib/services/earbuds_repository.dart`，`EarbudsRepository.instance` 单例 + `MutableXxx` 包装；`EarbudsState.allChips` 经此读取
- [事实] **芯片数据源**：`assets/data/earbuds_chips.json`（唯一真相源），由 `lib/services/earbuds_chip_loader.dart` 通过 `rootBundle` 装载
- [事实] 数据持久化：`shared_preferences` 单键 `earbuds_db_v1`；Schema `{ version:1, chips:[EarbudsChip.toJson()...] }`；`main()` 启动时 `await EarbudsRepository.instance.load()`
- [事实] 主题：`lib/theme/{app_theme,app_colors,app_spacing}.dart`
- [事实] i18n：自建 `lib/l10n/app_localizations.dart`，仅 zh / en

### 构建 / 测试
- [事实] 常用命令：`flutter pub get` · `flutter analyze` · `flutter test` · `flutter run` · `flutter build <target>`
- [事实] 测试目录：`test/widget_test.dart`（仅默认模板测试）
- [事实] Lint 配置：`analysis_options.yaml`（已关闭若干 const / key / print 相关规则）

### 文档体系
- [事实] TRAE 硬规则：`.TRAE/rules/project-rules.md`（<1000 字符，TRAE 自动加载）
- [事实] AI 入口：`CLAUDE.md`（项目根目录）
- [事实] AI 文档目录：`docs/ai/`（9 份 md）
- [事实] 长期记忆：`.ai/memory.md`（本文件，按章节组织，可整体复制用于跨项目迁移）

---

## 3. Decisions · 关键决策

> 一条决策 = 做了什么 + 为什么 + 放弃了什么。

### 状态管理
- [决策] 采用 `provider + ChangeNotifier`
  - 理由：Demo 规模小、学习成本低、现有代码已成体系
  - 放弃：Riverpod（改造成本高）/ Bloc（模板代码多）/ 纯 `setState`（跨页共享困难）

### 国际化
- [决策] 自建轻量 `AppLocalizations`，不启用 `intl` 代码生成
  - 理由：仅 zh / en 两种、文案量有限、避免额外 build_runner 步骤
  - 放弃：`flutter_intl` / `easy_localization`

### 主题 / 设计系统
- [决策] 主题拆为 `app_theme / app_colors / app_spacing` 三文件
  - 理由：颜色与间距高频复用，集中管理避免页面级重复定义

### 芯片参数建模
- [决策] 芯片数据存为 JSON 资源（`assets/data/earbuds_chips.json`），运行时由 `EarbudsChipLoader` 装载
  - 理由：人类可读、IDE 友好、与平台无关、易于 diff / review；改数据不必动 Dart
  - 放弃：每颗芯片一个 dart const 文件（已删除 `lib/config/earbuds/chips/*` 与 `earbuds_chip_registry.dart`）/ YAML / TOML / SQLite

### 运行时数据可变性 / Admin（2026-05-09）
- [决策] 在 `services/` 增加 `EarbudsRepository`（`ChangeNotifier` 单例）+ `MutableXxx` 包装类，作为 CRUD 入口；UI 仍消费不可变 `EarbudsChip` 快照
  - 理由：保持 `models/` 不可变契约的同时支持 admin 编辑；用户要求"数据库格式 + 全部字段可改"
  - 放弃：直接修改 `models/` 改 `final → mutable`（破坏现有不可变契约）/ 引入 `freezed copyWith`（增加构建步骤）
- [决策] `/admin` 路由通过 `MaterialApp.routes` 注册；Web 启用 `flutter_web_plugins/usePathUrlStrategy` 以支持纯路径 URL 后缀
  - 理由：用户明确要求"网址后面后缀 /admin"
  - 放弃：`go_router`（增加依赖体量，Demo 仅两条路由）

### 数据库格式 / 持久化（2026-05-09）
- [决策] **芯片数据从 Dart const 迁到 JSON 资源**：`assets/data/earbuds_chips.json`（schema `{version:1, chips:[...]}`），由 `EarbudsChipLoader` 通过 `rootBundle` 装载
  - 理由：用户要求"通用格式 + 从那里取数据"，JSON 是最通用、人类可读、IDE 友好（VSCode/JetBrains 都有自动格式化与折叠）
  - 放弃：YAML（多一个解析依赖、缩进敏感）/ TOML（同上）/ CSV（嵌套表达力差，scene、txSweep 是嵌套结构）/ SQLite（Web 麻烦、过度工程）
- [决策] 运行时数据落盘仍走 `shared_preferences ^2.2.0`，整库以单 JSON 字符串落键 `earbuds_db_v1`；Schema 与 asset 共用
  - 理由：六端原生通过、零原生依赖、读写性能足够、与 asset 同 schema 便于互转
- [决策] 历史 const 数据已彻底删除（`lib/config/earbuds/chips/*`、`earbuds_chip_registry.dart`、`tool/dump_chips_json.dart`），JSON 资源是唯一真相源；以后改数据 = 改 JSON
  - 理由：避免"两份数据要同步"的心智负担；保留 `@Deprecated` 通道反而催生技术债
- [决策] 持久化唯一入口为 `EarbudsRepository`；`models/` 提供 `toJson/fromJson`；写操作（`commit/add/duplicate/delete/resetToSeed`）触发 `_persist()`；`main()` 启动 `await load()`；`load()` 优先 SP 存档 → 否则读 JSON 资源 → 失败退化空仓
  - 理由：写入收口、UI 永远拿不可变快照、JSON 资源不可写决定数据源单向性

### 分层架构
- [决策] 严格向下依赖：`models → config → services → state → widgets → pages`
  - 理由：保证计算层可单元测试、UI 可替换
  - 放弃：MVC / MVVM（对小项目偏重）

### Lint 策略
- [决策] 保留 `flutter_lints ^2.0.0`，主动关闭若干规则（见 `analysis_options.yaml`）
  - 理由：避免对既有风格大规模返工
  - 放弃：升级 `^3.x`（需先评估新增规则）

### 历史拼写遗留
- [决策] 新代码禁用 `bes_comsuption`；旧拼写不做一次性重命名，改为增量修正
  - 理由：跨六端重命名风险高；当前 Demo 优先可运行

### AI 文档体系（2026-05-09）
- [决策] 根目录新增 `CLAUDE.md` 作为项目级 AI 协作入口
  - 理由：兼容非 TRAE 的 AI 助手；`.TRAE/rules/project-rules.md` 受 1000 字符限制
- [决策] memory 最终落点为**单文件** `.ai/memory.md`，按章节组织 7 部分
  - 理由：用户要求；单文件便于跨项目整体复制与一次性加载
  - 放弃：`docs/ai/memory/` 目录多文件（跨项目迁移需带 docs 混合内容）/ `.ai/memory/` 目录多文件（用户明确要求合并为单文件）

---

## 4. Constraints · 硬约束

> 违反会破坏构建 / 运行 / 规范。不得轻易变更。

### 技术
- [约束] Dart SDK：`>=3.6.0 <4.0.0`
- [约束] Flutter 设计体系：Material 3
- [约束] Lint：`flutter_lints ^2.0.0`；`analysis_options.yaml` 已关闭的规则**禁止反开**（`prefer_const_constructors` / `use_key_in_widget_constructors` / `avoid_print` 等）
- [约束] 依赖项变更必须写入 `pubspec.yaml` 并在 `docs/ai/task-log.md` 说明理由

### 架构
- [约束] 分层方向：`models → config → services → state → widgets → pages`，**禁止反向依赖**
- [约束] `lib/models/*.dart` 不得 `import 'package:flutter/*'`
- [约束] `lib/services/*.dart` 必须为纯函数 / 无状态类，不持有 `BuildContext`
- [约束] `lib/state/*.dart` 不直接持有 `BuildContext`
- [约束] `lib/widgets/*.dart` 不含业务副作用，数据一律从参数传入

### 状态
- [约束] 业务状态一律 `ChangeNotifier`
- [约束] 禁止在 `build()` 内触发 `notifyListeners()`
- [约束] 状态注入点唯一：`lib/main.dart` 顶层 `MultiProvider`

### i18n
- [约束] 任何用户可见文本必须走 `AppLocalizations.of(context).xxx`
- [约束] 新增文案必须**同时**补 `zh` 与 `en`
- [约束] 禁止在 `pages/` 或 `widgets/` 硬编码中英文 UI 字符串

### 代码风格
- [约束] 文件名：`snake_case.dart`
- [约束] 字符串：优先单引号 `'...'`
- [约束] 不新增无意义注释；未经要求不改动既有注释
- [约束] 单文件 > ~400 行优先考虑拆分，但**拆前先评估收益**

### 命名
- [约束] 工程名统一 `bes_consumption`；新文件 / 新配置 / 新标识符禁止回退 `bes_comsuption`
- [约束] Android 包名锁定 `com.example.bes_consumption`

### 平台
- [约束] 必须保持六端可构建：Android / iOS / Windows / macOS / Linux / Web
- [待确认] 各平台最低系统版本 / 构建工具链版本（仓库未显式锁定）

### 文档
- [约束] `.TRAE/rules/project-rules.md` 必须 < 1000 字符
- [约束] `docs/ai/memory.md` 仅作跳转导航，不得承载事实 / 决策
- [约束] 长期事实 / 决策 / 约束 / 坑一律写入本文件 `.ai/memory.md` 对应章节

---

## 5. Pitfalls · 坑与禁区

> 改代码前必读。

### 状态管理
- [坑] `build()` 内调用 `setXxx()` 触发 `notifyListeners()` → 循环重建
- [坑] `initState()` 里同步 `read<T>()` 并立刻 `notifyListeners()` 会告警 → 用 `WidgetsBinding.instance.addPostFrameCallback`
- [坑] 多处页面监听同一大 `ChangeNotifier` 性能差 → 拆分或用 `Selector`

### i18n
- [坑] 在 `pages/` / `widgets/` 硬编码中文 → 破坏 zh/en 同步
- [坑] 新增文案只补一种语言 → 切换语言出现缺失 key
- [坑] `lib/main.dart` 的 `const bool useChinese` 开关改动后，必须确认两语言完整性

### 命名 / 拼写
- [坑] 六端工程、`.vscode/`、`README`、`pubspec.yaml` 中散布 `bes_comsuption`；重命名必须全量搜索：
  - `android/`（Kotlin 包路径、`build.gradle.kts`、`AndroidManifest.xml`、`settings.gradle.kts`）
  - `ios/` / `macos/`（`Info.plist`、xcodeproj 的 PRODUCT_NAME）
  - `windows/` / `linux/`（`CMakeLists.txt`、`main.cc` / `main.cpp`）
  - `web/`（`manifest.json`、`index.html`）
  - `pubspec.yaml` / `pubspec.lock` / `.vscode/launch.json`

### 架构
- [禁区] `lib/models/` 禁止 `import 'package:flutter/*'`
- [禁区] `lib/services/` 禁止持有 `BuildContext`
- [禁区] `lib/widgets/` 引入业务副作用 → 破坏复用性
- [坑] 芯片参数写进 `state/` 而非 `config/` → 下次新增型号要改状态层

### Lint
- [禁区] 不得在 `analysis_options.yaml` 反开已关闭的规则
- [坑] 升级 `flutter_lints ^3.x` 会引入新规则 → 先评估再升级

### UI / 图表
- [待验证] Web 端 `fl_chart` 在大数据点下可能卡顿（未基准化）
- [坑] 自定义 `TooltipBehavior` / legend hover 与 `fl_chart` 默认行为叠加易出现双重提示

### 构建
- [坑] Windows 下不能 `flutter build linux`；跨平台构建需在对应宿主
- [坑] iOS 首次构建需 `cd ios && pod install`

### 文档
- [禁区] 不得再向 `docs/ai/memory.md` 追加事实 / 决策（已降级为导航）
- [禁区] 不得在 `task-log.md` 写调试过程
- [坑] memory 条目超过 2 行会变流水账 → 超长必须提炼

---

## 6. Progress · 高价值里程碑

- [事实] 2026-05-09 · AI 文档体系 v1：`.TRAE/rules/project-rules.md` + `docs/ai/` 九文件 + `CLAUDE.md` + `.ai/memory.md`（单文件按章节组织）
- [事实] 已完成六端工程 + M3 亮暗主题切换（`ThemeController`）
- [事实] 已完成 BLE / BT / Wi-Fi 场景页 + 耳机对比页 + Sniff 专页
- [事实] 已内置 16 款 BES 芯片参数（chip_1306 ~ chip_1702）

---

## 7. Open Questions · 未决 / 待验证

- [待验证] Web 端 `fl_chart` 在大数据点下的性能表现
- [待验证] 是否需要 CSV / 截图导出功能
- [待验证] `bes_comsuption` → `bes_consumption` 一次性跨六端重命名的启动时机
- [待确认] 各平台最低系统版本 / 构建工具链版本基线
- [待确认] 是否建立单元测试体系（当前 `test/` 仅有默认模板）
- [待确认] `current-focus.md` 中的 P0~P2 真实优先级
