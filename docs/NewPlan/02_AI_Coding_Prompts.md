# 芯片数据 Git 化 · AI Coding Prompt 集（精简版）

> 配套：[01_芯片数据GitOps架构与路线.md](./01_芯片数据GitOps架构与路线.md)（下称「架构文档」）
> 用法：按 P1 → P4 顺序发送；每次把「通用前置」和对应阶段一起发。上一阶段验收、提交后再进行下一阶段。

---

## 通用前置

```text
你在 bes_consumption 仓库（Flutter 多端 BES 芯片功耗 Demo）中工作。开始前阅读：
.TRAE/rules/project-rules.md、AGENTS.md、.ai/memory.md（§4 约束、§5 坑）、docs/NewPlan/01_芯片数据GitOps架构与路线.md（唯一设计依据）。

要求：
- 只实现本阶段列出的内容，不加架构文档 §6「删去的内容」里的任何功能；最小改动，不顺手重构。
- Flutter 分层 models → config → services → state → widgets → pages；用户可见文案走 AppLocalizations，zh + en 同步。
- Python 只用标准库，兼容 3.8+，Windows 与 Linux 都能运行；subprocess 传 list。
- 不确定处标 [待确认] 并问我，不臆造 API；不要执行任何修改服务器的命令（ssh/scp/git push server）。
- 完成后：涉及 Dart 运行 flutter analyze（tool/chip_server 下运行 dart analyze）；更新 docs/ai/task-log.md。
- [坑] flutter analyze 卡住时在命令前设 $env:LOCALAPPDATA='<Temp>\dlp'。
最后输出：改动文件清单、验证结果、遗留问题。
```

---

## P1 · 服务器 Git 化 + Git 发布

```text
目标：服务器每次 admin 保存都生成 Git 提交；发布改为 git push，不再覆盖线上数据（架构文档 §2、§2.4、§2.5）。

1. 新增 tool/chip_data_check.py：检查 assets/data/chips 下所有 .json 可解析、每个 index.json 引用的文件存在
   （index 结构：earbuds 子目录用 {"order":[文件名不含.json]}，其他域用 {"items":[{"id","file"}]}，以 lib/services/chip_json_repository.dart 的 exportFiles() 为准）。
   提供函数 check(root) -> list[str] 和 CLI（退出码 0/1）。

2. tool/chip_server/bin/server.dart：
   - 环境变量 CHIP_GIT_COMMIT=1 时，POST /api/chips 写盘后执行 git add <写入/删除的文件> 和
     git commit --author "<actor> <actor@chip-admin>" -m "admin(<domain>): <芯片 id 列表>"；没有变化不提交；
     本阶段 actor 取请求字段，缺省 "unknown"；
   - 该模式下不再写 .chip_backups；未开启时行为与现在完全一致；
   - 所有写入在进程内串行执行（简单的 Future 链即可）；
   - GET /api/chips 返回体增加 "revision"（git rev-parse HEAD；不是 Git 仓库或失败时为 null）；
   - POST 中任一文件内容不是合法 JSON → 400。

3. update_serve.py（按架构文档 §2.4）：
   - 删除上传 assets/ 和 pull_data/--pull-data/--skip-data；
   - 新增 push_repo()：chips 有未提交改动则退出 → 调用 chip_data_check → git push server HEAD:main；
     推送失败时提示「服务器上有未同步的改动，请先运行 python sync_from_server.py」并退出；
     没有 server 远端时按 SSH_USER/SSH_HOST 自动添加 ssh://<user>@<host>/opt/chip_server/repo；
   - 后端不再 scp 源码，改为在 /opt/chip_server/repo/tool/chip_server 中 dart pub get + dart compile exe -o /opt/chip_server/chip_server；
     systemd 单元 WorkingDirectory/CHIP_PROJECT_ROOT 改为 /opt/chip_server/repo，增加 Environment=CHIP_GIT_COMMIT=1；
   - 新增常量 REPO_DIR = "/opt/chip_server/repo"；更新文件头 docstring。

4. 更新 docs/admin/服务器更新流程.md 和 部署流程.md：数据相关章节改为新流程，加入架构文档 §4 的一次性迁移步骤。

验证：python tool/chip_data_check.py 对当前数据通过；dart analyze 通过；
在临时目录 git init 一个仓库，本地以 CHIP_GIT_COMMIT=1、CHIP_PROJECT_ROOT=<临时仓库> 启动 chip_server，curl POST 一次后 git log 有提交（写出你执行的命令）。
不要实际部署。
```

---

## P2 · sync_from_server.py

```text
目标：开发者主动运行脚本，把服务器上的芯片改动合并进本地（架构文档 §2.3）。

新增项目根目录 sync_from_server.py，严格按 §2.3 的 7 个步骤实现，只支持参数 --dry-run 和 --check：
- 复用 update_serve.py 中的 SSH_USER/SSH_HOST/REPO_DIR（import 或抽取，不要复制常量）；
- 校验复用 tool/chip_data_check.py；
- 所有 git 调用经一个 run_git() 封装，失败时打印命令和 stderr；
- 退出码：0 成功/已最新，1 预检或校验失败，2 合并冲突待手工解决。

验证：写一个 unittest（tool/tests/test_sync.py），在临时目录用本地路径做 "server" 远端（脚本支持隐藏参数 --remote-url 用于测试）：
服务器改芯片 A、本地改芯片 B → 合并成功；同一字段两边不同值 → 退出码 2；--dry-run 不改变 HEAD。
```

---

## P3 · 管理员并发保护 + 操作人

```text
目标：两个管理员同时编辑时不会互相覆盖；提交作者为真实操作人（架构文档 §2.1、§2.6）。

服务端 server.dart：
- POST /api/chips 接收 baseRevision、actor、domain；按 §2.1 的表格逐文件判断（base 用 git show <baseRevision>:<路径>，
  文件不在 base 中视为不存在；请求中缺少但 base 中存在的文件视为删除；比较用 jsonDecode 后的深度相等）；
- 有冲突返回 409 {revision, conflicts:[路径]}，不写任何文件；成功返回 200 {revision}；
- baseRevision 缺失时以 HEAD 为 base（兼容旧前端）。

Flutter：
- chip_backend_client.dart：fetchFiles 同时返回 revision；saveFiles 增加 baseRevision/actor/domain 参数，409 时抛 ChipSaveConflict(conflicts)；
- chip_json_repository.dart：保存 revision，pushToBackend 与 _commit 的自动同步都携带，成功后更新；
  遇到冲突时重新从后端加载数据（复用现有加载逻辑）并把冲突向上抛给页面；
- admin_session_store.dart：增加操作人读写（shared_preferences 键 admin_actor_name_v1）；
- admin_page.dart：登录页增加必填「操作人」输入框（预填上次值）；保存捕获 ChipSaveConflict 时 SnackBar 提示
  「数据已被其他人修改，已刷新，请重新编辑」；
- l10n 新文案 zh + en。

验证：flutter analyze 0 issue；手工验证步骤：两个浏览器窗口基于同一版本修改同一芯片 → 第二个保存得到提示；修改不同芯片 → 都成功。
```

---

## P4 · 变更记录页

```text
目标：admin 中查看芯片数据修改记录（架构文档 §2.2）。

服务端 server.dart：
- GET /api/history?domain=&limit=30&skip=0：
  git log --format=%H%x1f%an%x1f%aI%x1f%s -n <limit> --skip <skip> -- assets/data/chips/<domain>（domain 为空时取整个 chips 目录；domain 需做路径安全校验）；
  uncommitted 来自 git status --porcelain -- assets/data/chips；不是 Git 仓库时返回 501。
- GET /api/history/<sha>：校验 sha 为 7~40 位十六进制，返回 git show --format= <sha> -- assets/data/chips 的输出。

Flutter：
- chip_backend_client.dart 增加 fetchHistory / fetchHistoryDiff；
- 新增 lib/pages/admin_pages/admin_change_log_tab.dart：域下拉（选项来自 ChipJsonDomain）、列表（时间·操作人·说明·短 sha）、
  「加载更多」按钮、点击后弹窗显示 diff（+ 行绿、- 行红，颜色取自主题）、顶部「未提交」文件列表（为空则不显示）、501 时显示说明；
  页面状态用 StatefulWidget 本地管理即可，不新增 ChangeNotifier；
- admin_page.dart 增加「变更记录」Tab（Wi-Fi 之后），同步修改 DefaultTabController.length、_AdminTabStrip、_LazyAdminTabView；
- l10n 新文案 zh + en。

验证：flutter analyze 0 issue；本地以项目根为 CHIP_PROJECT_ROOT 启动 chip_server，页面能列出本仓库已有的芯片数据提交并打开 diff。
```

---

## 验收清单

- [ ] P1：admin 保存后服务器 `git log` 有提交；服务器有新提交时 `update_serve.py` 推送被拒并提示先同步
- [ ] P2：服务器改 A、本地改 B，`sync_from_server.py` 自动合并；冲突时给出清晰的处理提示
- [ ] P3：两名管理员同时改同一文件，后保存者收到提示而不是覆盖；提交作者是操作人
- [ ] P4：admin「变更记录」页能按域查看记录和 diff
