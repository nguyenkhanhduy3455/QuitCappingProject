import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/translations.dart';
import '../../../proof/presentation/widgets/submit_proof_dialog.dart';
import '../../domain/goal_model.dart';
import '../../domain/task_model.dart';
import '../roadmap_controller.dart';
import 'create_goal_screen.dart';

class RoadmapScreen extends ConsumerStatefulWidget {
  final GoalModel? initialGoal;

  const RoadmapScreen({super.key, this.initialGoal});

  @override
  ConsumerState<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends ConsumerState<RoadmapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialGoal != null) {
        ref.read(roadmapControllerProvider.notifier).loadRoadmapForGoal(widget.initialGoal!);
      } else {
        ref.read(roadmapControllerProvider.notifier).loadActiveRoadmap();
      }
    });
  }

  void _refresh() {
    if (widget.initialGoal != null) {
      ref.read(roadmapControllerProvider.notifier).loadRoadmapForGoal(widget.initialGoal!);
    } else {
      ref.read(roadmapControllerProvider.notifier).loadActiveRoadmap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(roadmapControllerProvider);
    final tr = ref.watch(translationsProvider);

    final title = widget.initialGoal != null
        ? '${tr.isVietnamese ? "Lộ trình" : "Roadmap"}: ${widget.initialGoal!.title}'
        : tr.dailyRoadmap;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            tooltip: tr.newAiGoal,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateGoalScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: state.isLoading && state.activeGoal == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : state.activeGoal == null
              ? _buildEmptyState(context, tr)
              : _buildRoadmapContent(context, ref, state, tr),
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
              child: const Icon(Icons.flag_outlined, size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              tr.noActiveRoadmap,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr.noActiveRoadmapDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
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

  Widget _buildRoadmapContent(
    BuildContext context,
    WidgetRef ref,
    RoadmapState state,
    Translations tr,
  ) {
    final goal = state.activeGoal!;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => _refresh(),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Active Goal Header Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tr.categoryName(goal.category).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          tr.dayXOfY
                              .replaceAll('{x}', '${state.selectedDay}')
                              .replaceAll('{y}', '${goal.durationDays}'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      goal.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Day Selector Scroll
          SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: goal.durationDays,
              itemBuilder: (ctx, index) {
                final day = index + 1;
                final isSelected = day == state.selectedDay;
                final isCurrentDay = day == goal.currentDay;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${tr.isVietnamese ? "Ngày" : "Day"} $day'),
                        if (isCurrentDay) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.fiber_manual_record, size: 8, color: AppColors.approve),
                        ],
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.cardBorder,
                    ),
                    onSelected: (_) => ref.read(roadmapControllerProvider.notifier).selectDay(day),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Micro-Tasks List for Selected Day
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr.microTasksForDay.replaceAll('{day}', '${state.selectedDay}'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      tr.completedStats
                          .replaceAll('{completed}', '${state.tasks.where((t) => t.isCompleted).length}')
                          .replaceAll('{total}', '${state.tasks.length}'),
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (state.tasks.isEmpty && !state.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'No tasks found for this day.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  ...state.tasks.map((task) => _buildTaskCard(context, task, tr)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, TaskModel task, Translations tr) {
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
                          style: const TextStyle(fontSize: 12, color: AppColors.pending, fontWeight: FontWeight.w600),
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
                          style: const TextStyle(fontSize: 12, color: AppColors.inQueue, fontWeight: FontWeight.w600),
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
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
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
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.pending),
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
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.inQueue),
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
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.reject),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
