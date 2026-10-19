import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/translations.dart';
import '../../domain/goal_model.dart';
import '../goals_controller.dart';
import 'create_goal_screen.dart';
import 'roadmap_screen.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(goalsControllerProvider);
    final tr = ref.watch(translationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.yourGoals),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.read(goalsControllerProvider.notifier).loadGoals(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: Text(
          tr.newAiGoal,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateGoalScreen()),
          );
        },
      ),
      body: state.isLoading && state.goals.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : state.goals.isEmpty
              ? _buildEmptyState(context, tr)
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => ref.read(goalsControllerProvider.notifier).loadGoals(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    itemCount: state.goals.length,
                    itemBuilder: (ctx, index) {
                      final goal = state.goals[index];
                      return _buildGoalCard(context, goal, tr);
                    },
                  ),
                ),
    );
  }

  Widget _buildGoalCard(BuildContext context, GoalModel goal, Translations tr) {
    final isCurrentActive = goal.isActive;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCurrentActive ? AppColors.primary : AppColors.cardBorder,
          width: isCurrentActive ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RoadmapScreen(initialGoal: goal)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Tags Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tr.categoryName(goal.category).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isCurrentActive
                          ? AppColors.approve.withValues(alpha: 0.15)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isCurrentActive ? tr.activeTag : tr.completedTag,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isCurrentActive ? AppColors.approve : AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                goal.title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),

              // Progress Bar & Percentage
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr.dayProgression
                        .replaceAll('{current}', '${goal.currentDay}')
                        .replaceAll('{total}', '${goal.durationDays}')
                        .replaceAll('{percent}', '${goal.percent}'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${goal.percent}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isCurrentActive ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: goal.progress,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCurrentActive ? AppColors.primary : AppColors.approve,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Drill down link
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    tr.viewRoadmap,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, Translations tr) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.track_changes_outlined,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              tr.noGoalsYet,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr.noGoalsYetDesc,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateGoalScreen()),
                );
              },
              icon: const Icon(Icons.auto_awesome),
              label: Text(tr.createAiGoalBtn),
            ),
          ],
        ),
      ),
    );
  }
}
