
class ApiEndpoints {
  static String get baseUrl {
    // With `adb reverse tcp:3005 tcp:3005`, 127.0.0.1:3005 forwards over USB directly to Mac host
    return 'http://127.0.0.1:3005';
  }

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';

  // Goals
  static const String goals = '/goals';
  static const String activeGoal = '/goals/active';
  static String goalRoadmap(String goalId) => '/goals/$goalId/roadmap';

  // Tasks
  static const String dailyTasks = '/tasks/daily';
  static String taskById(String taskId) => '/tasks/$taskId';

  // Submissions
  static const String submissions = '/submissions';
  static const String mySubmissions = '/submissions/me';
  static String submissionById(String id) => '/submissions/$id';

  // Reviews & Give-to-Get
  static const String reviewFeed = '/reviews/feed';
  static const String submitReview = '/reviews';
  static const String reviewQuota = '/reviews/quota';
}
