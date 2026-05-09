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
