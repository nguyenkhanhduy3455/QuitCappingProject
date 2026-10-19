import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_colors.dart';
import 'core/localization/translations.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_theme_mode.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/reviews/presentation/screens/review_feed_screen.dart';
import 'features/roadmap/presentation/screens/goals_screen.dart';
import 'features/tasks_today/presentation/screens/today_tasks_screen.dart';

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class QuitCappingApp extends ConsumerWidget {
  const QuitCappingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final themeSetting = ref.watch(appThemeModeProvider);
    AppColors.setIsDark(themeSetting == AppThemeSetting.dark);

    return MaterialApp(
      key: ValueKey(themeSetting),
      title: 'QuitCapping',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeSetting.themeMode,
      home: _resolveHomeScreen(authState),
    );
  }

  Widget _resolveHomeScreen(AuthState state) {
    if (state.status == AuthStatus.initial) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (state.status == AuthStatus.authenticated) {
      return const MainNavigationShell();
    }

    return const LoginScreen();
  }
}

class MainNavigationShell extends ConsumerWidget {
  const MainNavigationShell({super.key});

  static const List<Widget> _screens = [
    TodayTasksScreen(),
    GoalsScreen(),
    ReviewFeedScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationsProvider);
    final currentIndex = ref.watch(bottomNavIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          onTap: (index) => ref.read(bottomNavIndexProvider.notifier).state = index,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.check_circle_outline),
              activeIcon: const Icon(Icons.check_circle),
              label: tr.tasks,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.track_changes_outlined),
              activeIcon: const Icon(Icons.track_changes),
              label: tr.goals,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.style_outlined),
              activeIcon: const Icon(Icons.style),
              label: tr.peerReview,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: tr.profile,
            ),
          ],
        ),
      ),
    );
  }
}
