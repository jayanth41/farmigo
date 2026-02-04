import 'package:flutter/material.dart';

class AppColors {
  // Brand colors (OK to keep fixed)
  static const primary = Color(0xFF3FA34D);
  static const primaryDark = Color(0xFF2F8F3A);

  static const greenDark = Color(0xFF059669);
  static const tealDark = Color(0xFF0E7490);

  // ❌ REMOVE fixed white/bg/text usage in UI
  // static const bgSoft = Color(0xFFF2FBF4);
  // static const white = Color(0xFFFFFFFF);
  // static const textMain = Color(0xFF374151);
  // static const textMuted = Color(0xFF6B7280);
  // static const border = Color(0xFFE5E7EB);
  // static const chipBg = Color(0xFFEAF6ED);

  static const ratingBg = Color(0xFF22C55E);
  static const iconGrey = Color(0xFF6B7280);
  static const bgSoft = Color(0xFFF2FBF4);

  /// ✅ THEME BASED COLORS (USE THESE IN UI)
  static Color background(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  static Color surface(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  static Color textMain(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color textMuted(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

  static Color border(BuildContext context) =>
      Theme.of(context).dividerColor;

  static Color chipBg(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHighest;
}
