import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  final String apiKey;

  PlacesService({required this.apiKey});

  Future<List<PlacePrediction>> searchPlaces(String query) async {
    if (query.isEmpty) return [];

    final url = Uri.parse(
      '$_baseUrl/autocomplete/json?input=$query&components=country:tr&key=$apiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return (data['predictions'] as List)
              .map((prediction) => PlacePrediction.fromJson(prediction))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error searching places: $e');
      return [];
    }
  }

  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    final url = Uri.parse(
      '$_baseUrl/details/json?place_id=$placeId&fields=name,formatted_address,geometry&key=$apiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return PlaceDetails.fromJson(data['result']);
        }
      }
      return null;
    } catch (e) {
      print('Error getting place details: $e');
      return null;
    }
  }
}

class PlacePrediction {
  final String placeId;
  final String description;

  PlacePrediction({
    required this.placeId,
    required this.description,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      placeId: json['place_id'],
      description: json['description'],
    );
  }
}

class PlaceDetails {
  final String name;
  final String formattedAddress;
  final LatLng location;

  PlaceDetails({
    required this.name,
    required this.formattedAddress,
    required this.location,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry']['location'];
    return PlaceDetails(
      name: json['name'],
      formattedAddress: json['formatted_address'],
      location: LatLng(
        geometry['lat'],
        geometry['lng'],
      ),
    );
  }
} 