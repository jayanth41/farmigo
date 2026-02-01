import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryGreen = Color(0xFF43A047);
  static const Color darkGreen = Color(0xFF1B5E20);

  static ThemeData lightTheme() {
    final colorScheme = const ColorScheme.light().copyWith(
      primary: primaryGreen,
      primaryContainer: darkGreen,
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
      primary: primaryGreen,
      primaryContainer: darkGreen,
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
