import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  static const String _key = 'theme_preference';

  ThemeCubit() : super(ThemeMode.light) {
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_key) ?? false;
    emit(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  void toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (state == ThemeMode.light) {
      await prefs.setBool(_key, true);
      emit(ThemeMode.dark);
    } else {
      await prefs.setBool(_key, false);
      emit(ThemeMode.light);
    }
  }
}
