import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/itinerary.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity.dart';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/directions_service.dart';
import '../services/places_service.dart';
import 'package:uuid/uuid.dart';
import '../models/day_plan.dart';
import '../services/plan_service.dart';
import './auth_provider.dart' as app_auth;
import '../models/time_slot.dart';
import 'package:google_maps_flutter_platform_interface/src/types/location.dart';

class PlanProvider with ChangeNotifier {
  final PlanService planService;
  List<DayPlan> plans = [];

  PlanProvider({ required this.planService });

  Future<void> createPlan({
    required String location,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> preferences,
  }) async {
    plans = await planService.generatePlan(
      location: location,
      startDate: startDate,
      endDate: endDate,
      preferences: preferences,
    );
    notifyListeners();
  }
} 