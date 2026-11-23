# Current Focus

> 当前迭代关注点。任务切换时**原地更新**，不追加历史（历史进 task-log）。

## 阶段目标
- NewPlan P1「服务器 Git 化 + Git 发布」与 P2 `sync_from_server.py` 均已完成本地实现和临时仓库验证；未实际部署或线上验收。
- 下一阶段实现 P3 `baseRevision` 并发保护、409 刷新与操作人。

## 本周期优先级（P3 → P4）
1. **[P3]** — 在 P2 验收后实现 `baseRevision` 并发保护、409 刷新与操作人。
2. **[P4]** — 最后实现 Git 历史接口与 admin「变更记录」Tab。

## 明确不做（Not Now）
- 不执行实际部署、SSH、scp 或服务器 Git 写操作。
- 不恢复架构文档 §6 已删除的 P0 差异比对止血、CI 或自研 JSON 合并器。
- 不提前实现 P4 的 Git 历史接口或变更记录页面。

## 当前风险 / 阻塞
- P1/P2 尚未经过实际服务器流程验收。
- [待确认] 服务器是否已安装 Git，以及一次性迁移是否已执行。

## 下一步动作候选
- [ ] 按 `docs/NewPlan/02_AI_Coding_Prompts.md` 的 P3 Prompt 实现并发保护。
- [ ] 实际迁移后在 admin 保存一个字段，本地运行 `sync_from_server.py`，并用服务器 `git log -1` 核对提交。
