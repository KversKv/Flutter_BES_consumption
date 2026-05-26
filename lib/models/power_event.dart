import 'package:flutter/material.dart';

class PowerEvent {
  final double startUs;
  final double durationUs;
  final double currentMa;
  final String label;
  final Color color;
  final String? previewLabel;
  final double? totalLengthUs;
  final double? windowWideningLengthUs;
  final double? occupiedLengthUs;

  PowerEvent({
    required this.startUs,
    required this.durationUs,
    required this.currentMa,
    required this.label,
    required this.color,
    this.previewLabel,
    this.totalLengthUs,
    this.windowWideningLengthUs,
    this.occupiedLengthUs,
  });

  double get endUs => startUs + durationUs;

  bool get isSleepOrGap =>
      label.toLowerCase() == 'sleep' || label.toLowerCase() == 'gap';
}
