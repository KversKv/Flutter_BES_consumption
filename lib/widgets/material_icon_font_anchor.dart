import 'package:flutter/material.dart';

class MaterialIconFontAnchor extends StatelessWidget {
  const MaterialIconFontAnchor({super.key, required this.child});

  final Widget child;

  static const List<IconData> _icons = [
    Icons.account_tree_outlined,
    Icons.add,
    Icons.admin_panel_settings_outlined,
    Icons.auto_graph_rounded,
    Icons.battery_full,
    Icons.bedtime,
    Icons.bluetooth,
    Icons.bolt,
    Icons.brightness_auto,
    Icons.check_rounded,
    Icons.checklist_rounded,
    Icons.chevron_left,
    Icons.chevron_right,
    Icons.clear_all_rounded,
    Icons.compare_arrows,
    Icons.dark_mode,
    Icons.dashboard_outlined,
    Icons.data_object_outlined,
    Icons.delete_outline,
    Icons.done_all_rounded,
    Icons.download_rounded,
    Icons.drag_indicator,
    Icons.earbuds_outlined,
    Icons.edit_note,
    Icons.edit_outlined,
    Icons.error_outline,
    Icons.file_download_outlined,
    Icons.filter_alt_outlined,
    Icons.filter_list_outlined,
    Icons.headphones,
    Icons.headphones_outlined,
    Icons.headphones_rounded,
    Icons.home_outlined,
    Icons.info_outline,
    Icons.insights_rounded,
    Icons.key_outlined,
    Icons.keyboard_arrow_down,
    Icons.keyboard_arrow_right,
    Icons.keyboard_arrow_up,
    Icons.label_outline,
    Icons.light_mode,
    Icons.local_fire_department_outlined,
    Icons.lock_open_outlined,
    Icons.logout,
    Icons.memory_outlined,
    Icons.memory_rounded,
    Icons.more_horiz,
    Icons.power_rounded,
    Icons.radar_rounded,
    Icons.save_outlined,
    Icons.search,
    Icons.settings_outlined,
    Icons.schema_outlined,
    Icons.show_chart,
    Icons.show_chart_rounded,
    Icons.signal_cellular_alt,
    Icons.sort_rounded,
    Icons.stacked_bar_chart_rounded,
    Icons.table_chart_rounded,
    Icons.table_rows_rounded,
    Icons.tag,
    Icons.text_fields_outlined,
    Icons.timelapse,
    Icons.toggle_on_outlined,
    Icons.tune_outlined,
    Icons.tune_rounded,
    Icons.upload_rounded,
    Icons.view_agenda_outlined,
    Icons.wifi,
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned(
          left: -1,
          top: -1,
          width: 1,
          height: 1,
          child: ExcludeSemantics(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0,
                child: Wrap(
                  children: [
                    for (final icon in _icons) Icon(icon, size: 1),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
