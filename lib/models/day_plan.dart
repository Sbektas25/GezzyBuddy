import 'activity.dart';

class DayPlan {
  final DateTime date;
  final List<Activity> activities;

  DayPlan({
    required this.date,
    required this.activities,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'activities': activities.map((a) => a.toJson()).toList(),
    };
  }

  factory DayPlan.fromJson(Map<String, dynamic> json) {
    return DayPlan(
      date: DateTime.parse(json['date'] as String),
      activities: (json['activities'] as List)
          .map((a) => Activity.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
} 