# Admin 操作流程 - 手动添加芯片 / 修改配置

> 面向项目维护者，覆盖“运行时编辑 -> 导出 JSON -> 回写资源层”的完整链路。

---

## 0. 前置概念

bes_consumption 的芯片数据有两层存储，请务必区分：

| 层 | 介质 | 角色 | 跨端共享 |
|---|---|---|---|
| A. 资源层（权威） | `assets/data/chips/earbuds/index.json` + `assets/data/chips/earbuds/<id>.json` | 仓库里由 git 管理的种子数据；应用启动且无本地存档时从这里加载 | 是，提交 git 后共享 |
| B. 运行期层 | `shared_preferences` 的 `earbuds_db_v1` | 当前环境的工作副本；Admin 的增删改先落在这里 | 否，按平台或 Web origin 隔离 |

所有写入只走 [`EarbudsRepository`](../../lib/services/earbuds_repository.dart)，UI 永远读取不可变快照。

Web 端 `shared_preferences` 实际是 `localStorage`，按 `(scheme, hostname, port)` 隔离。`flutter run -d chrome` 默认随机端口会让每个端口拥有独立存档，因此本项目固定使用 `5174`。

## 1. 本地启动

VS Code 调试配置已经固定：

```json
"toolArgs": [
  "--web-port=5174",
  "--web-hostname=localhost"
]
```

也可以命令行启动：

```powershell
flutter run -d chrome --web-port=5174 --web-hostname=localhost
```

本地访问地址为 `http://localhost:5174/`，Admin 页面为 `http://localhost:5174/admin`。

## 2. 服务器部署访问

`5174` 不属于常见系统保留端口，也不是 IANA well-known port；它更像开发/静态服务端口。服务器部署后请显式暴露端口，访问格式统一为：

```text
http://<服务器IP>:5174/
http://<服务器IP>:5174/admin
```

不要使用裸 IP 访问；裸 IP 等价于默认 80 端口，会和本地 `5174` 形成不同 origin。若只是临时验证 `build/web`，可以让静态服务监听 `5174`：

```powershell
python -m http.server 5174 -d build/web
```

如果使用 nginx、Caddy、Docker 或 systemd，请把监听端口改为 `5174`，或把外部端口映射成 `5174`。

## 3. Admin 修改流程

1. 打开 `/admin`。
2. 在左侧选择、新增、复制、删除或拖拽排序芯片。
3. 在右侧编辑字段。
4. 点击“保存”，改动会写入运行期层，并立即刷新相关页面。
5. 改动稳定后点击“导出 JSON”，下载或生成 `bes_chips_export.zip`。
6. 解压后用其中的 `chips/earbuds/index.json` 和 `chips/earbuds/<id>.json` 覆盖仓库里的 `assets/data/chips/earbuds/`。
7. 重新运行并提交 git。

## 4. 直接编辑 JSON

如果只是修改少量字段，可以直接编辑 `assets/data/chips/earbuds/<id>.json`。新增或删除芯片文件时，必须同步更新 `assets/data/chips/earbuds/index.json` 的 `order` 数组。

如果当前浏览器已经有运行期存档，直接改资源文件后仍可能看到旧数据；需要在 Admin 点击“全部重置”，让 `shared_preferences` 失效并重新读取资源层。

## 5. 常见问题

**Q：为什么 Web 端昨天的修改今天看不到？**

A：通常是端口变了，导致 localStorage origin 变了。VS Code Debug 需要通过 `toolArgs` 固定 `--web-port=5174`，并养成修改完成后导出 JSON 的习惯。

**Q：为什么浏览器不能直接写回 `assets/data/`？**

A：浏览器安全沙箱禁止 Web 应用写本地任意路径，只能触发下载。当前设计是：SP 是工作副本，文件是权威数据，导出按钮负责把工作副本提升为权威数据。

**Q：导出的 zip 和 `assets/data/` 一致吗？**

A：是。导出内部使用同一套 `toJson` 逻辑，并用 2 空格缩进，便于 diff 和 review。

## 6. 相关文件

- 仓储与持久化：[lib/services/earbuds_repository.dart](../../lib/services/earbuds_repository.dart)
- 资源加载：[lib/services/earbuds_chip_loader.dart](../../lib/services/earbuds_chip_loader.dart)
- 导出：[lib/services/chips_export_service.dart](../../lib/services/chips_export_service.dart)
- 页面：[lib/pages/admin_page.dart](../../lib/pages/admin_page.dart)
- 资源：`assets/data/chips/earbuds/index.json` + `assets/data/chips/earbuds/<id>.json`
- 模型 schema：[lib/models/earbuds.dart](../../lib/models/earbuds.dart) 的 `EarbudsChip.toJson()` / `fromJson()`
