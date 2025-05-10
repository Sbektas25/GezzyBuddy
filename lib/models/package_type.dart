import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PackageField {
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final List<String>? options;
  final bool isRequired;

  const PackageField({
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.options,
    this.isRequired = true,
  });
}

class PackageType {
  final String title;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final double price;
  final List<String> preferences;
  final LatLng? locationLatLng;

  const PackageType({
    required this.title,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.price,
    required this.preferences,
    this.locationLatLng,
  });

  factory PackageType.fromMap(Map<String, dynamic> map) {
    return PackageType(
      title: map['title'] as String,
      location: map['location'] as String,
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      price: (map['price'] as num).toDouble(),
      preferences: List<String>.from(map['preferences'] as List),
      locationLatLng: map['locationLatLng'] != null
          ? LatLng(
              (map['locationLatLng'] as Map<String, dynamic>)['latitude'] as double,
              (map['locationLatLng'] as Map<String, dynamic>)['longitude'] as double,
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'location': location,
      'startDate': startDate,
      'endDate': endDate,
      'price': price,
      'preferences': preferences,
      'locationLatLng': locationLatLng != null
          ? {
              'latitude': locationLatLng!.latitude,
              'longitude': locationLatLng!.longitude,
            }
          : null,
    };
  }

  static final beachPackage = PackageType(
    title: 'Plaj & Deniz Gezi Planı',
    location: 'Konyaaltı',
    startDate: DateTime(2024, 5, 1),
    endDate: DateTime(2024, 5, 7),
    price: 1000.0,
    preferences: ['Yüzme', 'Dalış', 'Sörf', 'Tekne Turu'],
    locationLatLng: LatLng(36.8833, 30.7167),
  );

  static final culturalPackage = PackageType(
    title: 'Kültürel & Tarihi',
    location: 'Antalya',
    startDate: DateTime(2024, 5, 1),
    endDate: DateTime(2024, 5, 7),
    price: 1200.0,
    preferences: ['Antik Kent', 'Müze', 'Tarihi Yapı', 'Doğal Güzellik'],
    locationLatLng: LatLng(36.8833, 30.7167),
  );

  static PackageType fromTitle(String title) {
    switch (title) {
      case 'Plaj & Deniz Gezi Planı':
        return beachPackage;
      case 'Kültürel & Tarihi':
        return culturalPackage;
      default:
        throw Exception('Unknown package type: $title');
    }
  }
} 