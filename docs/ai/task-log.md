# Task Log

> 关键变更与决策流水。**仅记"对未来任务有价值的事"**，琐碎改动不必入账。
> 格式固定，方便增量写入与检索。

## 条目模板
```markdown
### YYYY-MM-DD · <一句话标题>
- **类型**：feature / fix / refactor / infra / docs / decision / revert
- **范围**：涉及文件或模块
- **动因**：为什么做
- **变更**：做了什么（要点 3~5 条）
- **影响**：对其它模块/文档的连带影响
- **后续**：遗留 TODO 或待验证项
```

---

## 2026-05-26 路 页面域配置架构一期：BLE/BT/Wi-Fi 数据拆分接入 ConfigRepository
- **类型**：refactor / decision
- **范围**：`assets/data/config_manifest.json`、`assets/data/chips/{ble,bt,wifi}/index.json`、`assets/data/chips/{ble,bt,wifi}/*.json`、`lib/models/{ble_chip,bt_chip,wifi_chip}.dart`、`lib/services/config/config_repository.dart`、`lib/state/{app_state,bt_state,sniffing_state,wifi_state}.dart`、`lib/main.dart`、`pubspec.yaml`
- **动因**：用户希望 BLE CASE / BT CASE / Wi-Fi / Earbuds 等页面的数据按域分离，便于独立维护，而不是继续散落在 `config/*.dart` 与各自 State 默认值中。
- **变更**：
  1. 新增 `ConfigRepository` 作为页面域配置统一读取入口；启动时先加载页面域配置，再加载既有 `EarbudsRepository`。
  2. BLE / BT / Wi-Fi 芯片列表从现有 Dart 配置机械导出为 `index.json` + 单芯片 JSON seed，保留旧 Dart 配置作为资源加载失败时的回退点，确保当前页面数据不变。
  3. 梳理后移除 `assets/data/pages` 默认参数层；BLE / BT / Wi-Fi 页面直接消费对应 chips 数据，interval/payload/battery 等 UI 初始值继续保留在 State。
  4. 为 `BleChip` / `BtChip` / `WifiChip` 补齐 `toJson/fromJson`，支持后续 Admin 与导入导出统一化。
  5. 新增 `config_manifest.json` 描述页面域数据模块；Earbuds 继续沿用既有拆分 JSON，并通过 `ConfigRepository.earbudsChips` 暴露兼容入口。
- **影响**：一期只迁移芯片数据入口与 seed 文件，不改变计算公式和当前默认参数；后续可继续把 Admin 升级为按页面域管理 BLE/BT/Wi-Fi/Earbuds 的配置中心。
- **后续**：`flutter analyze` 在当前环境中启动超时（Dart/Flutter 工具链层面卡住，未产生 analyzer 输出），需在工具链恢复后补跑。

## 2026-05-26 路 BLE/BT/Wi-Fi 芯片配置继续拆分为每芯片独立 JSON
- **类型**：refactor
- **范围**：`assets/data/chips/{ble,bt,wifi}/`、`assets/data/config_manifest.json`、`lib/services/config/config_repository.dart`
- **动因**：用户希望 BLE / BT / Wi-Fi 的芯片数据也像 Earbuds 一样按芯片文件维护，减少聚合 `chips.json` 的冲突和 diff 噪声。
- **变更**：
  1. 删除聚合 `chips.json`，改为每个域一个 `index.json` + 多个单芯片 JSON 文件。
  2. `index.json` 使用 `{id,file}` 映射，支持 `BES1505(HDT Demo)` 这类真实 id 与安全文件名分离。
  3. `ConfigRepository` 改为先读 `index.json`，再按顺序读取各芯片文件；导出也输出同样的拆分结构。
  4. `config_manifest.json` 中 BLE/BT/Wi-Fi 的 chips 入口更新为各自 `index.json`。
- **影响**：数据数值保持不变；维护入口变为 `assets/data/chips/<domain>/index.json` 与同目录下单芯片文件。

## 2026-05-26 路 修正芯片域目录并接入真实 Wi-Fi 页面
- **类型**：refactor / fix
- **范围**：`assets/data/chips/earbuds/`、`lib/services/earbuds_chip_loader.dart`、`lib/services/earbuds_repository.dart`、`lib/state/wifi_state.dart`、`lib/pages/wifi_case_page.dart`、`assets/data/config_manifest.json`、`pubspec.yaml`
- **动因**：根目录 `assets/data/chips/*.json` 实际是 Earbuds 数据，和新增的 BLE/BT/Wi-Fi 子目录并列后语义不清；同时 Wi-Fi 导航页仍返回 `EarbudsComparePage`，没有使用真实 Wi-Fi 数据。
- **变更**：
  1. Earbuds 数据迁入 `assets/data/chips/earbuds/index.json` + `assets/data/chips/earbuds/<id>.json`，loader 和 manifest 同步更新。
  2. `EarbudsRepository.exportAsJsonFiles()` 改为导出 `chips/earbuds/` 结构，Admin 导出提示同步更新。
  3. `WIFIState` 改为读取 `ConfigRepository.instance.wifiChips`，不再复用 BLE/BT 芯片池。
  4. `WifiPage` 改为真实 Wi-Fi 仿真页面，提供独立配置面板、KPI 与功耗事件图。
- **影响**：四类芯片域现在目录一致：`earbuds / ble / bt / wifi`；Wi-Fi 页开始消费 `assets/data/chips/wifi/` 数据。

---

## 2026-05-11 · 数据源拆分：单文件 → 每芯片独立 JSON + 导出按钮
- **类型**：refactor / decision
- **范围**：`assets/data/`、`lib/services/earbuds_chip_loader.dart`、`lib/services/earbuds_repository.dart`、`lib/services/chips_export_*.dart`、`lib/pages/admin_page.dart`、`lib/l10n/app_localizations.dart`、`pubspec.yaml`
- **动因**：原 `assets/data/earbuds_chips.json` 单文件难协作；用户希望"数据独立化、读写直连 JSON、不要和 port 挂钩"。但浏览器沙盒不允许写回 assets，故采用"拆分只读资源 + admin 导出 zip 由用户回写"的折中。
- **变更**：
  1. 删除 `assets/data/earbuds_chips.json`；新增 `assets/data/chips/<id>.json` ×16 与 `assets/data/chips_index.json`（含 `version` + `order`）。
  2. `EarbudsChipLoader` 改为先读 index、再 `Future.wait` 并行读各 chip 文件。
  3. `EarbudsRepository` 新增 `exportAsJsonFiles()` 返回 `{path -> jsonString}`；落盘逻辑放在新 `chips_export_service.dart`，通过条件导入分发到 `chips_export_io.dart`（原生写 systemTemp）/ `chips_export_web.dart`（Blob+AnchorElement 触发下载）。
  4. admin 工具栏新增「导出 JSON」按钮；新增 `adminExportJson / adminExportSuccess / adminExportFailed` 三组 zh+en 文案。
  5. 新增依赖 `archive: ^3.6.1`（理由：纯 Dart zip 编码，跨平台无原生依赖）。
- **影响**：浏览器 localStorage 仍按 origin 隔离，故 `--web-port=5174` 固定端口的 launch.json 改动保留作"运行期工作副本"兜底。最终的"权威数据"以 `assets/data/chips/` 为准；admin 修改后须导出 zip → 解压覆盖 → 重新 `flutter run` 才会同步给所有端。
- **后续**：`test/widget_test.dart` 仍是脚手架自带的计数器示例，无关本次改动；建议另起任务清理。

---

## 2026-05-11 · 精简 project-rules.md 至 ≤1000 字符
- **类型**：docs / decision
- **范围**：`.trae/rules/project-rules.md`、`docs/ai/tech-context.md`
- **动因**：规则文件冗长（>1100 字符），影响 LLM 注入预算与可读性。
- **变更**：
  1. 将"数据持久化"全套细则迁出至 `docs/ai/tech-context.md` 新增节"数据持久化细则（从 project-rules.md 迁出）"。
  2. 规则文件保留要点+指针，新增硬规则 #12："本文件 ≤1000 字符；超出须精简或外迁至 `docs/ai/`"。
  3. 当前字符数 = 999。
- **影响**：后续维护规则时若新增条目，须先评估字符预算，优先把"细则"沉到 `docs/ai/`。
- **后续**：无。

---

## 2026-05-11 · Admin 拖拽排序红屏一闪定位与根治
- **类型**：fix / decision
- **范围**：`lib/pages/admin_page.dart`、`lib/services/earbuds_repository.dart`、`lib/main.dart`、`.ai/memory.md`
- **动因**：在 `/admin` 拖拽排序后,屏幕短暂全红一闪,异常文案 `Unexpected null value`。需要先定位、再根治。
- **变更**：
  1. 临时加入三层诊断手段:`main.dart` 全局接管 `FlutterError.onError`(仅 `kDebugMode`);`EarbudsRepository.reorder` 与 `_AdminPageState._onRepoChanged`、`onReorder`、`itemBuilder` 路径加 `[admin]/[reorder]` `debugPrint`;`itemBuilder` 增加 `i` 越界保护(返回 `SizedBox.shrink`)
  2. 抓到的真实堆栈 `material/tooltip.dart::_buildTooltipOverlay → localToGlobal → applyPaintTransform → sliver_multi_box_adaptor.childMainAxisPosition` nullCheck,确认根因:`Tooltip` 在 `ReorderableDragStartListener` 内被 `Overlay` 渲染时,与 `ReorderableListView` 把 dragged item 从 sliver 中"提"走(`parentData` 短暂解除)发生时序竞态
  3. 根治:把拖拽手柄 `Icon(Icons.drag_indicator)` 外层的 `Tooltip(message:)` 替换为 `Semantics(label:, button: true)`,保留无障碍语义,彻底绕开 Tooltip Overlay 的 `localToGlobal` 路径
  4. 清理所有临时调试日志与 `FlutterError.onError` 接管;**保留** `itemBuilder` 的 `i` 越界 `SizedBox.shrink` 防御(成本低、收益正向)
  5. 补足顺序拖拽功能链:`EarbudsRepository.reorder(oldIndex, newIndex)` 写入入口、写入后 `_rebuildSnapshot/notifyListeners/_persist`;`_AdminPageState._onRepoChanged` 用 `SchedulerBinding.addPostFrameCallback` 推迟 setState 与 reorder 动画解耦;`_buildChipTile` 顶层包 `Material(type: transparency)` 让 drag overlay 仍能找到 Material 祖先
  6. i18n:新增 `adminDragHandle` / `adminReorderDisabledInSearch`(zh+en 同步)
- **影响**:
  - `EarbudsRepository.reorder` 成为芯片排序的唯一写入入口,顺序经 SP 持久化 + 经 `EarbudsState.allChips → EarbudsRepository.instance.chips` 自动同步到所有用户展示界面
  - 搜索过滤期间禁止拖拽(`canReorder = query.trim().isEmpty`),避免 index 与 records 错位
  - **新坑沉淀**:`Tooltip` 不可放在 `ReorderableDragStartListener` 的 child 上 → 写入 `.ai/memory.md` §5
- **校验**:`flutter analyze` → No issues found
- **后续**:无

---

## 2026-05-11 · Admin 增加芯片拖拽排序
- **类型**：feature
- **范围**：`lib/pages/admin_page.dart`、`lib/services/earbuds_repository.dart`、`lib/l10n/app_localizations.dart`
- **动因**：用户要求在 admin 中支持拖拽排芯片,且顺序需同步到所有用户展示界面
- **变更**：
  1. `EarbudsRepository` 新增 `reorder(int oldIndex, int newIndex)`:遵循 `ReorderableListView.onReorder` 语义(target>old 时减一),修改 `_records` → `_rebuildSnapshot()` → `notifyListeners()` → `unawaited(_persist())`
  2. `admin_page.dart` 把 `ListView.builder` 替换为 `ReorderableListView.builder(buildDefaultDragHandles: false)`,leading 槽放 `ReorderableDragStartListener(child: Icon(drag_indicator))` 作为自定义手柄
  3. 搜索过滤期间(`canReorder = query.trim().isEmpty`)降级为普通 `ListView.builder`,并显示"清空搜索后才能拖拽排序"提示,避免可见 index 与底层 `_records` 索引错位
  4. i18n 同步新增 `adminDragHandle` / `adminReorderDisabledInSearch`(zh+en)
- **影响**:`EarbudsState.allChips` 直接读 `EarbudsRepository.instance.chips`,新顺序经 `notifyListeners` 自动散发到所有页面;新顺序经 SP 持久化重启不丢
- **校验**:`flutter analyze` → No issues found
- **后续**：无

---


## 2026-05-09 · 删除历史 const 芯片数据（`lib/config/earbuds/chips/` + 反向导出脚本）
- **类型**：refactor / decision
- **范围**：删除 `lib/config/earbuds/chips/*.dart`（16 文件）、`lib/config/earbuds/earbuds_chip_registry.dart`、`tool/dump_chips_json.dart`；同步更新 `lib/models/earbuds.dart` 注释、`.trae/rules/project-rules.md`、`docs/ai/{project-overview,glossary,tech-context}.md`、`CLAUDE.md`、`.ai/memory.md`
- **动因**：用户确认"彻底删除"。`@Deprecated` const + 反向导出脚本属于过渡期技术债，留着会让"改数据到底动哪里"的语义模糊。
- **变更**：
  1. 删除 18 个文件（16 个 chip_xxxx.dart + registry + tool 脚本）
  2. 所有文档 / 规则 / 注释里的 `kAllChips` / `earbuds_chip_registry.dart` / `dump_chips_json.dart` / `lib/config/earbuds/chips` 字眼全部更新为 `assets/data/earbuds_chips.json`（唯一真相源）
  3. `.ai/memory.md` §3 "芯片参数建模" 决策改写为"数据存为 JSON 资源"，"运行时数据可变性"理由改写（不再提"保留 kAllChips 作种子"）
- **影响**：
  - **改芯片数据 = 改 JSON**，零歧义
  - lib/ 减少 ~3000 行 const 模板代码；`flutter build` 不再编译这些 const
  - 不可逆（git 可恢复）；未来若想重新引入"在 Dart 写然后导出 JSON"通道需手写新脚本
- **校验**：`flutter analyze` → No issues found
- **后续**：无

---


## 2026-05-09 · 芯片数据从 Dart 常量迁移到 JSON 资源
- **类型**：refactor / decision / docs
- **范围**：新增 `assets/data/earbuds_chips.json`、`lib/services/earbuds_chip_loader.dart`、`tool/dump_chips_json.dart`；`pubspec.yaml`、`lib/services/earbuds_repository.dart`、`lib/config/earbuds/earbuds_chip_registry.dart`、`.trae/rules/project-rules.md`、`.ai/memory.md`
- **动因**：用户澄清"数据库格式"指"芯片数据从 Dart 转为更通用格式（JSON）然后从那里读"。前一轮只做了 SharedPreferences 落盘缓存，数据源仍是 const，不符合需求。
- **变更**：
  1. `tool/dump_chips_json.dart`：一次性脚本，把 `kAllChips` + `EarbudsChip.toJson()` 序列化到 `assets/data/earbuds_chips.json`（schema `{version:1, chips:[...]}`，2 空格缩进）
  2. 跑脚本生成 16 颗芯片的 JSON（33991 字节）
  3. `pubspec.yaml` 注册 `assets:` → `assets/data/earbuds_chips.json`
  4. 新增 `services/earbuds_chip_loader.dart`：`rootBundle.loadString` 读 asset → `EarbudsChip.fromJson`，校验 schema version
  5. `EarbudsRepository`：移除对 `kAllChips` 的 import，构造函数不再同步种子；`load()` 改为 SP 命中直接用 → 否则 `_seedFromAsset()`（异步读 JSON）→ 落盘；`resetToSeed()` 同样改读 asset
  6. `kAllChips` 标 `@Deprecated`，注释明确"仅供 tool/ 脚本使用，业务代码禁止 import"；当前 lib/ 业务运行时已无引用
  7. 规则同步：种子来源改写为 JSON asset；`kAllChips` 转为脚本专用
- **影响**：
  - **改芯片数据 = 改 JSON 文件**，不必动 Dart；改完重新运行即可（用户存档存在时需先点 `/admin` 重置）
  - 启动时多一次 `rootBundle.loadString`（仅在首启 / 重置路径），数据量小，无感
  - lib/ 业务 0 处依赖 `kAllChips`；脚本用 `package:bes_consumption/...` 显式 import 以避开 `avoid_relative_lib_imports` lint
- **校验**：`flutter analyze` → No issues found
- **后续**：
  - [ ] 大幅修改 JSON 后若想同步刷新 const，可再改 chip_xxxx.dart 然后跑 `dart run tool/dump_chips_json.dart`（双向暂时只支持 const → JSON 一个方向）
  - [ ] 若引入 hot reload 数据热更新，可在 admin 页加"导入 / 导出 JSON"按钮，文件名约定 `earbuds_chips.json`

## 2026-05-09 · 切换为「数据库格式」：SharedPreferences 持久化 + 规则更新
- **类型**：feature / decision / docs
- **范围**：`.trae/rules/project-rules.md`、`pubspec.yaml`、`lib/models/earbuds.dart`、`lib/services/earbuds_repository.dart`、`lib/main.dart`、`lib/pages/admin_page.dart`、`.ai/memory.md`
- **动因**：用户要求「更改项目规则为使用数据库格式，并且实现」。原仓储为内存态，刷新即丢失。
- **变更**：
  1. `project-rules.md` 新增「数据持久化（数据库格式）」章节：唯一入口 `EarbudsRepository`、`shared_preferences` 后端、单键 `earbuds_db_v1`、Schema 版本化（`{version, chips:[...]}`）、`kAllChips` 仅作种子、写入只走仓储
  2. `pubspec.yaml` 引入 `shared_preferences ^2.2.0`（六端原生通过，最轻量持久化）
  3. `models/earbuds.dart` 为全部 9 个数据类（`SleepCurrent / RunCurrent / SceneTestConfig / EarbudsScene / BtScene / TxSweepVariant / RxSweep / AudioPa / EarbudsChip`）增加 `toJson` / `fromJson`，并附私有 `_d` / `_intDoubleMap` 辅助
  4. `EarbudsRepository` 新增 `Future<void> load()`（启动装载 / 缺省种子并落盘 / 解析失败 fallback 种子）、`Future<void> _persist()`（每次写操作触发）；`commit/add/duplicate/delete` 后 `unawaited(_persist())`；`resetToSeed` 改为 async 并清掉用户存档（写回种子）
  5. `main.dart` 改为 `Future<void> main() async`，调 `WidgetsFlutterBinding.ensureInitialized()` + `await EarbudsRepository.instance.load()`
  6. `admin_page.dart` 重置确认改为 `await resetToSeed()`
- **影响**：
  - 编辑数据现在跨刷新 / 跨进程持久化；首次启动行为与之前一致（看到 16 颗预置芯片）
  - 旧的「non-goal: 持久化」已经撤销
  - 现有计算 / 比较 UI 因消费 `repo.chips` 不可变快照，无需调整
- **后续**：
  - [ ] 若未来字段不兼容升级，需在 `_storageKey` 用 `earbuds_db_v2` 并写迁移
  - [ ] 预存 `test/widget_test.dart` 默认 counter 模板测试为历史遗留，未触碰

## 2026-05-09 · 新增 `/admin` 路由与运行时可编辑芯片仓储
- **类型**：feature / decision
- **范围**：`lib/main.dart`、`lib/services/earbuds_repository.dart`（新）、`lib/state/earbuds_state.dart`、`lib/pages/admin_page.dart`（新）、`lib/l10n/app_localizations.dart`、`pubspec.yaml`
- **动因**：用户要求通过 `/admin` URL 后缀进入管理界面，可显示并修改全部芯片数据字段并保存；进一步要求把现有数据"一步到位变为数据库格式"，便于后续 CRUD。
- **变更**：
  1. 新增 `EarbudsRepository`（`ChangeNotifier` 单例）+ `MutableEarbudsChip` 等 `MutableXxx` 包装类，从 `kAllChips` 种子化，提供 `records / commit / add / duplicate / delete / resetToSeed` 等 CRUD API；UI 层仍读取 `chips` 不可变快照
  2. `EarbudsState` 改为从仓储获取 `allChips`，并监听仓储变化以自动清理失效选中、触发 UI 刷新
  3. 新增 `AdminPage`（左侧列表 + 右侧编辑器）：基础字段、Scene/Scene-ANC、Test Config、BT、Sleep、MCU Run、TX Sweep（dBm→mA Map 编辑器）、RX VANA / RX VSYS、PA；支持新增 / 复制 / 删除 / 保存 / 还原 / 全部重置
  4. `AppLocalizations` 增补 `admin_*` 文案（zh+en 同步）
  5. `lib/main.dart` 启用 `usePathUrlStrategy`（Web）+ `routes` 注册 `/` 与 `/admin`
  6. `pubspec.yaml` 引入 `flutter_web_plugins`（来自 Flutter SDK，非第三方包）以支持 path URL strategy
- **影响**：
  - 数据访问入口由 `kAllChips` 常量切换为仓储快照；现有计算 / 比较页面无需改动
  - 数据为内存态，刷新页面将回到初始 `kAllChips`（项目 non-goal: 持久化）
- **后续**：
  - [ ] 如需跨刷新保留编辑，再评估持久化方案（与项目 non-goal 冲突，需用户决策）
  - [ ] 预存 `test/widget_test.dart` 默认 counter 模板测试失败为历史遗留，本次未触碰

## 2026-05-09 · 初始化 AI 协作文档体系
- **类型**：docs / infra
- **范围**：`.trae/rules/project-rules.md`、`docs/ai/*`
- **动因**：接入 TRAE AI Coding，需要稳定的上下文与记忆层。
- **变更**：
  1. 将原 4KB 详尽规则文件压缩为 <1000 字符的精简版
  2. 新建 `docs/ai/` 目录，包含 overview / product / tech / conventions / workflow / memory / current-focus / task-log / glossary 九个文件
  3. 从仓库现状归纳事实并写入 `memory.md`
- **影响**：后续所有 AI 任务必须遵循 `workflow.md` 的任务前后流程
- **后续**：
  - [ ] 确认 `current-focus.md` 的真实优先级
  - [ ] 评估 `bes_comsuption` 拼写审计的启动时机

## 2026-05-09 · 引入 CLAUDE.md + memory 目录化
- **类型**：docs / decision
- **范围**：`CLAUDE.md`、`.TRAE/rules/project-rules.md`、`docs/ai/memory.md`、`.ai/memory/*`
- **动因**：单文件 `memory.md` 不利于按职责检索和跨项目迁移；需要兼容非 TRAE 的 AI 助手。
- **变更**：
  1. 新建根目录 `CLAUDE.md` 作为项目级 AI 协作入口
  2. memory 拆为 7 份子文档，最终落点定为根目录 `.ai/memory/`（独立目录便于跨项目复制）
  3. `docs/ai/memory.md` 降级为跳转导航索引
  4. `.TRAE/rules/project-rules.md` 阅读顺序更新为 `CLAUDE.md` → overview → focus → `.ai/memory/`
- **影响**：所有 AI 助手改动前阅读路径变化；旧链接 `docs/ai/memory/*` 已作废
- **后续**：被下一条 2026-05-09 · memory 单文件化覆盖

## 2026-05-09 · memory 单文件化（覆盖上一条决策）
- **类型**：docs / decision / revert
- **范围**：`.ai/memory.md`（新）、删除 `.ai/memory/*` 与 `docs/ai/memory/*`、`CLAUDE.md`、`.TRAE/rules/project-rules.md`、`docs/ai/memory.md`
- **动因**：用户明确要求 memory 落点为单文件 `.ai/memory.md`（方案 A），以最小化跨项目迁移时的拷贝单元。
- **变更**：
  1. 新建 `.ai/memory.md`，内部按 7 章节组织（Overview / Facts / Decisions / Constraints / Pitfalls / Progress / Open Questions）
  2. 删除 `.ai/memory/` 下 5 份子文档与 `docs/ai/memory/` 下 3 份遗留文档
  3. `.TRAE/rules/project-rules.md` 阅读顺序末项改为 `.ai/memory.md`；完成项改为"更新 `.ai/memory.md` 对应章节"
  4. `CLAUDE.md` 所有 `.ai/memory/xxx.md` 引用改为 `.ai/memory.md §N`
  5. `docs/ai/memory.md` 导航表重写为章节锚点速查
- **影响**：
  - 跨项目迁移单元从"目录"变为"单文件"，复制粘贴即可
  - 旧路径 `.ai/memory/overview.md` 等全部失效
- **后续**：
  - [ ] 后续如 memory 单文件超过 ~1000 行，再评估是否重新拆分
  - [ ] 核对其它 docs/ai/ 文档是否还有 `.ai/memory/` 旧引用

## 2026-05-09 · earbuds_compare_page 拆分为 part 文件
- **类型**：refactor
- **范围**：`lib/pages/earbuds_compare_page.dart`、新增 `lib/pages/earbuds_pages/` 目录（5 份 part 文件）
- **动因**：单文件 2352 行已超出可维护阈值，按职能拆分便于检索与协作。
- **变更**：
  1. 主文件改为 `library;` + `part 'earbuds_pages/...dart'`，仅保留 `EarbudsComparePage` 与 `_EarbudsComparePageState`
  2. 新建 `earbuds_pages/earbuds_compare_shared.dart`：`_MetricStat` / `_computeMetricStats` / `_EmptyHint` / `_KeepAliveWrapper`
  3. 新建 `earbuds_pages/earbuds_left_sidebar.dart`：左侧栏（侧边栏 / 筛选 / 概览卡 / 芯片列表 / 视图模式）
  4. 新建 `earbuds_pages/earbuds_scene_tab.dart`：场景对比 + 单芯片场景视图（含雷达 / 洞察面板 / 数据表）
  5. 新建 `earbuds_pages/earbuds_metric_table_tab.dart`：度量表格仪表盘（KPI / 热力单元 / 工具栏 / 排序）
  6. 新建 `earbuds_pages/earbuds_sweep_tabs.dart`：`_TxSweepTab` / `_RxSweepTab` 占位
- **影响**：
  - 外部 API（`EarbudsComparePage`）保持不变；`home_page.dart`、`wifi_case_page.dart` 不需调整
  - 私有 `_` 前缀类型在 `part` 库内可继续共享，无需改成公开
  - `flutter analyze` 全工程通过
- **后续**：
  - [ ] 若后续 part 文件再变长，可考虑把 `_MetricStat` 提升为 services 层公开类型

## 2026-05-09 · earbuds Tab 进一步细化为「一 Tab 一文件」
- **类型**：refactor
- **范围**：`lib/pages/earbuds_compare_page.dart`、`lib/pages/earbuds_pages/`
- **动因**：上一次拆分仍把 4 个度量 Tab 合在 `earbuds_metric_table_tab.dart`、Tx/Rx 合在 `earbuds_sweep_tabs.dart`；用户要求"7 个 Tab → 7 个 dart"。
- **变更**：
  1. 新增 6 个 Tab 入口薄包装文件：`earbuds_bt_tab.dart` / `earbuds_sleep_tab.dart` / `earbuds_mcu_run_tab.dart` / `earbuds_pa_tab.dart` / `earbuds_tx_sweep_tab.dart` / `earbuds_rx_sweep_tab.dart`
  2. `earbuds_metric_table_tab.dart` 重命名为 `earbuds_metric_table_view.dart`，作为 4 个度量 Tab 的共享底层视图（KPI / 热力 / 工具栏 / 排序）
  3. 删除 `earbuds_sweep_tabs.dart`（已被 Tx/Rx 两个独立文件取代）
  4. 主文件 `part` 列表显式分组：3 个基础设施（shared / left_sidebar / metric_table_view）+ 7 个 Tab
  5. `TabBarView.children` 改为各 Tab 入口 widget（`_BtTab` / `_SleepTab` / ...），不再直接构造 `_MetricTableView(group: ...)`
- **影响**：
  - 外部 API 保持不变；只有内部文件物理布局调整
  - 度量表底层组件（`_MetricTableView` 等）保留为私有 part 类型，4 个 Tab 入口仅做 `MetricGroup` 绑定
  - `flutter analyze` 全工程通过
- **后续**：
  - [ ] 若 Tx/Rx Sweep 后续有真实实现，可在自己的 dart 文件内独立扩展，不影响其它 Tab

## 2026-05-26 - 固定 Web 调试与部署访问端口为 5174
- **类型**：infra / docs
- **范围**：`.vscode/launch.json`、`docs/admin/workflow.md`、`.ai/memory.md`
- **动因**：Web 端 `shared_preferences` 按 origin 隔离，随机端口会导致本地调试存档看起来丢失；服务器裸 IP 访问默认走 80 端口，也会和固定端口形成不同 origin。
- **变更**：
  1. VS Code debug/profile/release 三个启动项统一使用 `--web-port=5174 --web-hostname=localhost`。
  2. Admin 工作流文档统一说明本地访问 `http://localhost:5174/`，服务器访问 `http://<服务器IP>:5174/`。
  3. `.ai/memory.md` 的 Web origin 隔离坑位同步改为 5174。
- **影响**：后续 Web 调试与服务器访问都应固定 5174；历史 5173 origin 下的浏览器本地存档不会自动迁移。
- **后续**：若项目后续加入 nginx/Docker/systemd 配置，监听或外部映射端口也应使用 5174。

## 2026-05-26 - 修正 VS Code Web 端口参数传递方式
- **类型**：fix / docs
- **范围**：`.vscode/launch.json`、`docs/admin/workflow.md`、`.ai/memory.md`
- **动因**：Dart/Flutter VS Code 调试中 `args` 传给应用本身，`--web-port` 应作为 Flutter tool 参数传递；写在 `args` 会导致 Debug 仍使用随机端口。
- **变更**：将三套启动配置中的 `args` 改为 `toolArgs`，并同步文档和 memory。
- **影响**：从 VS Code 选择这些 launch 配置启动 Web Debug 时，应固定访问 `http://localhost:5174/`。
## 2026-05-26 - BT CASE timing controls
- **类型**：feature / fix
- **范围**：`lib/state/bt_state.dart`、`lib/widgets/config_panels.dart`、`lib/l10n/app_localizations.dart`
- **动因**：BT CASE 需要移除误露出的 HDT period / Listening window / Timeout，并补齐 Connect Interval、Voltage、Attempt、Clock drift、RX/TX Payload 控件。
- **变更**：
  1. 移除 BT CASE 面板中的 HDT period 展示与 `BTState.hdtPeriodUs` 字段。
  2. 新增 BT Connect Interval 滑块，按 625us slot 整数倍配置；该 interval 只改变周期尾部 Sleep，不改变 RX/TX/Post/TIFS 等事件时长。
  3. 新增 Voltage、Attempt、Clock drift、RX Payload、TX Payload 控件；Attempt 为普通数字输入框，Clock drift 作为 RX 前 window widening 事件，Payload 影响对应 RX/TX 时长。
  4. 修正 Relay case 选芯片列表与 `BTState.chip` 的 BT 芯片归属一致性。
- **验证**：`flutter analyze` 通过；`flutter test` 未通过，失败来自既有 `wifi_case_page.dart` Dropdown 类型异常、默认 counter smoke test 断言和小尺寸布局 overflow，非本次 BT CASE 改动路径。

## 2026-05-26 - BT CASE packet type and interval input
- **类型**：feature / fix
- **范围**：`lib/state/bt_state.dart`、`lib/widgets/config_panels.dart`、`lib/l10n/app_localizations.dart`
- **动因**：BT CASE 需要支持 Packet type，并让 Connect Interval 同时支持输入框和滑条且保持 625us slot 吸附。
- **变更**：
  1. 新增 Packet type 下拉，支持 DM1、2-DH1。
  2. Packet type 按 slot 数和 payload rate 影响 RX/TX payload airtime，上限不超过该包型 slot 时长。
  3. Connect Interval 改为输入框 + 滑条组合控件；输入和拖动都统一吸附到 0.625ms 整数倍并同步显示 slot 数。
- **验证**：`flutter analyze` 通过；`flutter test` 未通过，仍为既有 `wifi_case_page.dart` Dropdown 类型异常、默认 counter smoke test 断言和小尺寸布局 overflow。

## 2026-05-26 - BT sniff attempt 与 clock drift ppm 修正
- **类型**：fix / data / test
- **范围**：`lib/state/bt_state.dart`、`lib/widgets/config_panels.dart`、`lib/l10n/app_localizations.dart`、`assets/data/chips/bt/*.json`、`test/bt_state_test.dart`、`test/widget_test.dart`
- **动因**：按 `docs/admin/BT_SniffConsumption.md` 修正 BT CASE 中 sniff 单周期模型；Clock drift 应按 ppm 配置并由 Connect Interval 换算 guard。
- **变更**：
  1. BT sniff 的 `Attempt=N` 改为 1 次 Main RX + 1 次 TX + `N-1` 次 TX 后 RXmin，不再重复追加 TX。
  2. Clock drift UI 从 µs 改为 ppm；guard 使用 `Connect Interval * ppm / 1e6` 计算。
  3. 所有 BT 芯片 JSON 补 `clockDriftPpm: 50.0`，与 `BtChip` 默认值一致。
  4. 补 BTState 单元测试覆盖 Attempt/RXmin 和 ppm guard；修正 Wi-Fi TX power Dropdown 泛型和默认 widget smoke test，使全量测试可通过。
- **验证**：`flutter analyze` 通过；`flutter test` 全量通过。

## 2026-05-26 - BT sniff RXmin 与 attempt wait 参数化
- **类型**：fix / data / test
- **范围**：`lib/models/bt_chip.dart`、`lib/state/bt_state.dart`、`assets/data/chips/bt/*.json`、`test/bt_state_test.dart`
- **动因**：BT sniff 后续 RXmin 与首次 Main RX 的波形宽度需要拆开建模；TX 到每个 RXmin 前存在独立 idle wait 时序。
- **变更**：
  1. BT 芯片模型和所有 BT JSON 新增 `Rmin_us`（默认 88us）与 `AttemptWaitTimeUS`（默认 450us）。
  2. BT sniff Main RX 宽度改为 `Rmin_us + RX Payload airtime + Window Widening`。
  3. TX 后每个后续 RXmin 前新增 `Attempt wait` idle 事件，持续 `AttemptWaitTimeUS`；后续 RXmin 宽度固定为 `Rmin_us`。
  4. 更新 BTState 单元测试覆盖 attempt wait 数量与 Main RX 宽度公式。
- **验证**：`flutter analyze` 通过；`flutter test` 全量通过。

## 2026-05-26 - BT sniff Window widening 与 Attempt wait 电流修正
- **类型**：fix / test
- **范围**：`lib/state/bt_state.dart`、`test/bt_state_test.dart`
- **动因**：Window widening 需要保留独立波形效果；`AttemptWaitTimeUS` 对应 Standby 阶段而非 Sleep。
- **变更**：
  1. BT sniff 恢复独立 `Window widening` 事件，Main RX 自身宽度为 `Rmin_us + RX Payload airtime`。
  2. TX 后每个 `Attempt wait standby` 事件使用 `standbyCurrent_mA`，不再使用 sleep current。
  3. 更新 BTState 测试覆盖独立 window widening 和 attempt wait standby 电流。
- **验证**：`flutter analyze` 通过；`flutter test` 全量通过。

## 2026-05-26 - Clock drift 下限调整为 20ppm
- **类型**：fix / test
- **范围**：`lib/state/bt_state.dart`、`lib/widgets/config_panels.dart`、`test/bt_state_test.dart`
- **动因**：BT CASE 的 Clock drift 参数最小值需要限制为 20ppm。
- **变更**：状态层 `setClockDriftPpm` 与 UI slider 下限同步改为 20ppm，并补充 clamp 单元测试。
- **验证**：`flutter analyze` 通过；`flutter test` 全量通过。

## 2026-05-26 - BT 滑条输入框同步与 rxExtWindow 参数
- **类型**：feature / data / fix
- **范围**：`lib/widgets/config_panels.dart`、`lib/models/bt_chip.dart`、`lib/state/bt_state.dart`、`lib/config/bt_chip_config.dart`、`assets/data/chips/bt/*.json`、`test/bt_state_test.dart`
- **动因**：BT 面板中的滑条需要配套输入框并与状态双向同步；BT 首次 RX 需要使用新的扩展窗口字段。
- **变更**：
  1. 新增 `_NumberSliderInput`，用于 Voltage、Clock drift、PageScan channels、Relay hop gap、Battery capacity 的滑条 + 输入框同步。
  2. BT 芯片字段由 `rxWindow_us` 迁移为 `rxExtWindow_us`，BT JSON 与 fallback config 默认值统一写为 780us；模型保留旧字段读取兼容。
  3. BT sniff 的 Main RX 宽度改为 `rxExtWindow_us + Rmin_us + RX Payload airtime`（其中 packet airtime 仍受 packet type slot 上限限制）。
- **验证**：`flutter analyze` 通过；`flutter test` 全量通过。

## 2026-05-26 - 移除 BT rxWindow_us 兼容读取
- **类型**：cleanup / test
- **范围**：`lib/models/bt_chip.dart`
- **动因**：BT 数据已统一迁移到 `rxExtWindow_us`，不再需要兼容旧 `rxWindow_us`。
- **变更**：`BtChip.fromJson` 仅读取 `rxExtWindow_us`，缺省仍为 780us。
- **验证**：`flutter analyze` 通过；`flutter test` 全量通过。

## 2026-05-26 - BT 首个 RX 预览拆分总时间与占用时间
- **类型**：fix / ui / test
- **范围**：`lib/models/power_event.dart`、`lib/state/bt_state.dart`、`lib/widgets/chart_widgets.dart`、`lib/widgets/legend_hover_widgets.dart`、`lib/l10n/app_localizations.dart`、`test/bt_state_test.dart`
- **动因**：首个 RX 窗口预览需要同时表达包含 Window widening 的总 RX 时间，以及 Main RX 独立占用时间。
- **变更**：
  1. `PowerEvent` 新增可选 `totalDurationUs` / `occupiedDurationUs`。
  2. BT sniff 的 `Main RX` 事件写入总 RX 时间（Window widening + Main RX）和独立占用时间（Main RX）。
  3. 图表 tooltip 与 hover 信息栏在存在拆分数据时展示“总 RX 时间 / 独立占用时间”。
- **验证**：`flutter analyze` 通过；`flutter test` 全量通过。

## 2026-05-26 - BT 首个 RX 预览同屏展示 Window widening 与 Radio RX
- **类型**：fix / ui / test
- **范围**：`lib/models/power_event.dart`、`lib/state/bt_state.dart`、`lib/widgets/chart_widgets.dart`、`lib/widgets/legend_hover_widgets.dart`、`lib/l10n/app_localizations.dart`、`test/bt_state_test.dart`
- **动因**：鼠标悬浮在 `Window widening` 或 `Main RX` 上时，都应展示同一个 Main RX 窗口的完整拆分信息。
- **变更**：
  1. `PowerEvent` 新增 `previewLabel` 与 `windowWideningDurationUs`。
  2. `Window widening` 与 `Main RX` 事件均写入 `previewLabel: Main RX`、`totalDurationUs`、`windowWideningDurationUs`、`occupiedDurationUs`。
  3. tooltip / hover 信息栏展示为 `Main RX`、`Total RX time`、`Window widening Length`、`Radio RX Length`、`Current`。
- **验证**：`flutter analyze` 通过；`flutter test` 全量通过。

## 2026-05-26 - 预览命名从 Duration 统一为 Length
- **类型**：cleanup / ui / test
- **范围**：`lib/models/power_event.dart`、`lib/state/bt_state.dart`、`lib/widgets/chart_widgets.dart`、`lib/widgets/legend_hover_widgets.dart`、`lib/l10n/app_localizations.dart`、`test/bt_state_test.dart`
- **动因**：参数预览中应统一使用 Length 命名，避免 Duration 与 Length 混用。
- **变更**：
  1. 用户可见文案 `Duration` / `持续时间` 改为 `Length` / `长度`。
  2. RX 预览元数据字段从 `totalDurationUs` / `windowWideningDurationUs` / `occupiedDurationUs` 改为 `totalLengthUs` / `windowWideningLengthUs` / `occupiedLengthUs`。
  3. 检查 assets JSON，无 `duration/Duration` 键需要迁移。
- **验证**：`flutter analyze` 通过；`flutter test` 全量通过。

## 2026-05-26 - BT 默认 Vbat 从芯片数据同步
- **类型**：fix / test
- **范围**：`lib/state/bt_state.dart`、`test/bt_state_test.dart`
- **动因**：BT 页面打开时默认电压仍为硬编码 3.7V，未读取 BT JSON 中的 `vbat`，例如 `BES2711IUC2/3` 应为 3.8V。
- **变更**：
  1. 初始化、切换芯片、切换 Case 时统一同步当前 BT 芯片的 `vbat` 与 `clockDriftPpm` 默认值。
  2. 保留用户手动修改电压后的状态，不在普通重算中覆盖。
  3. 新增 BTState 单元测试覆盖初始电压与切换到 `nrf52832` 后同步 3.0V。
- **验证**：`flutter analyze` 通过；`flutter test` 全量通过。

## 2026-05-26 - BT CASE Default Config 波形长度
- **类型**：feature / data / test
- **范围**：`lib/models/bt_chip.dart`、`lib/state/bt_state.dart`、`lib/widgets/config_panels.dart`、`lib/l10n/app_localizations.dart`、`assets/data/chips/bt/*.json`、`test/bt_state_test.dart`
- **动因**：BT CASE 需要默认使用芯片 JSON 中的 Attempt=1 固定阶段 Length；只有关闭 Default Config 后才按窗口参数实时计算。
- **变更**：
  1. `BtChip` 新增 `defaultConfig`，包含 Attempt=1 下 Pre-processing、Crystal ramp-up、Standby、Window widening、Main RX、TIFS、TX、Post 的 `*Length_us`。
  2. 所有 BT JSON 增加 `defaultConfig`；缺省时模型可由现有芯片字段推导 fallback 默认配置。
  3. `BTState.useDefaultConfig` 默认开启；开启时 BT Sniff 直接使用 JSON Length 生成波形，只有 Sleep Length 随 Connect Interval 剩余时间变化；关闭后恢复 packet/payload/attempt/clock drift 公式计算。
  4. BT 配置面板将 Connect Interval 移到 Voltage 下方，并在其下新增 Default Config 开关；开启时隐藏后续手动长度参数。
- **验证**：`flutter analyze` 通过；`flutter test` 全量通过。
## 2026-05-26 - Admin 统一扩展为四类芯片 JSON 管理界面
- **类型**：feature / docs
- **范围**：`lib/main.dart`、`lib/pages/admin_page.dart`、`lib/services/chip_json_repository.dart`、`lib/services/config/config_repository.dart`、`lib/services/earbuds_repository.dart`、`lib/l10n/app_localizations.dart`、`.ai/memory.md`
- **动因**：用户要求 `/admin` 提供密钥登录，并以标签栏管理 BLE CASE、BT CASE、Earbuds、Wi-Fi、运维管理、访问热度；芯片字段需与当前 JSON 同步并支持自定义字段。
- **变更**：新增 `adminSecretKey = 'admin'`；新增通用 `ChipJsonRepository`；`AdminPage` 改为登录 + 6 标签 + 通用 JSON 字段表单；保存同步运行期模型，导出生成 `chips/<domain>/index.json + 单芯片 json`。
- **影响**：Web 端仍不能直接写回 assets，admin 保存先落本地持久化；权威源更新需导出后覆盖 `assets/data/chips/`。
- **验证**：`flutter analyze` 通过；`flutter test` 全量通过；本地 `http://localhost:54542/admin` 返回 200。

## 2026-05-26 - Admin JSON 字段展示优化与显式排序入口
- **类型**：feature / ui
- **范围**：`lib/pages/admin_page.dart`、`lib/l10n/app_localizations.dart`
- **动因**：对象字段以整段 JSON 文本呈现时，类似 `scene.noisePink` 的二级字段难以定位和修改；芯片排序能力也需要更显式地提示会同步到 `index.json`。
- **变更**：对象型 JSON 字段改为递归展开的子字段编辑器，数组和复杂结构仍保留 JSON 文本兜底；芯片列表保留拖拽排序，并在菜单中新增上移/下移；列表区提示导出 JSON 会将当前顺序写入 `index.json`。
- **影响**：保存后仍走 `ChipJsonRepository` 的运行期持久化与导出链路；排序不直接写 assets，导出后覆盖 `assets/data/chips/<domain>/index.json` 才成为新种子顺序。
- **验证**：`flutter analyze` 通过；`flutter test` 全量通过；本地 `http://localhost:54542/admin` 返回 200。

## 2026-05-26 - TX power levels derived from current map
- **Type**: cleanup / data / test
- **Scope**: `lib/models/{ble_chip,bt_chip,wifi_chip}.dart`, `lib/services/chip_json_repository.dart`, `lib/config/*_chip_config.dart`, `assets/data/chips/{ble,bt,wifi}/*.json`, `test/tx_power_levels_test.dart`
- **Reason**: `txPowerLevelsDbm` duplicated the keys of `txCurrent_mA_forDbm`, so admin edits had two sources of truth for the same TX power table.
- **Change**: BLE/BT/Wi-Fi models now derive `txPowerLevelsDbm` from sorted `txCurrent_mA_forDbm` keys, keep the legacy list only as a read fallback, and omit it from `toJson()`; admin repository canonicalizes BLE/BT/Wi-Fi records by removing `txPowerLevelsDbm`; seed JSON and Dart fallback configs were cleaned to store only the dBm -> mA map.
- **Verification**: `flutter analyze` passed; `flutter test` passed; local `http://localhost:54542/admin` returned 200.
