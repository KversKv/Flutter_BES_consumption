String formatDurationUsAuto(double durationUs) {
  if (durationUs.abs() >= 1000000.0) {
    return '${_formatNumber(durationUs / 1000000.0, 3)} s';
  }
  if (durationUs.abs() >= 1000.0) {
    return '${_formatNumber(durationUs / 1000.0, 3)} ms';
  }
  return '${durationUs.toStringAsFixed(0)} us';
}

String _formatNumber(double value, int decimals) {
  var text = value.toStringAsFixed(decimals);
  if (!text.contains('.')) return text;
  text = text.replaceFirst(RegExp(r'0+$'), '');
  return text.replaceFirst(RegExp(r'\.$'), '');
}
