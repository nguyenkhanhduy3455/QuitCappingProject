import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/storage/token_storage.dart';
import 'package:mobile/core/theme/app_theme_mode.dart';
import 'package:mobile/features/auth/domain/user_model.dart';
import 'package:mobile/features/auth/presentation/auth_controller.dart';
import 'package:mobile/features/profile/presentation/screens/profile_screen.dart';

class MockAuthController extends StateNotifier<AuthState> implements AuthController {
  MockAuthController()
      : super(AuthState(
          status: AuthStatus.authenticated,
          user: UserModel(
            id: 'u1',
            email: 'test@example.com',
            displayName: 'Test User',
            dailyReviewsDone: 5,
            streakCount: 3,
            quotaReached: true,
            points: 1050,
          ),
        ));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Theme Mode Tests', () {
    test('Default theme is Dark mode', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final notifier = AppThemeModeNotifier(prefs);
      expect(notifier.state, AppThemeSetting.dark);
      expect(notifier.state.themeMode, ThemeMode.dark);
      expect(AppColors.isDark, isTrue);
      expect(AppColors.background, const Color(0xFF0D0F14));
      expect(AppColors.surface, const Color(0xFF161B22));
    });

    test('Switching to Light mode updates AppColors and persists in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final notifier = AppThemeModeNotifier(prefs);
      await notifier.setThemeSetting(AppThemeSetting.light);

      expect(notifier.state, AppThemeSetting.light);
      expect(notifier.state.themeMode, ThemeMode.light);
      expect(AppColors.isDark, isFalse);
      expect(AppColors.background, const Color(0xFFF6F8FA));
      expect(AppColors.surface, const Color(0xFFFFFFFF));
      expect(prefs.getString('quitcapping_theme_mode'), 'light');

      // Switch back to Dark
      await notifier.toggleTheme();
      expect(notifier.state, AppThemeSetting.dark);
      expect(AppColors.isDark, isTrue);
      expect(AppColors.background, const Color(0xFF0D0F14));
      expect(prefs.getString('quitcapping_theme_mode'), 'dark');
    });

    testWidgets('ProfileScreen renders theme toggle and switches theme', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            authControllerProvider.overrideWith((ref) => MockAuthController()),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Check theme section exists in Settings
      expect(find.text('Giao diện'), findsOneWidget);
      expect(find.text('🌙 Tối'), findsOneWidget);
      expect(find.text('☀️ Sáng'), findsOneWidget);

      // Tap Light mode
      await tester.tap(find.text('☀️ Sáng'));
      await tester.pumpAndSettle();

      expect(AppColors.isDark, isFalse);

      // Tap Dark mode back
      await tester.tap(find.text('🌙 Tối'));
      await tester.pumpAndSettle();

      expect(AppColors.isDark, isTrue);
    });
  });
}
