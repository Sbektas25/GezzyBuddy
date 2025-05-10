import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/itinerary.dart';
import '../utils/app_utils.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String _baseUrl = 'http://10.0.2.2:3000/api';
  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<void> setAuthToken(String token) {
    _headers['Authorization'] = 'Bearer $token';
    return Future.value();
  }

  Future<void> clearAuthToken() {
    _headers.remove('Authorization');
    return Future.value();
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      throw AppConstants.errorMessages['network']!;
    }
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      throw AppConstants.errorMessages['network']!;
    }
  }

  Future<Itinerary> generatePlan({
    required String packageType,
    required DateTime startDate,
    required DateTime endDate,
    required int numberOfPeople,
    required Map<String, dynamic> preferences,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/plans/generate'),
        headers: _headers,
        body: jsonEncode({
          'package_type': packageType,
          'start_date': AppUtils.formatDate(startDate),
          'end_date': AppUtils.formatDate(endDate),
          'number_of_people': numberOfPeople,
          'preferences': preferences,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Itinerary.fromJson(data);
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      throw AppConstants.errorMessages['planCreation']!;
    }
  }

  Future<List<Map<String, dynamic>>> getNearbyPlaces({
    required double latitude,
    required double longitude,
    required String type,
    required int radius,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/places/nearby?lat=$latitude&lng=$longitude&type=$type&radius=$radius',
        ),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      throw AppConstants.errorMessages['location']!;
    }
  }

  Future<Map<String, dynamic>> getPlaceDetails(String placeId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/places/$placeId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      throw AppConstants.errorMessages['location']!;
    }
  }

  Future<List<Map<String, dynamic>>> getSavedPlans() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/plans'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      throw AppConstants.errorMessages['network']!;
    }
  }

  Future<void> savePlan(Itinerary plan) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/plans'),
        headers: _headers,
        body: jsonEncode(plan.toJson()),
      );

      if (response.statusCode != 201) {
        throw _handleError(response);
      }
    } catch (e) {
      throw AppConstants.errorMessages['planCreation']!;
    }
  }

  Future<void> deletePlan(String planId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/plans/$planId'),
        headers: _headers,
      );

      if (response.statusCode != 204) {
        throw _handleError(response);
      }
    } catch (e) {
      throw AppConstants.errorMessages['network']!;
    }
  }

  String _handleError(http.Response response) {
    try {
      final error = jsonDecode(response.body);
      return error['message'] ?? AppConstants.errorMessages['network']!;
    } catch (e) {
      return AppConstants.errorMessages['network']!;
    }
  }
} 