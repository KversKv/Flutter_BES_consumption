# 芯片数据双向同步：Git 化架构与路线（精简版）

> 状态：**方案稿（未实施）** · 修订：2026-11-23（在初稿基础上删去非必要功能）
> 适用：`assets/data/chips/**.json`（BLE / BT / Wi-Fi / Earbuds）
> 配套：[02_AI_Coding_Prompts.md](./02_AI_Coding_Prompts.md)
> 标注：`[事实]` 仓库可验证 · `[决策]` 本方案选择 · `[待确认]` 需确认

---

## 0. 结论

1. **问题根因**：现在服务器和开发者之间的同步只有 scp 整目录覆盖（`update_serve.py` 默认上传 `assets/`，`--pull-data` 拉回覆盖本地），没有共同的上一个版本，两边都改时只能"后写者赢"。
2. **方案**：让 Git 承担同步、合并和日志，自己不写合并器、不写日志系统。
   - 服务器数据目录是一个 Git 仓库；admin 每次 Save = 一次 `git commit`（作者 = 操作人）。
   - 开发者运行 `sync_from_server.py` = `git fetch` + `git merge`，用 Git 自带的合并。
   - 发布 = `git push server`，Git 自带"非快进拒绝"：服务器上有没同步的 admin 改动时推不上去。
   - 管理员之间：保存时带上"基于哪个版本"，别人改过同一个文件就返回 409，提示刷新后重试。
   - 日志 = Git 历史；admin 新增「变更记录」页，直接展示 `git log` / `git show`。
3. 不采用纯 PR 驱动的 GitOps（管理员需要网页编辑），也不采用数据库（超出项目范围，和"JSON 即种子"冲突）。

---

## 1. 为什么 Git 自带合并就够用

[事实] 每个芯片一个 JSON 文件，2 空格缩进，**一个字段一行**（`"rxCurrent_mA": 6.96,`）。所以：

- 服务器改芯片 A、本地改芯片 B → 不同文件，必然自动合并；
- 同一芯片、相隔较远的不同字段 → 不同行，自动合并；
- 同一字段，或相邻行、在 `index.json` 末尾两边都新增芯片 → Git 报冲突，开发者在编辑器（VS Code 合并视图）里手工解决。

最后这类情况在当前规模下很少见，手工解决成本低，**不值得为它写一个 JSON 合并器**。合并后统一跑一次最小校验（JSON 可解析、index 引用的文件存在），防止冲突解决时把 JSON 改坏。

---

## 2. 目标架构

```text
开发者本地仓库
   │  sync_from_server.py : git fetch server && git merge server/main
   │  update_serve.py     : git push server HEAD:main（非快进自动被拒）
   ▼
服务器 /opt/chip_server/repo   （项目仓库的克隆，main 检出，receive.denyCurrentBranch=updateInstead）
   ├─ assets/data/chips/**.json    ← chip_server 读写
   └─ tool/chip_server/            ← 后端在这里编译
chip_server(:8088)
   GET  /api/chips          → { revision: HEAD sha, files }
   POST /api/chips          → 版本检查 → 写盘 → git commit
   GET  /api/history        → git log（仅芯片数据）
   GET  /api/history/<sha>  → git show 的 diff 文本
Nginx(:5174)  /  → /var/www/flutter_web（不变，仍 scp）
              /api/ → 127.0.0.1:8088
```

[决策] 服务器仓库用 `receive.denyCurrentBranch=updateInstead`：开发者可以直接推送到已检出的 `main`，Git 会同时更新工作区；**非快进推送会被 Git 拒绝**，工作区不干净时也会拒绝。不需要中转分支，也不需要服务器端部署脚本。

[决策] 服务器只需要装 `git`，**不需要 Python**；提交逻辑写在 `server.dart` 里（`Process.run('git', ...)`）。

### 2.1 admin 保存（POST /api/chips）

请求在现有 `{files}` 之上加三个字段：

```json
{ "baseRevision": "<加载数据时的 sha>", "actor": "alice", "domain": "ble",
  "files": { "chips/ble/index.json": "...", "chips/ble/BES2720IMC.json": "..." } }
```

[事实] 前端 `exportFiles(only: domain)` 每次上传的是**这个域的全部文件**，所以必须逐文件判断，否则没改的文件也会盖掉别人的改动。服务端处理（同一进程内串行执行）：

对该域目录下每个文件，取 `base = git show <baseRevision>:<路径>`、`cur = 磁盘`、`new = 请求`（请求里没有但 base 里有 = 删除）。比较时按**解析后的 JSON 相等**判断，不按字节：

| 情况 | 处理 |
|---|---|
| `new == base` | 我没改这个文件 → 跳过 |
| `cur == base` | 只有我改了 → 写入 |
| `cur == new` | 改成了一样的 → 跳过 |
| 其他 | 别人也改了 → **冲突** |

- 有任何冲突 → 什么都不写，返回 `409 {revision, conflicts:[路径...]}`；前端提示"该数据已被其他人修改，请刷新后重新编辑"，并重新加载。
- 无冲突 → 写盘 → `git add` → `git commit --author "<actor> <actor@chip-admin>" -m "admin(<domain>): <改动的芯片 id 列表>"`；没有实际变化则不提交。返回 `200 {revision}`，前端更新自己的 `baseRevision`。
- 请求没带 `baseRevision`（旧前端）→ 按当前 HEAD 处理（即旧行为），保证升级过程中不坏。
- 环境变量 `CHIP_GIT_COMMIT=1` 才提交；本地开发默认不提交，改动留在工作区，由开发者自己 `git commit`。

### 2.2 修改记录

| 场景 | 记录 | 查看 |
|---|---|---|
| 服务器 admin 修改 | 每次 Save 一个提交，作者 = 操作人 | admin「变更记录」页 / `git log` |
| 开发者已提交的修改 | 普通 Git 提交（作者 = git user.name） | 本地 `git log`；发布后服务器「变更记录」页同样可见 |
| 开发者未提交的修改 | Git 工作区 | 本地 admin「变更记录」页顶部「未提交」列表（`git status`）/ `git diff` |
| 同步合并 | `sync_from_server.py` 产生的合并提交 | 同上 |

「变更记录」页（admin 新增 Tab）：
- 域下拉筛选（全部 / 各域）→ 对应 `git log -- assets/data/chips/<域>`；
- 列表：时间 · 操作人 · 提交说明 · 短 sha；底部「加载更多」；
- 点开一条 → 显示该提交的 diff 文本（`+` 绿 / `-` 红）。因为一个字段一行，diff 本身就能看出"哪个字段从多少改成多少"，不再做字段级解析；
- 顶部「未提交」：列出工作区里改动过的芯片文件（服务器上通常为空，本地开发时有用）。

接口：

```http
GET /api/history?domain=ble&limit=30&skip=0
200 { "entries": [ { "sha", "time", "author", "subject" } ], "uncommitted": [ "chips/ble/BES2720IMC.json" ] }

GET /api/history/<sha>
200 { "sha", "diff": "<git show --format= <sha> -- assets/data/chips 的输出>" }
```

### 2.3 `sync_from_server.py`（开发者主动触发）

```powershell
python sync_from_server.py            # 拉取并合并服务器上的改动
python sync_from_server.py --dry-run  # 只看服务器上有哪些新改动，不合并
```

1. 检查 `assets/data/chips` 没有未提交改动，有则退出并提示先提交（提交本身就是本地修改的记录）；
2. 没有 `server` 远端时自动添加（地址由 `update_serve.py` 现有的 `SSH_USER/SSH_HOST` 拼出）；
3. `git fetch server main`；打印 `git log HEAD..server/main -- assets/data/chips`（时间、操作人、说明）；没有新提交就提示"已是最新"并退出；`--dry-run` 再打印 `--stat` 后退出；
4. `git merge --no-edit server/main`；
5. 有冲突 → 列出冲突文件，提示在编辑器里解决、`git add`、`git commit`，然后运行 `python sync_from_server.py --check`；退出码 2；
6. 合并成功（或 `--check`）→ 跑最小校验；失败则列出问题文件，提示修复后提交；
7. 打印汇总：合入了哪些提交、改了哪些芯片文件。

### 2.4 `update_serve.py` 改动

- **删除**上传 `assets/` 和 `--pull-data`（后者提示改用 `sync_from_server.py`）；`--skip-data` 一并删除。
- 新增 `push_repo()`（除 `--frontend-only` 外都执行）：
  1. `assets/data/chips` 有未提交改动 → 退出，提示先提交；
  2. 最小校验；
  3. `git push server HEAD:main`；被拒绝（服务器有新的 admin 提交）→ 提示"先运行 `python sync_from_server.py`"并退出。
- 后端：不再 scp 后端源码，改为在 `/opt/chip_server/repo/tool/chip_server` 里编译并重启（仅在非 `--frontend-only` 时）；systemd 单元的 `WorkingDirectory`、`CHIP_PROJECT_ROOT` 改为 `/opt/chip_server/repo`，并加 `Environment=CHIP_GIT_COMMIT=1`。
- 前端构建与上传流程不变。

### 2.5 最小校验（`tool/chip_data_check.py`，同步和发布共用）

只检查两件事：所有芯片 JSON 能解析；每个 `index.json` 引用的文件都存在。退出码 0/1。

### 2.6 Flutter 侧改动

| 文件 | 改动 |
|---|---|
| `lib/services/chip_backend_client.dart` | `fetchFiles` 读取 `revision`；`saveFiles` 带 `baseRevision/actor/domain`，409 时抛出可识别的冲突异常；新增 `fetchHistory` / `fetchHistoryDiff` |
| `lib/services/chip_json_repository.dart` | 保存 `revision`，保存成功后更新；`pushToBackend` 和 `_commit` 的自动同步都带上它 |
| `lib/services/admin_session_store.dart` | 记住操作人名字 |
| `lib/pages/admin_page.dart` | 登录页加「操作人」输入框（必填）；保存遇到 409 时提示并重新加载；新增「变更记录」Tab |
| 新增 `lib/pages/admin_pages/admin_change_log_tab.dart` | 2.2 描述的页面 |
| `lib/l10n/app_localizations.dart` | 新文案 zh + en |

[约束] 「操作人」只用于标记是谁改的，不是账号体系；登录仍用共享密钥。

---

## 3. 路线（4 个阶段）

| 阶段 | 内容 | 完成后解决的问题 | 粒度 |
|---|---|---|---|
| **P1 服务器 Git 化 + Git 发布** | 一次性迁移（§4）；`server.dart` 保存后提交、GET 返回 revision；`update_serve.py` 改为 `git push`；`chip_data_check.py` | 发布不再覆盖线上数据；服务器每次修改都有记录 | M |
| **P2 同步脚本** | `sync_from_server.py` | 开发者能把服务器改动合并进本地 | S |
| **P3 管理员并发保护** | `baseRevision` 检查 + 409；前端带版本号、操作人输入框、409 提示 | 管理员之间不再互相覆盖；记录有操作人 | S |
| **P4 变更记录页** | `/api/history*` + admin「变更记录」Tab | 在网页上查看修改记录 | S |

P1 做完前，发布时请继续加 `--skip-data`。

---

## 4. 一次性迁移（P1）

1. 通知管理员暂停编辑；
2. 把线上数据拉回本地的**新分支**：`git switch -c migrate/server-data` → `python update_serve.py --pull-data`（旧脚本，迁移时最后用一次）→ `git diff main` 检查 → 提交 → 合回 `main`（如本地也有未发布的数据改动，在这里一并解决）；
3. 服务器：`sudo apt install -y git`（若未装）；`git init /opt/chip_server/repo`，`git -C /opt/chip_server/repo config receive.denyCurrentBranch updateInstead`；
4. 本地：`git remote add server ssh://mingyuanli@172.25.10.143/opt/chip_server/repo` → `git push server main`；
5. 旧目录 `/opt/chip_server/assets` 改名为 `assets.bak-<日期>` 保留一段时间；
6. 运行新版 `python update_serve.py --backend-only`（更新 systemd 单元、编译、重启）；
7. 在 admin 改一个字段 → 服务器 `git -C /opt/chip_server/repo log -1` 能看到该提交 → 恢复编辑。

[待确认] 服务器是否已安装 git。

---

## 5. 风险

| 风险 | 对策 |
|---|---|
| Git 文本合并遇到相邻行 / `index.json` 末尾同时新增 → 冲突 | 编辑器手工解决；解决后最小校验防止 JSON 损坏 |
| 发布推送时恰好有 admin 正在保存 | Git 的锁会让其中一个失败；推送失败就重试，或先 sync |
| 前端结构性操作（增/删/排序）自动同步也会产生提交 | 可接受，提交很小；记录反而更完整 |

---

## 6. 相比初稿删去的内容（需要时再加）

| 删去 | 理由 |
|---|---|
| 自研字段级 JSON 三方合并器 + Git merge driver + 冲突 sidecar 文件 | 一字段一行，Git 自带合并已够用 |
| 数值字面量保真的 JSON 读写库 | 不再有 Python 改写 JSON，没有格式漂移问题 |
| 服务器端三方合并、逐字段冲突对话框、`/resolve` 接口、兼容开关 | 改为"冲突就 409 + 刷新重试"，管理员少时足够 |
| 结构化提交 trailer、`prepare-commit-msg`/`pre-commit` 钩子 | Git 作者 + 提交说明已能回答"谁、何时、改了什么" |
| 字段级审计解析、审计缓存、来源/操作人/时间多维筛选 | diff 本身就是字段级的；只保留按域筛选 |
| 本地未提交修改的 journal 日志文件 | 用 `git status` / `git diff` 代替 |
| 部署日志 `deploy.jsonl`、中转分支 + 服务器部署脚本 | `updateInstead` 推送原生保证只能快进 |
| 网页一键回滚 | 需要时在本地 `git revert` 后发布 |
| 服务器 Python 依赖、flock 锁 | 提交逻辑写在 `server.dart`，进程内串行 |
| sync 的 `--prefer/--autostash/--push-origin`、冲突预测、同步报告文件 | 非必要；冲突交给编辑器 |
| P0 差异比对止血、P6 CI | P1 直接解决问题；CI 当前非必要 |

升级时机：管理员明显增多、409 频繁出现 → 再加字段级合并；需要权限区分 → 再做账号体系。
