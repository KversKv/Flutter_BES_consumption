import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'BES CONSUMPTION (Demo)',
      'nav_ble': 'BLE CASE',
      'nav_bt': 'BT CASE',
      'nav_earbuds': 'Earbuds Compare',
      'nav_wifi': 'WiFi CASE',
      'config': 'Configuration',
      'chip': 'Chip',
      'mode': 'Mode',
      'connected': 'Connected',
      'advertising': 'Advertising',
      'phy': 'PHY',
      'tx_power_label': 'TX Power (dBm):',
      'payload_bytes_label': 'Payload bytes:',
      'adv_interval_label': 'Adv interval (ms):',
      'conn_interval_label': 'Conn interval (ms)',
      'battery_capacity_label': 'Battery capacity (mAh):',
      'chip_specs_title': 'Chip specs & features',
      'chip_specs_description': 'Description: shows key chip parameters for quick comparison.',
      'model': 'Model',
      'vbat': 'VBAT',
      'rx': 'RX',
      'tx': 'TX',
      'description': 'Description',
      'listening_case': 'Listening case',
      'bt_sniff': 'BT sniff',
      'bt_page': 'BT page',
      'bt_pagescan': 'BT pagescan',
      'select_2_3_chips': 'Please select 2~3 chips to compare',
      'chip_id': 'Chip ID',
      'mass_prod_config': 'Mass Production Config',
      'mute': 'Mute',
      'noisepink': 'NoisePink',
      'one_khz': '1kHz',
      'call': 'Call',
      'idle': 'Idle',
      'power_off': 'Power Off',
      'kpi_period': 'Period',
      'kpi_avg_current': 'Average current',
      'kpi_sleep_current': 'Sleep current',
      'kpi_battery_life_est': 'Battery life (est)',
      'kpi_peak_current': 'Peak current',
      'bt_page_config': 'BT Page configuration',
      'bt_page_placeholder': 'Placeholder area — BT Page specific params',
      'bt_pagescan_config': 'BT PageScan configuration',
      'bt_pagescan_placeholder': 'Placeholder area — BT PageScan specific params',
      'bt_sniffing_config': 'BT Sniffing configuration',
      'bt_sniffing_placeholder': 'Placeholder — add sniffing related parameters',
      'sniffing_interval_label': 'Sniffing interval (ms)',
      'power_waveform': 'Power waveform',
      'kpi_title': 'KPI metrics',
      'avg_current_label': 'Average current:',
      'period_label': 'Period:',
      'listening_window': 'Listening window (µs):',
      'listening_interval': 'Listening interval (ms):',
      'channels_label': 'Channels per cycle:',
      'channel_gap': 'Channel gap (µs):',
      'default_note': '(set by code, default 150 µs, not editable)',
      'module_role': 'Module role',
      'sink': 'Sink',
      'source': 'Source',
      'frequency_band': 'Frequency band',
      'hdt_period': 'HDT period (µs):',
      'hdt_phy_rate': 'HDT PHY rate (Mbps):',
      'hdt_repeats': 'HDT repeats:',
      'relay': 'Relay',
      'relay_hop_gap': 'Relay hop gap (µs):',
      'theme_toggle_system': 'Theme: Follow system (click to switch)',
      'theme_toggle_dark': 'Theme: Dark (click to switch)',
      'theme_toggle_light': 'Theme: Light (click to switch)',

      // === Earbuds Compare ===
      'eb_title': 'Earbuds Power Compare',
      'eb_tab_scene': 'Earbuds Scene',
      'eb_tab_bt': 'BT & BLE',
      'eb_tab_sleep': 'Sleep',
      'eb_tab_run': 'MCU Run',
      'eb_tab_tx': 'TX Sweep',
      'eb_tab_rx': 'RX Sweep',
      'eb_tab_pa': 'Audio PA',
      'eb_filter_mass_only': 'Mass-production only',
      'eb_filter_sort_asc': 'Sort ↑',
      'eb_filter_sort_desc': 'Sort ↓',
      'eb_filter_sort_orig': 'Original order',
      'eb_select_chips_hint': 'Select up to 6 chips',
      'eb_selected_count': 'Selected {n}/6',
      'eb_chip_not_applicable': 'N/A',
      'eb_unit_ma': 'mA',
      'eb_unit_ua': 'µA',
      'eb_unit_v': 'V',
      'eb_unit_kb': 'KB',
      'eb_unit_dbm': 'dBm',
      'eb_raw_data': 'Raw data',
      'eb_metric_mute': 'Mute',
      'eb_metric_noisepink': 'NoisePink 8/15 AAC',
      'eb_metric_1khz': '1kHz -6dB 15/15 AAC',
      'eb_metric_call': 'Call 8/15',
      'eb_metric_sniffpage': '500ms Sniff & 1.28s Page',
      'eb_metric_poweroff': 'Power Off',
      'eb_metric_btbase': 'BT Base',
      'eb_metric_ble_adv': 'BLE ADV 500ms 9dBm',
      'eb_metric_ble_conn200': 'BLE Conn 200ms 0dBm',
      'eb_metric_ble_conn500': 'BLE Conn 500ms 0dBm',
      'eb_metric_bt_pagescan': 'BT Pagescan 1.28s 9dBm',
      'eb_metric_bt_sniff200': 'BT Sniff 200ms 0dBm',
      'eb_metric_bt_sniff500': 'BT Sniff 500ms 0dBm',
      'eb_metric_pd256': 'PD Sleep 256KB SRAM',
      'eb_metric_pdfull': 'PD Sleep Full SRAM',
      'eb_metric_deepsleep': 'Deep Sleep',
      'eb_metric_vcorem': 'VcoreM',
      'eb_metric_vcorel': 'VcoreL',
      'eb_metric_vana': 'Vana',
      'eb_metric_vhppa': 'Vhppa',
      'eb_metric_wfi24': 'WFI 24MHz',
      'eb_metric_cm24': 'Coremark 24MHz',
      'eb_metric_cm48': 'Coremark 48MHz',
      'eb_metric_cm96': 'Coremark 96MHz',
      'eb_metric_cm192': 'Coremark 192MHz',
      'eb_metric_pa0': 'Audio 0dB',
      'eb_metric_paneg20': 'Audio -20dB',
      'eb_metric_paneginf': 'Audio -∞dB',
      'eb_chart_xaxis_chip': 'Chip',
      'eb_chart_xaxis_dbm': 'TX Power (dBm)',
      'eb_chart_xaxis_gain': 'RX Gain',
      'eb_chart_yaxis_ma': 'Current (mA)',
      'eb_chart_yaxis_ua': 'Current (µA)',
      'eb_chart_yaxis_v': 'Voltage (V)',
      'eb_rx_domain': 'Supply domain',
      'eb_rx_vana': 'VANA',
      'eb_rx_vsys': 'VSYS (3.8V)',
      'eb_process': 'Process',
      'eb_core': 'Core',
      'eb_ram': 'RAM',
      'eb_mass': 'Mass-prod',
      'eb_yes': 'Y',
      'eb_no': 'N',
      'eb_selection_full': 'Already selected 6 chips',

      // === Earbuds Single Chip View ===
      'eb_view_single': 'Single Chip',
      'eb_view_compare': 'Comparison',
      'eb_test_object': 'Test object',
      'eb_software_version': 'Software Version',
      'eb_module_voltage': 'Module voltage',
      'eb_output_load': 'Output load',
      'eb_audio_output_power': 'Audio output power',
      'eb_audio_encoder': 'Audio encoder',
      'eb_test_phone': 'Test phone',
      'eb_test_date': 'Test date',
      'eb_measurement': 'FREEMAN (mA)',
      'eb_project': 'Project',
      'eb_test_music': 'Test music',
      'eb_volume_req': 'Volume requirement',
      'eb_anc_off': 'ANC OFF',
      'eb_anc_on': 'ANC ON',
      'eb_test_case_1': 'Test case 1',
      'eb_test_case_2': 'Test case 2',
      'eb_test_case_3': 'Test case 3',
      'eb_hotel_cal': "play 'hotel califonia'",
      'eb_play_1khz': "play '1kHz'",
      'eb_mute_current': 'mute current',
      'eb_pink_noise': "-6dB pink noise'",
      'eb_phone_call': 'phone call',
      'eb_power_off_current': 'power off current',
      'eb_standby': 'Standby',
      'eb_vol_13_25': 'Volume: 13/25',
      'eb_vol_25_25': 'Volume: 25/25',
      'eb_vol_0_25': 'Volume: 0/25',
      'eb_vol_10086': '10086 VOL:13/25',
      'eb_shutdown': 'Shutdown',
      'eb_connect_no_behavior': 'connect and no behavior',
      'eb_single_dac': 'Single DAC',
    },
    'zh': {
      'appTitle': 'BES 功耗 (演示)',
      'nav_ble': 'BLE CASE',
      'nav_bt': 'BT CASE',
      'nav_earbuds': 'Earbuds CASE',
      'nav_wifi': 'WiFi CASE',
      'config': '配置',
      'chip': '芯片',
      'mode': '模式',
      'connected': '连接',
      'advertising': '广播',
      'phy': 'PHY',
      'tx_power_label': '发射功率 (dBm):',
      'payload_bytes_label': '负载字节数:',
      'adv_interval_label': '广播间隔 (ms):',
      'conn_interval_label': '连接间隔 (ms)',
      'battery_capacity_label': '电池容量 (mAh):',
      'chip_specs_title': '芯片规格与特点',
      'chip_specs_description': '说明：显示芯片的关键参数，便于快速比较。',
      'model': '型号',
      'vbat': 'VBAT',
      'rx': 'RX',
      'tx': 'TX',
      'description': '说明',
      'listening_case': '侦听用例',
      'bt_sniff': 'BT sniff',
      'bt_page': 'BT page',
      'bt_pagescan': 'BT pagescan',
      'select_2_3_chips': '请选择 2~3 款芯片进行对比',
      'chip_id': 'Chip ID',
      'mass_prod_config': '量产配置',
      'mute': 'Mute',
      'noisepink': 'NoisePink',
      'one_khz': '1kHz',
      'call': 'Call',
      'idle': 'Idle',
      'power_off': 'Power Off',
      'kpi_period': '周期',
      'kpi_avg_current': '平均电流',
      'kpi_sleep_current':'睡眠电流',
      'kpi_battery_life_est': '电池寿命(估)',
      'kpi_peak_current': '峰值电流',
      'bt_page_config': 'BT Page 配置',
      'bt_page_placeholder': '此处为占位设计，后续集成 BT Page 专有参数',
      'bt_pagescan_config': 'BT PageScan 配置',
      'bt_pagescan_placeholder': '此处为占位设计，后续集成 BT PageScan 专有参数',
      'bt_sniffing_config': 'BT Sniffing 配置',
      'bt_sniffing_placeholder': '此处为占位设计，可添加 sniffing 相关参数配置',
      'sniffing_interval_label': 'Sniffing 间隔 (ms)',
      'power_waveform': '功耗波形',
      'kpi_title': 'KPI 指标',
      'avg_current_label': '平均电流:',
      'period_label': '周期:',
      'listening_window': '侦听窗口 (µs):',
      'listening_interval': '侦听间隔 (ms):',
      'channels_label': '侦听信道数:',
      'channel_gap': '信道间隙 (µs):',
      'default_note': '（由代码变量指定，默认 150 µs，不可交互修改）',
      'module_role': '模块角色',
      'sink': 'Sink',
      'source': 'Source',
      'frequency_band': '频段',
      'hdt_period': 'HDT 周期 (µs):',
      'hdt_phy_rate': 'HDT PHY 速率 (Mbps):',
      'hdt_repeats': 'HDT repeats:',
      'relay': 'Relay',
      'relay_hop_gap': 'Relay hop gap (µs):',
      'theme_toggle_system': '主题：跟随系统（点击切换）',
      'theme_toggle_dark': '主题：深色（点击切换）',
      'theme_toggle_light': '主题：浅色（点击切换）',

      // === Earbuds Compare ===
      'eb_title': '耳机功耗对比',
      'eb_tab_scene': '耳机场景',
      'eb_tab_bt': 'BT & BLE',
      'eb_tab_sleep': '睡眠电流',
      'eb_tab_run': 'MCU 运行',
      'eb_tab_tx': 'TX 扫描',
      'eb_tab_rx': 'RX 扫描',
      'eb_tab_pa': '音频 PA',
      'eb_filter_mass_only': '仅量产配置',
      'eb_filter_sort_asc': '升序 ↑',
      'eb_filter_sort_desc': '降序 ↓',
      'eb_filter_sort_orig': '默认顺序',
      'eb_select_chips_hint': '最多选择 6 颗芯片',
      'eb_selected_count': '已选 {n}/6',
      'eb_chip_not_applicable': '—',
      'eb_unit_ma': 'mA',
      'eb_unit_ua': 'µA',
      'eb_unit_v': 'V',
      'eb_unit_kb': 'KB',
      'eb_unit_dbm': 'dBm',
      'eb_raw_data': '原始数据',
      'eb_metric_mute': 'Mute（静音）',
      'eb_metric_noisepink': 'NoisePink 8/15 AAC',
      'eb_metric_1khz': '1kHz -6dB 15/15 AAC',
      'eb_metric_call': 'Call 8/15（通话）',
      'eb_metric_sniffpage': '500ms Sniff & 1.28s Page',
      'eb_metric_poweroff': '关机电流',
      'eb_metric_btbase': 'BT 基础电流',
      'eb_metric_ble_adv': 'BLE ADV 500ms 9dBm',
      'eb_metric_ble_conn200': 'BLE Conn 200ms 0dBm',
      'eb_metric_ble_conn500': 'BLE Conn 500ms 0dBm',
      'eb_metric_bt_pagescan': 'BT Pagescan 1.28s 9dBm',
      'eb_metric_bt_sniff200': 'BT Sniff 200ms 0dBm',
      'eb_metric_bt_sniff500': 'BT Sniff 500ms 0dBm',
      'eb_metric_pd256': '断电睡眠 (保留 256KB SRAM)',
      'eb_metric_pdfull': '断电睡眠 (保留全部 SRAM)',
      'eb_metric_deepsleep': '深度睡眠',
      'eb_metric_vcorem': 'VcoreM',
      'eb_metric_vcorel': 'VcoreL',
      'eb_metric_vana': 'Vana',
      'eb_metric_vhppa': 'Vhppa',
      'eb_metric_wfi24': 'WFI 24MHz',
      'eb_metric_cm24': 'Coremark 24MHz',
      'eb_metric_cm48': 'Coremark 48MHz',
      'eb_metric_cm96': 'Coremark 96MHz',
      'eb_metric_cm192': 'Coremark 192MHz',
      'eb_metric_pa0': '音频 0dB',
      'eb_metric_paneg20': '音频 -20dB',
      'eb_metric_paneginf': '音频 -∞dB',
      'eb_chart_xaxis_chip': '芯片',
      'eb_chart_xaxis_dbm': '发射功率 (dBm)',
      'eb_chart_xaxis_gain': 'RX 增益',
      'eb_chart_yaxis_ma': '电流 (mA)',
      'eb_chart_yaxis_ua': '电流 (µA)',
      'eb_chart_yaxis_v': '电压 (V)',
      'eb_rx_domain': '电源域',
      'eb_rx_vana': 'VANA',
      'eb_rx_vsys': 'VSYS (3.8V)',
      'eb_process': '工艺',
      'eb_core': 'Core',
      'eb_ram': 'RAM',
      'eb_mass': '量产',
      'eb_yes': '是',
      'eb_no': '否',
      'eb_selection_full': '已选满 6 颗芯片',

      // === Earbuds Single Chip View ===
      'eb_view_single': '单芯片',
      'eb_view_compare': '对比',
      'eb_test_object': '测试对象',
      'eb_software_version': '软件版本',
      'eb_module_voltage': '模块电压',
      'eb_output_load': '输出负载',
      'eb_audio_output_power': '音频输出功率',
      'eb_audio_encoder': '音频编码器',
      'eb_test_phone': '测试手机',
      'eb_test_date': '测试日期',
      'eb_measurement': 'FREEMAN (mA)',
      'eb_project': '项目',
      'eb_test_music': '测试音乐',
      'eb_volume_req': '音量要求',
      'eb_anc_off': 'ANC OFF',
      'eb_anc_on': 'ANC ON',
      'eb_test_case_1': 'Test case 1',
      'eb_test_case_2': 'Test case 2',
      'eb_test_case_3': 'Test case 3',
      'eb_hotel_cal': "play 'hotel califonia'",
      'eb_play_1khz': "play '1kHz'",
      'eb_mute_current': 'mute current',
      'eb_pink_noise': "-6dB pink noise'",
      'eb_phone_call': 'phone call',
      'eb_power_off_current': 'power off current',
      'eb_standby': '待机',
      'eb_vol_13_25': 'Volume: 13/25',
      'eb_vol_25_25': 'Volume: 25/25',
      'eb_vol_0_25': 'Volume: 0/25',
      'eb_vol_10086': '10086 VOL:13/25',
      'eb_shutdown': 'Shutdown',
      'eb_connect_no_behavior': 'connect and no behavior',
      'eb_single_dac': '单DAC',
    },
  };

  String _t(String key) {
    final code = locale.languageCode;
    return _localizedValues[code]?[key] ?? _localizedValues['en']![key] ?? key;
  }

  String get appTitle => _t('appTitle');
  String get navBle => _t('nav_ble');
  String get navBt => _t('nav_bt');
  String get navEarbuds => _t('nav_earbuds');
  String get navWifi => _t('nav_wifi');
  String get config => _t('config');
  String get chip => _t('chip');
  String get mode => _t('mode');
  String get connected => _t('connected');
  String get advertising => _t('advertising');

  String get advertisingTxRx => _t('Advertising(TX/RX)');
  String get advertisingTxOnly => _t('Advertising(TX Only)');
  String get bleConnectionCentral => _t('Connection(Central)');
  String get bleConnectionPeripheral => _t('Connection(Peripheral)');

  String get phy => _t('phy');
  String get txPowerLabel => _t('tx_power_label');
  String get payloadBytesLabel => _t('payload_bytes_label');
  String get advIntervalLabel => _t('adv_interval_label');
  String get connIntervalLabel => _t('conn_interval_label');
  String get batteryCapacityLabel => _t('battery_capacity_label');
  String get chipSpecsTitle => _t('chip_specs_title');
  String get chipSpecsDescription => _t('chip_specs_description');
  String get model => _t('model');
  String get vbat => _t('vbat');
  String get rx => _t('rx');
  String get tx => _t('tx');
  String get descriptionLabel => _t('description');
  String get listeningCase => _t('listening_case');
  String get btSniff => _t('bt_sniff');
  String get btPage => _t('bt_page');
  String get btPagescan => _t('bt_pagescan');
  String get select2to3Chips => _t('select_2_3_chips');
  String get chipId => _t('chip_id');
  String get massProdConfig => _t('mass_prod_config');
  String get mute => _t('mute');
  String get noisePink => _t('noisepink');
  String get oneKhz => _t('one_khz');
  String get call => _t('call');
  String get idle => _t('idle');
  String get powerOff => _t('power_off');
  String get btPageConfig => _t('bt_page_config');
  String get btPagePlaceholder => _t('bt_page_placeholder');
  String get btPageScanConfig => _t('bt_pagescan_config');
  String get btPageScanPlaceholder => _t('bt_pagescan_placeholder');
  String get btSniffingConfig => _t('bt_sniffing_config');
  String get btSniffingPlaceholder => _t('bt_sniffing_placeholder');
  String get sniffingIntervalLabel => _t('sniffing_interval_label');
  String get powerWaveform => _t('power_waveform');
  String get kpiTitle => _t('kpi_title');
  String get avgCurrentLabel => _t('avg_current_label');
  String get periodLabel => _t('period_label');
  String get listeningWindow => _t('listening_window');
  String get listeningInterval => _t('listening_interval');
  String get channelsLabel => _t('channels_label');
  String get channelGap => _t('channel_gap');
  String get defaultNote => _t('default_note');
  String get moduleRole => _t('module_role');
  String get sink => _t('sink');
  String get source => _t('source');
  String get frequencyBand => _t('frequency_band');
  String get hdtPeriod => _t('hdt_period');
  String get hdtPhyRate => _t('hdt_phy_rate');
  String get hdtRepeats => _t('hdt_repeats');
  String get relay => _t('relay');
  String get relayHopGap => _t('relay_hop_gap');
  String get kpiPeriod => _t('kpi_period');
  String get kpiAvgCurrent => _t('kpi_avg_current');
  String get kpiSleepCurrent => _t('kpi_sleep_current');
  String get themeToggleSystem => _t('theme_toggle_system');
  String get themeToggleDark => _t('theme_toggle_dark');
  String get themeToggleLight => _t('theme_toggle_light');
  String get kpiBatteryLifeEst => _t('kpi_battery_life_est');
  String get kpiPeakCurrent => _t('kpi_peak_current');

  // ===== Earbuds Compare =====
  String get ebTitle => _t('eb_title');
  String get ebTabScene => _t('eb_tab_scene');
  String get ebTabBt => _t('eb_tab_bt');
  String get ebTabSleep => _t('eb_tab_sleep');
  String get ebTabRun => _t('eb_tab_run');
  String get ebTabTx => _t('eb_tab_tx');
  String get ebTabRx => _t('eb_tab_rx');
  String get ebTabPa => _t('eb_tab_pa');
  String get ebFilterMassOnly => _t('eb_filter_mass_only');
  String get ebFilterSortAsc => _t('eb_filter_sort_asc');
  String get ebFilterSortDesc => _t('eb_filter_sort_desc');
  String get ebFilterSortOrig => _t('eb_filter_sort_orig');
  String get ebSelectChipsHint => _t('eb_select_chips_hint');
  String ebSelectedCount(int n) => _t('eb_selected_count').replaceFirst('{n}', '$n');
  String get ebChipNotApplicable => _t('eb_chip_not_applicable');
  String get ebUnitMa => _t('eb_unit_ma');
  String get ebUnitUa => _t('eb_unit_ua');
  String get ebUnitV => _t('eb_unit_v');
  String get ebUnitKb => _t('eb_unit_kb');
  String get ebUnitDbm => _t('eb_unit_dbm');
  String get ebRawData => _t('eb_raw_data');
  String get ebMetricMute => _t('eb_metric_mute');
  String get ebMetricNoisePink => _t('eb_metric_noisepink');
  String get ebMetric1Khz => _t('eb_metric_1khz');
  String get ebMetricCall => _t('eb_metric_call');
  String get ebMetricSniffPage => _t('eb_metric_sniffpage');
  String get ebMetricPowerOff => _t('eb_metric_poweroff');
  String get ebMetricBtBase => _t('eb_metric_btbase');
  String get ebMetricBleAdv => _t('eb_metric_ble_adv');
  String get ebMetricBleConn200 => _t('eb_metric_ble_conn200');
  String get ebMetricBleConn500 => _t('eb_metric_ble_conn500');
  String get ebMetricBtPagescan => _t('eb_metric_bt_pagescan');
  String get ebMetricBtSniff200 => _t('eb_metric_bt_sniff200');
  String get ebMetricBtSniff500 => _t('eb_metric_bt_sniff500');
  String get ebMetricPd256 => _t('eb_metric_pd256');
  String get ebMetricPdFull => _t('eb_metric_pdfull');
  String get ebMetricDeepSleep => _t('eb_metric_deepsleep');
  String get ebMetricVcoreM => _t('eb_metric_vcorem');
  String get ebMetricVcoreL => _t('eb_metric_vcorel');
  String get ebMetricVana => _t('eb_metric_vana');
  String get ebMetricVhppa => _t('eb_metric_vhppa');
  String get ebMetricWfi24 => _t('eb_metric_wfi24');
  String get ebMetricCm24 => _t('eb_metric_cm24');
  String get ebMetricCm48 => _t('eb_metric_cm48');
  String get ebMetricCm96 => _t('eb_metric_cm96');
  String get ebMetricCm192 => _t('eb_metric_cm192');
  String get ebMetricPa0 => _t('eb_metric_pa0');
  String get ebMetricPaNeg20 => _t('eb_metric_paneg20');
  String get ebMetricPaNegInf => _t('eb_metric_paneginf');
  String get ebChartXaxisChip => _t('eb_chart_xaxis_chip');
  String get ebChartXaxisDbm => _t('eb_chart_xaxis_dbm');
  String get ebChartXaxisGain => _t('eb_chart_xaxis_gain');
  String get ebChartYaxisMa => _t('eb_chart_yaxis_ma');
  String get ebChartYaxisUa => _t('eb_chart_yaxis_ua');
  String get ebChartYaxisV => _t('eb_chart_yaxis_v');
  String get ebRxDomain => _t('eb_rx_domain');
  String get ebRxVana => _t('eb_rx_vana');
  String get ebRxVsys => _t('eb_rx_vsys');
  String get ebProcess => _t('eb_process');
  String get ebCore => _t('eb_core');
  String get ebRam => _t('eb_ram');
  String get ebMass => _t('eb_mass');
  String get ebYes => _t('eb_yes');
  String get ebNo => _t('eb_no');
  String get ebSelectionFull => _t('eb_selection_full');

  // ===== Earbuds Single Chip View =====
  String get ebViewSingle => _t('eb_view_single');
  String get ebViewCompare => _t('eb_view_compare');
  String get ebTestObject => _t('eb_test_object');
  String get ebSoftwareVersion => _t('eb_software_version');
  String get ebModuleVoltage => _t('eb_module_voltage');
  String get ebOutputLoad => _t('eb_output_load');
  String get ebAudioOutputPower => _t('eb_audio_output_power');
  String get ebAudioEncoder => _t('eb_audio_encoder');
  String get ebTestPhone => _t('eb_test_phone');
  String get ebTestDate => _t('eb_test_date');
  String get ebMeasurement => _t('eb_measurement');
  String get ebProject => _t('eb_project');
  String get ebTestMusic => _t('eb_test_music');
  String get ebVolumeReq => _t('eb_volume_req');
  String get ebAncOff => _t('eb_anc_off');
  String get ebAncOn => _t('eb_anc_on');
  String get ebTestCase1 => _t('eb_test_case_1');
  String get ebTestCase2 => _t('eb_test_case_2');
  String get ebTestCase3 => _t('eb_test_case_3');
  String get ebHotelCal => _t('eb_hotel_cal');
  String get ebPlay1Khz => _t('eb_play_1khz');
  String get ebMuteCurrent => _t('eb_mute_current');
  String get ebPinkNoise => _t('eb_pink_noise');
  String get ebPhoneCall => _t('eb_phone_call');
  String get ebPowerOffCurrent => _t('eb_power_off_current');
  String get ebStandby => _t('eb_standby');
  String get ebVol1325 => _t('eb_vol_13_25');
  String get ebVol2525 => _t('eb_vol_25_25');
  String get ebVol025 => _t('eb_vol_0_25');
  String get ebVol10086 => _t('eb_vol_10086');
  String get ebShutdown => _t('eb_shutdown');
  String get ebConnectNoBehavior => _t('eb_connect_no_behavior');
  String get ebSingleDac => _t('eb_single_dac');

  static AppLocalizations of(BuildContext context) {
    final instance = Localizations.of<AppLocalizations>(context, AppLocalizations);
    if (instance == null) {
      // Fallback: return English
      return AppLocalizations(const Locale('en'));
    }
    return instance;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'zh'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}

const LocalizationsDelegate<AppLocalizations> appLocalizationsDelegate = _AppLocalizationsDelegate();
