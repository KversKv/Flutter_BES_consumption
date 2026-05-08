import 'package:flutter/material.dart';

/// 间距、圆角、阴影 Tokens（4/8pt 网格）
class AppSpacing {
  AppSpacing._();

  // 4pt 网格
  static const double x0 = 0;
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;
  static const double x10 = 40;
  static const double x12 = 48;

  // 页面内容级
  static const EdgeInsets pagePadding =
      EdgeInsets.symmetric(horizontal: x4, vertical: x4);
  static const EdgeInsets sectionGap = EdgeInsets.only(bottom: x6);

  // 圆角
  static const double radiusSm = 6;
  static const double radiusMd = 10;
  static const double radiusLg = 14;
  static const double radiusXl = 20;
}

class AppElevation {
  AppElevation._();

  /// 卡片阴影（深色底上用 alpha 极低的黑影 + 微亮顶描边模拟提亮）
  static List<BoxShadow> card = const [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  /// Hover/Active 时略强阴影
  static List<BoxShadow> cardElevated = const [
    BoxShadow(
      color: Color(0x4D000000),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
}
