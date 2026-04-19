class PlanReading {
  final int bookNumber;
  final String bookName;
  final int chapter;

  const PlanReading({
    required this.bookNumber,
    required this.bookName,
    required this.chapter,
  });

  Map<String, dynamic> toJson() => {
        'bookNumber': bookNumber,
        'bookName': bookName,
        'chapter': chapter,
      };

  factory PlanReading.fromJson(Map<String, dynamic> json) => PlanReading(
        bookNumber: json['bookNumber'] as int,
        bookName: json['bookName'] as String,
        chapter: json['chapter'] as int,
      );
}

class ReadingPlan {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int totalDays;
  final List<List<PlanReading>> dailyReadings;

  const ReadingPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.totalDays,
    required this.dailyReadings,
  });
}

class PlanProgress {
  final String planId;
  final DateTime startDate;
  final Set<int> completedDays;

  PlanProgress({
    required this.planId,
    required this.startDate,
    Set<int>? completedDays,
  }) : completedDays = completedDays ?? {};

  int get currentDay {
    final diff = DateTime.now().difference(startDate).inDays;
    return diff + 1; // 1-based
  }

  double get progressPercent {
    if (completedDays.isEmpty) return 0;
    return completedDays.length / _totalDays;
  }

  // This gets set externally when we know the plan
  int _totalDays = 1;
  void setTotalDays(int total) => _totalDays = total;

  Map<String, dynamic> toJson() => {
        'planId': planId,
        'startDate': startDate.toIso8601String(),
        'completedDays': completedDays.toList(),
      };

  factory PlanProgress.fromJson(Map<String, dynamic> json) => PlanProgress(
        planId: json['planId'] as String,
        startDate: DateTime.parse(json['startDate'] as String),
        completedDays: (json['completedDays'] as List).map((e) => e as int).toSet(),
      );
}
