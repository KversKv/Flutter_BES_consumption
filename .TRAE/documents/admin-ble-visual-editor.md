# Admin BLE JSON 可视化编辑

## Context

当前 Admin 的 BLE 编辑器只修改 `_FieldDraft` 字段，Save 时才汇总 JSON，无法直观看到参数对功耗结果的影响。本次仅升级 BLE 域：复用用户端算法、KPI 和时间轴，实现草稿即时预览及图表选阶段编辑；预览不持久化，Save 仍是唯一写入口。

规模：M。不新增依赖，不改变 JSON schema，不扩展 BT/Wi-Fi/TWS。

## 实施方案

### 1. 共用用户端 BLE 计算入口

- 在 `lib/services/power_calculator.dart` 增加纯计算结果与统一入口，收口 `AppState.recompute()` 现有的 Nordic/Legacy、广播/连接/HDT 周期分派，返回 `events` 与 `periodUs`。
- `lib/state/app_state.dart` 改为消费该入口；平均电流、峰值、电荷、吞吐量和续航公式保持不变，避免 Admin 复制算法后与用户页漂移。
- `lib/models/power_event.dart` 增加可选 `stageId`；BLE 生成阶段时赋予稳定且唯一的语义 ID（含重复 RX/TX/TIFS 的序号），其他域保持可选、不受影响。

### 2. 草稿驱动的实时预览

- `_JsonRecordEditorState` 继续唯一持有 `_FieldDraft`，额外保存仅用于预览的 `ProfileParams`、Nordic 开关、Hide sleep/Gap、电池容量和 HDT 选项；默认值对齐 `AppState`，不新增全局 Provider。
- 每次字段或场景变化，都通过现有 `_valueFromField()` 汇总独立 Map，再经 `BleChip.fromJson` 和共用计算入口重算。文本、Switch、嵌套 map、字段重命名/增删均统一触发 `setState`；hover/选中不重算。
- 输入过程中的非法 JSON、非有限数值或异常时保留最后一次有效预览并显示本地化提示，不修改现有 `BleChip.fromJson` 容错和 Save 校验。
- 新增展示型 `lib/widgets/ble_admin_preview.dart`：组合场景控件、用户端 KPI、时间轴及阶段编辑卡。宽屏采用预览与原字段编辑器分栏、独立滚动；窄屏预览在上、字段在下。

### 3. 图表与图例选择阶段

- `lib/widgets/chart_widgets.dart` 的 `UnifiedPowerChart` / `TimelineChartInteractive` 增加可选选中阶段与点击回调，复用现有 `_EventRect` 命中区域，增加触屏/鼠标点击和选中描边；无回调时保持用户页原行为。
- `lib/widgets/legend_hover_widgets.dart` 同步支持点击及选中样式，作为窄阶段的辅助入口；hover 与 selected 状态分离。
- 预览重算后按 `stageId` 保留选择，阶段已不存在时清空选择。

### 4. 阶段参数直接写回同一草稿

- 点击图表/图例后，在预览区展开对应参数卡，通过字段路径读写同一 `_FieldDraft`，因此阶段卡、原字段行、图表和 KPI 同步更新。
- 映射以 `stageId + 当前模型/模式/TX 档位/HDT 频段` 为准，只展示实际生效字段：Setup/Start/Post 的时长和电流、Tail/Setup Standby、Sleep、RX、TIFS、ADV_GAP、TX 当前 dBm 的嵌套电流；TX+CPU 同时映射 TX 与 `postCurrent_mA`，HDT 映射对应 band 的 RX/TX 和 idle 电流。
- 共享字段明确提示联动影响；Window widening、airtime、CPU 补偿等派生时长只读并指向场景控件，不错误映射到 Nordic 已退役字段。缺失字段显示不可编辑，不静默向 JSON 添加字段。
- 场景参数只影响预览，绝不写回芯片 JSON；原 `_save → ChipJsonRepository.update → pushToBackend` 流程不变。

### 5. KPI 与国际化

- `lib/widgets/kpi_widgets.dart` 提取不依赖 Provider 的 KPI 展示组件，`KPIRowAppState` 仅作数据适配，Admin 复用相同样式和指标。
- `lib/l10n/app_localizations.dart` 同步补齐 zh/en：预览、场景参数、阶段编辑、共享字段提示、无效预览等新增文案。

## 关键文件

- 修改：`lib/pages/admin_page.dart`、`lib/services/power_calculator.dart`、`lib/state/app_state.dart`、`lib/models/power_event.dart`
- 修改：`lib/widgets/chart_widgets.dart`、`legend_hover_widgets.dart`、`kpi_widgets.dart`、`lib/l10n/app_localizations.dart`
- 新增：`lib/widgets/ble_admin_preview.dart`，以及必要的聚焦测试文件
- 收尾：更新 `docs/ai/task-log.md`、`docs/ai/current-focus.md`；将“Admin 预览不落库、阶段 ID 映射草稿”的稳定决策记入 `.ai/memory.md`

## 风险与回滚

- 风险：共用计算入口重构造成结果漂移；通过原算法测试和 AppState 对照测试兜底。
- 风险：重复/共享阶段误映射；通过唯一 `stageId`、当前模式映射及共享提示兜底。
- 回滚：预览组件和图表点击参数均为可选增量，无 JSON 数据迁移；可独立撤回 Admin 展示层，再还原共用计算入口。

## 验证

1. 扩充 `test/power_calculator_test.dart`：Nordic/Legacy、广播/连接/HDT 的共用入口与 AppState 结果一致，BLE `stageId` 非空、唯一且重算稳定。
2. 新增 widget 测试：字段与嵌套 TX 修改即时更新 KPI/图表，点击柱段和图例选中正确阶段，阶段卡编辑同步草稿；非法输入不崩溃，预览场景字段不进入 JSON。
3. 按项目已知测试死锁规避方式串行执行相关 `flutter test --concurrency=1`，并用临时 `LOCALAPPDATA` 执行 `flutter analyze`。
4. Windows 实际运行 `/admin`：验证宽/窄布局、模式与 Hide sleep/Gap 切换、即时预览、图表选阶段编辑；未 Save 不写仓储，Save 后仍按原流程保存和提示。
