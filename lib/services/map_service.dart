import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../constants/app_constants.dart';
import '../models/itinerary.dart';
import 'location_service.dart';
import 'package:geocoding/geocoding.dart';

class MapService {
  static final MapService _instance = MapService._internal();
  factory MapService() => _instance;
  MapService._internal();

  final LocationService _locationService = LocationService();
  static String get _apiKey {
    final key = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('Google Maps API anahtarı bulunamadı!');
    }
    return key;
  }
  static const _baseUrl = 'https://maps.googleapis.com/maps/api';

  Future<Map<String, dynamic>> getRouteInfo(Map<String, String> locationInfo) async {
    try {
      final origin = locationInfo['street']! + ', ' + locationInfo['city']! + ', ' + locationInfo['country']!;
      final destination = locationInfo['city']! + ', ' + locationInfo['country']!;

      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$_apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final route = data['routes'][0]['legs'][0];
          return {
            'distance': route['distance']['text'],
            'duration': route['duration']['text'],
            'startLocation': route['start_location'],
            'endLocation': route['end_location'],
          };
        }
      }
    } catch (e) {
      print('Error getting route info: $e');
    }

    return {
      'distance': 'Bilinmeyen',
      'duration': 'Bilinmeyen',
      'startLocation': {'lat': 0.0, 'lng': 0.0},
      'endLocation': {'lat': 0.0, 'lng': 0.0},
    };
  }

  Future<LatLng?> geocodeAddress(String address) async {
    try {
      final List<Location> locations = await locationFromAddress(address);
      
      if (locations.isEmpty) {
        throw Exception('Adres bulunamadı');
      }
      
      return LatLng(locations.first.latitude, locations.first.longitude);
    } catch (e) {
      print('Geocoding hatası: $e');
      return null;
    }
  }

  Future<Map<String, String>?> getRoute(LatLng origin, LatLng dest) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/directions/json?'
          'origin=${origin.latitude},${origin.longitude}'
          '&destination=${dest.latitude},${dest.longitude}'
          '&mode=driving'
          '&language=tr'
          '&key=$_apiKey'
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final route = data['routes'][0]['legs'][0];
          return {
            'mesafe': route['distance']['text'],
            'süre': route['duration']['text'],
            'talimatlar': route['steps']
                .map((step) => step['html_instructions'])
                .join('\n'),
          };
        }
      }
      throw Exception('Rota hesaplanamadı');
    } catch (e) {
      print('Rota hesaplama hatası: $e');
      return null;
    }
  }

  Future<List<String>> getSuggestions(String query) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/place/autocomplete/json?'
          'input=$query'
          '&language=tr'
          '&components=country:tr'
          '&key=$_apiKey'
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return (data['predictions'] as List)
              .map((p) => p['description'] as String)
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Öneri alma hatası: $e');
      return [];
    }
  }

  Future<List<Marker>> getMarkers(Itinerary itinerary) async {
    final List<Marker> markers = [];
    int markerId = 0;

    for (final item in itinerary.items) {
      final LatLng? position = await geocodeAddress(item.location);
      if (position != null) {
        markers.add(
          Marker(
            markerId: MarkerId('marker_${markerId++}'),
            position: position,
            infoWindow: InfoWindow(
              title: item.title,
              snippet: item.description,
            ),
          ),
        );
      }
    }

    return markers;
  }

  Future<List<Polyline>> getRoutes(Itinerary itinerary) async {
    final List<Polyline> polylines = [];
    int polylineId = 0;

    for (int i = 0; i < itinerary.items.length - 1; i++) {
      final LatLng? origin = await geocodeAddress(itinerary.items[i].location);
      final LatLng? destination = await geocodeAddress(itinerary.items[i + 1].location);

      if (origin != null && destination != null) {
        final response = await http.get(
          Uri.parse(
            'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$_apiKey',
          ),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK') {
            final points = _decodePolyline(data['routes'][0]['overview_polyline']['points']);
            polylines.add(
              Polyline(
                polylineId: PolylineId('polyline_${polylineId++}'),
                points: points,
                color: const Color(0xFF0000FF),
                width: 5,
              ),
            );
          }
        }
      }
    }

    return polylines;
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  Set<Marker> getMarkersForItinerary(Itinerary itinerary) {
    final markers = <Marker>{};
    for (final item in itinerary.items) {
      if (item.latitude != null && item.longitude != null) {
        markers.add(
          Marker(
            markerId: MarkerId(item.id),
            position: LatLng(item.latitude!, item.longitude!),
            infoWindow: InfoWindow(
              title: item.title,
              snippet: item.description,
            ),
          ),
        );
      }
    }
    return markers;
  }

  Set<Polyline> getRoutesForItinerary(Itinerary itinerary) {
    final polylines = <Polyline>{};
    final items = itinerary.items;
    for (var i = 0; i < items.length - 1; i++) {
      final currentItem = items[i];
      final nextItem = items[i + 1];
      if (currentItem.latitude != null && currentItem.longitude != null &&
          nextItem.latitude != null && nextItem.longitude != null) {
        polylines.add(
          Polyline(
            polylineId: PolylineId('${currentItem.id}_${nextItem.id}'),
            points: [
              LatLng(currentItem.latitude!, currentItem.longitude!),
              LatLng(nextItem.latitude!, nextItem.longitude!),
            ],
            color: Colors.blue,
            width: 3,
          ),
        );
      }
    }
    return polylines;
  }

  LatLngBounds getBoundsForItinerary(Itinerary itinerary) {
    double minLat = 90.0;
    double maxLat = -90.0;
    double minLng = 180.0;
    double maxLng = -180.0;

    for (final item in itinerary.items) {
      if (item.latitude != null && item.longitude != null) {
        minLat = item.latitude! < minLat ? item.latitude! : minLat;
        maxLat = item.latitude! > maxLat ? item.latitude! : maxLat;
        minLng = item.longitude! < minLng ? item.longitude! : minLng;
        maxLng = item.longitude! > maxLng ? item.longitude! : maxLng;
      }
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Future<Map<String, dynamic>> getDirections(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=$startLat,$startLng'
          '&destination=$endLat,$endLng'
          '&key=${AppConstants.apiKeys['googleMaps']}',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          return {
            'distance': leg['distance']['text'],
            'duration': leg['duration']['text'],
            'steps': leg['steps'].map((step) {
              return {
                'instruction': step['html_instructions'],
                'distance': step['distance']['text'],
                'duration': step['duration']['text'],
              };
            }).toList(),
          };
        }
      }
      throw AppConstants.errorMessages['location']!;
    } catch (e) {
      throw AppConstants.errorMessages['location']!;
    }
  }

  Future<List<LatLng>> getPolylinePoints(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=$startLat,$startLng'
          '&destination=$endLat,$endLng'
          '&key=${AppConstants.apiKeys['googleMaps']}',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          final points = <LatLng>[];
          final route = data['routes'][0];
          final leg = route['legs'][0];

          for (final step in leg['steps']) {
            final polyline = step['polyline']['points'];
            points.addAll(_decodePolyline(polyline));
          }

          return points;
        }
      }
      throw AppConstants.errorMessages['location']!;
    } catch (e) {
      throw AppConstants.errorMessages['location']!;
    }
  }

  Future<List<LatLng>> getRouteForDay(Itinerary itinerary, int dayIndex) async {
    List<LatLng> route = [];
    final items = itinerary.items;
    final itemsPerDay = (items.length / itinerary.numberOfDays).ceil();
    final startIndex = dayIndex * itemsPerDay;
    final endIndex = (startIndex + itemsPerDay).clamp(0, items.length);
    
    if (startIndex >= items.length) return route;

    final dayItems = items.sublist(startIndex, endIndex);
    for (int i = 0; i < dayItems.length - 1; i++) {
      final current = dayItems[i];
      final next = dayItems[i + 1];
      if (current.latitude != null && current.longitude != null &&
          next.latitude != null && next.longitude != null) {
        final start = LatLng(current.latitude!, current.longitude!);
        final end = LatLng(next.latitude!, next.longitude!);
        final path = await getRouteBetweenPoints(start, end);
        route.addAll(path);
      }
    }

    return route;
  }

  Future<Map<String, List<LatLng>>> getAllRoutes(Itinerary itinerary) async {
    Map<String, List<LatLng>> routes = {};

    for (int i = 0; i < itinerary.numberOfDays; i++) {
      final route = await getRouteForDay(itinerary, i);
      routes['Day ${i + 1}'] = route;
    }

    return routes;
  }

  List<LatLng> getAllLocations(Itinerary itinerary) {
    List<LatLng> locations = [];

    for (final item in itinerary.items) {
      if (item.latitude != null && item.longitude != null) {
        locations.add(LatLng(item.latitude!, item.longitude!));
      }
    }

    return locations;
  }

  Future<List<LatLng>> getRouteBetweenPoints(LatLng start, LatLng end) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${start.latitude},${start.longitude}'
          '&destination=${end.latitude},${end.longitude}'
          '&key=$_apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          final List<LatLng> points = [];
          final route = data['routes'][0]['overview_polyline']['points'];
          final decodedPoints = _decodePolyline(route);
          
          for (var point in decodedPoints) {
            points.add(point);
          }
          
          return points;
        }
      }
      
      return [start, end];
    } catch (e) {
      print('Error getting route: $e');
      return [start, end];
    }
  }

  List<List<double>> decodePolyline(String encoded) {
    List<List<double>> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add([lat * 1e-5, lng * 1e-5]);
    }

    return poly;
  }
} 