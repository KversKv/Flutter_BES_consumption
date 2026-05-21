import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// 应用主题入口 —— 提供深色 / 浅色双主题。
///
/// 设计原则（参考 ui-ux-pro-max）：
/// - color-semantic：统一 ColorScheme 语义色 token
/// - text-styles-system：基于 Material 3 type roles 的层级排版
/// - elevation-consistent：统一卡片 / 导航 elevation 规格
/// - dark-mode-pairing：深 / 浅配对设计，对比度独立验证
class AppTheme {
  AppTheme._();

  /// 深色主题。
  static ThemeData buildDark() => _build(AppPalette.dark);

  /// 浅色主题。
  static ThemeData buildLight() => _build(AppPalette.light);

  /// 根据指定 brightness 构建 ThemeData。
  static ThemeData buildFor(Brightness b) =>
      b == Brightness.light ? buildLight() : buildDark();

  /// 基于一个调色板生成完整 ThemeData。深浅共享结构，仅注入不同颜色。
  static ThemeData _build(AppPalette p) {
    final colorScheme = ColorScheme(
      brightness: p.brightness,
      primary: p.accent,
      onPrimary: p.accentOn,
      primaryContainer: p.accentMuted,
      onPrimaryContainer: p.isDark ? p.textPrimary : p.accent,
      secondary: p.info,
      onSecondary: p.textOnAccent,
      secondaryContainer: p.accentMuted,
      onSecondaryContainer: p.isDark ? p.textPrimary : p.accent,
      surface: p.bgElevated2,
      onSurface: p.textPrimary,
      surfaceContainerLowest: p.bgBase,
      surfaceContainerLow: p.bgElevated1,
      surfaceContainer: p.bgElevated2,
      surfaceContainerHigh: p.bgElevated3,
      surfaceContainerHighest: p.bgElevated3,
      onSurfaceVariant: p.textSecondary,
      outline: p.borderSubtle,
      outlineVariant: p.borderStrong,
      error: p.danger,
      onError: p.textOnAccent,
      shadow: p.isDark ? Colors.black : const Color(0xFF0F172A),
      scrim: p.isDark ? Colors.black : const Color(0xFF0F172A),
    );

    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(
      const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.2),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.2),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.3),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.5),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.2),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.3),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.4),
      ),
    );

    final baseText = baseTextTheme.apply(
      bodyColor: p.textPrimary,
      displayColor: p.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: p.bgBase,
      canvasColor: p.bgBase,
      dividerColor: p.borderSubtle,
      textTheme: baseText,

      cardTheme: CardThemeData(
        color: p.bgElevated2,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: p.borderSubtle),
        ),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: p.bgElevated1,
        selectedIconTheme: IconThemeData(color: p.accent, size: 24),
        unselectedIconTheme: IconThemeData(color: p.textSecondary, size: 22),
        selectedLabelTextStyle: baseText.labelLarge?.copyWith(
          color: p.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: baseText.labelLarge?.copyWith(
          color: p.textSecondary,
        ),
        indicatorColor: p.accentMuted,
        useIndicator: true,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: p.bgElevated1,
        foregroundColor: p.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: p.textPrimary,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.accentOn,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x4, vertical: AppSpacing.x3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: baseText.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
          side: BorderSide(color: p.borderStrong),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x4, vertical: AppSpacing.x3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: p.accent),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return p.accent;
          return p.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return p.accentMuted;
          return p.bgElevated3;
        }),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: p.accent,
        inactiveTrackColor: p.borderStrong,
        thumbColor: p.accent,
        overlayColor: p.accent.withValues(alpha: 0.2),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: p.chartTooltipBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: p.borderStrong),
        ),
        textStyle: TextStyle(color: p.textPrimary, fontSize: 12),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.bgElevated1,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x3, vertical: AppSpacing.x3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: p.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: p.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: p.accent, width: 1.5),
        ),
        labelStyle: TextStyle(color: p.textSecondary),
        hintStyle: TextStyle(color: p.textMuted),
      ),

      dividerTheme: DividerThemeData(
        color: p.borderSubtle,
        thickness: 1,
        space: 1,
      ),

      iconTheme: IconThemeData(color: p.textSecondary, size: 22),
    );
  }
}
