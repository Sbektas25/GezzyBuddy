import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/itinerary.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Auth Token
  Future<void> saveAuthToken(String token) async {
    await _prefs.setString(AppConstants.prefKeys['authToken']!, token);
  }

  String? getAuthToken() {
    return _prefs.getString(AppConstants.prefKeys['authToken']!);
  }

  Future<void> clearAuthToken() async {
    await _prefs.remove(AppConstants.prefKeys['authToken']!);
  }

  // User Email
  Future<void> saveUserEmail(String email) async {
    await _prefs.setString(AppConstants.prefKeys['userEmail']!, email);
  }

  String? getUserEmail() {
    return _prefs.getString(AppConstants.prefKeys['userEmail']!);
  }

  Future<void> clearUserEmail() async {
    await _prefs.remove(AppConstants.prefKeys['userEmail']!);
  }

  // Last Location
  Future<void> saveLastLocation(double latitude, double longitude) async {
    await _prefs.setString(
      AppConstants.prefKeys['lastLocation']!,
      jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
      }),
    );
  }

  Map<String, double>? getLastLocation() {
    final locationStr = _prefs.getString(AppConstants.prefKeys['lastLocation']!);
    if (locationStr == null) return null;

    try {
      final location = jsonDecode(locationStr) as Map<String, dynamic>;
      return {
        'latitude': location['latitude'] as double,
        'longitude': location['longitude'] as double,
      };
    } catch (e) {
      return null;
    }
  }

  Future<void> clearLastLocation() async {
    await _prefs.remove(AppConstants.prefKeys['lastLocation']!);
  }

  // Saved Plans
  Future<void> savePlan(Itinerary plan) async {
    final plans = getSavedPlans();
    plans.add(plan);
    await _prefs.setString(
      AppConstants.prefKeys['savedPlans']!,
      jsonEncode(plans.map((p) => p.toJson()).toList()),
    );
  }

  List<Itinerary> getSavedPlans() {
    final plansStr = _prefs.getString(AppConstants.prefKeys['savedPlans']!);
    if (plansStr == null) return [];

    try {
      final List<dynamic> plans = jsonDecode(plansStr);
      return plans.map((p) => Itinerary.fromJson(p)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> deletePlan(String planId) async {
    final plans = getSavedPlans();
    plans.removeWhere((plan) => plan.id == planId);
    await _prefs.setString(
      AppConstants.prefKeys['savedPlans']!,
      jsonEncode(plans.map((p) => p.toJson()).toList()),
    );
  }

  Future<void> clearSavedPlans() async {
    await _prefs.remove(AppConstants.prefKeys['savedPlans']!);
  }

  // Clear All Data
  Future<void> clearAll() async {
    await _prefs.clear();
  }
} 