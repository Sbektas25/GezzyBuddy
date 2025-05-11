import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'activity.dart';

class DayPlan {
  final int dayIndex;
  final String title;
  final int numberOfDays;
  final String location;
  final List<Activity> activities;

  DayPlan({
    required this.dayIndex,
    required this.title,
    required this.numberOfDays,
    required this.location,
    required this.activities,
  });

  factory DayPlan.fromJson(Map<String, dynamic> json) {
    return DayPlan(
      dayIndex: json['dayIndex'] as int,
      title: json['title'] as String,
      numberOfDays: json['numberOfDays'] as int,
      location: json['location'] as String,
      activities: (json['activities'] as List)
          .map((e) => Activity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayIndex': dayIndex,
      'title': title,
      'numberOfDays': numberOfDays,
      'location': location,
      'activities': activities.map((e) => e.toJson()).toList(),
    };
  }

  DayPlan copyWith({
    int? dayIndex,
    String? title,
    int? numberOfDays,
    String? location,
    List<Activity>? activities,
  }) {
    return DayPlan(
      dayIndex: dayIndex ?? this.dayIndex,
      title: title ?? this.title,
      numberOfDays: numberOfDays ?? this.numberOfDays,
      location: location ?? this.location,
      activities: activities ?? this.activities,
    );
  }
} 