import 'reading_plan.dart';

class CustomPlan {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int totalDays;
  final List<List<PlanReading>> dailyReadings;
  final DateTime createdAt;

  CustomPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.totalDays,
    required this.dailyReadings,
    required this.createdAt,
  });

  ReadingPlan toReadingPlan() => ReadingPlan(
        id: id,
        title: title,
        description: description,
        icon: icon,
        totalDays: totalDays,
        dailyReadings: dailyReadings,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'icon': icon,
        'totalDays': totalDays,
        'dailyReadings': dailyReadings
            .map((day) => day.map((r) => r.toJson()).toList())
            .toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory CustomPlan.fromJson(Map<String, dynamic> json) {
    final days = (json['dailyReadings'] as List).map((day) {
      return (day as List)
          .map((r) => PlanReading.fromJson(r as Map<String, dynamic>))
          .toList();
    }).toList();

    return CustomPlan(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String? ?? '📋',
      totalDays: json['totalDays'] as int,
      dailyReadings: days,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
