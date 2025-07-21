import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class ThemeHelper {
  // Get theme-aware colors
  static Color getOnSurfaceColor(BuildContext context, [double opacity = 1.0]) {
    return Theme
        .of(context)
        .brightness == Brightness.dark
        ? Colors.white.withOpacity(opacity)
        : AppColors.textPrimary.withOpacity(opacity);
  }

  static Color getSecondaryTextColor(BuildContext context) {
    return Theme
        .of(context)
        .brightness == Brightness.dark
        ? AppColors.textSecondary
        : AppColors.textSecondary;
  }

  static Color getSurfaceColor(BuildContext context) {
    return Theme
        .of(context)
        .brightness == Brightness.dark
        ? AppColors.surfaceDark
        : AppColors.surface;
  }

  static Color getBackgroundColor(BuildContext context) {
    return Theme
        .of(context)
        .brightness == Brightness.dark
        ? AppColors.backgroundDark
        : AppColors.background;
  }

  static Color getBorderColor(BuildContext context) {
    return Theme
        .of(context)
        .brightness == Brightness.dark
        ? AppColors.borderDark
        : AppColors.border;
  }

  static Color getShadowColor(BuildContext context) {
    return Theme
        .of(context)
        .brightness == Brightness.dark
        ? AppColors.shadowDark
        : AppColors.shadow;
  }

  // Get theme-aware icons
  static IconData getThemeIcon(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.system:
        return Icons.brightness_auto;
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
    }
  }

  static IconData getContrastIcon(BuildContext context, IconData lightIcon,
      IconData darkIcon) {
    return Theme
        .of(context)
        .brightness == Brightness.dark ? darkIcon : lightIcon;
  }

  // Theme-aware gradients
  static LinearGradient getCardGradient(BuildContext context, Color baseColor) {
    return Theme
        .of(context)
        .brightness == Brightness.dark
        ? LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor.withOpacity(0.8),
        baseColor.withOpacity(0.6),
      ],
    )
        : LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor,
        baseColor.withOpacity(0.8),
      ],
    );
  }

  // Theme-aware text styles
  static TextStyle getTitleTextStyle(BuildContext context, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;
    return TextStyle(
      fontSize: fontSize ?? 16,
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color ?? (isDark ? AppColors.textDark : AppColors.textPrimary),
    );
  }

  static TextStyle getBodyTextStyle(BuildContext context, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double opacity = 1.0,
  }) {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;
    return TextStyle(
      fontSize: fontSize ?? 14,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color ?? (isDark
          ? AppColors.textDark.withOpacity(opacity)
          : AppColors.textPrimary.withOpacity(opacity)),
    );
  }

  static TextStyle getSecondaryTextStyle(BuildContext context, {
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    return TextStyle(
      fontSize: fontSize ?? 12,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: AppColors.textSecondary,
    );
  }

  // Theme-aware decorations
  static BoxDecoration getCardDecoration(BuildContext context, {
    Color? color,
    double borderRadius = 16,
    bool hasShadow = true,
  }) {
    return BoxDecoration(
      color: color ?? getSurfaceColor(context),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: getBorderColor(context).withOpacity(0.2),
      ),
      boxShadow: hasShadow ? [
        BoxShadow(
          color: getShadowColor(context),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ] : null,
    );
  }

  static BoxDecoration getInputDecoration(BuildContext context, {
    double borderRadius = 12,
  }) {
    return BoxDecoration(
      color: getSurfaceColor(context),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: getBorderColor(context),
      ),
    );
  }

  // Animation curves and durations
  static const Duration themeTransitionDuration = Duration(milliseconds: 200);
  static const Curve themeTransitionCurve = Curves.easeInOut;
}