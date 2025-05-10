import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../constants/app_constants.dart';
import '../utils/app_utils.dart';
import 'package:location/location.dart' as location;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final location.Location _location = location.Location();
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api';
  static String get _apiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  Future<bool> checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Konum servisi kapalı';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Konum izni reddedildi';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Konum izni kalıcı olarak reddedildi';
    }

    return true;
  }

  Future<LatLng> getCurrentLocation() async {
    await checkLocationPermission();
    final position = await Geolocator.getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }

  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    final url = Uri.parse(
      '$_baseUrl/place/textsearch/json?query=$query&key=$_apiKey',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['results']);
    } else {
      throw 'Yer arama başarısız: ${response.statusCode}';
    }
  }

  Future<List<Map<String, dynamic>>> getNearbyPlaces(
    LatLng location,
    String type, {
    int radius = 1500,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/place/nearbysearch/json'
      '?location=${location.latitude},${location.longitude}'
      '&radius=$radius'
      '&type=$type'
      '&key=$_apiKey',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['results']);
    } else {
      throw 'Yakındaki yerler bulunamadı: ${response.statusCode}';
    }
  }

  Future<Map<String, dynamic>> getPlaceDetails(String placeId) async {
    final url = Uri.parse(
      '$_baseUrl/place/details/json?place_id=$placeId&key=$_apiKey',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['result'];
    } else {
      throw 'Yer detayları alınamadı: ${response.statusCode}';
    }
  }

  Future<Map<String, dynamic>> getDistanceMatrix(
    LatLng origin,
    LatLng destination,
  ) async {
    final url = Uri.parse(
      '$_baseUrl/distancematrix/json'
      '?origins=${origin.latitude},${origin.longitude}'
      '&destinations=${destination.latitude},${destination.longitude}'
      '&key=$_apiKey',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['rows'][0]['elements'][0];
    } else {
      throw 'Mesafe hesaplanamadı: ${response.statusCode}';
    }
  }

  Future<Map<String, dynamic>> getDirections(
    LatLng origin,
    LatLng destination, {
    String mode = 'driving',
  }) async {
    final url = Uri.parse(
      '$_baseUrl/directions/json'
      '?origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '&mode=$mode'
      '&key=$_apiKey',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    } else {
      throw 'Rota oluşturulamadı: ${response.statusCode}';
    }
  }

  Future<String> getAddressFromCoordinates(LatLng location) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isEmpty) {
        throw AppConstants.errorMessages['location']!;
      }

      final place = placemarks.first;
      return '${place.street}, ${place.subLocality}, ${place.locality}, ${place.country}';
    } catch (e) {
      throw AppConstants.errorMessages['location']!;
    }
  }

  Future<List<Location>> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);

      if (locations.isEmpty) {
        throw AppConstants.errorMessages['location']!;
      }

      return locations;
    } catch (e) {
      throw AppConstants.errorMessages['location']!;
    }
  }

  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  String getFormattedDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    final distance = calculateDistance(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
    return AppUtils.getDistanceString(distance);
  }

  Future<Map<String, String>> getLocationInfo() async {
    try {
      final locationData = await _location.getLocation();
      final placemarks = await placemarkFromCoordinates(
        locationData.latitude!,
        locationData.longitude!,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return {
          'city': place.locality ?? 'Bilinmeyen Şehir',
          'country': place.country ?? 'Bilinmeyen Ülke',
          'street': place.street ?? 'Bilinmeyen Cadde',
        };
      }
    } catch (e) {
      print('Error getting location info: $e');
    }

    return {
      'city': 'Bilinmeyen Şehir',
      'country': 'Bilinmeyen Ülke',
      'street': 'Bilinmeyen Cadde',
    };
  }
} 