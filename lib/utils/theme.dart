import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1A73E8);
  static const Color accentColor = Color(0xFF4285F4);
  static const Color backgroundColor = Color(0xFF121212);
  static const Color surfaceColor = Color(0xFF1E1E1E);
  static const Color cardColor = Color(0xFF2D2D2D);

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
        cardColor: cardColor,
        colorScheme: const ColorScheme.dark(
          primary: primaryColor,
          secondary: accentColor,
          surface: surfaceColor,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundColor,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: surfaceColor,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: cardColor,
          selectedColor: primaryColor,
          labelStyle: const TextStyle(color: Colors.white),
          secondaryLabelStyle: const TextStyle(color: Colors.white),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: cardColor,
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.grey[100],
        colorScheme: ColorScheme.light(
          primary: primaryColor,
          secondary: accentColor,
          surface: Colors.grey[50]!,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: Colors.black87),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey[600],
          type: BottomNavigationBarType.fixed,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.grey[200],
          selectedColor: primaryColor,
          labelStyle: const TextStyle(color: Colors.black87),
          secondaryLabelStyle: const TextStyle(color: Colors.white),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      );
}
