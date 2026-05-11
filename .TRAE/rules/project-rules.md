# bes_consumption · TRAE 核心规则

## 目标
Flutter 多端 BES 芯片功耗仿真 Demo。

## 技术栈
Flutter(M3) · Dart >=3.6<4.0 · provider^6 · fl_chart^1.1 · shared_preferences^2 · 自建 l10n(zh/en) · flutter_lints^2。

## 分层（禁反向依赖）
models→config→services→state→widgets→pages；models 不依赖 Flutter。

## 数据持久化（要点）
唯一入口 `services/earbuds_repository.dart`；种子 `assets/data/earbuds_chips.json`；落键 `earbuds_db_v1`。**详情见 `docs/ai/tech-context.md` "数据持久化细则"。**

## 硬规则
1. 改前先读 `CLAUDE.md`→`docs/ai/project-overview.md`→`current-focus.md`→`.ai/memory.md`。
2. 复用优先，禁无需求重构与批量格式化。
3. 最小改动，只动相关文件。
4. 新依赖写 `pubspec.yaml` 并说理由。
5. 可见文案走 `AppLocalizations`，zh+en 同步。
6. 状态用 `ChangeNotifier`；禁 `build` 内 `notifyListeners`。
7. 文件 `snake_case`；单引号；禁无意义注释。
8. 工程名 `bes_consumption`，禁 `bes_comsuption`。
9. 不确定标 [推断]/[待确认]，禁臆造 API。
10. 代码/文档/决策一致。
11. 写库只走仓储，禁直调 `SharedPreferences`。
12. 本文件 ≤1000 字符；超出须精简或外迁至 `docs/ai/`。

## 完成后必做
更新 `docs/ai/task-log.md`；稳定事实/决策/坑→`.ai/memory.md`；规则变更同步本文件并记 task-log。

## 校验
提交前：`flutter analyze` · `flutter test`。
