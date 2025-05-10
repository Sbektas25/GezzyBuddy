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

class PlanProvider with ChangeNotifier {
  final PlanService _planService;
  final app_auth.AuthProvider _authProvider;
  final _uuid = const Uuid();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _baseUrl = 'http://10.0.2.2:3001/api';
  List<Itinerary> _plans = [];
  bool _isLoading = false;
  String? _error;
  String? _planError;
  Itinerary? _currentPlan;
  Itinerary? _itinerary;
  DocumentSnapshot? _lastDocument;
  static const int _pageSize = 10;
  bool _hasMore = true;
  List<Activity> _activities = [];
  List<DayPlan> _generatedPlan = [];

  // Gün bazlı planlama desteği
  int _currentDay = 0;
  final List<List<Activity>> _dailyPlans = [];
  int get currentDay => _currentDay;
  int get totalDays => 3; // örnek: 3 günlük paket

  PlanProvider({
    required PlanService planService,
    required app_auth.AuthProvider authProvider,
  })  : _planService = planService,
        _authProvider = authProvider;

  List<Itinerary> get plans => _plans;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get planError => _planError;
  Itinerary? get currentPlan => _currentPlan;
  Itinerary? get itinerary => _itinerary;
  bool get hasMore => _hasMore;
  List<Activity> get activities => _activities;
  List<DayPlan> get generatedPlan => _generatedPlan;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void clearError() {
    _setError(null);
  }

  int _getActivityDurationMinutes(String activityName) {
    final name = activityName.toLowerCase();
    if (name.contains('kahvaltı') || name.contains('restoran') || name.contains('kafe') || name.contains('bar')) {
      return 60;
    } else if (name.contains('plaj') || name.contains('yüzme')) {
      return 360;
    } else if (name.contains('müze') || name.contains('tarihi') || name.contains('cami') || name.contains('kale') || name.contains('açıkhava')) {
      return 90;
    } else {
      return 60;
    }
  }

  Future<void> fetchActivities({
    required LatLng hotelLocation,
    required DateTime tripStart,
    required DateTime tripEnd,
    required List<String> userPrefs,
    required String accommodationName,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _generatedPlan = await _planService.generatePlan(
        location: hotelLocation,
        startTime: tripStart,
        endTime: tripEnd,
        preferences: userPrefs,
        accommodationName: accommodationName,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<List<LatLng>> _generateActivityLocations(List<String> preferences, LatLng baseLocation) async {
    // Bu fonksiyon gerçek uygulamada Places API'den lokasyonları alacak
    return List.generate(
      preferences.length,
      (index) => LatLng(
        baseLocation.latitude + (index * 0.01),
        baseLocation.longitude + (index * 0.01),
      ),
    );
  }

  Future<List<Activity>> _getActivities({
    required String type,
    required List<String> preferences,
    required LatLng location,
  }) async {
    // Önce tipi eşleşen aktiviteleri çek
    final snapshot = await _db
        .collection('activities')
        .where('type', isEqualTo: type)
        .get();

    // Tercihlere uyan aktiviteler
    final preferredActivities = snapshot.docs
        .map((doc) => Activity.fromFirestore(doc))
        .where((activity) => preferences.any((pref) => activity.tags.contains(pref)))
        .toList();

    if (preferredActivities.isNotEmpty) {
      preferredActivities.sort((a, b) {
        final distanceA = _calculateDistance(
          location,
          LatLng(a.latitude ?? 0, a.longitude ?? 0),
        );
        final distanceB = _calculateDistance(
          location,
          LatLng(b.latitude ?? 0, b.longitude ?? 0),
        );
        return distanceA.compareTo(distanceB);
      });
      return preferredActivities;
    }

    // Eğer tercihlere uyan yoksa, tipten bağımsız en yakın aktiviteleri getir
    final allSnapshot = await _db.collection('activities').get();
    final allActivities = allSnapshot.docs
        .map((doc) => Activity.fromFirestore(doc))
        .toList();
    allActivities.sort((a, b) {
      final distanceA = _calculateDistance(
        location,
        LatLng(a.latitude ?? 0, a.longitude ?? 0),
      );
      final distanceB = _calculateDistance(
        location,
        LatLng(b.latitude ?? 0, b.longitude ?? 0),
      );
      return distanceA.compareTo(distanceB);
    });
    // En azından 5 aktivite öner
    return allActivities.take(5).toList();
  }

  Future<List<Activity>> _getActivitiesRelaxed({
    required String type,
    required LatLng location,
  }) async {
    // Sadece type'a bakan, tercihlere bakmayan gevşek filtre
    final snapshot = await _db
        .collection('activities')
        .where('type', isEqualTo: type)
        .get();
    final activities = snapshot.docs
        .map((doc) => Activity.fromFirestore(doc))
        .toList();
    activities.sort((a, b) {
      final distanceA = _calculateDistance(
        location,
        LatLng(a.latitude ?? 0, a.longitude ?? 0),
      );
      final distanceB = _calculateDistance(
        location,
        LatLng(b.latitude ?? 0, b.longitude ?? 0),
      );
      return distanceA.compareTo(distanceB);
    });
    return activities;
  }

  Future<List<Activity>> _getAnyActivities({
    required LatLng location,
  }) async {
    // Hiçbir filtre olmadan, en yakın 5 aktivite
    final allSnapshot = await _db.collection('activities').get();
    final allActivities = allSnapshot.docs
        .map((doc) => Activity.fromFirestore(doc))
        .toList();
    allActivities.sort((a, b) {
      final distanceA = _calculateDistance(
        location,
        LatLng(a.latitude ?? 0, a.longitude ?? 0),
      );
      final distanceB = _calculateDistance(
        location,
        LatLng(b.latitude ?? 0, b.longitude ?? 0),
      );
      return distanceA.compareTo(distanceB);
    });
    return allActivities.take(5).toList();
  }

  List<Activity> _createDayPlan({
    required List<Activity> activities,
    required DateTime date,
    required double dailyBudget,
  }) {
    final List<Activity> dayActivities = [];
    double remainingBudget = dailyBudget;

    _addActivitiesForTimeSlot(
      activities: activities,
      timeSlot: TimeSlot.morning,
      maxBudget: remainingBudget,
      result: dayActivities,
    );
    remainingBudget -= dayActivities.fold(0.0, (sum, a) => sum + (a.price ?? 0));

    _addActivitiesForTimeSlot(
      activities: activities,
      timeSlot: TimeSlot.afternoon,
      maxBudget: remainingBudget,
      result: dayActivities,
    );
    remainingBudget -= dayActivities.fold(0.0, (sum, a) => sum + (a.price ?? 0));

    _addActivitiesForTimeSlot(
      activities: activities,
      timeSlot: TimeSlot.evening,
      maxBudget: remainingBudget,
      result: dayActivities,
    );

    return dayActivities;
  }

  void _addActivitiesForTimeSlot({
    required List<Activity> activities,
    required TimeSlot timeSlot,
    required double maxBudget,
    required List<Activity> result,
  }) {
    final timeSlotActivities = activities
        .where((a) => 
            a.timeSlot == timeSlot && 
            (a.price ?? 0) <= maxBudget &&
            !result.contains(a))
        .take(2)
        .toList();
    
    result.addAll(timeSlotActivities);
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // metre cinsinden dünya yarıçapı
    
    final lat1 = point1.latitude * (pi / 180);
    final lat2 = point2.latitude * (pi / 180);
    final dLat = (point2.latitude - point1.latitude) * (pi / 180);
    final dLon = (point2.longitude - point1.longitude) * (pi / 180);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _calculateTotalDistance(List<DayPlan> days) {
    double total = 0;
    
    for (var day in days) {
      for (int i = 0; i < day.activities.length - 1; i++) {
        total += _calculateDistance(
          LatLng(day.activities[i].latitude, day.activities[i].longitude),
          LatLng(day.activities[i + 1].latitude, day.activities[i + 1].longitude),
        );
      }
    }
    
    return total;
  }

  double _calculateTotalPrice(List<DayPlan> days) {
    return days.fold(0.0, (total, day) => 
      total + day.activities.fold(0.0, (sum, activity) => sum + (activity.price ?? 0)));
  }

  Future<void> _savePlan() async {
    try {
      if (_currentPlan == null) return;

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('Oturum açmanız gerekiyor');
      }

      final planData = _currentPlan!.toMap();
      planData['userId'] = userId;
      planData['createdAt'] = FieldValue.serverTimestamp();
      planData['updatedAt'] = FieldValue.serverTimestamp();

      await _db.collection('plans').doc(_currentPlan!.id).set(planData);

      _itinerary = _currentPlan;
    } catch (e) {
      throw Exception('Plan kaydedilirken bir hata oluştu: $e');
    }
  }

  Future<void> loadPlan(String planId) async {
    try {
      _setLoading(true);
      _setError(null);

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('Oturum açmanız gerekiyor');
      }

      final doc = await _db
          .collection('plans')
          .doc(planId)
          .get();

      if (!doc.exists) {
        throw Exception('Plan bulunamadı');
      }

      _itinerary = Itinerary.fromMap(doc.data()!);
      notifyListeners();

    } catch (e) {
      _setError('Plan yüklenirken bir hata oluştu: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updatePlanDetails(Itinerary plan) async {
    if (_itinerary == null) return;

    try {
      _setLoading(true);
      _setError(null);

      final updatedPlan = _itinerary!.copyWith(
        title: plan.title,
        startDate: plan.startDate,
        endDate: plan.endDate,
        items: plan.items,
      );

      await FirebaseFirestore.instance
          .collection('plans')
          .doc(_itinerary!.id)
          .update(updatedPlan.toMap());

      _itinerary = updatedPlan;
      notifyListeners();
    } catch (e) {
      _setError('Plan güncellenirken bir hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deletePlanById(String id) async {
    if (_itinerary == null) return;

    try {
      _setLoading(true);
      _setError(null);

      await FirebaseFirestore.instance
          .collection('itineraries')
          .doc(_itinerary!.id)
          .delete();

      _itinerary = null;
      notifyListeners();
    } catch (e) {
      _setError('Plan silinirken bir hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadPlans() async {
    try {
      _isLoading = true;
      _error = null;
      _lastDocument = null;
      _hasMore = true;
      notifyListeners();

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final querySnapshot = await _db
          .collection('plans')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(_pageSize)
          .get();

      _plans = querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Itinerary.fromMap(data);
          })
          .toList();

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
      }

      _hasMore = querySnapshot.docs.length == _pageSize;
      print('Planlar yüklendi: ${_plans.length} adet plan bulundu');
    } catch (e) {
      _error = e.toString();
      print('Plan yükleme hatası: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMorePlans() async {
    if (!_hasMore || _isLoading) return;

    try {
      _isLoading = true;
      notifyListeners();

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final querySnapshot = await _db
          .collection('plans')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_pageSize)
          .get();

      final newPlans = querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Itinerary.fromMap(data);
          })
          .toList();

      _plans.addAll(newPlans);

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
      }

      _hasMore = querySnapshot.docs.length == _pageSize;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> savePlan(Itinerary plan) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final planData = plan.toMap();
      planData['userId'] = userId;
      planData['createdAt'] = FieldValue.serverTimestamp();
      planData['updatedAt'] = FieldValue.serverTimestamp();

      await _db.collection('plans').add(planData);

      // Yeni planı listeye ekle
      _plans.insert(0, plan);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePlan(String planId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _db.collection('plans').doc(planId).delete();

      // Planı listeden kaldır
      _plans.removeWhere((plan) => plan.id == planId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Stream<List<Itinerary>> getPlansStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _db
        .collection('plans')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return Itinerary.fromMap(data);
            })
            .toList());
  }

  List<Activity> getDayPlan(int dayIndex) {
    return _dailyPlans[dayIndex];
  }

  /// Firestore'dan, `tags` alanında herhangi biri geçen aktiviteleri getirir.
  Future<List<Activity>> fetchActivitiesByTags(List<String> tags) async {
    if (tags.isEmpty) return [];
    final query = FirebaseFirestore.instance
      .collection('activities')
      .where('tags', arrayContainsAny: tags)
      .limit(200);
    final snap = await query.get();
    return snap.docs
      .map((d) => Activity.fromJson(d.data() as Map<String, dynamic>))
      .toList();
  }

  Future<void> generateNextDayPlan(DateTime date, double budget, List<String> prefs, LatLng homeBase) async {
    if (_currentDay >= totalDays) return;
    // Firestore'dan sadece seçilen tercihlere uygun aktiviteleri çek
    final allActivities = await fetchActivitiesByTags(prefs);
    final dayActivities = allActivities.take(5).toList();
    // En baş ve sonda konaklama lokasyonunu ekle
    final start = Activity(
      id: 'start_${date.millisecondsSinceEpoch}',
      placeId: 'start_${date.millisecondsSinceEpoch}',
      name: 'Konaklama',
      address: 'Konaklama lokasyonu',
      latitude: homeBase.latitude,
      longitude: homeBase.longitude,
      photoUrl: '',
      rating: 0,
      reviews: 0,
      startTime: DateTime(date.year, date.month, date.day, 9, 0),
      endTime: DateTime(date.year, date.month, date.day, 9, 0),
      timeSlot: TimeSlot.morning,
      description: 'Konaklama lokasyonu',
      price: 0,
      tags: ['konaklama'],
      type: ActivityType.start,
    );
    final end = Activity(
      id: 'end_${date.millisecondsSinceEpoch}',
      placeId: 'end_${date.millisecondsSinceEpoch}',
      name: 'Konaklama',
      address: 'Konaklama lokasyonu',
      latitude: homeBase.latitude,
      longitude: homeBase.longitude,
      photoUrl: '',
      rating: 0,
      reviews: 0,
      startTime: DateTime(date.year, date.month, date.day, 23, 0),
      endTime: DateTime(date.year, date.month, date.day, 23, 0),
      timeSlot: TimeSlot.night,
      description: 'Konaklama lokasyonu',
      price: 0,
      tags: ['konaklama'],
      type: ActivityType.end,
    );
    final plan = [start, ...dayActivities, end];
    _dailyPlans.add(plan);
    _currentDay++;
    notifyListeners();
  }

  /// Akıllı gezi planı algoritması (Google Places API ile, kriterlere göre)
  Future<List<Activity>> generateSmartTripPlan({
    required LatLng accommodation,
    required DateTime startTime,
    required DateTime endTime,
    required bool wantsBreakfast,
    required bool wantsLunch,
    required bool wantsDinner,
    required bool wantsBeach,
    required bool wantsCafe,
    required bool wantsBar,
    required List<String> userPrefs,
  }) async {
    // 1. Konaklama lokasyonunda ve kullanıcının belirlediği saatte başla
    List<Activity> plan = [];
    LatLng currentLocation = accommodation;
    DateTime currentTime = startTime;

    // 2. Kahvaltı
    if (wantsBreakfast) {
      final breakfastPlace = await findBestBreakfastPlace(
        near: currentLocation,
      );
      plan.add(breakfastPlace);
      currentLocation = LatLng(breakfastPlace.latitude, breakfastPlace.longitude);
      currentTime = currentTime.add(const Duration(hours: 1));
    }

    // 3. Plaj
    if (wantsBeach) {
      final beach = await findBestPlace(
        near: currentLocation,
        type: 'beach',
      );
      plan.add(beach);
      currentLocation = LatLng(beach.latitude, beach.longitude);
      currentTime = currentTime.add(const Duration(hours: 3));
    }

    // 4. Öğlen Yemeği
    if (wantsLunch) {
      final lunchPlace = await findBestPlace(
        near: currentLocation,
        type: 'restaurant',
        excludeTypes: ['otel', 'motel', 'hostel', 'pansiyon'],
      );
      plan.add(lunchPlace);
      currentLocation = LatLng(lunchPlace.latitude, lunchPlace.longitude);
      currentTime = currentTime.add(const Duration(hours: 1));
    }

    // 5. Akşam Yemeği
    if (wantsDinner) {
      final dinnerPlace = await findBestPlace(
        near: currentLocation,
        type: 'restaurant',
        excludeTypes: ['otel', 'motel', 'hostel', 'pansiyon'],
      );
      plan.add(dinnerPlace);
      currentLocation = LatLng(dinnerPlace.latitude, dinnerPlace.longitude);
      currentTime = currentTime.add(const Duration(hours: 1));
    }

    // 6. Kafe
    if (wantsCafe) {
      final cafe = await findBestPlace(
        near: currentLocation,
        type: 'cafe',
      );
      plan.add(cafe);
      currentLocation = LatLng(cafe.latitude, cafe.longitude);
      currentTime = currentTime.add(const Duration(hours: 1));
    }

    // 7. Bar
    if (wantsBar) {
      final bar = await findBestPlace(
        near: currentLocation,
        type: 'bar',
      );
      plan.add(bar);
      currentLocation = LatLng(bar.latitude, bar.longitude);
      currentTime = currentTime.add(const Duration(hours: 1));
    }

    // 8. Dönüş (Konaklama)
    plan.add(Activity(
      id: 'end',
      placeId: 'end',
      name: 'Konaklama',
      address: 'Konaklama lokasyonu',
      latitude: accommodation.latitude,
      longitude: accommodation.longitude,
      photoUrl: '',
      rating: 0,
      reviews: 0,
      startTime: currentTime,
      endTime: currentTime,
      timeSlot: TimeSlot.night,
      description: 'Konaklama lokasyonu',
      price: 0,
      tags: ['konaklama'],
      type: ActivityType.end,
    ));

    return plan;
  }

  Future<Activity> findBestPlace({
    required LatLng near,
    String? type,
    List<String>? excludeTypes,
    bool freeOnly = false,
  }) async {
    return Activity(
      id: _uuid.v4(),
      placeId: 'dummy_place_id',
      name: 'Sample Place',
      address: 'Sample Address',
      latitude: near.latitude,
      longitude: near.longitude,
      photoUrl: '',
      rating: 4.5,
      reviews: 100,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(const Duration(hours: 2)),
      timeSlot: TimeSlot.morning,
      description: 'Sample description',
      price: 0,
      tags: ['sample'],
      type: ActivityType.start,
    );
  }

  Future<Activity> _findKahvaltiMekani(LatLng location) async {
    final kahvaltiMekan = await findBestPlace(
      near: location,
      type: 'restaurant',
      excludeTypes: ['bar', 'cafe'],
    );

    return Activity(
      id: kahvaltiMekan.id,
      placeId: kahvaltiMekan.placeId,
      name: kahvaltiMekan.name,
      address: kahvaltiMekan.address,
      latitude: kahvaltiMekan.latitude,
      longitude: kahvaltiMekan.longitude,
      photoUrl: kahvaltiMekan.photoUrl,
      rating: kahvaltiMekan.rating,
      reviews: kahvaltiMekan.reviews,
      startTime: kahvaltiMekan.startTime,
      endTime: kahvaltiMekan.endTime,
      timeSlot: TimeSlot.breakfast,
      description: kahvaltiMekan.description,
      price: kahvaltiMekan.price,
      tags: kahvaltiMekan.tags,
      type: ActivityType.breakfast,
    );
  }

  Future<Activity> _findPlaj(LatLng location) async {
    final plaj = await findBestPlace(
      near: location,
      type: 'beach',
    );

    return Activity(
      id: plaj.id,
      placeId: plaj.placeId,
      name: plaj.name,
      address: plaj.address,
      latitude: plaj.latitude,
      longitude: plaj.longitude,
      photoUrl: plaj.photoUrl,
      rating: plaj.rating,
      reviews: plaj.reviews,
      startTime: plaj.startTime,
      endTime: plaj.endTime,
      timeSlot: TimeSlot.beach,
      description: plaj.description,
      price: plaj.price,
      tags: plaj.tags,
      type: ActivityType.beach,
    );
  }

  Future<Activity> _findOglenYemegi(LatLng location) async {
    final oglenYemek = await findBestPlace(
      near: location,
      type: 'restaurant',
      excludeTypes: ['bar', 'cafe'],
    );

    return Activity(
      id: oglenYemek.id,
      placeId: oglenYemek.placeId,
      name: oglenYemek.name,
      address: oglenYemek.address,
      latitude: oglenYemek.latitude,
      longitude: oglenYemek.longitude,
      photoUrl: oglenYemek.photoUrl,
      rating: oglenYemek.rating,
      reviews: oglenYemek.reviews,
      startTime: oglenYemek.startTime,
      endTime: oglenYemek.endTime,
      timeSlot: TimeSlot.lunch,
      description: oglenYemek.description,
      price: oglenYemek.price,
      tags: oglenYemek.tags,
      type: ActivityType.lunch,
    );
  }

  Future<Activity> _findAksamYemegi(LatLng location) async {
    final aksamYemek = await findBestPlace(
      near: location,
      type: 'restaurant',
      excludeTypes: ['bar', 'cafe'],
    );

    return Activity(
      id: aksamYemek.id,
      placeId: aksamYemek.placeId,
      name: aksamYemek.name,
      address: aksamYemek.address,
      latitude: aksamYemek.latitude,
      longitude: aksamYemek.longitude,
      photoUrl: aksamYemek.photoUrl,
      rating: aksamYemek.rating,
      reviews: aksamYemek.reviews,
      startTime: aksamYemek.startTime,
      endTime: aksamYemek.endTime,
      timeSlot: TimeSlot.dinner,
      description: aksamYemek.description,
      price: aksamYemek.price,
      tags: aksamYemek.tags,
      type: ActivityType.dinner,
    );
  }

  Future<Activity> _findKafe(LatLng location) async {
    final kafe = await findBestPlace(
      near: location,
      type: 'cafe',
    );

    return Activity(
      id: kafe.id,
      placeId: kafe.placeId,
      name: kafe.name,
      address: kafe.address,
      latitude: kafe.latitude,
      longitude: kafe.longitude,
      photoUrl: kafe.photoUrl,
      rating: kafe.rating,
      reviews: kafe.reviews,
      startTime: kafe.startTime,
      endTime: kafe.endTime,
      timeSlot: TimeSlot.cafe,
      description: kafe.description,
      price: kafe.price,
      tags: kafe.tags,
      type: ActivityType.cafe,
    );
  }

  Future<Activity> _findBar(LatLng location) async {
    final bar = await findBestPlace(
      near: location,
      type: 'bar',
    );

    return Activity(
      id: bar.id,
      placeId: bar.placeId,
      name: bar.name,
      address: bar.address,
      latitude: bar.latitude,
      longitude: bar.longitude,
      photoUrl: bar.photoUrl,
      rating: bar.rating,
      reviews: bar.reviews,
      startTime: bar.startTime,
      endTime: bar.endTime,
      timeSlot: TimeSlot.bar,
      description: bar.description,
      price: bar.price,
      tags: bar.tags,
      type: ActivityType.bar,
    );
  }

  /// Google Places API ile en iyi kahvaltı mekanı bulma (otel, pansiyon hariç)
  Future<Activity> findBestBreakfastPlace({
    required LatLng near,
  }) async {
    // Google Places API ile "breakfast" veya "kahvaltı" kategorisinde, otel/motel/hostel/pansiyon hariç en yakın ve yüksek puanlı mekanı bul
    // (Burada gerçek API entegrasyonu yapılacak. Şimdilik örnek veri dönüyorum)
    // TODO: Buraya gerçek Google Places API entegrasyonu eklenecek
    return Activity(
      id: 'kahvalti_1',
      placeId: 'place_kahvalti_1',
      name: 'Mado (Kahvaltı Lokasyonu)',
      address: 'Eryaman, Göksu, 5532. Cad. No:9 D:25, 06824 Etimesgut/Ankara',
      latitude: near.latitude + 0.01,
      longitude: near.longitude + 0.01,
      photoUrl: '',
      rating: 4.5,
      reviews: 1200,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(const Duration(hours: 1)),
      timeSlot: TimeSlot.breakfast,
      description: 'Google Place açıklaması buraya gelecek',
      price: 100.0,
      tags: ['kahvaltı', 'restoran'],
      type: ActivityType.breakfast,
    );
  }
} 