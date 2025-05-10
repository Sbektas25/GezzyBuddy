import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'activity.dart';
import 'package:flutter/material.dart';

class ItineraryItem {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime startTime;
  final DateTime endTime;
  final String type;
  final double? price;
  final double? rating;
  final String? photoUrl;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double? distance;
  final int? travelDurationSec;

  ItineraryItem({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.price,
    this.rating,
    this.photoUrl,
    this.address,
    this.latitude,
    this.longitude,
    this.distance,
    this.travelDurationSec,
  });

  LatLng? get locationLatLng =>
      (latitude != null && longitude != null) ? LatLng(latitude!, longitude!) : null;

  int? get travelDurationToNext => travelDurationSec != null ? (travelDurationSec! ~/ 60) : null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'location': location,
    'startTime': Timestamp.fromDate(startTime),
    'endTime': Timestamp.fromDate(endTime),
    'price': price,
    'rating': rating,
    'photoUrl': photoUrl,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'distance': distance,
    'type': type,
    'travelDurationSec': travelDurationSec,
  };

  factory ItineraryItem.fromJson(Map<String, dynamic> json) => ItineraryItem(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    location: json['location'] as String,
    startTime: (json['startTime'] as Timestamp).toDate(),
    endTime: (json['endTime'] as Timestamp).toDate(),
    price: json['price'] as double?,
    rating: json['rating'] as double?,
    photoUrl: json['photoUrl'] as String?,
    address: json['address'] as String?,
    latitude: json['latitude'] as double?,
    longitude: json['longitude'] as double?,
    distance: json['distance'] as double?,
    type: json['type'] as String,
    travelDurationSec: json['travelDurationSec'] as int?,
  );

  factory ItineraryItem.fromMap(Map<String, dynamic> map) {
    return ItineraryItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      startTime: parseDate(map['startTime']),
      endTime: parseDate(map['endTime']),
      price: map['price'] as double?,
      rating: map['rating'] as double?,
      photoUrl: map['photoUrl'] as String?,
      address: map['address'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      distance: map['distance'] as double?,
      type: map['type'] ?? '',
      travelDurationSec: map['travelDurationSec'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'price': price,
      'rating': rating,
      'photoUrl': photoUrl,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'type': type,
      'travelDurationSec': travelDurationSec,
    };
  }

  ItineraryItem copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    double? price,
    double? rating,
    String? photoUrl,
    String? address,
    double? latitude,
    double? longitude,
    double? distance,
    String? type,
    int? travelDurationSec,
  }) {
    return ItineraryItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      price: price ?? this.price,
      rating: rating ?? this.rating,
      photoUrl: photoUrl ?? this.photoUrl,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distance: distance ?? this.distance,
      type: type ?? this.type,
      travelDurationSec: travelDurationSec ?? this.travelDurationSec,
    );
  }
}

class Itinerary {
  final String id;
  final String title;
  final String location;
  final int numberOfDays;
  final List<String> preferences;
  final DateTime startDate;
  final DateTime endDate;
  final List<ItineraryItem> items;
  final String? accommodationLocation;
  final String? userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Itinerary({
    required this.id,
    required this.title,
    required this.location,
    required this.numberOfDays,
    required this.preferences,
    required this.startDate,
    required this.endDate,
    required this.items,
    this.accommodationLocation,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory Itinerary.fromMap(Map<String, dynamic> map) {
    String locationString;
    final locationData = map['location'];
    if (locationData is String) {
      locationString = locationData;
    } else if (locationData is Map) {
      final lat = locationData['latitude'] ?? '';
      final lng = locationData['longitude'] ?? '';
      locationString = '$lat,$lng';
    } else {
      locationString = '';
    }

    String? accommodationLocationString;
    final accommodationLocationData = map['accommodationLocation'];
    if (accommodationLocationData is String) {
      accommodationLocationString = accommodationLocationData;
    } else if (accommodationLocationData is Map) {
      final lat = accommodationLocationData['latitude'] ?? '';
      final lng = accommodationLocationData['longitude'] ?? '';
      accommodationLocationString = '$lat,$lng';
    } else {
      accommodationLocationString = null;
    }

    return Itinerary(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      location: locationString,
      numberOfDays: map['numberOfDays'] ?? 0,
      preferences: List<String>.from(map['preferences'] ?? []),
      startDate: parseDate(map['startDate']),
      endDate: parseDate(map['endDate']),
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => ItineraryItem.fromMap(item))
              .toList() ??
          [],
      accommodationLocation: accommodationLocationString,
      userId: map['userId'],
      createdAt: map['createdAt'] != null ? parseDate(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'numberOfDays': numberOfDays,
      'preferences': preferences,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'items': items.map((item) => item.toMap()).toList(),
      'accommodationLocation': accommodationLocation,
      'userId': userId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  Itinerary copyWith({
    String? id,
    String? title,
    String? location,
    int? numberOfDays,
    List<String>? preferences,
    DateTime? startDate,
    DateTime? endDate,
    List<ItineraryItem>? items,
    String? accommodationLocation,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Itinerary(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      numberOfDays: numberOfDays ?? this.numberOfDays,
      preferences: preferences ?? this.preferences,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      items: items ?? this.items,
      accommodationLocation: accommodationLocation ?? this.accommodationLocation,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

DateTime parseDate(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  } else if (value is String) {
    return DateTime.parse(value);
  } else if (value is DateTime) {
    return value;
  } else {
    throw Exception('Geçersiz tarih formatı: $value');
  }
} 