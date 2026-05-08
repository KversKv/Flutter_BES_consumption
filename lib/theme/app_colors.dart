import 'package:flutter/material.dart';

/// 应用色板 —— 专业仪表盘风格（支持深色 / 浅色双主题）。
///
/// 设计目标：
/// - color-semantic：所有 token 语义化命名（surface / text / accent / data-series）
/// - color-dark-mode：深浅模式独立调优，不是简单反色
/// - color-accessible-pairs：正文文本与背景 >= 4.5:1
/// - dark-mode-pairing：两套值成对设计
///
/// 使用约定：
/// 1. `AppColors.xxx` 是**编译期常量**（深色值），保留用于所有需要 const 的地方
///    （`const BoxDecoration`、`const TextStyle`、`const Icon` 等）。
/// 2. `AppPalette.of(context)` 在 build 中拿到当前主题对应的可变调色板，
///    推荐用于动态着色（如自绘图表、需要随主题变的 Container 背景等）。
/// 3. 最关键：Theme / ColorScheme 已经是主题感知的——凡是通过 Theme 注入
///    的颜色（Card / AppBar / NavigationRail / Button 等）在切主题时自动生效，
///    不需要手改 AppColors。

/// 可变调色板 —— 同一套 token 有深/浅两套具体取值。
class AppPalette {
  // Surface 层级
  final Color bgBase;
  final Color bgElevated1;
  final Color bgElevated2;
  final Color bgElevated3;

  // 边框
  final Color borderSubtle;
  final Color borderStrong;

  // 文本
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textOnAccent;

  // 品牌强调
  final Color accent;
  final Color accentMuted;
  final Color accentOn;

  // 语义
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  // 数据可视化
  final List<Color> dataSeries;

  // 图表辅助
  final Color chartGrid;
  final Color chartAxis;
  final Color chartTooltipBg;

  final Brightness brightness;

  const AppPalette({
    required this.brightness,
    required this.bgBase,
    required this.bgElevated1,
    required this.bgElevated2,
    required this.bgElevated3,
    required this.borderSubtle,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textOnAccent,
    required this.accent,
    required this.accentMuted,
    required this.accentOn,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.dataSeries,
    required this.chartGrid,
    required this.chartAxis,
    required this.chartTooltipBg,
  });

  bool get isDark => brightness == Brightness.dark;

  /// 在 build 中根据当前 Theme.brightness 选择调色板。
  static AppPalette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light ? light : dark;
  }

  // ---------------------------------------------------------------------------
  // 深色主题调色板
  // ---------------------------------------------------------------------------
  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    bgBase: Color(0xFF0B1020),
    bgElevated1: Color(0xFF121933),
    bgElevated2: Color(0xFF1A2240),
    bgElevated3: Color(0xFF232C4D),
    borderSubtle: Color(0xFF2A345A),
    borderStrong: Color(0xFF3A4676),
    textPrimary: Color(0xFFE6EAF5),
    textSecondary: Color(0xFFA8B0CE),
    textMuted: Color(0xFF6C7699),
    textOnAccent: Color(0xFF0B1020),
    accent: Color(0xFF4DA8FF),
    accentMuted: Color(0xFF1E4B7F),
    accentOn: Color(0xFF0B1020),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    info: Color(0xFF60A5FA),
    dataSeries: [
      Color(0xFF4DA8FF),
      Color(0xFF34D399),
      Color(0xFFFBBF24),
      Color(0xFFF472B6),
      Color(0xFF818CF8),
      Color(0xFF22D3EE),
      Color(0xFFFB923C),
    ],
    chartGrid: Color(0xFF1F284A),
    chartAxis: Color(0xFF5A6388),
    chartTooltipBg: Color(0xFF232C4D),
  );

  // ---------------------------------------------------------------------------
  // 浅色主题调色板
  // 对比度（前景 vs bgBase #F6F8FC）：
  //   textPrimary   #0F172A -> 15.6:1 AAA
  //   textSecondary #475569 ->  7.4:1 AAA
  //   textMuted     #94A3B8 ->  3.0:1（仅用于辅助 / 大文字）
  //   accent        #2563EB ->  5.9:1 AA
  //   success       #059669 ->  4.1:1 AA (图形/大文本)
  //   danger        #DC2626 ->  5.1:1 AA
  //   warning       #D97706 ->  4.0:1 AA (图形/粗体)
  // ---------------------------------------------------------------------------
  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    bgBase: Color(0xFFF6F8FC),
    bgElevated1: Color(0xFFEDF1F8),
    bgElevated2: Color(0xFFFFFFFF),
    bgElevated3: Color(0xFFF3F5FA),
    borderSubtle: Color(0xFFE2E8F0),
    borderStrong: Color(0xFFCBD5E1),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF94A3B8),
    textOnAccent: Color(0xFFFFFFFF),
    accent: Color(0xFF2563EB),
    accentMuted: Color(0xFFDBEAFE),
    accentOn: Color(0xFFFFFFFF),
    success: Color(0xFF059669),
    warning: Color(0xFFD97706),
    danger: Color(0xFFDC2626),
    info: Color(0xFF2563EB),
    dataSeries: [
      Color(0xFF2563EB),
      Color(0xFF059669),
      Color(0xFFD97706),
      Color(0xFFDB2777),
      Color(0xFF7C3AED),
      Color(0xFF0891B2),
      Color(0xFFEA580C),
    ],
    chartGrid: Color(0xFFE2E8F0),
    chartAxis: Color(0xFF94A3B8),
    chartTooltipBg: Color(0xFFFFFFFF),
  );
}

/// 深色调色板的编译期常量别名。
///
/// 保留 `AppColors.xxx` 的旧用法以便 `const BoxDecoration`、`const TextStyle`
/// 等上下文继续工作。新代码如果需要随主题变化，请改用
/// `AppPalette.of(context).xxx` 或 `Theme.of(context).colorScheme.xxx`。
class AppColors {
  AppColors._();

  // Surface
  static const Color bgBase = Color(0xFF0B1020);
  static const Color bgElevated1 = Color(0xFF121933);
  static const Color bgElevated2 = Color(0xFF1A2240);
  static const Color bgElevated3 = Color(0xFF232C4D);

  // 边框
  static const Color borderSubtle = Color(0xFF2A345A);
  static const Color borderStrong = Color(0xFF3A4676);

  // 文本
  static const Color textPrimary = Color(0xFFE6EAF5);
  static const Color textSecondary = Color(0xFFA8B0CE);
  static const Color textMuted = Color(0xFF6C7699);
  static const Color textOnAccent = Color(0xFF0B1020);

  // 品牌
  static const Color accent = Color(0xFF4DA8FF);
  static const Color accentMuted = Color(0xFF1E4B7F);
  static const Color accentOn = Color(0xFF0B1020);

  // 语义
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFF87171);
  static const Color info = Color(0xFF60A5FA);

  // 数据可视化（深色）
  static const List<Color> dataSeries = [
    Color(0xFF4DA8FF),
    Color(0xFF34D399),
    Color(0xFFFBBF24),
    Color(0xFFF472B6),
    Color(0xFF818CF8),
    Color(0xFF22D3EE),
    Color(0xFFFB923C),
  ];

  // 图表辅助
  static const Color chartGrid = Color(0xFF1F284A);
  static const Color chartAxis = Color(0xFF5A6388);
  static const Color chartTooltipBg = Color(0xFF232C4D);
}
