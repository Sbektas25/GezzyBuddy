import 'package:flutter/material.dart';

class Package {
  final String id;
  final String name;
  final String description;
  final double price;
  final List<String> features;
  final String imageUrl;
  final int duration; // in days

  Package({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.features,
    required this.imageUrl,
    required this.duration,
  });

  factory Package.fromJson(Map<String, dynamic> json) {
    return Package(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      features: List<String>.from(json['features'] as List),
      imageUrl: json['imageUrl'] as String,
      duration: json['duration'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'features': features,
      'imageUrl': imageUrl,
      'duration': duration,
    };
  }
} 