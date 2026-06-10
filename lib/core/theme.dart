import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF00A3FF); // Electric Sky Blue
  static const Color darkNavy = Color(0xFF0F172A); // Dark Slate Navy
  static const Color cardDark = Color(0xFF1E293B); // Dark Slate Navy for containers/cards

  // Light Mode Colors
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color cardLight = Colors.white;
  static const Color inputBgLight = Color(0xFFF1F5F9);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);

  // Dark Mode Colors
  static const Color bgDark = Color(0xFF090D16);
  static const Color inputBgDark = Color(0xFF334155);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  static const Color success = Color(0xFF10B981); // Emerald green
  static const Color warning = Color(0xFFF59E0B); // Amber warning
  static const Color error = Color(0xFFEF4444); // Red error
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'SFPro', // 👈 تفعيل خط الآيفون كخط أساسي للوضع المضيء
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.bgLight,
      cardColor: AppColors.cardLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.darkNavy,
        surface: AppColors.bgLight,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      // تعديل تنسيق النصوص ليعتمد على خط الآيفون مع الحفاظ على ألوان كودك الأصلية
      textTheme: const TextTheme().apply(
        fontFamily: 'SFPro',
        bodyColor: AppColors.textPrimaryLight,
        displayColor: AppColors.textPrimaryLight,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBgLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkNavy,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'SFPro'),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'SFPro', // 👈 تفعيل خط الآيفون كخط أساسي للوضع المظلم
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.bgDark,
      cardColor: AppColors.cardDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primary,
        surface: AppColors.bgDark,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      // تعديل تنسيق النصوص للوضع المظلم
      textTheme: const TextTheme().apply(
        fontFamily: 'SFPro',
        bodyColor: AppColors.textPrimaryDark,
        displayColor: AppColors.textPrimaryDark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBgDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'SFPro'),
        ),
      ),
    );
  }
}