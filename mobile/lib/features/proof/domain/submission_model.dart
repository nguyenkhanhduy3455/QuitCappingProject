class SubmissionModel {
  final String id;
  final String taskId;
  final String userId;
  final String imageUrl;
  final String status;
  final int upvotes;
  final int downvotes;
  final DateTime createdAt;

  SubmissionModel({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.imageUrl,
    required this.status,
    required this.upvotes,
    required this.downvotes,
    required this.createdAt,
  });

  factory SubmissionModel.fromJson(Map<String, dynamic> json) {
    return SubmissionModel(
      id: json['_id'] ?? json['id'] ?? '',
      taskId: json['taskId'] is Map ? json['taskId']['_id'] : json['taskId'] ?? '',
      userId: json['userId'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      status: json['status'] ?? 'pending_quota',
      upvotes: json['upvotes'] ?? 0,
      downvotes: json['downvotes'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }
}
