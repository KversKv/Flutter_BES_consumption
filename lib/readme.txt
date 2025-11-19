lib/
├── main.dart                     # 程序入口
├── models/
│   ├── ble_chip.dart             # 芯片参数定义
│   ├── power_event.dart          # 事件定义
│   ├── profile_params.dart       # 配置参数定义
│
├── state/
│   ├── app_state.dart            # 广播/连接模式状态
│   └── sniffing_state.dart       # Sniffing 状态
│
├── pages/
│   ├── home_page.dart            # 主页面（导航）
│   ├── ble_case_page.dart        # BLE CASE 页面
│   ├── sniffing_page.dart        # Sniffing 页面
│
├── widgets/
│   ├── kpi_widgets.dart          # KPI小部件
│   ├── chart_widgets.dart        # 图表与交互绘图
│   ├── config_panels.dart        # 左侧配置面板
│   ├── legend_hover_widgets.dart # 图下事件和悬浮信息
