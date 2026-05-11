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
