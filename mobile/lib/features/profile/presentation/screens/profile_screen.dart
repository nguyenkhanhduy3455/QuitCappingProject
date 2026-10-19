import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/theme/app_theme_mode.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../roadmap/presentation/roadmap_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final roadmapState = ref.watch(roadmapControllerProvider);
    final activeGoal = roadmapState.activeGoal;
    final tr = ref.watch(translationsProvider);
    final currentLang = ref.watch(appLanguageProvider);
    final currentTheme = ref.watch(appThemeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.profile),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.reject),
            tooltip: tr.logOut,
            onPressed: () => _confirmLogout(context, ref, tr),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await ref.read(authControllerProvider.notifier).refreshProfile();
                await ref.read(roadmapControllerProvider.notifier).loadActiveRoadmap();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // User Identity Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                            child: Text(
                              user.displayName.isNotEmpty
                                  ? user.displayName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.displayName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.email,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (user.id == 'guest_local_user')
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppColors.primary, width: 0.8),
                                      ),
                                      child: Text(
                                        tr.guestModeBanner,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reward Points Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Text('🪙', style: TextStyle(fontSize: 22)),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tr.points,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${user.points}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Flexible(
                            child: Text(
                              tr.pointsEarnedInfo,
                              textAlign: TextAlign.end,
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Streak & Accountability Metrics Grid
                  Row(
                    children: [
                      // Streak Counter
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text('🔥', style: TextStyle(fontSize: 22)),
                                    const SizedBox(width: 6),
                                    Text(
                                      tr.streakTitle,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textSecondary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  tr.daysStreak.replaceAll('{count}', '${user.streakCount}'),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tr.zeroCapNotice,
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Daily Review Quota
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      user.dailyReviewsDone >= 5 ? Icons.verified : Icons.lock_clock,
                                      size: 20,
                                      color: user.dailyReviewsDone >= 5
                                          ? AppColors.approve
                                          : AppColors.pending,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      tr.quotaTitle,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textSecondary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '${user.dailyReviewsDone} / 5',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: user.dailyReviewsDone >= 5
                                        ? AppColors.approve
                                        : AppColors.pending,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.dailyReviewsDone >= 5 ? tr.unlockedInQueue : tr.lockedUntil5,
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Settings Card: Language Switcher (VN / EN)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.settings_outlined, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                tr.settings,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.language, size: 18, color: AppColors.textSecondary),
                                  const SizedBox(width: 8),
                                  Text(
                                    tr.languageTitle,
                                    style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                              SegmentedButton<AppLanguage>(
                                segments: const [
                                  ButtonSegment(
                                    value: AppLanguage.vi,
                                    label: Text('🇻🇳 VN'),
                                  ),
                                  ButtonSegment(
                                    value: AppLanguage.en,
                                    label: Text('🇬🇧 EN'),
                                  ),
                                ],
                                selected: {currentLang},
                                onSelectionChanged: (set) {
                                  ref.read(appLanguageProvider.notifier).setLanguage(set.first);
                                },
                                style: ButtonStyle(
                                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                                    if (states.contains(WidgetState.selected)) {
                                      return AppColors.primary.withValues(alpha: 0.25);
                                    }
                                    return AppColors.surfaceVariant;
                                  }),
                                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                                    if (states.contains(WidgetState.selected)) {
                                      return AppColors.primary;
                                    }
                                    return AppColors.textSecondary;
                                  }),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    currentTheme == AppThemeSetting.dark
                                        ? Icons.dark_mode_outlined
                                        : Icons.light_mode_outlined,
                                    size: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    tr.themeTitle,
                                    style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                              SegmentedButton<AppThemeSetting>(
                                segments: [
                                  ButtonSegment(
                                    value: AppThemeSetting.dark,
                                    label: Text('🌙 ${tr.darkTheme}'),
                                  ),
                                  ButtonSegment(
                                    value: AppThemeSetting.light,
                                    label: Text('☀️ ${tr.lightTheme}'),
                                  ),
                                ],
                                selected: {currentTheme},
                                onSelectionChanged: (set) {
                                  ref.read(appThemeModeProvider.notifier).setThemeSetting(set.first);
                                },
                                style: ButtonStyle(
                                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                                    if (states.contains(WidgetState.selected)) {
                                      return AppColors.primary.withValues(alpha: 0.25);
                                    }
                                    return AppColors.surfaceVariant;
                                  }),
                                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                                    if (states.contains(WidgetState.selected)) {
                                      return AppColors.primary;
                                    }
                                    return AppColors.textSecondary;
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Active Goal Status Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.track_changes, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                tr.currentRoadmap,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (activeGoal != null) ...[
                            Text(
                              activeGoal.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${tr.category}: ${tr.categoryName(activeGoal.category)} • ${tr.dayXOfY.replaceAll('{x}', '${activeGoal.currentDay}').replaceAll('{y}', '${activeGoal.durationDays}')}',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: (activeGoal.currentDay / activeGoal.durationDays).clamp(0.0, 1.0),
                                minHeight: 8,
                                backgroundColor: AppColors.surfaceVariant,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            ),
                          ] else ...[
                            Text(
                              tr.noActiveGoalProfile,
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Anti-Cheat Guarantee Badge
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shield, color: AppColors.approve, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              tr.antiCheatRulesTitle,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr.antiCheatSummary,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref, Translations tr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(tr.logOut),
        content: Text(tr.logOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr.cancel, style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.reject),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authControllerProvider.notifier).logout();
            },
            child: Text(tr.logOut),
          ),
        ],
      ),
    );
  }
}
