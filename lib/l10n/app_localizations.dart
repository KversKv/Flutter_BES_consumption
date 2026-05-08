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
