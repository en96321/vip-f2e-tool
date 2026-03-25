import 'package:flutter/material.dart';

/// App-wide theme configuration - One UI style
class AppTheme {
  // One UI inspired color palette
  static const Color primaryBackground = Color(0xFFF7F7F7);
  static const Color cardBackground = Colors.white;
  static const Color accentBlue = Color(0xFF0381FE);  // One UI Blue
  static const Color accentPurple = Color(0xFF7B61FF);
  static const Color accentOrange = Color(0xFFFF7043);
  static const Color accentGreen = Color(0xFF00C853);
  static const Color accentRed = Color(0xFFFF5252);
  
  // Text colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textOnPrimary = Colors.white;

  /// One UI inspired light theme
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: accentBlue,
          secondary: accentBlue,
          surface: cardBackground,
          error: accentRed,
          onPrimary: textOnPrimary,
          onSurface: textPrimary,
          onSecondary: textOnPrimary,
        ),
        scaffoldBackgroundColor: primaryBackground,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          foregroundColor: textPrimary,
          iconTheme: const IconThemeData(color: textPrimary),
          titleTextStyle: const TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          color: cardBackground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF0F0F0),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accentBlue, width: 2),
          ),
          hintStyle: const TextStyle(color: textSecondary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: accentBlue,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: const BorderSide(color: accentBlue, width: 1.5),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: accentBlue,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFF0F0F0),
          labelStyle: const TextStyle(
            color: textPrimary,
            fontSize: 13,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF323232),
          contentTextStyle: const TextStyle(color: Colors.white),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE0E0E0),
          thickness: 1,
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          subtitleTextStyle: TextStyle(
            color: textSecondary,
            fontSize: 14,
          ),
        ),
        iconTheme: const IconThemeData(
          color: textPrimary,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
          titleSmall: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: textPrimary),
          bodyMedium: TextStyle(color: textPrimary),
          bodySmall: TextStyle(color: textSecondary),
          labelLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
          labelMedium: TextStyle(color: textSecondary),
          labelSmall: TextStyle(color: textSecondary),
        ),
      );
}
