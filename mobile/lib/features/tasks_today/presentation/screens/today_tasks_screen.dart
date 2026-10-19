import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/translations.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../proof/presentation/widgets/submit_proof_dialog.dart';
import '../../../roadmap/domain/task_model.dart';
import '../today_tasks_controller.dart';

class TodayTasksScreen extends ConsumerWidget {
  const TodayTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(todayTasksControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final tr = ref.watch(translationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.todayTasks),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(todayTasksControllerProvider.notifier).loadTodayTasks(),
          ),
        ],
      ),
      body: state.isLoading && state.selectedGoal == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : state.selectedGoal == null || state.tasks.isEmpty
              ? _buildEmptyState(context, ref, tr)
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => ref.read(todayTasksControllerProvider.notifier).loadTodayTasks(),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    children: [
                      // Header Progress & Streak Summary Card
                      _buildHeaderCard(context, state, authState, tr),
                      const SizedBox(height: 16),

                      // Goal Selector / Active Goal Badge
                      _buildGoalSelector(context, ref, state, tr),
                      const SizedBox(height: 16),

                      // Section Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tr.microTasksForDay.replaceAll('{day}', '${state.dayNumber}'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            tr.completedStats
                                .replaceAll('{completed}', '${state.completedTasksCount}')
                                .replaceAll('{total}', '${state.totalTasksCount}'),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Task List Cards
                      ...state.tasks.map((task) => _buildTaskCard(context, ref, task, tr)),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    TodayTasksState state,
    AuthState authState,
    Translations tr,
  ) {
    final streak = authState.user?.streakCount ?? 0;
    final now = DateTime.now();
    final dateStr = tr.isVietnamese
        ? 'Hôm nay, ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}'
        : 'Today, ${now.day}/${now.month}/${now.year}';

    final percent = (state.completionProgress * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.pending.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.pending.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥 ', style: TextStyle(fontSize: 12)),
                      Text(
                        tr.isVietnamese ? '$streak ngày chuỗi' : '$streak day streak',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.pending,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr.todayTasksSubtitle
                      .replaceAll('{completed}', '${state.completedTasksCount}')
                      .replaceAll('{total}', '${state.totalTasksCount}'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '$percent%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: state.completionProgress,
                minHeight: 8,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalSelector(
    BuildContext context,
    WidgetRef ref,
    TodayTasksState state,
    Translations tr,
  ) {
    final goal = state.selectedGoal;
    if (goal == null) return const SizedBox.shrink();

    final goals = state.userGoals;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.18),
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
              const SizedBox(width: 8),
              Text(
                tr.dayXOfY
                    .replaceAll('{x}', '${state.dayNumber}')
                    .replaceAll('{y}', '${goal.durationDays}'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (goals.length > 1)
                InkWell(
                  onTap: () => _showGoalSelectionModal(context, ref, state, tr),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tr.switchGoal,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: AppColors.primary, size: 18),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            goal.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showGoalSelectionModal(
    BuildContext context,
    WidgetRef ref,
    TodayTasksState state,
    Translations tr,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.cardBorder),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    tr.switchGoal,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Divider(color: AppColors.cardBorder),
                ...state.userGoals.map((g) {
                  final isSelected = g.id == state.selectedGoal?.id;
                  return ListTile(
                    leading: Icon(
                      isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                    title: Text(
                      g.title,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '${tr.categoryName(g.category)} • ${tr.isVietnamese ? "Ngày" : "Day"} ${g.currentDay}/${g.durationDays}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      ref.read(todayTasksControllerProvider.notifier).selectGoal(g);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    WidgetRef ref,
    TaskModel task,
    Translations tr,
  ) {
    final submission = task.latestSubmission;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Completion icon
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: task.isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(task, tr),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              task.description,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3),
            ),
            const SizedBox(height: 12),

            // Concrete Evidence Prompt Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.camera_alt, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${tr.proofRequired}${task.evidencePrompt}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Action / Status Area
            if (!task.isCompleted) ...[
              if (submission == null || submission.status == 'rejected') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      backgroundColor: submission?.status == 'rejected' ? AppColors.reject : AppColors.primary,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => SubmitProofDialog(task: task),
                      );
                    },
                    icon: Icon(
                      submission?.status == 'rejected' ? Icons.replay : Icons.upload_file,
                      size: 16,
                    ),
                    label: Text(
                      submission?.status == 'rejected' ? tr.retryProof : tr.submitProof,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ] else if (submission.status == 'pending_quota') ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.pending.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.pending.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_clock, size: 18, color: AppColors.pending),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tr.lockedNotice,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.pending,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (submission.status == 'in_queue') ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.inQueue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.inQueue.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.how_to_vote, size: 18, color: AppColors.inQueue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tr.inQueueNotice(submission.upvotes, submission.downvotes),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.inQueue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(TaskModel task, Translations tr) {
    if (task.isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.approve.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 14, color: AppColors.approve),
            const SizedBox(width: 4),
            Text(
              tr.approvedBadge,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.approve,
              ),
            ),
          ],
        ),
      );
    }

    final sub = task.latestSubmission;
    if (sub == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          tr.pendingProofBadge,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    switch (sub.status) {
      case 'pending_quota':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.pending.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            tr.lockedBadge,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.pending,
            ),
          ),
        );
      case 'in_queue':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.inQueue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            tr.inQueueBadge,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.inQueue,
            ),
          ),
        );
      case 'rejected':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.reject.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            tr.rejectedBadge,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.reject,
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, Translations tr) {
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
                Icons.check_circle_outline,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              tr.noTasksToday,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr.noTasksTodayDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () {
                // Programmatically switch to Tab 2 (Goals)
                ref.read(bottomNavIndexProvider.notifier).state = 1;
              },
              icon: const Icon(Icons.track_changes),
              label: Text(tr.goToGoals),
            ),
          ],
        ),
      ),
    );
  }
}
