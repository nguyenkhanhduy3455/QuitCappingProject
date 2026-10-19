import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../storage/token_storage.dart';

enum AppLanguage {
  vi('vi', 'Tiếng Việt', '🇻🇳'),
  en('en', 'English', '🇬🇧');

  final String code;
  final String label;
  final String flag;

  const AppLanguage(this.code, this.label, this.flag);

  static AppLanguage fromCode(String? code) {
    if (code == 'en') return AppLanguage.en;
    return AppLanguage.vi; // Default to Vietnamese
  }
}

final appLanguageProvider = StateNotifierProvider<AppLanguageNotifier, AppLanguage>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppLanguageNotifier(prefs);
});

class AppLanguageNotifier extends StateNotifier<AppLanguage> {
  final SharedPreferences _prefs;
  static const String _prefKey = 'quitcapping_app_language';

  AppLanguageNotifier(this._prefs)
      : super(AppLanguage.fromCode(_prefs.getString(_prefKey))) {
    // If not set yet, store default
    if (!_prefs.containsKey(_prefKey)) {
      _prefs.setString(_prefKey, state.code);
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    await _prefs.setString(_prefKey, language.code);
  }

  Future<void> toggleLanguage() async {
    final next = state == AppLanguage.vi ? AppLanguage.en : AppLanguage.vi;
    await setLanguage(next);
  }
}
