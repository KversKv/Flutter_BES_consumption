import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../models/power_event.dart';
import '../theme/app_colors.dart';
import 'legend_hover_widgets.dart';

/// ===========================================================================
/// 统一的图表组件 (Unified Chart Widget)
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

        Expanded(
          child: RepaintBoundary(
            child: TimelineChartInteractive(
              events: widget.events,
              periodUs: widget.periodUs,
              maxCurrent: math.max(1.0, widget.maxCurrent),
              hideLowPowerGaps: widget.hideLowPowerGaps,
              onHoverEvent: (e) => setState(() => hovered = e),
            ),
          ),
        ),

        const SizedBox(height: 8),
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

// ===========================================================================
//   Interactive Chart
// ===========================================================================

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
  State<TimelineChartInteractive> createState() =>
      _TimelineChartInteractiveState();
}

class _TimelineChartInteractiveState extends State<TimelineChartInteractive> {
  List<_EventRect> _rects = [];
  Size _lastSize = Size.zero;
  PowerEvent? hoveredEvent;
  Offset? pointerLocalPos;

  void _recomputeRects(Size size) {
    if (size == _lastSize &&
        _rects.isNotEmpty) {
      return;
    }
    _lastSize = size;
    _rects = _computeEventRects(
      size: size,
      events: widget.events,
      periodUs: widget.periodUs,
      hideLowPowerGaps: widget.hideLowPowerGaps,
      maxCurrent: widget.maxCurrent,
    );
  }

  void _forceRecomputeRects(Size size) {
    _lastSize = size;
    _rects = _computeEventRects(
      size: size,
      events: widget.events,
      periodUs: widget.periodUs,
      hideLowPowerGaps: widget.hideLowPowerGaps,
      maxCurrent: widget.maxCurrent,
    );
  }

  @override
  void didUpdateWidget(covariant TimelineChartInteractive oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events != widget.events ||
        oldWidget.periodUs != widget.periodUs ||
        oldWidget.maxCurrent != widget.maxCurrent ||
        oldWidget.hideLowPowerGaps != widget.hideLowPowerGaps) {
      _rects = [];
    }
  }

  void _handleHover(PointerHoverEvent e, Size size) {
    if (_rects.isEmpty) _forceRecomputeRects(size);
    final pos = e.localPosition;
    pointerLocalPos = pos;
    PowerEvent? hit;
    for (final r in _rects) {
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
                palette: AppPalette.of(context),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hoveredEvent!.label,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Length: ${hoveredEvent!.durationUs.toStringAsFixed(0)} µs',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Current: ${hoveredEvent!.currentMa.toStringAsFixed(3)} mA',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
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
  const padding = 40.0;
  final w = size.width - padding * 2;
  final h = size.height - padding * 2;
  final origin = Offset(padding, size.height - padding);

  if (w <= 0 || h <= 0 || periodUs <= 0) return [];

  final drawEvents =
      hideLowPowerGaps ? events.where((e) => !e.isSleepOrGap).toList() : events;

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
    
    // 对Sleep状态进行高度放大，放大5倍
    final displayCurrent = e.isSleepOrGap ? e.currentMa * 5.0 : e.currentMa;
    final yTop = origin.dy - (displayCurrent / maxCurrent) * h;

    final r = Rect.fromLTRB(x1, yTop, x2, origin.dy);
    rects.add(_EventRect(e, r));

    if (hideLowPowerGaps) tAccUs += e.durationUs;
  }

  return rects;
}

// ===========================================================================
//   Painter
// ===========================================================================

class _TimelinePainter extends CustomPainter {
  final List<PowerEvent> events;
  final double periodUs;
  final double maxCurrent;
  final bool hideLowPowerGaps;
  final PowerEvent? hovered;
  final AppPalette palette;

  _TimelinePainter({
    required this.events,
    required this.periodUs,
    required this.maxCurrent,
    required this.hideLowPowerGaps,
    required this.palette,
    this.hovered,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ignore: prefer_const_declarations
    final padding = 40.0;
    final w = size.width - padding * 2;
    final h = size.height - padding * 2;
    if (w <= 0 || h <= 0 || periodUs <= 0) return;

    final drawEvents =
        hideLowPowerGaps ? events.where((e) => !e.isSleepOrGap).toList() : events;
    if (drawEvents.isEmpty) return;

    final viewPeriodUs = hideLowPowerGaps
        ? drawEvents.fold(0.0, (sum, e) => sum + e.durationUs)
        : periodUs;

    final origin = Offset(padding, size.height - padding);
    final Paint axis = Paint()
      ..color = palette.chartAxis
      ..strokeWidth = 1.0;

    canvas.drawLine(origin, Offset(padding + w, origin.dy), axis);
    canvas.drawLine(origin, Offset(origin.dx, origin.dy - h), axis);

    final gridPaint = Paint()
      ..color = palette.chartGrid
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // -------------------------------
    // 修复后的 Y 轴刻度与标题布局
    // -------------------------------
    int yTicks = 4;
    for (int i = 1; i <= yTicks; i++) {
      double yVal = maxCurrent * i / yTicks;
      double y = origin.dy - (yVal / maxCurrent) * h;

      canvas.drawLine(
          Offset(origin.dx, y), Offset(origin.dx + w, y), gridPaint);

      textPainter.text = TextSpan(
        text: yVal.toStringAsFixed(1),
        style: TextStyle(
          fontSize: 10,
          color: palette.textSecondary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(12, y - textPainter.height / 2));
    }

    // Y label ———— 往左移以避免重叠
    textPainter.text = TextSpan(
      text: 'Current (mA)',
      style: TextStyle(
        fontSize: 12,
        color: palette.textPrimary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
    textPainter.layout();
    canvas.save();
    canvas.translate(origin.dx - 40, origin.dy - h / 2 + textPainter.width / 2);
    canvas.rotate(-math.pi / 2);
    textPainter.paint(canvas, Offset(0, -textPainter.height / 2));
    canvas.restore();

    // X ticks
    final msTotal = viewPeriodUs / 1000.0;
    const xTicks = 6;
    for (int i = 0; i <= xTicks; i++) {
      double frac = i / xTicks;
      double x = origin.dx + w * frac;

      canvas.drawLine(
          Offset(x, origin.dy), Offset(x, origin.dy - h), gridPaint);

      textPainter.text = TextSpan(
        text: (msTotal * frac).toStringAsFixed(1),
        style: TextStyle(
          fontSize: 10,
          color: palette.textSecondary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, origin.dy + 4));
    }

    // X label
    textPainter.text = TextSpan(
      text: 'Time (ms)',
      style: TextStyle(
        fontSize: 12,
        color: palette.textPrimary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
    textPainter.layout();
    textPainter.paint(
        canvas, Offset(origin.dx + w / 2 - textPainter.width / 2, origin.dy + 20));

    // Draw events
    double tAccUs = 0.0;
    for (final e in drawEvents) {
      final startUs = hideLowPowerGaps ? tAccUs : e.startUs;
      final endUs = startUs + e.durationUs;
      final x1 = origin.dx + (startUs / viewPeriodUs) * w;
      final x2 = origin.dx + (endUs / viewPeriodUs) * w;
      
      // 对Sleep状态进行高度放大，放大5倍
      final displayCurrent = e.isSleepOrGap ? e.currentMa * 5.0 : e.currentMa;
      final yTop = origin.dy - (displayCurrent / maxCurrent) * h;

      final r = RRect.fromRectAndRadius(
        Rect.fromLTRB(x1, yTop, x2, origin.dy),
        const Radius.circular(2),
      );
      final p = Paint()..color = e.color.withValues(alpha: 0.9);
      canvas.drawRRect(r, p);

      if (hideLowPowerGaps) tAccUs += e.durationUs;
    }
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter oldDelegate) {
    return oldDelegate.events != events ||
        oldDelegate.periodUs != periodUs ||
        oldDelegate.maxCurrent != maxCurrent ||
        oldDelegate.hideLowPowerGaps != hideLowPowerGaps ||
        oldDelegate.hovered != hovered ||
        oldDelegate.palette.brightness != palette.brightness;
  }
}