import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/storage/local_data_storage.dart';
import 'package:dio/dio.dart';
import 'package:mobile/features/roadmap/data/goal_repository.dart';
import 'package:mobile/features/proof/data/submission_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Guest Mode & Local Data Storage Tests', () {
    late SharedPreferences prefs;
    late LocalDataStorage localData;
    late GoalRepository goalRepo;
    late SubmissionRepository submissionRepo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      localData = LocalDataStorage(prefs);
      goalRepo = GoalRepository(Dio(), localData);
      submissionRepo = SubmissionRepository(Dio(), localData);
    });

    test('Initial guest mode is false, activating enables guest data and 1000 points', () async {
      expect(localData.isGuestMode(), isFalse);

      await localData.setGuestMode(true);
      expect(localData.isGuestMode(), isTrue);

      await localData.ensureInitialized();

      final user = localData.getGuestUser();
      expect(user.points, 1000);
      expect(user.displayName, contains('Khách'));

      final goals = await goalRepo.getUserGoals();
      expect(goals, isNotEmpty);
      expect(goals.first.title, contains('tiếng Anh'));

      final tasks = await goalRepo.getDailyTasks(goalId: goals.first.id, dayNumber: 1);
      expect(tasks.length, 3);
    });

    test('Guest can create and update tasks locally', () async {
      await localData.setGuestMode(true);
      await localData.ensureInitialized();

      final newTask = await goalRepo.createTask(
        title: 'Chạy bộ 5km',
        description: 'Tập chạy quanh công viên',
        evidencePrompt: 'Chụp ảnh giày chạy bộ',
      );

      expect(newTask.title, 'Chạy bộ 5km');
      expect(newTask.isCompleted, isFalse);

      final updatedTask = await goalRepo.updateTask(
        newTask.id,
        title: 'Chạy bộ 10km',
      );
      expect(updatedTask.title, 'Chạy bộ 10km');

      await goalRepo.deleteTask(newTask.id);
      final tasks = await goalRepo.getDailyTasks();
      expect(tasks.any((t) => t.id == newTask.id), isFalse);
    });

    test('Guest can submit proof and earn +10 points locally', () async {
      await localData.setGuestMode(true);
      await localData.ensureInitialized();

      final tasks = await goalRepo.getDailyTasks();
      final taskToSubmit = tasks.first;

      final initialPoints = localData.getGuestUser().points;
      final result = await submissionRepo.submitProof(
        taskId: taskToSubmit.id,
        imageUrl: 'https://example.com/test_proof.jpg',
      );

      expect(result.submission.status, 'approved');
      expect(localData.getGuestUser().points, initialPoints + 10);

      final refreshedTasks = await goalRepo.getDailyTasks();
      final submittedTask = refreshedTasks.firstWhere((t) => t.id == taskToSubmit.id);
      expect(submittedTask.isCompleted, isTrue);
      expect(submittedTask.latestSubmission, isNotNull);
    });

    test('Creating a goal in guest mode deducts 500 points', () async {
      await localData.setGuestMode(true);
      await localData.ensureInitialized();

      final userBefore = localData.getGuestUser();
      expect(userBefore.points, 1000);

      final newGoal = await goalRepo.createGoal(
        title: 'Học lập trình Flutter',
        category: 'Coding',
        currentSkillLevel: 'Beginner',
        durationDays: 7,
      );

      expect(newGoal.title, 'Học lập trình Flutter');
      final userAfter = localData.getGuestUser();
      expect(userAfter.points, 500);

      final tasks = await goalRepo.getDailyTasks(goalId: newGoal.id, dayNumber: 1);
      expect(tasks, isNotEmpty);
    });
  });
}
