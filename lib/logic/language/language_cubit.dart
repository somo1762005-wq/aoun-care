import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageCubit extends Cubit<String> {
  static const String _key = 'language_preference';

  LanguageCubit() : super('ar') {
    _loadLanguage();
  }

  void _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    emit(prefs.getString(_key) ?? 'ar');
  }

  void toggleLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final newLang = state == 'ar' ? 'en' : 'ar';
    await prefs.setString(_key, newLang);
    emit(newLang);
  }

  void setLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, langCode);
    emit(langCode);
  }
}
