import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../data/goal_repository.dart';
import '../domain/goal_model.dart';

class GoalsState {
  final bool isLoading;
  final List<GoalModel> goals;
  final String? errorMessage;

  const GoalsState({
    required this.isLoading,
    required this.goals,
    this.errorMessage,
  });

  factory GoalsState.initial() => const GoalsState(
        isLoading: false,
        goals: [],
      );

  GoalsState copyWith({
    bool? isLoading,
    List<GoalModel>? goals,
    String? errorMessage,
    bool clearError = false,
  }) {
    return GoalsState(
      isLoading: isLoading ?? this.isLoading,
      goals: goals ?? this.goals,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final goalsControllerProvider =
    StateNotifierProvider<GoalsController, GoalsState>((ref) {
  final goalRepo = ref.watch(goalRepositoryProvider);
  return GoalsController(goalRepo);
});

class GoalsController extends StateNotifier<GoalsState> {
  final GoalRepository _goalRepo;

  GoalsController(this._goalRepo) : super(GoalsState.initial()) {
    loadGoals();
  }

  Future<void> loadGoals() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final goals = await _goalRepo.getUserGoals();
      state = state.copyWith(isLoading: false, goals: goals);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load goals: ${e.toString()}',
      );
    }
  }
}
