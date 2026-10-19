import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/local_data_storage.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_repository.dart';
import '../domain/user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  final localData = ref.watch(localDataStorageProvider);
  return AuthController(authRepo, tokenStorage, localData);
});

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepo;
  final TokenStorage _tokenStorage;
  final LocalDataStorage _localData;

  AuthController(this._authRepo, this._tokenStorage, this._localData) : super(AuthState.initial()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    if (_localData.isGuestMode()) {
      await _localData.ensureInitialized();
      final guestUser = _localData.getGuestUser();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: guestUser,
      );
      return;
    }

    final token = _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      final user = await _authRepo.getProfile();
      await _tokenStorage.saveUserJson(jsonEncode(user.toJson()));
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
    } catch (_) {
      // If token expired or invalid, clear and set unauthenticated
      await _tokenStorage.clearToken();
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> continueAsGuest() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    await _localData.setGuestMode(true);
    await _localData.ensureInitialized();
    final guestUser = _localData.getGuestUser();
    state = state.copyWith(
      status: AuthStatus.authenticated,
      user: guestUser,
    );
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    await _localData.setGuestMode(false);
    try {
      final result = await _authRepo.login(email: email, password: password);
      await _tokenStorage.saveToken(result.token);
      await _tokenStorage.saveUserJson(jsonEncode(result.user.toJson()));
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Login failed: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> register(String email, String password, String displayName) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    await _localData.setGuestMode(false);
    try {
      final result = await _authRepo.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      await _tokenStorage.saveToken(result.token);
      await _tokenStorage.saveUserJson(jsonEncode(result.user.toJson()));
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Registration failed: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> refreshProfile() async {
    if (_localData.isGuestMode()) {
      final guestUser = _localData.getGuestUser();
      state = state.copyWith(user: guestUser);
      return;
    }
    try {
      final user = await _authRepo.getProfile();
      state = state.copyWith(user: user);
    } catch (_) {}
  }

  Future<void> logout() async {
    await _tokenStorage.clearToken();
    await _localData.setGuestMode(false);
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
