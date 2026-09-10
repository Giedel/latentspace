import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF6B4FA0);
  static const Color appBackgroundColor = Color(0xFFFAFAFA);
  static const Color surfaceColor = Colors.white;
  static const Color textPrimary = Color(0xFF1E1E1E);
  static const Color textSecondary = Color(0xFF757575);

  // Was used in money_page.dart #0xFF9575CD

  static ThemeData get lightTheme => _buildTheme(
        primaryColor,
      Colors.white,
      Colors.white,
      );

  static ThemeData get oceanTheme => _buildTheme(
        const Color(0xFF1565C0),
        Colors.white,
        Colors.white,
      );

  static ThemeData get forestTheme => _buildTheme(
        const Color(0xFF2E7D32),
        Colors.white,
        Colors.white,
      );

  static ThemeData get sunsetTheme => _buildTheme(
        const Color(0xFFC4512C),
        Colors.white,
        Colors.white,
      );

  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      dialogTheme: const DialogThemeData(
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  static ThemeData _buildTheme(Color seedColor, Color backgroundColor, Color surfaceColor) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        surface: backgroundColor,
        surfaceContainer: surfaceColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      useMaterial3: true,
      // Universal AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: seedColor),
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Universal Card Theme
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: seedColor),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: seedColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      )
    );
  }

}