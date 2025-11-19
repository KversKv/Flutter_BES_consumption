import 'package:flutter/material.dart';
import '../models/power_event.dart';

/// 鼠标悬浮时显示的当前事件信息栏
class HoverInfoBar extends StatelessWidget {
  final PowerEvent? event;
  const HoverInfoBar({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    if (event == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '悬浮在图表上可查看阶段名、持续时间、电流信息',
          style: textStyle,
        ),
      );
    }

    final durMs = event!.durationUs / 1000.0;
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          Text('阶段: ${event!.label}', style: textStyle),
          Text('持续: ${durMs.toStringAsFixed(3)} ms', style: textStyle),
          Text('电流: ${event!.currentMa.toStringAsFixed(3)} mA', style: textStyle),
        ],
      ),
    );
  }
}

/// 图例面板：列出每个阶段的颜色、名称、持续时间、电流
class EventLegendPanel extends StatelessWidget {
  final List<PowerEvent> events;
  final PowerEvent? hovered;
  final ValueChanged<PowerEvent?>? onHover;

  const EventLegendPanel({super.key, required this.events, required this.hovered, this.onHover});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: events.map((e) {
          final isHovered = hovered == e;
          return MouseRegion(
            onEnter: (_) => onHover?.call(e),
            onExit: (_) => onHover?.call(null),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isHovered ? theme.colorScheme.primary : const Color(0xFFDDDDDD),
                  width: isHovered ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: e.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(e.label, style: theme.textTheme.labelLarge),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
