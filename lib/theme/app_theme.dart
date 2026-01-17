import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // Map a subset of the provided CSS variables to concrete Flutter colors.
  // Many CSS values use oklch() which we approximate with hex colors here.

  static const Color primary = Color(0xFF030213); // --primary
  static const Color primaryForeground = Color(0xFFFFFFFF); // --primary-foreground
  static const Color secondary = Color(0xFF66BB6A); // green-ish accent
  static const Color background = Color(0xFFFFFFFF); // --background
  static const Color foreground = Color(0xFF262626); // neutral foreground
  static const Color card = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFFECECF0);
  static const Color border = Color.fromRGBO(0, 0, 0, 0.08);
  static const Color inputBackground = Color(0xFFF3F3F5);

  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.light(
      primary: primary,
      onPrimary: primaryForeground,
      secondary: secondary,
      background: background,
      surface: card,
      onSurface: foreground,
    );

    return ThemeData(
      colorScheme: colorScheme,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      canvasColor: card,
      appBarTheme: const AppBarTheme(
  backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
  selectedColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        brightness: Brightness.light,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: border)),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: foreground),
        bodyMedium: TextStyle(fontSize: 14, color: foreground),
        // Booking specific styles
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: foreground),
        labelMedium: TextStyle(fontSize: 12, color: Color(0xFF6B6B6B)),
        bodySmall: TextStyle(fontSize: 13, color: Color(0xFF4B4B4B)),
      ),
    );
  }

  static ThemeData darkTheme() {
    final colorScheme = ColorScheme.dark(
      primary: Color(0xFF030213),
      onPrimary: Colors.white,
      secondary: Color(0xFF66BB6A),
      background: Color(0xFF121212),
      surface: Color(0xFF1E1E1E),
      onSurface: Colors.white,
    );

    return ThemeData(
      colorScheme: colorScheme,
      primaryColor: colorScheme.primary,
      scaffoldBackgroundColor: colorScheme.background,
      canvasColor: colorScheme.surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // Booking card tokens
  static const double bookingCardRadius = 20.0;
  static const Color bookingCardColor = Color(0xFFFFFFFF);
  static const Color bookingCardShadowColor = Color.fromRGBO(3, 2, 19, 0.06);
  static const double bookingImageWidth = 240.0;
  static const double bookingImageHeight = 180.0;

  // Booking badge colors
  static const Color bookingBadgeConfirmedBg = Color(0xFFE8F5E9);
  static const Color bookingBadgeConfirmedFg = Color(0xFF2E7D32);
  static const Color bookingBadgeUpcomingBg = Color(0xFFE3F2FD);
  static const Color bookingBadgeUpcomingFg = Color(0xFF1565C0);
  static const Color bookingBadgeCancelledBg = Color(0xFFFFEBEE);
  static const Color bookingBadgeCancelledFg = Color(0xFFC62828);

  // Buttons
  static const double bookingButtonRadius = 10.0;
  static const Color bookingActionBorder = Color(0xFFE6E6E6);
  static const Color bookingDangerBorder = Color(0xFFF8D7DA);

}
