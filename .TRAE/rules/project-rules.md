# bes_consumption · TRAE 核心规则

## 目标
Flutter 多端 BES 芯片功耗仿真 Demo。

## 技术栈
Flutter(M3) · Dart >=3.6<4.0 · provider^6 · fl_chart^1.1 · shared_preferences^2 · 自建 l10n(zh/en) · flutter_lints^2。

## 分层
models→config→services→state→widgets→pages；禁反向依赖；models 不依赖 Flutter。

## 数据
唯一入口 `services/earbuds_repository.dart`；种子 `assets/data/earbuds_chips.json`；落键 `earbuds_db_v1`。详见 `docs/ai/tech-context.md`。

## 硬规则
1. 改前读 `CLAUDE.md`→`docs/ai/project-overview.md`→`current-focus.md`→`.ai/memory.md`。
2. 复用优先；最小改动；禁无需求重构、批量格式化。
3. 新依赖写 `pubspec.yaml` 并在日志说明理由。
4. 可见文案走 `AppLocalizations`，zh+en 同步。
5. 状态用 `ChangeNotifier`；禁 `build` 内 `notifyListeners`。
6. 文件 `snake_case`；单引号；禁无意义注释。
7. 工程名 `bes_consumption`，禁 `bes_comsuption`。
8. 不确定标 [推断]/[待确认]，禁臆造 API。
9. 代码/文档/决策一致；任务完成更新 `docs/ai/task-log.md`。
10. 写库只走仓储，禁直调 `SharedPreferences`。
11. Web 运行期禁外网加载 CanvasKit/字体等资源；须本地随包或同源托管。
12. 本文件 ≤1000 字符；超出须精简或外迁至 `docs/ai/`。

## 校验
提交前：`flutter analyze` · `flutter test`。
