import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:math';

enum TimeSlot {
  morning,
  afternoon,
  evening,
  night,
  breakfast,
  lunch,
  beach,
  dinner,
  cafe,
  bar,
  returnHome,
}

enum ActivityType {
  start,
  end,
  breakfast,
  lunch,
  dinner,
  beach,
  cafe,
  bar,
  night,
}

class Activity {
  final String id;
  final String placeId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String photoUrl;
  final double rating;
  final int reviews;
  final DateTime startTime;
  final DateTime endTime;
  final TimeSlot timeSlot;
  final String? description;
  final double? price;
  final List<String> tags;
  final ActivityType? type;
  final int? travelDurationSec;

  Activity({
    required this.id,
    required this.placeId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.photoUrl,
    required this.rating,
    required this.reviews,
    required this.startTime,
    required this.endTime,
    required this.timeSlot,
    this.description,
    this.price,
    this.tags = const [],
    this.type,
    this.travelDurationSec,
  });

  /// helper to plug into markers/polylines
  LatLng get position => LatLng(latitude, longitude);
  LatLng get location => LatLng(latitude, longitude);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'placeId': placeId,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'photoUrl': photoUrl,
      'rating': rating,
      'reviews': reviews,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'timeSlot': timeSlot.toString(),
      'description': description,
      'price': price,
      'tags': tags,
      'type': type?.toString(),
      'travelDurationSec': travelDurationSec,
    };
  }

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      placeId: json['placeId'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      photoUrl: json['photoUrl'] as String,
      rating: (json['rating'] as num).toDouble(),
      reviews: json['reviews'] as int,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      timeSlot: TimeSlot.values.firstWhere(
        (e) => e.toString() == json['timeSlot'],
      ),
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      type: json['type'] != null
          ? ActivityType.values.firstWhere(
              (e) => e.toString() == json['type'],
            )
          : null,
      travelDurationSec: json['travelDurationSec'] as int?,
    );
  }

  factory Activity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Activity(
      id: data['id'] as String,
      placeId: data['placeId'] as String,
      name: data['name'] as String,
      address: data['address'] as String,
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      photoUrl: data['photoUrl'] as String,
      rating: (data['rating'] as num).toDouble(),
      reviews: data['reviews'] as int,
      startTime: DateTime.fromMillisecondsSinceEpoch(data['startTime'] as int),
      endTime: DateTime.fromMillisecondsSinceEpoch(data['endTime'] as int),
      timeSlot: TimeSlot.values.firstWhere(
        (e) => e.toString() == data['timeSlot'],
      ),
      description: data['description'] as String?,
      price: (data['price'] as num?)?.toDouble(),
      tags: (data['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      type: data['type'] != null
          ? ActivityType.values.firstWhere(
              (e) => e.toString() == data['type'],
            )
          : null,
      travelDurationSec: data['travelDurationSec'] as int?,
    );
  }

  Activity copyWith({
    String? id,
    String? placeId,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? photoUrl,
    double? rating,
    int? reviews,
    DateTime? startTime,
    DateTime? endTime,
    TimeSlot? timeSlot,
    String? description,
    double? price,
    List<String>? tags,
    ActivityType? type,
    int? travelDurationSec,
  }) {
    return Activity(
      id: id ?? this.id,
      placeId: placeId ?? this.placeId,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photoUrl: photoUrl ?? this.photoUrl,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      timeSlot: timeSlot ?? this.timeSlot,
      description: description ?? this.description,
      price: price ?? this.price,
      tags: tags ?? this.tags,
      type: type ?? this.type,
      travelDurationSec: travelDurationSec ?? this.travelDurationSec,
    );
  }
} 