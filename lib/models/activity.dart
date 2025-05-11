import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:uuid/uuid.dart';
import 'activity_type.dart';
import 'time_slot.dart';
import '../config/api_keys.dart';

class Activity {
  final String id;
  final String placeId;
  final String name;
  final LatLng position;
  final List<String> tags;
  final ActivityType type;
  final DateTime startTime;
  final DateTime endTime;
  final TimeSlot timeSlot;
  final String? photoUrl;
  final int reviews;
  final double rating;
  final double price;
  final int travelDurationSec;
  final String address;

  Activity({
    required this.id,
    required this.placeId,
    required this.name,
    required this.position,
    required this.tags,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.timeSlot,
    this.photoUrl,
    required this.reviews,
    required this.rating,
    required this.price,
    required this.travelDurationSec,
    required this.address,
  });

  Activity copyWith({
    String? id,
    String? placeId,
    String? name,
    LatLng? position,
    List<String>? tags,
    ActivityType? type,
    DateTime? startTime,
    DateTime? endTime,
    TimeSlot? timeSlot,
    String? photoUrl,
    int? reviews,
    double? rating,
    double? price,
    int? travelDurationSec,
    String? address,
  }) {
    return Activity(
      id: id ?? this.id,
      placeId: placeId ?? this.placeId,
      name: name ?? this.name,
      position: position ?? this.position,
      tags: tags ?? this.tags,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      timeSlot: timeSlot ?? this.timeSlot,
      photoUrl: photoUrl ?? this.photoUrl,
      reviews: reviews ?? this.reviews,
      rating: rating ?? this.rating,
      price: price ?? this.price,
      travelDurationSec: travelDurationSec ?? this.travelDurationSec,
      address: address ?? this.address,
    );
  }

  factory Activity.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>;
    final location = geometry['location'] as Map<String, dynamic>;
    
    return Activity(
      id: json['id'] as String? ?? const Uuid().v4(),
      placeId: json['place_id'] as String,
      name: json['name'] as String,
      position: LatLng(
        (location['lat'] as num).toDouble(),
        (location['lng'] as num).toDouble(),
      ),
      tags: List<String>.from(json['types'] ?? []),
      type: _getActivityTypeFromString(json['timeSlot'] as String?),
      startTime: DateTime.parse(json['start'] as String),
      endTime: DateTime.parse(json['end'] as String),
      timeSlot: _getTimeSlotFromString(json['timeSlot'] as String?),
      photoUrl: (json['photos'] as List?)?.isNotEmpty == true
          ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${(json['photos'] as List).first['photo_reference']}&key=${ApiKeys.googlePlacesApiKey}'
          : null,
      reviews: (json['user_ratings_total'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      price: (json['price_level'] as num?)?.toDouble() ?? 0.0,
      travelDurationSec: (json['travel_duration_sec'] as num?)?.toInt() ?? 0,
      address: json['vicinity'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'place_id': placeId,
      'name': name,
      'vicinity': address,
      'geometry': {
        'location': {
          'lat': position.latitude,
          'lng': position.longitude,
        },
      },
      'types': tags,
      'timeSlot': timeSlot.toString(),
      'start': startTime.toIso8601String(),
      'end': endTime.toIso8601String(),
      'photos': photoUrl != null ? [{'photo_reference': photoUrl}] : null,
      'user_ratings_total': reviews,
      'rating': rating,
      'price_level': price,
      'travel_duration_sec': travelDurationSec,
    };
  }

  static ActivityType _getActivityTypeFromString(String? typeStr) {
    if (typeStr == null) return ActivityType.start;
    try {
      return ActivityType.values.firstWhere(
        (e) => e.toString() == 'ActivityType.$typeStr',
        orElse: () => ActivityType.start,
      );
    } catch (e) {
      return ActivityType.start;
    }
  }

  static TimeSlot _getTimeSlotFromString(String? slotStr) {
    if (slotStr == null) return TimeSlot.morning;
    try {
      return TimeSlot.values.firstWhere(
        (e) => e.toString() == 'TimeSlot.$slotStr',
        orElse: () => TimeSlot.morning,
      );
    } catch (e) {
      return TimeSlot.morning;
    }
  }
} 