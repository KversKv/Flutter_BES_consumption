# AI Collaboration Workflow

## 任务开始前（必读）
1. `.trae/rules/project-rules.md`（硬规则）
2. `docs/ai/project-overview.md`（定位与索引）
3. `docs/ai/current-focus.md`（当前优先级）
4. `docs/ai/memory.md`（已知事实/决策/坑）
5. 任务涉及的具体文件（按索引找到后 `Read`）

## 任务执行中
- 先回答 / 先确认方案，再动代码
- 不确定的信息：显式标注 `[推断]` / `[待确认]`，不臆造 API
- 最小改动：只动相关文件，不顺手重构
- 复用优先：先查现有模式（state/widgets/services）再新增

## 任务完成后（必做）
- [ ] `flutter analyze` 通过
- [ ] `flutter test` 通过（若改动可能影响逻辑）
- [ ] 在 `docs/ai/task-log.md` 追加一条（见模板）
- [ ] 若产生稳定事实/决策/坑 → 更新 `docs/ai/memory.md`
- [ ] 若规则变化 → 更新 `.trae/rules/project-rules.md` 并在 task-log 记录
- [ ] 若引入跨模块概念或新子系统 → 新建 `docs/ai/<topic>.md`

## 改动粒度建议
| 改动类型 | 说明 |
|---|---|
| XS | 文案/常量/lint 修复 |
| S  | 单文件内小功能 |
| M  | 跨 2~5 文件的特性 |
| L  | 新增页面/state/service；必须记 task-log |
| XL | 目录结构/依赖重大调整；必须先在 task-log 立项 |

## 回复语言
保持与用户最近一条消息一致（当前默认：中文）。
