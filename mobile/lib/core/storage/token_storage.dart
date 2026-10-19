import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized before runApp');
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TokenStorage(prefs);
});

class TokenStorage {
  final SharedPreferences _prefs;
  static const String _tokenKey = 'auth_jwt_token';
  static const String _userKey = 'auth_user_data';

  TokenStorage(this._prefs);

  String? getToken() {
    return _prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userKey);
  }

  String? getUserJson() {
    return _prefs.getString(_userKey);
  }

  Future<void> saveUserJson(String jsonStr) async {
    await _prefs.setString(_userKey, jsonStr);
  }
}
