# Glossary

| 术语 | 含义 |
|---|---|
| BES | Best-in-class Embedded System；国产无线 SoC 厂商系列芯片 |
| BLE | Bluetooth Low Energy，低功耗蓝牙 |
| BT  | Bluetooth Classic，经典蓝牙 |
| TWS | True Wireless Stereo，真无线耳机 |
| Profile | 协议 Profile（A2DP/HFP/HID…）或本项目中的"场景参数集" |
| Sniff | BT Classic 下的低功耗侦听模式，可配置 interval/attempt/timeout |
| Advertising Interval | BLE 广播间隔，影响发现延迟与功耗 |
| Connection Interval | BLE 连接间隔，影响延迟与功耗 |
| KPI | 本项目指：平均电流(mA) / 平均功耗(mW) / 续航(h/day) |
| ChangeNotifier | `provider` 推荐的可观察状态基类 |
| AppLocalizations | 本项目自建 i18n 入口，位于 `lib/l10n/app_localizations.dart` |
| Chip Registry | `assets/data/earbuds_chips.json`，集中存放所有芯片型号；运行期由 `EarbudsRepository` 经 `EarbudsChipLoader` 装载 |
