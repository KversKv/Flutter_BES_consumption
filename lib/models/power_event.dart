import 'package:flutter/material.dart';

class PowerEvent {
  final double startUs;
  final double durationUs;
  final double currentMa;
  final String label;
  final Color color;

  PowerEvent({
    required this.startUs,
    required this.durationUs,
    required this.currentMa,
    required this.label,
    required this.color,
  });

  double get endUs => startUs + durationUs;

  bool get isSleepOrGap =>
    label.toLowerCase() == 'sleep' ||
    label.toLowerCase() == 'gap';
}
