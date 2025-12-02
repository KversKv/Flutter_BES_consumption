import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../models/power_event.dart';
import 'legend_hover_widgets.dart';

/// ===========================================================================
/// 统一的图表组件 (Unified Chart Widget)
/// 不再依赖具体的 Provider，而是通过参数传入数据，实现复用
/// ===========================================================================

class UnifiedPowerChart extends StatefulWidget {
  final List<PowerEvent> events;
  final double periodUs;
  final double maxCurrent;
  final bool hideLowPowerGaps;
  final ValueChanged<bool> onToggleHideGaps;

  const UnifiedPowerChart({
    super.key,
    required this.events,
    required this.periodUs,
    required this.maxCurrent,
    required this.hideLowPowerGaps,
    required this.onToggleHideGaps,
  });

  @override
  State<UnifiedPowerChart> createState() => _UnifiedPowerChartState();
}

class _UnifiedPowerChartState extends State<UnifiedPowerChart> {
  PowerEvent? hovered;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 顶部选项
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('隐藏睡眠/空隙'),
                Switch(
                  value: widget.hideLowPowerGaps,
                  onChanged: widget.onToggleHideGaps,
                ),
              ],
            ),
            Text(
              widget.hideLowPowerGaps
                  ? '时间轴：压缩视图（睡眠已隐藏）'
                  : '时间轴：完整周期视图',
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 模型图（交互）
        Expanded(
          child: TimelineChartInteractive(
            events: widget.events,
            periodUs: widget.periodUs,
            maxCurrent: math.max(1.0, widget.maxCurrent),
            hideLowPowerGaps: widget.hideLowPowerGaps,
            onHoverEvent: (e) => setState(() => hovered = e),
          ),
        ),
        const SizedBox(height: 8),
        // 图下参数区域：事件色块列表
        EventLegendPanel(
          events: widget.hideLowPowerGaps
              ? widget.events.where((e) => !e.isSleepOrGap).toList()
              : widget.events,
          hovered: hovered,
          onHover: (e) => setState(() => hovered = e),
        ),
      ],
    );
  }
}

// ============ 交互式模型图 (保持原逻辑不变) ============

class TimelineChartInteractive extends StatefulWidget {
  final List<PowerEvent> events;
  final double periodUs;
  final double maxCurrent;
  final bool hideLowPowerGaps;
  final ValueChanged<PowerEvent?>? onHoverEvent;

  const TimelineChartInteractive({
    super.key,
    required this.events,
    required this.periodUs,
    required this.maxCurrent,
    required this.hideLowPowerGaps,
    this.onHoverEvent,
  });

  @override
  State<TimelineChartInteractive> createState() => _TimelineChartInteractiveState();
}

class _TimelineChartInteractiveState extends State<TimelineChartInteractive> {
  List<_EventRect> rects = [];
  PowerEvent? hoveredEvent;
  Offset? pointerLocalPos;

  void _recomputeRects(Size size) {
    rects = _computeEventRects(
      size: size,
      events: widget.events,
      periodUs: widget.periodUs,
      hideLowPowerGaps: widget.hideLowPowerGaps,
      maxCurrent: widget.maxCurrent,
    );
  }

  void _handleHover(PointerHoverEvent e, Size size) {
    if (rects.isEmpty) _recomputeRects(size);
    final pos = e.localPosition;
    pointerLocalPos = pos;
    PowerEvent? hit;
    for (final r in rects) {
      if (r.rect.contains(pos)) {
        hit = r.event;
        break;
      }
    }
    if (hit != hoveredEvent) {
      setState(() => hoveredEvent = hit);
      widget.onHoverEvent?.call(hit);
    } else {
      setState(() {});
    }
  }

  void _handleExit(PointerExitEvent e) {
    pointerLocalPos = null;
    setState(() => hoveredEvent = null);
    widget.onHoverEvent?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, cons) {
      final size = Size(cons.maxWidth, cons.maxHeight);
      _recomputeRects(size);
      return MouseRegion(
        onHover: (ev) => _handleHover(ev, size),
        onExit: _handleExit,
        child: Stack(
          children: [
            CustomPaint(
              painter: _TimelinePainter(
                events: widget.events,
                periodUs: widget.periodUs,
                maxCurrent: widget.maxCurrent,
                hideLowPowerGaps: widget.hideLowPowerGaps,
                hovered: hoveredEvent,
              ),
              size: Size.infinite,
            ),
            if (hoveredEvent != null && pointerLocalPos != null)
              Positioned(
                left: pointerLocalPos!.dx + 8,
                top: math.max(8, pointerLocalPos!.dy - 60),
                child: Material(
                  elevation: 4,
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hoveredEvent!.label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Length: ${hoveredEvent!.durationUs.toStringAsFixed(0)} µs', style: Theme.of(context).textTheme.bodySmall),
                        Text('Current: ${hoveredEvent!.currentMa.toStringAsFixed(3)} mA', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _EventRect {
  final PowerEvent event;
  final Rect rect;
  _EventRect(this.event, this.rect);
}

List<_EventRect> _computeEventRects({
  required Size size,
  required List<PowerEvent> events,
  required double periodUs,
  required bool hideLowPowerGaps,
  required double maxCurrent,
}) {
  final padding = 40.0;
  final w = size.width - padding * 2;
  final h = size.height - padding * 2;
  final origin = Offset(padding, size.height - padding);

  if (w <= 0 || h <= 0 || periodUs <= 0) return [];

  final drawEvents = hideLowPowerGaps
      ? events.where((e) => !e.isSleepOrGap).toList()
      : events.toList();

  if (drawEvents.isEmpty) return [];

  final viewPeriodUs = hideLowPowerGaps
      ? drawEvents.fold(0.0, (sum, e) => sum + e.durationUs)
      : periodUs;

  double tAccUs = 0.0;
  final rects = <_EventRect>[];

  for (final e in drawEvents) {
    final startUs = hideLowPowerGaps ? tAccUs : e.startUs;
    final endUs = startUs + e.durationUs;
    final x1 = origin.dx + (startUs / viewPeriodUs) * w;
    final x2 = origin.dx + (endUs / viewPeriodUs) * w;
    final yTop = origin.dy - (e.currentMa / maxCurrent) * h;

    final r = Rect.fromLTRB(x1, yTop, x2, origin.dy);
    rects.add(_EventRect(e, r));

    if (hideLowPowerGaps) {
      tAccUs += e.durationUs;
    }
  }

  return rects;
}

class _TimelinePainter extends CustomPainter {
  final List<PowerEvent> events;
  final double periodUs;
  final double maxCurrent;
  final bool hideLowPowerGaps;
  final PowerEvent? hovered;

  _TimelinePainter({
    required this.events,
    required this.periodUs,
    required this.maxCurrent,
    required this.hideLowPowerGaps,
    this.hovered,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 40.0;
    final w = size.width - padding * 2;
    final h = size.height - padding * 2;
    if (w <= 0 || h <= 0 || periodUs <= 0) return;

    final drawEvents = hideLowPowerGaps
        ? events.where((e) => !e.isSleepOrGap).toList()
        : events.toList();
    if (drawEvents.isEmpty) return;

    final viewPeriodUs = hideLowPowerGaps
        ? drawEvents.fold(0.0, (sum, e) => sum + e.durationUs)
        : periodUs;

    final origin = Offset(padding, size.height - padding);
    final Paint axis = Paint()
      ..color = const Color(0xFF888888)
      ..strokeWidth = 1.0;

    canvas.drawLine(origin, Offset(padding + w, origin.dy), axis); // X
    canvas.drawLine(origin, Offset(origin.dx, origin.dy - h), axis); // Y

    final gridPaint = Paint()
      ..color = const Color(0x22888888)
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Y 轴刻度
    int yTicks = 4;
    for (int i = 1; i <= yTicks; i++) {
      double yVal = maxCurrent * i / yTicks;
      double y = origin.dy - (yVal / maxCurrent) * h;
      canvas.drawLine(Offset(origin.dx, y), Offset(origin.dx + w, y), gridPaint);
      final span = TextSpan(
        text: yVal.toStringAsFixed(1),
        style: const TextStyle(fontSize: 10, color: Colors.black87),
      );
      textPainter.text = span;
      textPainter.layout();
      textPainter.paint(canvas, Offset(4, y - textPainter.height / 2));
    }

    // X 轴刻度
    final msTotal = viewPeriodUs / 1000.0;
    final xTicks = 6;
    for (int i = 0; i <= xTicks; i++) {
      double frac = i / xTicks;
      double x = origin.dx + w * frac;
      canvas.drawLine(Offset(x, origin.dy), Offset(x, origin.dy - h), gridPaint);
      final span = TextSpan(
        text: (msTotal * frac).toStringAsFixed(1),
        style: const TextStyle(fontSize: 10, color: Colors.black87),
      );
      textPainter.text = span;
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, origin.dy + 4));
    }

    // Y 轴标签
    final yLabel = TextSpan(
      text: 'Current (mA)',
      style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600),
    );
    textPainter.text = yLabel;
    textPainter.layout();
    canvas.save();
    canvas.translate(origin.dx - 28, origin.dy - h / 2 + textPainter.width / 2);
    canvas.rotate(-math.pi / 2);
    textPainter.paint(canvas, Offset(0, -textPainter.height / 2));
    canvas.restore();

    // X 轴标签
    final xLabel = TextSpan(
      text: 'Time (ms)',
      style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600),
    );
    textPainter.text = xLabel;
    textPainter.layout();
    final xCenter = origin.dx + w / 2;
    textPainter.paint(canvas, Offset(xCenter - textPainter.width / 2, origin.dy + 20));

    // 绘制事件块
    double tAccUs = 0.0;
    for (final e in drawEvents) {
      final startUs = hideLowPowerGaps ? tAccUs : e.startUs;
      final endUs = startUs + e.durationUs;
      final x1 = origin.dx + (startUs / viewPeriodUs) * w;
      final x2 = origin.dx + (endUs / viewPeriodUs) * w;
      final yTop = origin.dy - (e.currentMa / maxCurrent) * h;

      final r = RRect.fromRectAndRadius(
        Rect.fromLTRB(x1, yTop, x2, origin.dy),
        const Radius.circular(2),
      );
      final p = Paint()..color = e.color.withOpacity(0.9);
      canvas.drawRRect(r, p);

      if (hideLowPowerGaps) {
        tAccUs += e.durationUs;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter oldDelegate) {
    return oldDelegate.events != events ||
        oldDelegate.periodUs != periodUs ||
        oldDelegate.maxCurrent != maxCurrent ||
        oldDelegate.hideLowPowerGaps != hideLowPowerGaps;
  }
}