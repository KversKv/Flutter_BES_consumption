d:\CodeProject\FlutterProjects\bes_comsuption\
├── .dart_tool\                # Dart 工具链缓存和配置文件
├── .gitignore                 # Git 忽略文件配置
├── .metadata                  # Flutter 项目元数据
├── README.md                  # 项目说明文档
├── analysis_options.yaml      # Dart 代码分析配置
├── android\                   # Android 平台相关代码和配置
│   ├── app\                   # Android 应用主代码
│   ├── build.gradle.kts       # Android 构建脚本
│   └── gradle\                # Gradle 配置
├── build\                     # 构建输出目录
├── ios\                       # iOS 平台相关代码和配置
│   ├── Flutter\               # Flutter iOS 相关配置
│   ├── Runner\                # iOS 应用主代码
│   └── Runner.xcodeproj\      # Xcode 项目文件
├── lib\                       # 主源代码目录
│   ├── config\                # 配置文件目录
│   │   ├── ble_chip_config.dart  # BLE 芯片参数配置
│   │   ├── bt_chip_config.dart   # 蓝牙芯片参数配置
│   │   └── wifi_chip_config.dart # Wi-Fi 芯片参数配置
│   ├── l10n\                  # 国际化资源文件
│   │   └── app_localizations.dart # 应用本地化支持
│   ├── main.dart              # 应用入口文件
│   ├── models\                # 数据模型定义
│   │   ├── ble_chip.dart      # BLE 芯片模型
│   │   ├── bt_chip.dart       # 蓝牙芯片模型
│   │   ├── earbuds.dart       # 耳机设备模型
│   │   ├── power_event.dart   # 功耗事件模型
│   │   ├── profile_params.dart # 配置参数模型
│   │   └── wifi_chip.dart     # Wi-Fi 芯片模型
│   ├── pages\                 # 应用页面
│   │   ├── ble_case_page.dart     # BLE 场景分析页面
│   │   ├── bt_home_page.dart      # 蓝牙主页
│   │   ├── bt_page.dart           # 蓝牙功能页面
│   │   ├── bt_page_main.dart      # 蓝牙主功能页面
│   │   ├── bt_pagescan.dart       # 蓝牙扫描页面
│   │   ├── bt_sniffing.dart       # 蓝牙嗅探页面
│   │   ├── earbuds_compare_page.dart # 耳机比较页面
│   │   ├── home_page.dart         # 应用主页
│   │   └── wifi_home_page.dart    # Wi-Fi 主页
│   ├── services\              # 业务逻辑服务
│   ├── state\                 # 应用状态管理
│   │   └── app_state.dart     # 应用全局状态
│   └── widgets\               # 自定义组件
├── pubspec.lock               # 依赖版本锁定文件
├── pubspec.yaml               # 项目依赖配置
└── windows\                   # Windows 平台相关代码和配置
