import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../data/goal_repository.dart';
import '../domain/goal_model.dart';
import '../domain/task_model.dart';

class RoadmapState {
  final bool isLoading;
  final bool isGenerating;
  final GoalModel? activeGoal;
  final int selectedDay;
  final List<TaskModel> tasks;
  final String? errorMessage;

  const RoadmapState({
    required this.isLoading,
    required this.isGenerating,
    this.activeGoal,
    required this.selectedDay,
    required this.tasks,
    this.errorMessage,
  });

  factory RoadmapState.initial() => const RoadmapState(
        isLoading: false,
        isGenerating: false,
        activeGoal: null,
        selectedDay: 1,
        tasks: [],
      );

  RoadmapState copyWith({
    bool? isLoading,
    bool? isGenerating,
    GoalModel? activeGoal,
    int? selectedDay,
    List<TaskModel>? tasks,
    String? errorMessage,
  }) {
    return RoadmapState(
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      activeGoal: activeGoal ?? this.activeGoal,
      selectedDay: selectedDay ?? this.selectedDay,
      tasks: tasks ?? this.tasks,
      errorMessage: errorMessage,
    );
  }
}

final roadmapControllerProvider =
    StateNotifierProvider<RoadmapController, RoadmapState>((ref) {
  final goalRepo = ref.watch(goalRepositoryProvider);
  return RoadmapController(goalRepo);
});

class RoadmapController extends StateNotifier<RoadmapState> {
  final GoalRepository _goalRepo;

  RoadmapController(this._goalRepo) : super(RoadmapState.initial()) {
    loadActiveRoadmap();
  }

  Future<void> loadActiveRoadmap() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final activeGoal = await _goalRepo.getActiveGoal();
      if (activeGoal == null) {
        state = state.copyWith(isLoading: false, activeGoal: null, tasks: []);
        return;
      }

      final dayToSelect = activeGoal.currentDay;
      final tasks = await _goalRepo.getDailyTasks(
        goalId: activeGoal.id,
        dayNumber: dayToSelect,
      );

      state = state.copyWith(
        isLoading: false,
        activeGoal: activeGoal,
        selectedDay: dayToSelect,
        tasks: tasks,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load roadmap: ${e.toString()}',
      );
    }
  }

  Future<void> selectDay(int day) async {
    if (state.activeGoal == null || day == state.selectedDay) return;
    state = state.copyWith(isLoading: true, selectedDay: day);
    try {
      final tasks = await _goalRepo.getDailyTasks(
        goalId: state.activeGoal!.id,
        dayNumber: day,
      );
      state = state.copyWith(isLoading: false, tasks: tasks);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> createGoal({
    required String title,
    required String category,
    required String currentSkillLevel,
    required int durationDays,
  }) async {
    state = state.copyWith(isGenerating: true, errorMessage: null);
    try {
      final goal = await _goalRepo.createGoal(
        title: title,
        category: category,
        currentSkillLevel: currentSkillLevel,
        durationDays: durationDays,
      );

      final tasks = await _goalRepo.getDailyTasks(
        goalId: goal.id,
        dayNumber: 1,
      );

      state = state.copyWith(
        isGenerating: false,
        activeGoal: goal,
        selectedDay: 1,
        tasks: tasks,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isGenerating: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        errorMessage: 'AI generation error: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> refreshCurrentTasks() async {
    if (state.activeGoal == null) return;
    try {
      final tasks = await _goalRepo.getDailyTasks(
        goalId: state.activeGoal!.id,
        dayNumber: state.selectedDay,
      );
      state = state.copyWith(tasks: tasks);
    } catch (_) {}
  }
}
