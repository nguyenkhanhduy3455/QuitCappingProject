import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/local_data_storage.dart';
import '../domain/goal_model.dart';
import '../domain/task_model.dart';

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final localData = ref.watch(localDataStorageProvider);
  return GoalRepository(dio, localData);
});

class GoalRepository {
  final Dio _dio;
  final LocalDataStorage _localData;

  GoalRepository(this._dio, this._localData);

  Future<GoalModel> createGoal({
    required String title,
    required String category,
    required String currentSkillLevel,
    required int durationDays,
  }) async {
    if (_localData.isGuestMode()) {
      return await _localData.createGoal(
        title: title,
        category: category,
        currentSkillLevel: currentSkillLevel,
        durationDays: durationDays,
      );
    }

    try {
      final response = await _dio.post(
        ApiEndpoints.goals,
        data: {
          'title': title.trim(),
          'category': category.trim(),
          'currentSkillLevel': currentSkillLevel,
          'durationDays': durationDays,
        },
      );
      return GoalModel.fromJson(response.data['goal'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(e.message ?? 'Failed to create AI goal');
    }
  }

  Future<GoalModel?> getActiveGoal() async {
    if (_localData.isGuestMode()) {
      return _localData.getActiveGoal();
    }

    try {
      final response = await _dio.get(ApiEndpoints.activeGoal);
      if (response.data == null || response.data['goal'] == null) {
        return null;
      }
      return GoalModel.fromJson(response.data['goal'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(e.message ?? 'Failed to fetch active goal');
    }
  }

  Future<List<GoalModel>> getUserGoals() async {
    if (_localData.isGuestMode()) {
      return _localData.getGoals();
    }

    try {
      final response = await _dio.get(ApiEndpoints.goals);
      final list = response.data as List<dynamic>? ?? [];
      return list.map((g) => GoalModel.fromJson(g as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(e.message ?? 'Failed to fetch user goals');
    }
  }

  Future<List<TaskModel>> getDailyTasks({String? goalId, int? dayNumber}) async {
    if (_localData.isGuestMode()) {
      return _localData.getTasks(goalId: goalId, dayNumber: dayNumber);
    }

    try {
      final queryParams = <String, dynamic>{};
      if (goalId != null) queryParams['goalId'] = goalId;
      if (dayNumber != null) queryParams['dayNumber'] = dayNumber;

      final response = await _dio.get(
        ApiEndpoints.dailyTasks,
        queryParameters: queryParams,
      );

      final tasksJson = response.data['tasks'] as List<dynamic>? ?? [];
      return tasksJson.map((t) => TaskModel.fromJson(t as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(e.message ?? 'Failed to fetch daily tasks');
    }
  }

  Future<({GoalModel? goal, int dayNumber, List<TaskModel> tasks})> getDailyTasksDetailed({
    String? goalId,
    int? dayNumber,
  }) async {
    if (_localData.isGuestMode()) {
      final activeGoal = _localData.getActiveGoal();
      final gId = goalId ?? activeGoal?.id;
      final dNum = dayNumber ?? 1;
      final tasks = _localData.getTasks(goalId: gId, dayNumber: dNum);
      return (goal: activeGoal, dayNumber: dNum, tasks: tasks);
    }

    try {
      final queryParams = <String, dynamic>{};
      if (goalId != null) queryParams['goalId'] = goalId;
      if (dayNumber != null) queryParams['dayNumber'] = dayNumber;

      final response = await _dio.get(
        ApiEndpoints.dailyTasks,
        queryParameters: queryParams,
      );

      GoalModel? goal;
      if (response.data != null && response.data['goal'] != null) {
        goal = GoalModel.fromJson(response.data['goal'] as Map<String, dynamic>);
      }
      final resolvedDayNumber = (response.data?['dayNumber'] as num?)?.toInt() ?? 1;
      final tasksJson = response.data?['tasks'] as List<dynamic>? ?? [];
      final tasks = tasksJson.map((t) => TaskModel.fromJson(t as Map<String, dynamic>)).toList();
      return (goal: goal, dayNumber: resolvedDayNumber, tasks: tasks);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(e.message ?? 'Failed to fetch daily tasks');
    }
  }

  Future<({GoalModel goal, List<TaskModel> tasks})> getGoalRoadmap(String goalId) async {
    if (_localData.isGuestMode()) {
      final goals = _localData.getGoals();
      final goal = goals.firstWhere((g) => g.id == goalId, orElse: () => goals.first);
      final tasks = _localData.getTasks(goalId: goal.id);
      return (goal: goal, tasks: tasks);
    }

    try {
      final response = await _dio.get(ApiEndpoints.goalRoadmap(goalId));
      final goal = GoalModel.fromJson(response.data['goal'] as Map<String, dynamic>);
      final tasksJson = response.data['tasks'] as List<dynamic>? ?? [];
      final tasks = tasksJson.map((t) => TaskModel.fromJson(t as Map<String, dynamic>)).toList();
      return (goal: goal, tasks: tasks);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(e.message ?? 'Failed to fetch goal roadmap');
    }
  }

  Future<TaskModel> createTask({
    String? goalId,
    int? dayNumber,
    required String title,
    String? description,
    String? evidencePrompt,
  }) async {
    if (_localData.isGuestMode()) {
      return await _localData.createTask(
        goalId: goalId,
        dayNumber: dayNumber,
        title: title,
        description: description,
        evidencePrompt: evidencePrompt,
      );
    }

    try {
      final data = <String, dynamic>{
        'title': title.trim(),
      };
      if (goalId != null) data['goalId'] = goalId;
      if (dayNumber != null) data['dayNumber'] = dayNumber;
      if (description != null && description.trim().isNotEmpty) {
        data['description'] = description.trim();
      }
      if (evidencePrompt != null && evidencePrompt.trim().isNotEmpty) {
        data['evidencePrompt'] = evidencePrompt.trim();
      }

      final response = await _dio.post(ApiEndpoints.tasks, data: data);
      return TaskModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(e.message ?? 'Failed to create task');
    }
  }

  Future<TaskModel> updateTask(
    String taskId, {
    String? title,
    String? description,
    String? evidencePrompt,
  }) async {
    if (_localData.isGuestMode()) {
      return await _localData.updateTask(
        taskId,
        title: title,
        description: description,
        evidencePrompt: evidencePrompt,
      );
    }

    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title.trim();
      if (description != null) data['description'] = description.trim();
      if (evidencePrompt != null) data['evidencePrompt'] = evidencePrompt.trim();

      final response = await _dio.patch(ApiEndpoints.taskById(taskId), data: data);
      return TaskModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(e.message ?? 'Failed to update task');
    }
  }

  Future<void> deleteTask(String taskId) async {
    if (_localData.isGuestMode()) {
      await _localData.deleteTask(taskId);
      return;
    }

    try {
      await _dio.delete(ApiEndpoints.taskById(taskId));
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(e.message ?? 'Failed to delete task');
    }
  }
}
