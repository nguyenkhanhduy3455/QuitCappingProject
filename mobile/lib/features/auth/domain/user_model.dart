class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final int dailyReviewsDone;
  final int streakCount;
  final bool quotaReached;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    required this.dailyReviewsDone,
    required this.streakCount,
    required this.quotaReached,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      avatarUrl: json['avatarUrl'],
      dailyReviewsDone: json['dailyReviewsDone'] ?? 0,
      streakCount: json['streakCount'] ?? 0,
      quotaReached: json['quotaReached'] ?? ((json['dailyReviewsDone'] ?? 0) >= 5),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'dailyReviewsDone': dailyReviewsDone,
      'streakCount': streakCount,
      'quotaReached': quotaReached,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    int? dailyReviewsDone,
    int? streakCount,
    bool? quotaReached,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dailyReviewsDone: dailyReviewsDone ?? this.dailyReviewsDone,
      streakCount: streakCount ?? this.streakCount,
      quotaReached: quotaReached ?? this.quotaReached,
    );
  }
}
