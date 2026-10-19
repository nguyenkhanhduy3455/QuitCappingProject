import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../storage/token_storage.dart';
import '../constants/app_colors.dart';

enum AppThemeSetting {
  dark('dark', 'Tối', '🌙'),
  light('light', 'Sáng', '☀️');

  final String code;
  final String label;
  final String icon;

  const AppThemeSetting(this.code, this.label, this.icon);

  static AppThemeSetting fromCode(String? code) {
    if (code == 'light') return AppThemeSetting.light;
    return AppThemeSetting.dark; // Default to Dark mode
  }

  ThemeMode get themeMode => this == AppThemeSetting.light ? ThemeMode.light : ThemeMode.dark;
}

final appThemeModeProvider = StateNotifierProvider<AppThemeModeNotifier, AppThemeSetting>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppThemeModeNotifier(prefs);
});

class AppThemeModeNotifier extends StateNotifier<AppThemeSetting> {
  final SharedPreferences _prefs;
  static const String _prefKey = 'quitcapping_theme_mode';

  AppThemeModeNotifier(this._prefs)
      : super(AppThemeSetting.fromCode(_prefs.getString(_prefKey))) {
    AppColors.setIsDark(state == AppThemeSetting.dark);
    if (!_prefs.containsKey(_prefKey)) {
      _prefs.setString(_prefKey, state.code);
    }
  }

  Future<void> setThemeSetting(AppThemeSetting setting) async {
    AppColors.setIsDark(setting == AppThemeSetting.dark);
    state = setting;
    await _prefs.setString(_prefKey, setting.code);
  }

  Future<void> toggleTheme() async {
    final next = state == AppThemeSetting.dark ? AppThemeSetting.light : AppThemeSetting.dark;
    await setThemeSetting(next);
  }
}
