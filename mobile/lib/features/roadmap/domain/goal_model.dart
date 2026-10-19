class GoalModel {
  final String id;
  final String title;
  final String category;
  final int durationDays;
  final int currentDay;
  final String status;

  GoalModel({
    required this.id,
    required this.title,
    required this.category,
    required this.durationDays,
    required this.currentDay,
    required this.status,
  });

  bool get isActive => status == 'active';
  double get progress => durationDays > 0 ? (currentDay / durationDays).clamp(0.0, 1.0) : 0.0;
  int get percent => (progress * 100).round();

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      durationDays: json['durationDays'] ?? 30,
      currentDay: json['currentDay'] ?? 1,
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'durationDays': durationDays,
      'currentDay': currentDay,
      'status': status,
    };
  }
}
