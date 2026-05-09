# bes_consumption · TRAE 核心规则

## 目标
Flutter 多端（Android/iOS/Win/macOS/Linux/Web）BES 芯片功耗仿真 Demo。

## 技术栈
Flutter(M3) · Dart >=3.6 <4.0 · provider ^6 · fl_chart ^1.1 · 自建 l10n(zh/en) · flutter_lints ^2。

## 分层（严禁跨层反向依赖）
models → config → services → state → widgets → pages；models 不依赖 Flutter。

## 硬规则
1. 改动前先读 `CLAUDE.md` → `docs/ai/project-overview.md` → `current-focus.md` → `.ai/memory.md`。
2. 复用现有模式优先；禁止无需求重构、禁止批量格式化。
3. 最小改动：只动相关文件。
4. 新依赖写入 `pubspec.yaml` 并说明理由。
5. 用户可见文案必须走 `AppLocalizations`，zh+en 同步。
6. 状态用 `ChangeNotifier`；禁止 `build` 内触发 `notifyListeners`。
7. 文件 `snake_case`；字符串单引号；不加无意义注释。
8. 工程名统一 `bes_consumption`，禁止 `bes_comsuption`。
9. 不确定信息显式标注 [推断]/[待确认]，不臆造 API。
10. 代码、文档、决策必须一致。

## 完成后必做
- 更新 `docs/ai/task-log.md`。
- 稳定事实/决策/约束/坑 → 更新 `.ai/memory.md` 对应章节。
- 规则变更 → 同步本文件并在 task-log 记录。

## 校验
提交前：`flutter analyze` · `flutter test`。
