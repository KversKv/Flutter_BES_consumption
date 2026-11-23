# Current Focus

> 当前迭代关注点。任务切换时**原地更新**，不追加历史（历史进 task-log）。

## 阶段目标
- Admin BLE JSON 已升级为与 User 共用算法的图表/KPI 实时预览，并支持图表或图例选择阶段编辑真实草稿字段。
- 上方左右按 2:3 分配：左侧为预览场景/阶段编辑，右侧顶部 KPI、下方功耗图表；下方整个区域仅为 JSON 参数，各编辑区独立滚动。预览不写库，Save 仍是唯一写入口。

## 本周期优先级（P0 → P2）
1. **[P0]** — 在可用的 Flutter 测试环境运行新增算法与组件测试，并完成 Admin 登录后的交互验收。
2. **[P1]** — 修复既有 `windows/flutter/CMakeLists.txt` 缺失后再验证 Windows 构建。
3. **[P2]** — 保持 BT/Wi-Fi/TWS 与现有保存协议不扩散改动。

## 明确不做（Not Now）
- 引入新状态管理库（Riverpod/Bloc）
- 接入真实蓝牙/电流采样
- 预览过程自动保存或把场景参数写入芯片 JSON

## 当前风险 / 阻塞
- 本机 `flutter_tester` 在加载或本地连接阶段空转，新增测试尚未取得运行结果。
- Windows 构建缺少既有 `windows/flutter/CMakeLists.txt`；Web Debug 构建与 `flutter analyze` 已通过。
- 浏览器 `/admin` 路由已验证，交互验收尚未完成 Admin 登录接管。

## 下一步动作候选
- [ ] 串行运行 `test/power_calculator_test.dart` 与 `test/ble_admin_preview_test.dart`
- [ ] 登录 `/admin`，核对字段/嵌套 TX 修改、KPI 联动、图表选阶段、固定结果区及独立滚动条
- [ ] 修复 Windows Flutter CMake 文件后执行 `flutter build windows --debug`
