import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color primary = Colors.green;
  static const Color primaryLight = Color(0xFFE8F5E9);
  static const Color error = Colors.red;
  static const Color textSecondary = Colors.grey;

  static ThemeData get light => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
          ),
        ),
        cardTheme: const CardTheme(
          elevation: 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12))),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
      );
}
