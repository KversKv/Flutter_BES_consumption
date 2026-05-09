# Product Context

## 目标用户
[推断] BES 芯片方案 FAE、销售、终端客户的硬件/固件工程师，用于**直观对比功耗与续航**，辅助选型与客户沟通。

## 业务目标
1. 在一个 App 中覆盖 BLE / BT(Classic) / Wi-Fi / TWS 耳机四类场景。
2. 支持多 Profile 参数调节（广播间隔、连接间隔、扫描窗口、Sniff 参数、音频码率等）。
3. 输出关键 KPI：平均电流（mA）、平均功耗（mW）、电池续航（h / day）。
4. 支持多款 BES 芯片横向对比（当前已内置 16 个型号）。

## 功能边界
- [事实] 纯**仿真/估算 Demo**，不接真实硬件、不采样真实电流。
- [事实] 计算集中在 `services/power_calculator.dart` 与 `earbuds_query.dart`，纯函数无副作用。
- [事实] 不做持久化存储；所有状态在内存中（`ChangeNotifier`）。
- [推断] 暂不做账号/云端同步/多用户。
- [待确认] 是否需要导出 CSV / 截图报告。

## 关键用户场景
1. 选中某颗芯片 → 选择 Profile → 调参数 → 实时看 KPI + 图表。
2. 多芯片对比页（`earbuds_compare_page.dart`）横向排序。
3. Sniff 场景单独深度配置（`bt_sniffing.dart` + `sniffing_state.dart`）。

## 非目标（Out of Scope）
- 真实 BLE/BT 协议栈交互
- 云端数据、账号系统
- 跨项目通用组件库抽取
