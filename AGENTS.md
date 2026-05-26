# AGENTS.md — AI 协作入口（bes_consumption）

> 面向任意 AI 编码助手的项目级协作入口。本文件优先级：**仅次于** `.TRAE/rules/project-rules.md`（TRAE 自动加载的硬规则）。当两者冲突时以 `project-rules.md` 为准。

---

## 1. 项目是什么

- **名称**：`bes_consumption`（历史目录拼写 `bes_comsuption` 已视为待修正项，新代码禁止回退）
- **定位**：Flutter 多端（Android / iOS / Windows / macOS / Linux / Web）**BES 芯片功耗仿真与可视化 Demo**
- **核心能力**：在 BLE / BT Classic / Wi-Fi / TWS 耳机四类场景下，按 Profile 与参数估算平均电流、平均功耗、续航，并支持多芯片横向对比
- **技术栈**：Flutter(M3) · Dart `>=3.6 <4.0` · `provider ^6` · `fl_chart ^1.1` · 自建 `AppLocalizations` · `flutter_lints ^2`
- **非目标**：不接真实硬件、不做持久化、不做账号/云端

详见 [docs/ai/project-overview.md](./docs/ai/project-overview.md)、[docs/ai/product-context.md](./docs/ai/product-context.md)。

---

## 2. 开始任务前的阅读顺序（强制）

1. `.TRAE/rules/project-rules.md` — 硬规则，永远第一
2. `docs/ai/project-overview.md` — 定位 + 代码索引
3. `docs/ai/current-focus.md` — 当前迭代关注点
4. `.ai/memory.md` — 已沉淀的长期记忆（按章节查：Facts / Decisions / Constraints / Pitfalls）
5. `docs/ai/tech-context.md` / `coding-conventions.md` — 按需查阅
6. 任务涉及的具体源码文件（通过 `project-overview.md` 的索引定位）

> 原则：**先读文档、再读代码、最后动代码**。未读 memory 不要做假设。

---

## 3. 协作原则

- **最小改动**：只动与任务相关的文件；不顺手重构、不批量格式化、不改既有注释风格。
- **复用优先**：新增功能前先在 `state/ services/ widgets/` 找现有模式；找不到再新增。
- **分层不可逆**：`models → config → services → state → widgets → pages`，严禁反向依赖；`models` 不得 `import 'package:flutter/*'`。
- **i18n 强制**：任何用户可见文案必须走 `AppLocalizations`，且 `zh` 与 `en` 同步补全。
- **状态纪律**：业务状态一律 `ChangeNotifier`；禁止在 `build()` 内触发 `notifyListeners()`。
- **不确定即标注**：用 `[事实]` / `[推断]` / `[待确认]` 区分信息等级；不臆造 API 与参数名。
- **一致性**：代码、文档、决策三者必须同步；发现不一致立刻记入 `task-log.md`。

---

## 4. 修改代码前的检查项

- [ ] 已读 `project-rules.md` + `project-overview.md` + `current-focus.md`
- [ ] 已查 `.ai/memory.md` §5 Pitfalls 确认不踩历史坑
- [ ] 已查 `.ai/memory.md` §4 Constraints 确认不违反硬约束
- [ ] 已在现有代码中搜索是否存在可复用的 state / service / widget
- [ ] 改动不破坏 `models → ... → pages` 分层方向
- [ ] 用户可见文案已规划 zh + en 双语
- [ ] 若引入新依赖，已准备在 `pubspec.yaml` 与 `task-log.md` 记录理由

---

## 5. 文档维护规则

| 触发条件 | 必须更新 |
|---|---|
| 任务完成（任何规模） | `docs/ai/task-log.md`（值得记就记） |
| 任务切换 / 优先级变化 | `docs/ai/current-focus.md`（**原地改**，不追加） |
| 产生新的长期事实 | `.ai/memory.md` §2 Facts |
| 做出新的技术/架构决策 | `.ai/memory.md` §3 Decisions（含被放弃的替代） |
| 发现新的硬约束 | `.ai/memory.md` §4 Constraints |
| 踩坑 / 发现禁区 | `.ai/memory.md` §5 Pitfalls |
| 达成重要里程碑 | `.ai/memory.md` §6 Progress |
| 产生待验证问题 | `.ai/memory.md` §7 Open Questions |
| 硬规则本身变化 | `.TRAE/rules/project-rules.md` + `task-log.md` |
| 协作流程变化 | `AGENTS.md` + `docs/ai/workflow.md` |
| 引入新子系统 / 新模块概念 | 新建 `docs/ai/<topic>.md` |

> 写文档时遵循"高价值、可复用、可检索"；过程细节进 `task-log.md`，稳定结论进 `.ai/memory.md`。

---

## 6. memory 使用说明

- **位置**：`.ai/memory.md`（单文件，按章节组织，设计为"可整体复制到其他项目的迁移单元"）
- **内部结构**：`§1 Overview · §2 Facts · §3 Decisions · §4 Constraints · §5 Pitfalls · §6 Progress · §7 Open Questions`
- **导航入口**：[docs/ai/memory.md](./docs/ai/memory.md) 从 `docs/ai/` 跳转回 `.ai/memory.md`
- **原则**：
  - **只记结论，不记过程**；流水账进 `task-log.md`
  - **原地更新**优先于追加；决策被推翻要改写原条目并在 `task-log.md` 备注日期与原因
  - 每条尽量单行；超过 2 行必须提炼要点
  - 所有条目以标签打头：`[事实] / [决策] / [约束] / [坑] / [待验证]`
  - **分章节下沉**：事实进 §2，决策进 §3，约束进 §4，坑进 §5；不混放
- **何时写**：任务结束后，若产生的是"对未来任务仍有价值的稳定结论"
- **何时不写**：临时实现细节、单次 bug 修复过程、尚未验证的想法（最多放 §7 Open Questions）
- **跨项目迁移**：整体复制 `.ai/memory.md` 到新项目 → 保留章节结构、清空项目特定条目（包名 / 芯片清单 / 历史拼写）、保留通用工程决策（provider 模式 / 分层 / i18n 规范）

---

## 7. 对新任务的处理方式

1. **复述目标**：用一句话复述用户需求，并列出隐含假设。
2. **检索上下文**：按第 2 节顺序读文档；信息不足时用搜索工具查代码，不问用户能在仓库查到的事。
3. **给方案**：列出改动范围（文件清单 + 粒度 XS/S/M/L/XL）、风险、回滚点。
4. **最小执行**：按方案动代码，边做边核对检查项（第 4 节）。
5. **自检**：`flutter analyze` + 涉及逻辑时 `flutter test`。
6. **收尾**：更新 `task-log.md`，必要时更新 `.ai/memory.md` 与 `current-focus.md`。

---

## 8. 对不确定信息的处理方式

- **能在仓库验证** → 用搜索工具自行验证，**不要问用户**。
- **仓库中无且影响实现** → 列出 2~3 个候选方案，注明 `[待确认]` 并询问用户。
- **仓库中无但不阻塞** → 选最保守方案，代码/文档里标 `[推断]`，并在 `.ai/memory.md` §7 Open Questions 记录。
- **绝不做**：编造 API 名、版本号、文件路径、接口签名。

---

## 9. 关键索引（最常用）

- 入口：[lib/main.dart](./lib/main.dart)
- 主页：[lib/pages/home_page.dart](./lib/pages/home_page.dart)
- 功耗算法：[lib/services/power_calculator.dart](./lib/services/power_calculator.dart)
- 芯片数据：[assets/data/earbuds_chips.json](./assets/data/earbuds_chips.json) · [lib/services/earbuds_chip_loader.dart](./lib/services/earbuds_chip_loader.dart) · [lib/services/earbuds_repository.dart](./lib/services/earbuds_repository.dart)
- i18n：[lib/l10n/app_localizations.dart](./lib/l10n/app_localizations.dart)
- 主题：[lib/theme/app_theme.dart](./lib/theme/app_theme.dart)
- Lint：[analysis_options.yaml](./analysis_options.yaml)

---

## 10. 构建与验证命令（PowerShell）

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
flutter build windows   # 或 web / apk / ios / macos / linux
```

提交前至少通过 `flutter analyze`。
