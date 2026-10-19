import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/translations.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../roadmap/domain/task_model.dart';
import '../today_tasks_controller.dart';
import 'task_detail_screen.dart';

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
            tooltip: 'Refresh',
            onPressed: () => ref.read(todayTasksControllerProvider.notifier).refresh(),
          ),
        ],
      ),
      body: state.isLoading && state.selectedGoal == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : state.selectedGoal == null && state.userGoals.isEmpty
              ? _buildEmptyState(context, ref, tr)
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => ref.read(todayTasksControllerProvider.notifier).refresh(),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    children: [
                      // Header Progress & Streak Summary Card
                      _buildHeaderCard(context, state, authState, tr),
                      const SizedBox(height: 12),

                      // Search Icon & 7 Recent Days Chips
                      _buildDateSelectionBar(context, ref, state, tr),
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

                      // Clean Task List Cards (Only Title & "Mở" button)
                      if (state.tasks.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              tr.noTasksToday,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            ),
                          ),
                        )
                      else
                        ...state.tasks.map((task) => _buildCleanTaskCard(context, task, tr)),
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
    final d = state.selectedDate;
    final now = DateTime.now();
    final isToday = d.year == now.year && d.month == now.month && d.day == now.day;

    final dateStr = isToday
        ? (tr.isVietnamese
            ? 'Hôm nay, ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}'
            : 'Today, ${d.day}/${d.month}/${d.year}')
        : (tr.isVietnamese
            ? 'Ngày ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}'
            : 'Date: ${d.day}/${d.month}/${d.year}');

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

  Widget _buildDateSelectionBar(
    BuildContext context,
    WidgetRef ref,
    TodayTasksState state,
    Translations tr,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 7 most recent days (Today, D-1, D-2, D-3, D-4, D-5, D-6)
    final recentDays = List.generate(7, (i) => today.subtract(Duration(days: i)));

    final selectedDateOnly = DateTime(
      state.selectedDate.year,
      state.selectedDate.month,
      state.selectedDate.day,
    );

    final isCustomDate = !recentDays.any((d) => d == selectedDateOnly);

    return Row(
      children: [
        // Search Icon Button
        IconButton(
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AppColors.cardBorder),
            ),
            padding: const EdgeInsets.all(10),
          ),
          icon: const Icon(Icons.search, color: AppColors.primary, size: 22),
          tooltip: tr.searchByDate,
          onPressed: () => _showDateSearchDialog(context, ref, state, tr),
        ),
        const SizedBox(width: 8),

        // Horizontal Chips List for 7 days
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (isCustomDate) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      selected: true,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      label: Text(
                        '${selectedDateOnly.day.toString().padLeft(2, '0')}/${selectedDateOnly.month.toString().padLeft(2, '0')}',
                      ),
                      labelStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      side: const BorderSide(color: AppColors.primary),
                      onSelected: (_) {},
                    ),
                  ),
                ],
                ...recentDays.map((date) {
                  final isSelected = !isCustomDate && date == selectedDateOnly;
                  final isToday = date == today;
                  final dateLabel =
                      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
                  final displayText = isToday ? '$dateLabel (${tr.todayLabel})' : dateLabel;

                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      label: Text(displayText),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.cardBorder,
                      ),
                      onSelected: (_) {
                        ref.read(todayTasksControllerProvider.notifier).selectDate(date);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showDateSearchDialog(
    BuildContext context,
    WidgetRef ref,
    TodayTasksState state,
    Translations tr,
  ) {
    final d = state.selectedDate;
    final textController = TextEditingController(
      text: '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: Row(
          children: [
            const Icon(Icons.calendar_month, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(tr.searchByDate, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr.enterDatePrompt,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              keyboardType: TextInputType.datetime,
              decoration: InputDecoration(
                hintText: 'dd/MM/yyyy',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.date_range, color: AppColors.primary),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: state.selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppColors.primary,
                              surface: AppColors.surface,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      textController.text =
                          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr.cancel, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final raw = textController.text.trim();
              final parts = raw.split('/');
              if (parts.length == 3) {
                final day = int.tryParse(parts[0]);
                final month = int.tryParse(parts[1]);
                final year = int.tryParse(parts[2]);
                if (day != null && month != null && year != null) {
                  try {
                    final date = DateTime(year, month, day);
                    if (date.isBefore(DateTime.now().add(const Duration(days: 1)))) {
                      ref.read(todayTasksControllerProvider.notifier).selectDate(date);
                      Navigator.pop(ctx);
                      return;
                    }
                  } catch (_) {}
                }
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(tr.invalidDate), backgroundColor: AppColors.reject),
              );
            },
            child: Text(tr.confirm),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanTaskCard(
    BuildContext context,
    TaskModel task,
    Translations tr,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              // Check / Status icon
              Icon(
                task.isCompleted
                    ? Icons.check_circle
                    : (task.latestSubmission != null
                        ? Icons.access_time_filled
                        : Icons.radio_button_unchecked),
                color: task.isCompleted
                    ? AppColors.approve
                    : (task.latestSubmission != null
                        ? AppColors.pending
                        : AppColors.textSecondary),
                size: 22,
              ),
              const SizedBox(width: 12),

              // Title & Status Badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: task.isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _buildStatusBadge(task, tr),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Button "Mở"
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
                  );
                },
                icon: const Icon(Icons.arrow_forward, size: 14),
                label: Text(
                  tr.openTask,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(TaskModel task, Translations tr) {
    if (task.isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.approve.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          tr.approvedBadge,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.approve),
        ),
      );
    }

    final sub = task.latestSubmission;
    if (sub == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(4),
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
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.pending.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            tr.lockedBadge,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.pending),
          ),
        );
      case 'in_queue':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.inQueue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            tr.inQueueBadge,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.inQueue),
          ),
        );
      case 'rejected':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.reject.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
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
