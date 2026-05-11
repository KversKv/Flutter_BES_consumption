# Admin 操作流程 · 手动添加芯片 / 修改配置

> 面向项目维护者的说明。覆盖"运行时编辑 → 落盘种子"完整链路。

---

## 0. 前置概念（必读）

bes_consumption 的芯片数据有**两层存储**，请务必区分：

| 层 | 介质 | 角色 | 跨端共享 |
|---|---|---|---|
| **A. 资源层（权威）** | `assets/data/chips_index.json` + `assets/data/chips/<id>.json` | 仓库里被 git 管理的"种子数据"，所有端启动时若无本地存档则从这里加载 | ✅（提交 git 后） |
| **B. 运行期层** | `shared_preferences` 的 `earbuds_db_v1` | 当前进程的"工作副本"，admin 的增删改先落在这里 | ❌（按平台 / Web origin 隔离） |

**规则**：所有写入只走 [`EarbudsRepository`](../../lib/services/earbuds_repository.dart)；UI 永远读不可变快照。

> Web 端 `shared_preferences` 实际是 `localStorage`，按 `(scheme, hostname, port)` 隔离。`flutter run -d chrome` 默认随机端口 → 会给每个端口建一份独立存档；建议用 `.vscode/launch.json` 里固定的 `--web-port=5173`。

---

## 1. 启动 admin 页面

```pwsh
flutter run -d chrome   # 或 windows / macos / android / ios
```

进入应用后地址栏访问 `/admin`，或在主界面入口跳转。页面布局：

- 左侧：芯片列表（搜索框 / 拖拽手柄 / + 新增 / 复制 / 删除）
- 右侧：当前选中芯片的编辑器（参数表单）
- 顶部 AppBar：「**导出 JSON**」「**全部重置**」

---

## 2. 新增一颗芯片

1. 左侧点击 **"+"**（`onAdd` → `EarbudsRepository.add()`）
   - 自动分配新 `id`（默认 `chip_new`，重复时追加序号）
   - 立即写入运行期层并刷新列表，光标跳到新条目
2. 在右侧编辑器里改 **ID**（不能为空、不能与现有 ID 重复，否则提示 `adminInvalidId`）
3. 逐项填写：
   - **基础**：name、家族、工艺、封装、是否量产
   - **场景功耗**：ANC OFF / ANC ON 各模式 mA
   - **BT 链路**：sniff / page / inquiry 等
   - **MCU / Sleep / TX Sweep / RX Vana / RX Vsys / PA / 测试配置**
4. 点 **"保存"**（[admin_page.dart#L423](../../lib/pages/admin_page.dart) → `EarbudsRepository.commit()`）
   - 触发 `_persist()` 把整库 JSON 写到 `shared_preferences`
   - SnackBar 显示 `已保存（内存中）。`，提醒你这只是运行期层

> 如果只想做"复制再改"，列表里点条目右侧的复制图标（`onDuplicate` → `EarbudsRepository.duplicate(id)`），会基于现有芯片克隆一份再让你改 ID。

---

## 3. 修改已有芯片

1. 左侧搜索 / 滚动选中目标芯片
2. 在右侧表单里改任意字段
3. **保存**（同上 `commit()`）
4. 此时所有页面（场景对比、Sniff 详情等）都会立即读到新值，因为它们都监听 `EarbudsRepository.instance` 的 `ChangeNotifier`

> ⚠️ 不点保存就切换芯片，未提交的草稿会被丢弃。这是有意设计：编辑器右侧的 `_ChipEditor(key: ValueKey('chip_${selected.id}'))` 在切 ID 时会重建。

---

## 4. 调整顺序（拖拽排序）

- 列表条目左侧的拖拽手柄长按拖拽
- 写入唯一入口：`EarbudsRepository.reorder(oldIndex, newIndex)`，语义遵循 `ReorderableListView.onReorder`
- **限制**：搜索框非空时禁用拖拽（避免可见 index 与底层 `_records` 索引错位），UI 会提示"请先清空搜索"

---

## 5. 删除芯片

- 列表条目右侧"删除"图标 → 二次确认弹窗 → `EarbudsRepository.delete(id)`
- 删除后若当前选中项被删，自动跳到列表首项

---

## 6. **回写到资源层 / 跨端同步（关键）**

到这一步为止你做的所有改动**仅在你这台机器、当前 origin 的运行期层**。要让别的同事 / 别的端 / 重装环境也看到这些改动，必须把它们沉淀回 `assets/data/chips/`。

### 6.1 操作步骤

1. AppBar 点 **「导出 JSON」**
   - Web：浏览器自动下载 `bes_chips_export.zip`
   - 桌面 / 移动：写到系统临时目录（`Directory.systemTemp`），SnackBar 显示绝对路径
2. 解压 zip，里面是：
   ```
   chips_index.json
   chips/
     ├─ <id1>.json
     ├─ <id2>.json
     └─ ...
   ```
3. **整体覆盖** 仓库里的 `assets/data/chips_index.json` 与 `assets/data/chips/`（建议先 `git status` 看 diff 确认）
4. `flutter pub get`（一般不用，除非新增了文件且 IDE 没自动 reload）
5. 重新 `flutter run`，所有端、所有用户都会看到新种子
6. `git add assets/data/ && git commit` 提交

### 6.2 想丢弃运行期层、重新看到资源层种子？

- AppBar 点 **「全部重置」** → `EarbudsRepository.resetToSeed()`：清空 `shared_preferences` → 从 `assets/data/chips/` 重新装载

### 6.3 直接编辑 JSON（不走 admin）

如果只是改一两个字段，也可以直接编辑 `assets/data/chips/<id>.json`，schema 与 `EarbudsChip.toJson()` 保持一致。改完：
- 启动应用前如已存在运行期层，需要先点「全部重置」让 SP 失效，否则仍会显示旧值
- 新增 / 删除文件时，记得同步更新 `chips_index.json` 的 `order` 数组

> 建议：批量修改用直接编辑 JSON；交互式探索用 admin → 导出。

---

## 7. 数据流时序图（速查）

```
[用户在 admin 改字段 / 加芯片]
        │
        ▼
EarbudsRepository.commit / add / reorder / delete
        │
        ├──► 内存 _records 更新
        ├──► _rebuildSnapshot() → 不可变 List<EarbudsChip>
        ├──► notifyListeners()  ── 所有页面立即刷新
        └──► _persist() ── 写 shared_preferences (key: earbuds_db_v1)
                    │
                    │  应用重启
                    ▼
EarbudsRepository.load()
   ├─ 命中 SP 存档 → 用之
   └─ 未命中    → 读 assets/data/chips_index.json + chips/*.json

[用户点「导出 JSON」]
        │
        ▼
exportAsJsonFiles() → { 'chips_index.json': ..., 'chips/<id>.json': ... }
        │
        ▼
saveChipsExportZip()
   ├─ Web   → Blob + AnchorElement.download
   └─ 原生  → Directory.systemTemp/bes_chips_export.zip
        │
        ▼
[人工解压 → 覆盖 assets/data/ → git commit]
```

---

## 8. 常见疑问

**Q1：为什么 Web 端我前一天的修改今天没了？**
A：你换了 `flutter run` 端口 → localStorage origin 变了。固定 `--web-port=5173`，或养成"改完导出 zip"的习惯。

**Q2：为什么浏览器不能直接帮我写回 `assets/data/`？**
A：浏览器安全沙盒禁止 Web 应用写本地任意路径，只能"下载到下载目录"。这是物理限制不可绕过。Native 端理论上能，但为了六端行为一致，统一走"导出 zip 用户回写"流程。

**Q3：导出 zip 的内容和 `assets/data/` 完全一致吗？**
A：是。`exportAsJsonFiles()` 内部用同一个 `EarbudsChip.toJson()`，并用 2 空格缩进的 `JsonEncoder.withIndent` 序列化，diff 友好。

**Q4：能不能让 admin 不写 SP，只写文件？**
A：技术上可以但对 Web 不可行，且"实时编辑必须立即看到效果"需要内存层。当前设计是: SP 是工作副本，文件是权威；导出按钮负责把工作副本"提升"为权威。

---

## 9. 相关代码与文件

- 仓储与持久化：[lib/services/earbuds_repository.dart](../../lib/services/earbuds_repository.dart)
- 资源加载：[lib/services/earbuds_chip_loader.dart](../../lib/services/earbuds_chip_loader.dart)
- 导出：[lib/services/chips_export_service.dart](../../lib/services/chips_export_service.dart)（条件导入 `chips_export_io.dart` / `chips_export_web.dart`）
- 页面：[lib/pages/admin_page.dart](../../lib/pages/admin_page.dart)
- 资源：`assets/data/chips_index.json` + `assets/data/chips/<id>.json`
- 模型 schema：[lib/models/earbuds.dart](../../lib/models/earbuds.dart) 的 `EarbudsChip.toJson() / fromJson()`
