# Project Memory

> 长期记忆文件。**只记沉淀后的结论**，不记流水；有状态变化时**原地更新**而非追加。
> 标注体系：`[事实]` 仓库可直接验证 / `[决策]` 主动选择 / `[约束]` 外部限制 / `[坑]` 已踩过 / `[待验证]` 暂定。

---

## 1. 稳定事实（Facts）
- [事实] 工程名为 `bes_consumption`；历史目录名 `bes_comsuption` 为拼写错误待修正。
- [事实] 包名 / AppId：`com.example.bes_consumption`。
- [事实] 六端工程齐全：Android / iOS / Windows / macOS / Linux / Web。
- [事实] 状态注入点仅在 `lib/main.dart` 顶层 `MultiProvider`，当前注入 `AppState / EarbudsState / ThemeController`。
- [事实] 芯片预置 16 个：`lib/config/earbuds/chips/chip_*.dart`，通过 `earbuds_chip_registry.dart` 统一注册。
- [事实] 未使用 `freezed` / `json_serializable` / 网络库 / 数据库。

## 2. 关键决策（Decisions）
- [决策] 状态管理选 `provider + ChangeNotifier`，不引入 Riverpod/Bloc —— 理由：Demo 规模小、学习成本低、现有代码已成体系。
- [决策] 自建轻量 `AppLocalizations`，不使用 `intl` 代码生成 —— 理由：仅 zh/en 两种、文案量有限。
- [决策] 主题系统拆成 `app_theme / app_colors / app_spacing`，禁止各页面重复定义颜色/间距常量。
- [决策] 芯片参数用"静态 config 对象"模式，不引入 JSON/配置文件 —— 理由：类型安全 + IDE 跳转友好。

## 3. 已知约束（Constraints）
- [约束] Dart SDK `>=3.6.0 <4.0.0`。
- [约束] Flutter Lints 版本为 `^2.0.0`（较旧），升级需同步处理新增规则。
- [约束] `analysis_options.yaml` 已关闭多条 const/key 相关规则，不得反开。

## 4. 常见坑 / 禁区（Pitfalls）
- [坑] 在 `build()` 内调用 `setXxx()` 触发 `notifyListeners()` 会导致循环重建。
- [坑] 直接在 `pages` / `widgets` 硬编码中文会破坏 zh/en 同步，必须走 `AppLocalizations`。
- [坑] 平台工程里散布 `bes_comsuption` 拼写，重命名时必须全量搜索 6 端 + `pubspec.yaml` + `.vscode/`。
- [禁区] 不要为了"看起来统一"批量替换已存在的合理风格（例如既有引号/注释）。

## 5. 已完成的重要任务（Milestones）
- [事实] 已搭建六端工程 + M3 亮暗主题切换（`ThemeController`）。
- [事实] 已完成 BLE/BT/Wi-Fi 场景页 + 耳机对比页 + Sniff 专页。
- [事实] 已内置 16 款 BES 芯片参数。

## 6. 暂定结论 / 待验证（Tentative）
- [待验证] 是否需要 CSV/截图导出功能。
- [待验证] Web 端 `fl_chart` 性能在大量数据点下的表现。
- [待验证] 是否需要从 `bes_comsuption` → `bes_consumption` 做一次性跨平台重命名审计。

---

## 维护说明

### ✅ 应写入 memory
- 长期有效的事实（工程名、包名、架构决策）
- 已经做出的技术选型与其**理由**
- 踩过并修复的坑（防止重犯）
- 影响跨任务的约束（SDK 版本、lint 策略）

### ❌ 不应写入 memory
- 单次任务过程细节（放 `task-log.md`）
- 临时 TODO / bug 跟踪（放 Issue 或 `current-focus.md`）
- 代码片段 / 实现细节（代码本身即事实源）
- 尚未验证的想法（最多放入"待验证"区并标注）

### 🕒 更新时机
- 任务结束且产生了**新的稳定结论**时
- 决策被推翻时（**原地改写 + 在 task-log 记录变更日期**）
- 发现新坑 / 新约束时

### 🧹 防止流水账
- 每条目单行为主，超过 2 行必须提炼要点
- 每季度 review 一次，合并/删除过期条目
- 同类事项合并成分类列表，不按时间堆叠
- 时间/过程性叙述一律下沉到 `task-log.md`
