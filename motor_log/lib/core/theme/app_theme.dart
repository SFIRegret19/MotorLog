import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryPurple = Color(0xFFE8DEF8); 
  static const Color accentPurple = Color(0xFF6750A4);
  static const Color bgWhite = Color(0xFFFAFAFA);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: bgWhite,
    colorScheme: ColorScheme.fromSeed(seedColor: accentPurple),
    appBarTheme: const AppBarTheme(backgroundColor: bgWhite, centerTitle: true),
    
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: primaryPurple, width: 1.5),
      ),
      elevation: 0,
      color: Colors.white,
    ),
  );
}