# Current Focus

> 当前迭代关注点。任务切换时**原地更新**，不追加历史（历史进 task-log）。

## 阶段目标
- NewPlan P1「服务器 Git 化 + Git 发布」、P2 `sync_from_server.py` 与 P3 管理员并发保护均已完成本地实现和临时仓库验证；未实际部署或线上验收。
- 下一阶段实现 P4 Git 历史接口与 admin「变更记录」Tab。

## 本周期优先级（P4）
1. **[P4]** — 实现 Git 历史接口与 admin「变更记录」Tab。

## 明确不做（Not Now）
- 不执行实际部署、SSH、scp 或服务器 Git 写操作。
- 不恢复架构文档 §6 已删除的 P0 差异比对止血、CI 或自研 JSON 合并器。

## 当前风险 / 阻塞
- P1/P2/P3 尚未经过实际服务器流程验收；P3 尚未执行浏览器双窗口手工验收。
- [待确认] 服务器是否已安装 Git，以及一次性迁移是否已执行。

## 下一步动作候选
- [ ] 按 `docs/NewPlan/02_AI_Coding_Prompts.md` 的 P4 Prompt 实现变更记录。
- [ ] 实际迁移后验证双管理员同/不同文件保存、操作人作者、`sync_from_server.py` 与服务器 `git log -1`。
