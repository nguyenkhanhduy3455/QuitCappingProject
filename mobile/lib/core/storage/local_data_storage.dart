import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/domain/user_model.dart';
import '../../features/proof/data/submission_repository.dart';
import '../../features/proof/domain/submission_model.dart';
import '../../features/reviews/data/review_repository.dart';
import '../../features/reviews/domain/review_models.dart';
import '../../features/roadmap/domain/goal_model.dart';
import '../../features/roadmap/domain/task_model.dart';
import '../network/api_exception.dart';
import 'token_storage.dart';

final localDataStorageProvider = Provider<LocalDataStorage>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalDataStorage(prefs);
});

class LocalDataStorage {
  final SharedPreferences _prefs;

  static const String _guestModeKey = 'is_guest_mode';
  static const String _guestUserKey = 'guest_user_data';
  static const String _guestGoalsKey = 'guest_goals_data';
  static const String _guestTasksKey = 'guest_tasks_data';

  LocalDataStorage(this._prefs);

  bool isGuestMode() {
    return _prefs.getBool(_guestModeKey) ?? false;
  }

  Future<void> setGuestMode(bool isGuest) async {
    await _prefs.setBool(_guestModeKey, isGuest);
  }

  // --- Guest User Profile & Points ---
  UserModel getGuestUser() {
    final raw = _prefs.getString(_guestUserKey);
    if (raw != null) {
      try {
        return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }

    final defaultGuest = UserModel(
      id: 'guest_local_user',
      email: 'guest@device.local',
      displayName: 'Khách (Offline)',
      dailyReviewsDone: 5,
      streakCount: 1,
      quotaReached: true,
      points: 1000,
    );
    saveGuestUser(defaultGuest);
    return defaultGuest;
  }

  Future<void> saveGuestUser(UserModel user) async {
    await _prefs.setString(_guestUserKey, jsonEncode(user.toJson()));
  }

  Future<UserModel> updateGuestPoints(int delta) async {
    final user = getGuestUser();
    final newPoints = (user.points + delta).clamp(0, 999999);
    final updated = user.copyWith(points: newPoints);
    await saveGuestUser(updated);
    return updated;
  }

  // --- Initialize Starter Data if Empty ---
  Future<void> ensureInitialized() async {
    final goals = getGoals();
    if (goals.isEmpty) {
      final now = DateTime.now();
      final defaultGoal = GoalModel(
        id: 'guest_goal_starter',
        title: 'Tự học tiếng Anh giao tiếp 7 ngày',
        category: 'Academics',
        durationDays: 7,
        currentDay: 1,
        status: 'active',
        createdAt: now,
      );

      final starterTasks = [
        TaskModel(
          id: 'guest_task_1',
          goalId: defaultGoal.id,
          dayNumber: 1,
          title: 'Học 10 từ vựng chủ đề Daily Routine',
          description: 'Ghi chép 10 từ vựng và đặt câu ví dụ vào sổ tay học tập.',
          evidencePrompt: 'Chụp ảnh trang vở có ghi chép 10 từ vựng hôm nay.',
          isCompleted: false,
        ),
        TaskModel(
          id: 'guest_task_2',
          goalId: defaultGoal.id,
          dayNumber: 1,
          title: 'Luyện nghe podcast tiếng Anh 15 phút',
          description: 'Nghe 1 đoạn audio ngắn về giao tiếp hằng ngày và ghi lại 3 ý chính.',
          evidencePrompt: 'Chụp ảnh màn hình ứng dụng nghe podcast hoặc ghi chú tóm tắt.',
          isCompleted: false,
        ),
        TaskModel(
          id: 'guest_task_3',
          goalId: defaultGoal.id,
          dayNumber: 1,
          title: 'Thực hành phát âm Shadowing 10 phút',
          description: 'Nhại lại giọng người bản xứ theo 1 đoạn video ngắn trên YouTube.',
          evidencePrompt: 'Chụp ảnh màn hình bài luyện tập phát âm.',
          isCompleted: false,
        ),
        // Day 2
        TaskModel(
          id: 'guest_task_4',
          goalId: defaultGoal.id,
          dayNumber: 2,
          title: 'Học cách giới thiệu bản thân bằng tiếng Anh',
          description: 'Viết một đoạn giới thiệu ngắn gồm tên, nghề nghiệp, sở thích.',
          evidencePrompt: 'Chụp ảnh bài viết giới thiệu bản thân.',
          isCompleted: false,
        ),
        TaskModel(
          id: 'guest_task_5',
          goalId: defaultGoal.id,
          dayNumber: 2,
          title: 'Luyện tập trả lời 5 câu hỏi phỏng vấn cơ bản',
          description: 'Tự trả lời bằng tiếng Anh và ghi chú các từ khóa chính.',
          evidencePrompt: 'Chụp ảnh các câu trả lời đã chuẩn bị.',
          isCompleted: false,
        ),
      ];

      await saveGoals([defaultGoal]);
      await saveTasks(starterTasks);
    }
  }

  // --- Goals ---
  List<GoalModel> getGoals() {
    final raw = _prefs.getString(_guestGoalsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((g) => GoalModel.fromJson(g as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveGoals(List<GoalModel> goals) async {
    final list = goals.map((g) => g.toJson()).toList();
    await _prefs.setString(_guestGoalsKey, jsonEncode(list));
  }

  GoalModel? getActiveGoal() {
    final goals = getGoals();
    try {
      return goals.firstWhere((g) => g.isActive);
    } catch (_) {
      return goals.isNotEmpty ? goals.first : null;
    }
  }

  Future<GoalModel> createGoal({
    required String title,
    required String category,
    required String currentSkillLevel,
    required int durationDays,
  }) async {
    final user = getGuestUser();
    if (user.points < 500) {
      throw ApiException('Bạn không đủ điểm! Cần 500 điểm để tạo mục tiêu.');
    }

    // Deduct 500 points
    await updateGuestPoints(-500);

    final goalId = 'guest_goal_${DateTime.now().millisecondsSinceEpoch}';
    final newGoal = GoalModel(
      id: goalId,
      title: title,
      category: category,
      durationDays: durationDays,
      currentDay: 1,
      status: 'active',
      createdAt: DateTime.now(),
    );

    final currentGoals = getGoals();
    final updatedGoals = [newGoal, ...currentGoals];
    await saveGoals(updatedGoals);

    // Generate local micro-tasks for the duration
    final generatedTasks = <TaskModel>[];
    for (int day = 1; day <= durationDays; day++) {
      generatedTasks.add(
        TaskModel(
          id: 'guest_task_${goalId}_d${day}_1',
          goalId: goalId,
          dayNumber: day,
          title: '$title - Bước $day.1: Nắm bắt kiến thức trọng tâm',
          description: 'Nghiên cứu tài liệu và hoàn thành phần lý thuyết ngày $day cho mục tiêu $title.',
          evidencePrompt: 'Chụp ảnh tài liệu học tập hoặc sản phẩm hoàn thành trong ngày.',
          isCompleted: false,
        ),
      );
      generatedTasks.add(
        TaskModel(
          id: 'guest_task_${goalId}_d${day}_2',
          goalId: goalId,
          dayNumber: day,
          title: '$title - Bước $day.2: Thực hành ứng dụng thực tế',
          description: 'Thực hành ít nhất 25 phút bài tập ứng dụng cho ngày $day ($currentSkillLevel).',
          evidencePrompt: 'Chụp ảnh màn hình làm bài hoặc nhật ký ghi nhận kết quả.',
          isCompleted: false,
        ),
      );
    }

    final currentTasks = getTasks();
    await saveTasks([...generatedTasks, ...currentTasks]);

    return newGoal;
  }

  // --- Tasks ---
  List<TaskModel> getTasks({String? goalId, int? dayNumber}) {
    final raw = _prefs.getString(_guestTasksKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      var tasks = list.map((t) => TaskModel.fromJson(t as Map<String, dynamic>)).toList();
      if (goalId != null && goalId.isNotEmpty) {
        tasks = tasks.where((t) => t.goalId == goalId).toList();
      }
      if (dayNumber != null) {
        tasks = tasks.where((t) => t.dayNumber == dayNumber).toList();
      }
      return tasks;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTasks(List<TaskModel> tasks) async {
    final list = tasks.map((t) => t.toJson()).toList();
    await _prefs.setString(_guestTasksKey, jsonEncode(list));
  }

  Future<TaskModel> createTask({
    String? goalId,
    int? dayNumber,
    required String title,
    String? description,
    String? evidencePrompt,
  }) async {
    final activeGoal = getActiveGoal();
    final gId = goalId ?? activeGoal?.id ?? 'guest_default_goal';
    final dNum = dayNumber ?? 1;

    final newTask = TaskModel(
      id: 'guest_task_${DateTime.now().millisecondsSinceEpoch}',
      goalId: gId,
      dayNumber: dNum,
      title: title,
      description: description ?? '',
      evidencePrompt: evidencePrompt ?? 'Chụp ảnh hoàn thành công việc',
      isCompleted: false,
    );

    final currentTasks = getTasks();
    await saveTasks([newTask, ...currentTasks]);
    return newTask;
  }

  Future<TaskModel> updateTask(
    String taskId, {
    String? title,
    String? description,
    String? evidencePrompt,
  }) async {
    final tasks = getTasks();
    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) {
      throw ApiException('Không tìm thấy nhiệm vụ để cập nhật.');
    }

    final existing = tasks[index];
    final updated = existing.copyWith(
      title: title ?? existing.title,
      description: description ?? existing.description,
      evidencePrompt: evidencePrompt ?? existing.evidencePrompt,
    );

    tasks[index] = updated;
    await saveTasks(tasks);
    return updated;
  }

  Future<void> deleteTask(String taskId) async {
    final tasks = getTasks();
    tasks.removeWhere((t) => t.id == taskId);
    await saveTasks(tasks);
  }

  // --- Submissions (Proof Submission in Guest Mode) ---
  Future<SubmissionResult> submitProof({
    required String taskId,
    String? imageUrl,
  }) async {
    final tasks = getTasks();
    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) {
      throw ApiException('Không tìm thấy nhiệm vụ để nộp bằng chứng.');
    }

    final now = DateTime.now();
    final submissionId = 'guest_sub_${now.millisecondsSinceEpoch}';
    final proofUrl = imageUrl ??
        'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=800&auto=format&fit=crop&q=80';

    final submissionSummary = TaskSubmissionSummary(
      id: submissionId,
      imageUrl: proofUrl,
      status: 'approved',
      upvotes: 3,
      downvotes: 0,
      createdAt: now,
    );

    final updatedTask = tasks[index].copyWith(
      isCompleted: true,
      latestSubmission: submissionSummary,
    );
    tasks[index] = updatedTask;
    await saveTasks(tasks);

    // Reward +10 points to guest user
    await updateGuestPoints(10);

    final submissionModel = SubmissionModel(
      id: submissionId,
      taskId: taskId,
      userId: 'guest_local_user',
      imageUrl: proofUrl,
      status: 'approved',
      upvotes: 3,
      downvotes: 0,
      createdAt: now,
    );

    return SubmissionResult(
      submission: submissionModel,
      dailyReviewsDone: 5,
      reviewsNeededToQueue: 0,
      isUnlockedInQueue: true,
      message: 'Bằng chứng đã được lưu trên máy! Hoàn thành nhiệm vụ +10 điểm.',
    );
  }

  // --- Peer Review Feed in Guest Mode ---
  List<BlindReviewCard> getDemoReviewFeed() {
    return [
      BlindReviewCard(
        submissionId: 'guest_demo_sub_1',
        taskId: 'guest_demo_t_1',
        taskTitle: 'Đọc 10 trang sách Phát triển bản thân',
        taskDescription: 'Đọc và ghi chú lại ý tưởng tâm đắc nhất.',
        evidencePrompt: 'Chụp ảnh cuốn sách mở tại trang vừa đọc.',
        imageUrl: 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=800&auto=format&fit=crop&q=80',
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
        isOwnSubmission: false,
        upvotes: 2,
        downvotes: 0,
        totalReviews: 2,
      ),
      BlindReviewCard(
        submissionId: 'guest_demo_sub_2',
        taskId: 'guest_demo_t_2',
        taskTitle: 'Chạy bộ 3km buổi sáng',
        taskDescription: 'Duy trì nhịp chạy đều và chụp lại ứng dụng Strava.',
        evidencePrompt: 'Ảnh chụp màn hình lộ trình 3km từ Strava.',
        imageUrl: 'https://images.unsplash.com/photo-1502680390469-be75c86b636f?w=800&auto=format&fit=crop&q=80',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        isOwnSubmission: false,
        upvotes: 1,
        downvotes: 0,
        totalReviews: 1,
      ),
      BlindReviewCard(
        submissionId: 'guest_demo_sub_3',
        taskId: 'guest_demo_t_3',
        taskTitle: 'Thực hành giải 1 bài toán LeetCode Medium',
        taskDescription: 'Giải bằng Python hoặc Dart và pass 100% test case.',
        evidencePrompt: 'Ảnh chụp màn hình Accepted trên LeetCode.',
        imageUrl: 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=800&auto=format&fit=crop&q=80',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        isOwnSubmission: false,
        upvotes: 4,
        downvotes: 0,
        totalReviews: 4,
      ),
    ];
  }

  Future<SubmitReviewResult> submitReviewVote({
    required String submissionId,
    required bool isApproved,
  }) async {
    // Reward +5 points to guest user
    await updateGuestPoints(5);

    return SubmitReviewResult(
      message: 'Đã ghi nhận đánh giá của bạn! (+5 điểm)',
      currentUpvotes: isApproved ? 3 : 1,
      currentDownvotes: isApproved ? 0 : 2,
      submissionStatus: isApproved ? 'approved' : 'rejected',
      dailyReviewsDone: 5,
      quotaReached: true,
      unlockedSubmissionsCount: 1,
    );
  }
}
