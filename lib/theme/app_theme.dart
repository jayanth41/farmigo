import 'package:flutter/material.dart';

class AppTheme {
  // Updated to match the attached SKYBASE background (deep navy)
  static const Color primaryBlue = Color(0xFF173A46);
  static const Color darkBlue = Color(0xFF0F2C33);

  // Backwards-compatible theme tokens used by older widgets.
  // These provide safe defaults so UI widgets that reference AppTheme.*
  // continue to compile even if they predate the consolidated ThemeData.
  static Color get bookingCardColor => Colors.white;
  static double get bookingCardRadius => 12.0;
  static Color get bookingCardShadowColor => Colors.black12;

  static double get bookingImageWidth => 160.0;
  static double get bookingImageHeight => 120.0;

  static Color get bookingBadgeConfirmedBg => Colors.greenAccent.shade100;
  static Color get bookingBadgeConfirmedFg => Colors.green.shade800;

  static Color get bookingBadgeUpcomingBg => Colors.yellow.shade100;
  static Color get bookingBadgeUpcomingFg => Colors.orange.shade800;

  static Color get bookingBadgeCancelledBg => Colors.red.shade50;
  static Color get bookingBadgeCancelledFg => Colors.red.shade700;

  static Color get bookingDangerBorder => Colors.red.shade300;
  static Color get bookingActionBorder => Colors.grey.shade300;
  static double get bookingButtonRadius => 10.0;

  static ThemeData lightTheme() {
    final colorScheme = const ColorScheme.light().copyWith(
      primary: primaryBlue,
      primaryContainer: darkBlue,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSurface: Colors.black87,
    );

    return ThemeData(
      useMaterial3: false,
      colorScheme: colorScheme,
      brightness: Brightness.light,
      primaryColor: colorScheme.primary,
      scaffoldBackgroundColor: colorScheme.surface,

      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        centerTitle: true,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
      ),

      cardColor: colorScheme.surface,

      iconTheme: IconThemeData(color: colorScheme.primary),

      textTheme: TextTheme(
        bodyLarge: TextStyle(color: colorScheme.onSurface),
  bodyMedium: TextStyle(color: colorScheme.onSurface.withOpacity(0.9)),
  bodySmall: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
  hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  static ThemeData darkTheme() {
    final colorScheme = const ColorScheme.dark().copyWith(
      primary: primaryBlue,
      primaryContainer: darkBlue,
      surface: const Color(0xFF1E1E1E),
      onPrimary: Colors.white,
      onSurface: Colors.white70,
    );

    return ThemeData(
      useMaterial3: false,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      primaryColor: colorScheme.primary,
      scaffoldBackgroundColor: colorScheme.surface,

      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        centerTitle: true,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
      ),

      cardColor: colorScheme.surface,

      iconTheme: IconThemeData(color: colorScheme.primary),

      textTheme: TextTheme(
        bodyLarge: TextStyle(color: colorScheme.onSurface),
  bodyMedium: TextStyle(color: colorScheme.onSurface.withOpacity(0.9)),
  bodySmall: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
  hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
