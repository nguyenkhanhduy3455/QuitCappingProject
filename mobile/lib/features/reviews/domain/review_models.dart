class BlindReviewCard {
  final String submissionId;
  final String taskId;
  final String taskTitle;
  final String taskDescription;
  final String evidencePrompt;
  final String imageUrl;
  final DateTime createdAt;
  final bool isOwnSubmission;

  BlindReviewCard({
    required this.submissionId,
    required this.taskId,
    required this.taskTitle,
    required this.taskDescription,
    required this.evidencePrompt,
    required this.imageUrl,
    required this.createdAt,
    this.isOwnSubmission = false,
  });

  String get cleanTaskTitle {
    return taskTitle.replaceFirst(RegExp(r'^(Day|Ngày)\s*\d+:\s*', caseSensitive: false), '').trim();
  }

  factory BlindReviewCard.fromJson(Map<String, dynamic> json) {
    return BlindReviewCard(
      submissionId: json['submissionId'] ?? '',
      taskId: json['taskId'] ?? '',
      taskTitle: json['taskTitle'] ?? '',
      taskDescription: json['taskDescription'] ?? '',
      evidencePrompt: json['evidencePrompt'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isOwnSubmission: json['isOwnSubmission'] ?? false,
    );
  }
}

class ReviewQuotaStatus {
  final int dailyReviewsDone;
  final int targetQuota;
  final bool quotaReached;
  final int remainingToQuota;
  final int pendingProofsLocked;
  final int inQueueProofsActive;
  final int availableToReviewCount;
  final bool bypassQuotaActive;
  final int streakCount;

  ReviewQuotaStatus({
    required this.dailyReviewsDone,
    required this.targetQuota,
    required this.quotaReached,
    required this.remainingToQuota,
    required this.pendingProofsLocked,
    required this.inQueueProofsActive,
    this.availableToReviewCount = 0,
    this.bypassQuotaActive = false,
    required this.streakCount,
  });

  factory ReviewQuotaStatus.fromJson(Map<String, dynamic> json) {
    return ReviewQuotaStatus(
      dailyReviewsDone: json['dailyReviewsDone'] ?? 0,
      targetQuota: json['targetQuota'] ?? 5,
      quotaReached: json['quotaReached'] ?? false,
      remainingToQuota: json['remainingToQuota'] ?? 5,
      pendingProofsLocked: json['pendingProofsLocked'] ?? 0,
      inQueueProofsActive: json['inQueueProofsActive'] ?? 0,
      availableToReviewCount: json['availableToReviewCount'] ?? 0,
      bypassQuotaActive: json['bypassQuotaActive'] ?? false,
      streakCount: json['streakCount'] ?? 0,
    );
  }
}
