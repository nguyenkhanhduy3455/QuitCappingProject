class TaskSubmissionSummary {
  final String id;
  final String imageUrl;
  final String status;
  final int upvotes;
  final int downvotes;
  final DateTime? createdAt;

  TaskSubmissionSummary({
    required this.id,
    required this.imageUrl,
    required this.status,
    required this.upvotes,
    required this.downvotes,
    this.createdAt,
  });

  factory TaskSubmissionSummary.fromJson(Map<String, dynamic> json) {
    return TaskSubmissionSummary(
      id: json['id'] ?? json['_id'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      status: json['status'] ?? 'pending_quota',
      upvotes: json['upvotes'] ?? 0,
      downvotes: json['downvotes'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }
}

class TaskModel {
  final String id;
  final String goalId;
  final int dayNumber;
  final String title;
  final String description;
  final String evidencePrompt;
  final bool isCompleted;
  final TaskSubmissionSummary? latestSubmission;

  TaskModel({
    required this.id,
    required this.goalId,
    required this.dayNumber,
    required this.title,
    required this.description,
    required this.evidencePrompt,
    required this.isCompleted,
    this.latestSubmission,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? json['_id'] ?? '',
      goalId: json['goalId'] ?? '',
      dayNumber: json['dayNumber'] ?? 1,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      evidencePrompt: json['evidencePrompt'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
      latestSubmission: json['latestSubmission'] != null
          ? TaskSubmissionSummary.fromJson(json['latestSubmission'] as Map<String, dynamic>)
          : null,
    );
  }

  String get cleanTitle => title.replaceAll(RegExp(r'^(Day|Ngày)\s*\d+[\s:\-–—]+', caseSensitive: false), '').trim();

  bool get hasSubmittedEvidence => latestSubmission != null || isCompleted;

  TaskModel copyWith({
    String? id,
    String? goalId,
    int? dayNumber,
    String? title,
    String? description,
    String? evidencePrompt,
    bool? isCompleted,
    TaskSubmissionSummary? latestSubmission,
  }) {
    return TaskModel(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      dayNumber: dayNumber ?? this.dayNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      evidencePrompt: evidencePrompt ?? this.evidencePrompt,
      isCompleted: isCompleted ?? this.isCompleted,
      latestSubmission: latestSubmission ?? this.latestSubmission,
    );
  }
}
