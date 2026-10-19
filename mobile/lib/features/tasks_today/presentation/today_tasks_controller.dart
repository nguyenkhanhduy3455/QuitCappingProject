import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../roadmap/data/goal_repository.dart';
import '../../roadmap/domain/goal_model.dart';
import '../../roadmap/domain/task_model.dart';

class TodayTasksState {
  final bool isLoading;
  final List<GoalModel> userGoals;
  final GoalModel? selectedGoal;
  final DateTime selectedDate;
  final int dayNumber;
  final List<TaskModel> tasks;
  final String? errorMessage;

  TodayTasksState({
    required this.isLoading,
    required this.userGoals,
    this.selectedGoal,
    required this.selectedDate,
    required this.dayNumber,
    required this.tasks,
    this.errorMessage,
  });

  factory TodayTasksState.initial() => TodayTasksState(
        isLoading: false,
        userGoals: [],
        selectedGoal: null,
        selectedDate: DateTime.now(),
        dayNumber: 1,
        tasks: [],
      );

  TodayTasksState copyWith({
    bool? isLoading,
    List<GoalModel>? userGoals,
    GoalModel? selectedGoal,
    bool clearSelectedGoal = false,
    DateTime? selectedDate,
    int? dayNumber,
    List<TaskModel>? tasks,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TodayTasksState(
      isLoading: isLoading ?? this.isLoading,
      userGoals: userGoals ?? this.userGoals,
      selectedGoal: clearSelectedGoal ? null : (selectedGoal ?? this.selectedGoal),
      selectedDate: selectedDate ?? this.selectedDate,
      dayNumber: dayNumber ?? this.dayNumber,
      tasks: tasks ?? this.tasks,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  int get completedTasksCount => tasks.where((t) => t.isCompleted).length;
  int get totalTasksCount => tasks.length;
  double get completionProgress =>
      totalTasksCount > 0 ? (completedTasksCount / totalTasksCount) : 0.0;
}

final todayTasksControllerProvider =
    StateNotifierProvider<TodayTasksController, TodayTasksState>((ref) {
  final goalRepo = ref.watch(goalRepositoryProvider);
  return TodayTasksController(goalRepo);
});

class TodayTasksController extends StateNotifier<TodayTasksState> {
  final GoalRepository _goalRepo;

  TodayTasksController(this._goalRepo) : super(TodayTasksState.initial()) {
    loadTodayTasks();
  }

  int _resolveDayNumberForDate(GoalModel goal, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final daysDiff = today.difference(target).inDays;
    final dayNum = goal.currentDay - daysDiff;
    return dayNum.clamp(1, goal.durationDays);
  }

  Future<void> loadTodayTasks() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final goals = await _goalRepo.getUserGoals();
      if (goals.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          userGoals: [],
          clearSelectedGoal: true,
          tasks: [],
          dayNumber: 1,
        );
        return;
      }

      GoalModel targetGoal;
      if (state.selectedGoal != null && goals.any((g) => g.id == state.selectedGoal!.id)) {
        targetGoal = goals.firstWhere((g) => g.id == state.selectedGoal!.id);
      } else {
        targetGoal = goals.firstWhere((g) => g.isActive, orElse: () => goals.first);
      }

      final dayNumber = _resolveDayNumberForDate(targetGoal, state.selectedDate);

      final result = await _goalRepo.getDailyTasksDetailed(
        goalId: targetGoal.id,
        dayNumber: dayNumber,
      );

      state = state.copyWith(
        isLoading: false,
        userGoals: goals,
        selectedGoal: targetGoal,
        dayNumber: result.dayNumber,
        tasks: result.tasks,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load today tasks: ${e.toString()}',
      );
    }
  }

  Future<void> selectDate(DateTime date) async {
    state = state.copyWith(isLoading: true, selectedDate: date, clearError: true);
    try {
      GoalModel? targetGoal = state.selectedGoal;
      if (targetGoal == null) {
        final goals = await _goalRepo.getUserGoals();
        if (goals.isEmpty) {
          state = state.copyWith(
            isLoading: false,
            selectedDate: date,
            tasks: [],
          );
          return;
        }
        targetGoal = goals.firstWhere((g) => g.isActive, orElse: () => goals.first);
      }

      final dayNumber = _resolveDayNumberForDate(targetGoal, date);
      final result = await _goalRepo.getDailyTasksDetailed(
        goalId: targetGoal.id,
        dayNumber: dayNumber,
      );

      state = state.copyWith(
        isLoading: false,
        selectedGoal: targetGoal,
        selectedDate: date,
        dayNumber: result.dayNumber,
        tasks: result.tasks,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to switch date tasks: ${e.toString()}',
      );
    }
  }

  Future<void> selectGoal(GoalModel goal) async {
    if (state.selectedGoal?.id == goal.id && state.tasks.isNotEmpty) return;
    state = state.copyWith(isLoading: true, selectedGoal: goal, clearError: true);
    try {
      final dayNumber = _resolveDayNumberForDate(goal, state.selectedDate);
      final result = await _goalRepo.getDailyTasksDetailed(
        goalId: goal.id,
        dayNumber: dayNumber,
      );
      state = state.copyWith(
        isLoading: false,
        selectedGoal: goal,
        dayNumber: result.dayNumber,
        tasks: result.tasks,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to switch goal tasks: ${e.toString()}',
      );
    }
  }

  Future<void> refresh() async {
    try {
      final goals = await _goalRepo.getUserGoals();
      if (goals.isEmpty) {
        state = state.copyWith(
          userGoals: [],
          clearSelectedGoal: true,
          tasks: [],
        );
        return;
      }

      GoalModel targetGoal;
      if (state.selectedGoal != null && goals.any((g) => g.id == state.selectedGoal!.id)) {
        targetGoal = goals.firstWhere((g) => g.id == state.selectedGoal!.id);
      } else {
        targetGoal = goals.firstWhere((g) => g.isActive, orElse: () => goals.first);
      }

      final dayNumber = _resolveDayNumberForDate(targetGoal, state.selectedDate);

      final result = await _goalRepo.getDailyTasksDetailed(
        goalId: targetGoal.id,
        dayNumber: dayNumber,
      );

      state = state.copyWith(
        userGoals: goals,
        selectedGoal: targetGoal,
        dayNumber: result.dayNumber,
        tasks: result.tasks,
      );
    } catch (_) {}
  }
}
