import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'BES CONSUMPTION',
      'browser_title_user': 'BES CONSUMPTION - User',
      'browser_title_admin': 'BES CONSUMPTION - Admin',
      'nav_ble': 'BLE CASE',
      'nav_bt': 'BT CASE',
      'nav_earbuds': 'Earbuds',
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
      'chip_specs_description':
          'Description: shows key chip parameters for quick comparison.',
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
      'bt_pagescan_placeholder':
          'Placeholder area — BT PageScan specific params',
      'bt_sniffing_config': 'BT Sniffing configuration',
      'bt_sniffing_placeholder':
          'Placeholder — add sniffing related parameters',
      'sniffing_interval_label': 'Sniffing interval (ms)',
      'power_waveform': 'Power waveform',
      'kpi_title': 'KPI metrics',
      'avg_current_label': 'Average current:',
      'period_label': 'Period:',
      'listening_window': 'Listening window (µs):',
      'listening_interval': 'Listening interval (ms):',
      'channels_label': 'Channels per cycle:',
      'channel_gap': 'Channel gap (µs):',
      'bt_packet_type_label': 'Packet type',
      'bt_voltage_label': 'Voltage:',
      'bt_rx_payload_label': 'RX Payload:',
      'bt_tx_payload_label': 'TX Payload:',
      'bt_connect_interval_label': 'Connect interval:',
      'bt_default_config_label': 'Default Config',
      'bt_attempt_label': 'Attempt:',
      'bt_clock_drift_label': 'Clock drift:',
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
      'config_section_device': 'Device',
      'config_section_radio': 'Radio',
      'config_section_timing': 'Timing',
      'config_section_advanced': 'Advanced',
      'config_section_power': 'Power',
      'config_section_case': 'Case',
      'config_section_manual': 'Manual parameters',

      // === Earbuds ===
      'eb_title': 'Earbuds Power Compare',
      'eb_tab_scene': 'Earbuds Scene',
      'eb_tab_bt': 'BT & BLE',
      'eb_tab_sleep': 'Sleep',
      'eb_tab_run': 'MCU Run',
      'eb_tab_cpu_consumption': 'CPU Consumption',
      'eb_tab_tx': 'TX Sweep',
      'eb_tab_rx': 'RX Sweep',
      'eb_tab_pa': 'Audio PA',
      'eb_config': 'Config',
      'eb_content': 'Content',
      'eb_view_mode': 'View Mode',
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
      'eb_metric_standby': 'Standby',
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
      'eb_sweep_view_curve': 'Curve',
      'eb_sweep_view_table': 'Table',
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
      'eb_summary': 'Summary',
      'eb_best': 'Best',
      'eb_worst': 'Worst',
      'eb_avg': 'Avg',
      'eb_radar_title': 'Multi-dimension Radar',
      'eb_delta_vs_best': 'Δ vs Best',
      'eb_baseline': 'Baseline',
      'eb_search_chip': 'Search chip...',
      'eb_chip_info': 'Chip Info',
      'eb_no_data': 'No Data',
      'eb_noisepink_detail_title': 'NoisePink 8/15 AAC · Voltage & Power Breakdown',
      'eb_npd_voltage': 'Voltage (V)',
      'eb_npd_current': 'Current (mA)',
      'eb_npd_isys': 'Isys',
      'eb_npd_icore': 'Icore',
      'eb_npd_iana': 'Iana',
      'eb_npd_ihppa': 'Ihppa',
      'eb_npd_isys_remain': 'Isys_remain',

      // === Admin Page ===
      'admin_title': 'Admin · Earbuds Data Editor',
      'admin_back_home': 'Back to Home',
      'admin_search_chip': 'Search by Chip ID...',
      'admin_add_chip': 'Add Chip',
      'admin_duplicate': 'Duplicate',
      'admin_delete': 'Delete',
      'admin_save': 'Save',
      'admin_revert': 'Revert',
      'admin_reset_all': 'Reset all to seed',
      'admin_unsaved_changes': 'Unsaved changes',
      'admin_saved': 'Saved (in-memory).',
      'admin_reset_confirm_title': 'Reset all data?',
      'admin_reset_confirm_body':
          'This restores every chip record to the original seed (const) data. Your in-memory edits will be lost.',
      'admin_reset_domain_body':
          'Records in this tab will be restored from the JSON seed files. Edits saved locally will be lost.',
      'admin_sync_excel': 'Sync Excel',
      'admin_sync_excel_pick_failed': 'No file selected or read failed.',
      'admin_sync_excel_parse_failed':
          'Could not parse the file. Please check the format.',
      'admin_sync_excel_empty':
          'No valid NoisePink rows found in the file.',
      'admin_sync_excel_result_title': 'Sync finished',
      'admin_sync_excel_result_body':
          'Synced {matched} chip(s); skipped {skipped} unmatched.',
      'admin_sync_excel_result_saved':
          'All {matched} chip(s) were written back to the JSON files automatically. No need to Save each chip.',
      'admin_sync_excel_result_unsaved':
          'Changes for {matched} chip(s) are staged locally but NOT written to JSON (backend unavailable): {error}',
      'admin_sync_excel_matched_title': 'Synced ({n})',
      'admin_sync_excel_skipped_title': 'Skipped ({n})',
      'admin_sync_excel_skipped_hint':
          'These IDs appear in the Excel file but no matching chip exists in the in-memory store, so they were ignored.',
      'admin_delete_confirm_title': 'Delete chip?',
      'admin_delete_confirm_body':
          'Chip "{id}" will be removed from the in-memory store. Continue?',
      'admin_cancel': 'Cancel',
      'admin_confirm': 'OK',
      'admin_field_id': 'ID',
      'admin_field_process': 'Process',
      'admin_field_core': 'Core',
      'admin_field_full_ram_kb': 'Full RAM (KB)',
      'admin_field_mass_production': 'Mass Production',
      'admin_section_basic': 'Basic',
      'admin_section_scene': 'Earbuds Scene (mA)',
      'admin_section_scene_anc_on': 'Earbuds Scene · ANC ON (mA)',
      'admin_section_bt': 'BT & BLE Scene (mA)',
      'admin_section_sleep': 'Sleep Current (µA / V)',
      'admin_section_mcu_run': 'MCU Run Current (mA)',
      'admin_section_tx_sweep': 'TX Sweep (dBm → mA)',
      'admin_section_rx_vana': 'RX Sweep · VANA (gain → mA)',
      'admin_section_rx_vsys': 'RX Sweep · VSYS (gain → mA)',
      'admin_section_pa': 'Audio PA (mA)',
      'admin_section_test_config': 'Scene Test Config',
      'admin_add_row': 'Add row',
      'admin_remove_row': 'Remove',
      'admin_remove_field_confirm_title': 'Remove field?',
      'admin_remove_field_confirm_body':
          'Field "{name}" will be removed from this record. Continue?',
      'admin_no_chip_selected': 'Select a chip on the left to edit.',
      'admin_total_chips': 'Total: {n}',
      'admin_invalid_id': 'ID cannot be empty or duplicated.',
      'admin_invalid_id_empty':
          'ID cannot be empty (or left as the "chip_new" placeholder). Please enter a unique ID.',
      'admin_invalid_id_duplicate':
          'ID "{id}" already exists. Please choose a different one.',
      'admin_drag_handle': 'Drag to reorder',
      'admin_reorder_disabled_in_search':
          'Clear the search to drag-reorder chips.',
      'admin_sort_hint':
          'Drag the handle or use Move up / Move down. Export JSON writes this order to index.json.',
      'admin_move_up': 'Move up',
      'admin_move_down': 'Move down',
      'admin_export_json': 'Export JSON',
      'admin_export_success':
          'Exported chips to {location}. Replace assets/data/chips/ to make it the new seed.',
      'admin_export_failed': 'Export failed: {error}',
      'admin_login_title': 'Welcome to BES Admin',
      'admin_login_subtitle':
          'Enter your administrator credentials to continue (Demo).',
      'admin_login_badge': 'Secure admin verification',
      'admin_secret': 'Access key',
      'admin_secret_hint': 'Enter administrator access key',
      'admin_login': 'Login',
      'admin_login_checking': 'Verifying...',
      'admin_show_secret': 'Show access key',
      'admin_hide_secret': 'Hide access key',
      'admin_logout': 'Logout',
      'admin_invalid_secret': 'Invalid secret key.',
      'admin_ble_case': 'BLE CASE Management',
      'admin_bt_case': 'BT CASE Management',
      'admin_earbuds': 'Earbuds Management',
      'admin_wifi': 'Wi-Fi Management',
      'admin_ops': 'Operations',
      'admin_heat': 'Visit Heat',
      'admin_json_editor': 'JSON fields',
      'admin_add_field': 'Add field',
      'admin_field_name': 'Field name',
      'admin_field_value': 'Value',
      'admin_field_type': 'Type',
      'admin_type_string': 'String',
      'admin_type_number': 'Number',
      'admin_type_bool': 'Boolean',
      'admin_type_json': 'JSON',
      'admin_bad_json': 'Invalid JSON.',
      'admin_nested_fields': 'Expanded object fields',
      'admin_add_nested_field': 'Add nested field',
      'admin_group_identity': 'Identity & metadata',
      'admin_group_timing': 'Window & timing parameters',
      'admin_group_current': 'Current & power parameters',
      'admin_group_radio': 'Radio & payload parameters',
      'admin_group_hardware': 'Crystal & hardware parameters',
      'admin_group_other': 'Other parameters',
      'admin_object_editor_subtitle': '{n} nested fields',
      'admin_saved_local': 'Saved locally. Export JSON to update seed files.',
      'admin_saved_json': 'Saved to JSON files on the server.',
      'admin_save_backend_failed':
          'Backend not reachable, NOT saved to JSON: {error}',
      'admin_reset_domain': 'Reset this tab',
      'admin_export_all': 'Export all JSON',
      'admin_ops_hint':
          'Use Export all JSON after editing, then replace assets/data/chips/ with the exported files.',
      'admin_heat_hint':
          'Visit heat is reserved for future instrumentation. No telemetry is collected in this demo.',
      'chart_hide_sleep_gaps': 'Hide sleep/gaps',
      'chart_timeline_compressed': 'Timeline: compressed view (sleep hidden)',
      'chart_timeline_full': 'Timeline: full period view',
      'chart_hover_hint':
          'Hover over the chart to view phase name, length, and current info',
      'chart_phase': 'Phase',
      'chart_length': 'Length',
      'chart_total_rx_time': 'Total RX time',
      'chart_window_widening_length': 'Window widening Length',
      'chart_radio_rx_length': 'Radio RX Length',
      'chart_current': 'Current',
      'collapse_panel': 'Collapse panel',
      'expand_panel': 'Expand panel',
    },
    'zh': {
      'appTitle': 'BES 功耗',
      'browser_title_user': 'BES 功耗 - 用户界面',
      'browser_title_admin': 'BES 功耗 - 管理员界面',
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
      'kpi_sleep_current': '睡眠电流',
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
      'bt_packet_type_label': 'Packet type',
      'bt_voltage_label': '电压:',
      'bt_rx_payload_label': 'RX Payload:',
      'bt_tx_payload_label': 'TX Payload:',
      'bt_connect_interval_label': '连接间隔:',
      'bt_default_config_label': '默认配置',
      'bt_attempt_label': '尝试次数:',
      'bt_clock_drift_label': '时钟漂移:',
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
      'config_section_device': '设备',
      'config_section_radio': '射频',
      'config_section_timing': '时序',
      'config_section_advanced': '高级',
      'config_section_power': '电源',
      'config_section_case': '场景',
      'config_section_manual': '手动参数',

      // === Earbuds ===
      'eb_title': '耳机功耗对比',
      'eb_tab_scene': '耳机场景',
      'eb_tab_bt': 'BT & BLE',
      'eb_tab_sleep': '睡眠电流',
      'eb_tab_run': 'MCU 运行',
      'eb_tab_cpu_consumption': 'CPU 功耗',
      'eb_tab_tx': 'TX 扫描',
      'eb_tab_rx': 'RX 扫描',
      'eb_tab_pa': '音频 PA',
      'eb_config': '配置',
      'eb_content': '内容',
      'eb_view_mode': '视图模式',
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
      'eb_metric_standby': '待机',
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
      'eb_sweep_view_curve': '曲线',
      'eb_sweep_view_table': '表格',
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
      'eb_summary': '汇总',
      'eb_best': '最优',
      'eb_worst': '最差',
      'eb_avg': '均值',
      'eb_radar_title': '多维雷达图',
      'eb_delta_vs_best': 'Δ vs 最优',
      'eb_baseline': '基线',
      'eb_search_chip': '搜索芯片...',
      'eb_chip_info': '芯片信息',
      'eb_no_data': '无数据',
      'eb_noisepink_detail_title': 'NoisePink 8/15 AAC · 电压与功耗拆分',
      'eb_npd_voltage': '电压 (V)',
      'eb_npd_current': '电流 (mA)',
      'eb_npd_isys': 'Isys',
      'eb_npd_icore': 'Icore',
      'eb_npd_iana': 'Iana',
      'eb_npd_ihppa': 'Ihppa',
      'eb_npd_isys_remain': 'Isys_remain',

      // === Admin Page ===
      'admin_title': '管理员 · 耳机数据编辑',
      'admin_back_home': '返回主页',
      'admin_search_chip': '按 Chip ID 搜索...',
      'admin_add_chip': '新增芯片',
      'admin_duplicate': '复制',
      'admin_delete': '删除',
      'admin_save': '保存',
      'admin_revert': '撤销',
      'admin_reset_all': '全部还原到种子数据',
      'admin_unsaved_changes': '有未保存改动',
      'admin_saved': '已保存（内存中）。',
      'admin_reset_confirm_title': '确认还原全部数据？',
      'admin_reset_confirm_body': '所有芯片记录将还原为源代码（const）中的初始数据，内存中的编辑会丢失。',
      'admin_reset_domain_body': '当前标签的芯片记录将从 JSON 种子文件重新还原，本地保存的编辑会丢失。',
      'admin_sync_excel': '同步 Excel',
      'admin_sync_excel_pick_failed': '未选择文件或读取失败。',
      'admin_sync_excel_parse_failed': '无法解析该文件，请检查格式。',
      'admin_sync_excel_empty': '文件中未找到有效的 NoisePink 数据行。',
      'admin_sync_excel_result_title': '同步完成',
      'admin_sync_excel_result_body': '已同步 {matched} 颗芯片；跳过 {skipped} 颗未匹配。',
      'admin_sync_excel_result_saved': '{matched} 颗芯片已自动写回 JSON 文件，无需逐个点 Save。',
      'admin_sync_excel_result_unsaved':
          '{matched} 颗芯片已在本地暂存，但未写回 JSON（后端不可用）：{error}',
      'admin_sync_excel_matched_title': '已同步（{n}）',
      'admin_sync_excel_skipped_title': '已跳过（{n}）',
      'admin_sync_excel_skipped_hint': '这些 ID 在 Excel 中存在，但内存仓储里没有匹配的芯片，已被忽略。',
      'admin_delete_confirm_title': '确认删除？',
      'admin_delete_confirm_body': '芯片 "{id}" 将从内存仓储中移除，是否继续？',
      'admin_cancel': '取消',
      'admin_confirm': '确定',
      'admin_field_id': 'ID',
      'admin_field_process': '工艺',
      'admin_field_core': 'Core',
      'admin_field_full_ram_kb': 'Full RAM (KB)',
      'admin_field_mass_production': '是否量产',
      'admin_section_basic': '基础信息',
      'admin_section_scene': '耳机场景 (mA)',
      'admin_section_scene_anc_on': '耳机场景 · ANC ON (mA)',
      'admin_section_bt': 'BT & BLE 场景 (mA)',
      'admin_section_sleep': '睡眠电流 (µA / V)',
      'admin_section_mcu_run': 'MCU 运行电流 (mA)',
      'admin_section_tx_sweep': 'TX 扫描 (dBm → mA)',
      'admin_section_rx_vana': 'RX 扫描 · VANA (gain → mA)',
      'admin_section_rx_vsys': 'RX 扫描 · VSYS (gain → mA)',
      'admin_section_pa': '音频 PA (mA)',
      'admin_section_test_config': '场景测试配置',
      'admin_add_row': '新增一行',
      'admin_remove_row': '删除',
      'admin_remove_field_confirm_title': '确认删除字段？',
      'admin_remove_field_confirm_body': '字段 "{name}" 将从该记录中移除，是否继续？',
      'admin_no_chip_selected': '请在左侧选择一个芯片进行编辑。',
      'admin_total_chips': '共 {n} 颗',
      'admin_invalid_id': 'ID 不能为空或与已有 ID 重复。',
      'admin_invalid_id_empty': 'ID 不能为空（也不能保留 "chip_new" 占位值），请填写一个唯一的 ID。',
      'admin_invalid_id_duplicate': 'ID "{id}" 已存在，请改为其它值。',
      'admin_drag_handle': '拖拽排序',
      'admin_reorder_disabled_in_search': '请先清空搜索,才能拖拽排序。',
      'admin_sort_hint': '可拖拽手柄，或使用上移 / 下移；导出 JSON 会把当前顺序写入 index.json。',
      'admin_move_up': '上移',
      'admin_move_down': '下移',
      'admin_export_json': '导出 JSON',
      'admin_export_success':
          '已导出到 {location}，覆盖 assets/data/chips/ 后即为新的种子数据。',
      'admin_export_failed': '导出失败：{error}',
      'admin_login_title': '欢迎登录 BES 管理系统',
      'admin_login_subtitle': '请输入您的管理员凭证以继续 (Demo)。',
      'admin_login_badge': '安全管理员验证',
      'admin_secret': 'Access Key',
      'admin_secret_hint': '请输入管理员 Access Key',
      'admin_login': '登录',
      'admin_login_checking': '验证中...',
      'admin_show_secret': '显示 Access Key',
      'admin_hide_secret': '隐藏 Access Key',
      'admin_logout': '退出',
      'admin_invalid_secret': '密钥不正确。',
      'admin_ble_case': 'BLE CASE 管理',
      'admin_bt_case': 'BT CASE 管理',
      'admin_earbuds': 'Earbuds 管理',
      'admin_wifi': 'Wi-Fi 管理',
      'admin_ops': '运维管理',
      'admin_heat': '访问热度',
      'admin_json_editor': 'JSON 字段',
      'admin_add_field': '新增字段',
      'admin_field_name': '字段名',
      'admin_field_value': '值',
      'admin_field_type': '类型',
      'admin_type_string': '字符串',
      'admin_type_number': '数字',
      'admin_type_bool': '布尔',
      'admin_type_json': 'JSON',
      'admin_bad_json': 'JSON 格式不正确。',
      'admin_nested_fields': '已展开对象字段',
      'admin_add_nested_field': '新增子字段',
      'admin_group_identity': '身份与基础信息',
      'admin_group_timing': '窗口与时间参数',
      'admin_group_current': '电流与功耗参数',
      'admin_group_radio': '射频与负载参数',
      'admin_group_hardware': '晶振与硬件参数',
      'admin_group_other': '其他参数',
      'admin_object_editor_subtitle': '{n} 个嵌套字段',
      'admin_saved_local': '已保存到本地，导出 JSON 后可更新种子文件。',
      'admin_saved_json': '已保存到服务器 JSON 文件。',
      'admin_save_backend_failed': '后端不可达，未保存到 JSON：{error}',
      'admin_reset_domain': '还原当前标签',
      'admin_export_all': '导出全部 JSON',
      'admin_ops_hint': '编辑后使用“导出全部 JSON”，再用导出的文件覆盖 assets/data/chips/。',
      'admin_heat_hint': '访问热度预留给后续埋点；当前 Demo 不采集遥测数据。',
      'chart_hide_sleep_gaps': '隐藏睡眠/空隙',
      'chart_timeline_compressed': '时间轴：压缩视图（睡眠已隐藏）',
      'chart_timeline_full': '时间轴：完整周期视图',
      'chart_hover_hint': '悬浮在图表上可查看阶段名、长度、电流信息',
      'chart_phase': '阶段',
      'chart_length': '长度',
      'chart_total_rx_time': '总 RX 时间',
      'chart_window_widening_length': 'Window widening 长度',
      'chart_radio_rx_length': 'Radio RX 长度',
      'chart_current': '电流',
      'collapse_panel': '收起面板',
      'expand_panel': '展开面板',
    },
  };

  String _t(String key) {
    final code = locale.languageCode;
    return _localizedValues[code]?[key] ?? _localizedValues['en']![key] ?? key;
  }

  String get appTitle => _t('appTitle');
  String get browserTitleUser => _t('browser_title_user');
  String get browserTitleAdmin => _t('browser_title_admin');
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
  String get btPacketTypeLabel => _t('bt_packet_type_label');
  String get btVoltageLabel => _t('bt_voltage_label');
  String get btRxPayloadLabel => _t('bt_rx_payload_label');
  String get btTxPayloadLabel => _t('bt_tx_payload_label');
  String get btConnectIntervalLabel => _t('bt_connect_interval_label');
  String get btDefaultConfigLabel => _t('bt_default_config_label');
  String get btAttemptLabel => _t('bt_attempt_label');
  String get btClockDriftLabel => _t('bt_clock_drift_label');
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
  String get configSectionDevice => _t('config_section_device');
  String get configSectionRadio => _t('config_section_radio');
  String get configSectionTiming => _t('config_section_timing');
  String get configSectionAdvanced => _t('config_section_advanced');
  String get configSectionPower => _t('config_section_power');
  String get configSectionCase => _t('config_section_case');
  String get configSectionManual => _t('config_section_manual');
  String get kpiBatteryLifeEst => _t('kpi_battery_life_est');
  String get kpiPeakCurrent => _t('kpi_peak_current');

  // ===== Earbuds =====
  String get ebTitle => _t('eb_title');
  String get ebTabScene => _t('eb_tab_scene');
  String get ebTabBt => _t('eb_tab_bt');
  String get ebTabSleep => _t('eb_tab_sleep');
  String get ebTabRun => _t('eb_tab_run');
  String get ebTabCpuConsumption => _t('eb_tab_cpu_consumption');
  String get ebTabTx => _t('eb_tab_tx');
  String get ebTabRx => _t('eb_tab_rx');
  String get ebTabPa => _t('eb_tab_pa');
  String get ebConfig => _t('eb_config');
  String get ebContent => _t('eb_content');
  String get ebViewMode => _t('eb_view_mode');
  String get ebFilterMassOnly => _t('eb_filter_mass_only');
  String get ebFilterSortAsc => _t('eb_filter_sort_asc');
  String get ebFilterSortDesc => _t('eb_filter_sort_desc');
  String get ebFilterSortOrig => _t('eb_filter_sort_orig');
  String get ebSelectChipsHint => _t('eb_select_chips_hint');
  String ebSelectedCount(int n) =>
      _t('eb_selected_count').replaceFirst('{n}', '$n');
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
  String get ebMetricStandby => _t('eb_metric_standby');
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
  String get ebSweepViewCurve => _t('eb_sweep_view_curve');
  String get ebSweepViewTable => _t('eb_sweep_view_table');
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
  String get ebSummary => _t('eb_summary');
  String get ebBest => _t('eb_best');
  String get ebWorst => _t('eb_worst');
  String get ebAvg => _t('eb_avg');
  String get ebRadarTitle => _t('eb_radar_title');
  String get ebDeltaVsBest => _t('eb_delta_vs_best');
  String get ebBaseline => _t('eb_baseline');
  String get ebSearchChip => _t('eb_search_chip');
  String get ebChipInfo => _t('eb_chip_info');
  String get ebNoData => _t('eb_no_data');
  String get ebNoisePinkDetailTitle => _t('eb_noisepink_detail_title');
  String get ebNpdVoltage => _t('eb_npd_voltage');
  String get ebNpdCurrent => _t('eb_npd_current');
  String get ebNpdIsys => _t('eb_npd_isys');
  String get ebNpdIcore => _t('eb_npd_icore');
  String get ebNpdIana => _t('eb_npd_iana');
  String get ebNpdIhppa => _t('eb_npd_ihppa');
  String get ebNpdIsysRemain => _t('eb_npd_isys_remain');

  // ===== Admin =====
  String get adminTitle => _t('admin_title');
  String get adminBackHome => _t('admin_back_home');
  String get adminSearchChip => _t('admin_search_chip');
  String get adminAddChip => _t('admin_add_chip');
  String get adminDuplicate => _t('admin_duplicate');
  String get adminDelete => _t('admin_delete');
  String get adminSave => _t('admin_save');
  String get adminRevert => _t('admin_revert');
  String get adminResetAll => _t('admin_reset_all');
  String get adminUnsavedChanges => _t('admin_unsaved_changes');
  String get adminSaved => _t('admin_saved');
  String get adminResetConfirmTitle => _t('admin_reset_confirm_title');
  String get adminResetConfirmBody => _t('admin_reset_confirm_body');
  String get adminResetDomainBody => _t('admin_reset_domain_body');
  String get adminDeleteConfirmTitle => _t('admin_delete_confirm_title');
  String adminDeleteConfirmBody(String id) =>
      _t('admin_delete_confirm_body').replaceFirst('{id}', id);
  String get adminCancel => _t('admin_cancel');
  String get adminConfirm => _t('admin_confirm');
  String get adminFieldId => _t('admin_field_id');
  String get adminFieldProcess => _t('admin_field_process');
  String get adminFieldCore => _t('admin_field_core');
  String get adminFieldFullRamKb => _t('admin_field_full_ram_kb');
  String get adminFieldMassProduction => _t('admin_field_mass_production');
  String get adminSectionBasic => _t('admin_section_basic');
  String get adminSectionScene => _t('admin_section_scene');
  String get adminSectionSceneAncOn => _t('admin_section_scene_anc_on');
  String get adminSectionBt => _t('admin_section_bt');
  String get adminSectionSleep => _t('admin_section_sleep');
  String get adminSectionMcuRun => _t('admin_section_mcu_run');
  String get adminSectionTxSweep => _t('admin_section_tx_sweep');
  String get adminSectionRxVana => _t('admin_section_rx_vana');
  String get adminSectionRxVsys => _t('admin_section_rx_vsys');
  String get adminSectionPa => _t('admin_section_pa');
  String get adminSectionTestConfig => _t('admin_section_test_config');
  String get adminAddRow => _t('admin_add_row');
  String get adminRemoveRow => _t('admin_remove_row');
  String get adminRemoveFieldConfirmTitle =>
      _t('admin_remove_field_confirm_title');
  String adminRemoveFieldConfirmBody(String name) =>
      _t('admin_remove_field_confirm_body').replaceFirst('{name}', name);
  String get adminNoChipSelected => _t('admin_no_chip_selected');
  String adminTotalChips(int n) =>
      _t('admin_total_chips').replaceFirst('{n}', '$n');
  String get adminInvalidId => _t('admin_invalid_id');
  String get adminInvalidIdEmpty => _t('admin_invalid_id_empty');
  String adminInvalidIdDuplicate(String id) =>
      _t('admin_invalid_id_duplicate').replaceFirst('{id}', id);
  String get adminDragHandle => _t('admin_drag_handle');
  String get adminReorderDisabledInSearch =>
      _t('admin_reorder_disabled_in_search');
  String get adminSortHint => _t('admin_sort_hint');
  String get adminMoveUp => _t('admin_move_up');
  String get adminMoveDown => _t('admin_move_down');
  String get adminExportJson => _t('admin_export_json');
  String adminExportSuccess(String location) =>
      _t('admin_export_success').replaceFirst('{location}', location);
  String adminExportFailed(String error) =>
      _t('admin_export_failed').replaceFirst('{error}', error);
  String get adminLoginTitle => _t('admin_login_title');
  String get adminLoginSubtitle => _t('admin_login_subtitle');
  String get adminLoginBadge => _t('admin_login_badge');
  String get adminSecret => _t('admin_secret');
  String get adminSecretHint => _t('admin_secret_hint');
  String get adminLogin => _t('admin_login');
  String get adminLoginChecking => _t('admin_login_checking');
  String get adminShowSecret => _t('admin_show_secret');
  String get adminHideSecret => _t('admin_hide_secret');
  String get adminLogout => _t('admin_logout');
  String get adminInvalidSecret => _t('admin_invalid_secret');
  String get adminBleCase => _t('admin_ble_case');
  String get adminBtCase => _t('admin_bt_case');
  String get adminEarbuds => _t('admin_earbuds');
  String get adminWifi => _t('admin_wifi');
  String get adminOps => _t('admin_ops');
  String get adminHeat => _t('admin_heat');
  String get adminJsonEditor => _t('admin_json_editor');
  String get adminAddField => _t('admin_add_field');
  String get adminFieldName => _t('admin_field_name');
  String get adminFieldValue => _t('admin_field_value');
  String get adminFieldType => _t('admin_field_type');
  String get adminTypeString => _t('admin_type_string');
  String get adminTypeNumber => _t('admin_type_number');
  String get adminTypeBool => _t('admin_type_bool');
  String get adminTypeJson => _t('admin_type_json');
  String get adminBadJson => _t('admin_bad_json');
  String get adminNestedFields => _t('admin_nested_fields');
  String get adminAddNestedField => _t('admin_add_nested_field');
  String get adminGroupIdentity => _t('admin_group_identity');
  String get adminGroupTiming => _t('admin_group_timing');
  String get adminGroupCurrent => _t('admin_group_current');
  String get adminGroupRadio => _t('admin_group_radio');
  String get adminGroupHardware => _t('admin_group_hardware');
  String get adminGroupOther => _t('admin_group_other');
  String adminObjectEditorSubtitle(int n) =>
      _t('admin_object_editor_subtitle').replaceFirst('{n}', '$n');
  String get adminSavedLocal => _t('admin_saved_local');
  String get adminSavedJson => _t('admin_saved_json');
  String adminSaveBackendFailed(String error) =>
      _t('admin_save_backend_failed').replaceFirst('{error}', error);
  String get adminResetDomain => _t('admin_reset_domain');
  String get adminSyncExcel => _t('admin_sync_excel');
  String get adminSyncExcelPickFailed => _t('admin_sync_excel_pick_failed');
  String get adminSyncExcelParseFailed => _t('admin_sync_excel_parse_failed');
  String get adminSyncExcelEmpty => _t('admin_sync_excel_empty');
  String get adminSyncExcelResultTitle => _t('admin_sync_excel_result_title');
  String adminSyncExcelResultBody(int matched, int skipped) =>
      _t('admin_sync_excel_result_body')
          .replaceFirst('{matched}', '$matched')
          .replaceFirst('{skipped}', '$skipped');
  String adminSyncExcelResultSaved(int matched) =>
      _t('admin_sync_excel_result_saved').replaceFirst('{matched}', '$matched');
  String adminSyncExcelResultUnsaved(int matched, String error) =>
      _t('admin_sync_excel_result_unsaved')
          .replaceFirst('{matched}', '$matched')
          .replaceFirst('{error}', error);
  String adminSyncExcelMatchedTitle(int n) =>
      _t('admin_sync_excel_matched_title').replaceFirst('{n}', '$n');
  String adminSyncExcelSkippedTitle(int n) =>
      _t('admin_sync_excel_skipped_title').replaceFirst('{n}', '$n');
  String get adminSyncExcelSkippedHint => _t('admin_sync_excel_skipped_hint');
  String get adminExportAll => _t('admin_export_all');
  String get adminOpsHint => _t('admin_ops_hint');
  String get adminHeatHint => _t('admin_heat_hint');

  String get chartHideSleepGaps => _t('chart_hide_sleep_gaps');
  String get chartTimelineCompressed => _t('chart_timeline_compressed');
  String get chartTimelineFull => _t('chart_timeline_full');
  String get chartHoverHint => _t('chart_hover_hint');
  String get chartPhase => _t('chart_phase');
  String get chartLength => _t('chart_length');
  String get chartTotalRxTime => _t('chart_total_rx_time');
  String get chartWindowWideningLength => _t('chart_window_widening_length');
  String get chartRadioRxLength => _t('chart_radio_rx_length');
  String get chartCurrent => _t('chart_current');
  String get collapsePanel => _t('collapse_panel');
  String get expandPanel => _t('expand_panel');

  static AppLocalizations of(BuildContext context) {
    final instance =
        Localizations.of<AppLocalizations>(context, AppLocalizations);
    if (instance == null) {
      // Fallback: return English
      return AppLocalizations(const Locale('en'));
    }
    return instance;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'zh'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

const LocalizationsDelegate<AppLocalizations> appLocalizationsDelegate =
    _AppLocalizationsDelegate();
