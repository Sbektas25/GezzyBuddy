import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:google_maps_flutter_platform_interface/src/types/location.dart';
import '../models/activity.dart';
import '../models/day_plan.dart';
import '../config/api_keys.dart';
import '../models/time_slot.dart';
import '../models/activity_type.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

class PlanService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  final _uuid = const Uuid();

  final Map<String, List<String>> keywordMap = {
    'Kahvaltı': [
      'kahvaltı', 'kahvaltı salonu', 'serpme kahvaltı', 'açık büfe kahvaltı', 'kır kahvaltısı',
      'kahvaltı tabağı', 'brunch', 'breakfast', 'breakfast cafe', 'pancake', 'waffle', 'şarküteri'
    ],
    'Restaurant / Lokanta': [
      'restorant', 'lokanta', 'esnaf lokantası', 'fast food', 'burger', 'pizza', 'dönerci',
      'kebapçı', 'izgara', 'grill house', 'meat restaurant', 'yemek salonu', 'family restaurant',
      'dinner', 'lunch'
    ],
    'Kafe': [
      'kafe', 'cafe', 'coffee shop', 'kahveci', 'çay evi', 'çay bahçesi', 'tea house',
      'cozy cafe', 'soğuk meşrubat', 'cold drinks', 'smoothie bar', 'bakery cafe', 'pastane'
    ],
    'Bar': [
      'bar', 'pub', 'lounge', 'meyhane', 'şarap barı', 'bira evi', 'beer house', 'cocktail bar',
      'nightclub', 'gece kulübü', 'wine bar', 'sports bar'
    ],
    'Halk Plajı': [
      'plaj', 'halk plajı', 'kum plajı', 'mavi bayrak', 'public beach', 'free beach',
      'community beach', 'beach park', 'open beach', 'family beach', 'coastal beach'
    ],
    'Ücretli Plaj': [
      'özel plaj', 'paralı plaj', 'beach club', 'private beach', 'paid beach', 'resort beach',
      'beach entry fee', 'şezlong', 'güneşlenme alanı', 'luxury beach', 'beach resort', 'beach bar'
    ],
  };

  final Set<String> forbiddenTypes = {
    'locality',
    'political',
    'administrative_area_level_1',
    'administrative_area_level_2',
    'administrative_area_level_3',
    'lodging',
    'hotel',
    'resort',
  };

  Future<List<Activity>> searchNearbyPlaces(
    LatLng location,
    String type,
    double radius,
    {List<String>? keywords, List<String>? types}
  ) async {
    Future<List<Activity>> _doSearch(double r, {List<String>? k, List<String>? t}) async {
      String typeParam = t != null && t.isNotEmpty ? t.first : type;
      String keywordParam = k != null && k.isNotEmpty ? '&keyword=${k.join(',')}' : '';
      final url = Uri.parse(
        '$_baseUrl/nearbysearch/json?location=${location.latitude},${location.longitude}&radius=$r&type=$typeParam$keywordParam&key=${ApiKeys.googlePlacesApiKey}',
      );
      final response = await http.get(url);
      if (response.statusCode != 200) {
        throw Exception('Failed to load places');
      }
      final data = json.decode(response.body);
      if (data['status'] != 'OK') {
        if (data['status'] == 'ZERO_RESULTS') return [];
        throw Exception('API error: ${data['status']}');
      }
      final results = data['results'] as List;
      final filtered = results.where((place) {
        final types = List<String>.from(place['types'] ?? []);
        final name = (place['name'] ?? '').toString().toLowerCase();
        if (types.any((t) => forbiddenTypes.contains(t))) {
          return false;
        }
        if ((type == 'Halk Plajı' || type == 'Ücretli Plaj') &&
            !(types.any((t) => t.contains('beach') || t.contains('plaj')) || name.contains('beach') || name.contains('plaj'))
        ) {
          return false;
        }
        if (type == 'Kahvaltı' && types.any((t) => t.contains('kebab') || t.contains('steakhouse') || t.contains('bbq') || t.contains('grill'))) {
          return false;
        }
        return true;
      }).toList();
      return filtered.map((place) {
        final geometry = place['geometry']['location'];
        return Activity(
          id: _uuid.v4(),
          placeId: place['place_id'],
          name: place['name'],
          position: LatLng(
            (geometry['lat'] as num).toDouble(),
            (geometry['lng'] as num).toDouble(),
          ),
          tags: List<String>.from(place['types'] ?? []),
          type: _getActivityType(type),
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 1)),
          timeSlot: _getTimeSlot(type),
          photoUrl: place['photos']?.isNotEmpty == true
              ? '$_baseUrl/photo?maxwidth=400&photoreference=${place['photos'][0]['photo_reference']}&key=${ApiKeys.googlePlacesApiKey}'
              : null,
          reviews: (place['user_ratings_total'] as num?)?.toInt() ?? 0,
          rating: (place['rating'] as num?)?.toDouble() ?? 0.0,
          price: _getPriceLevel(place['price_level']),
          travelDurationSec: 0,
          address: place['vicinity'] as String? ?? '',
        );
      }).toList();
    }

    // 1. Anahtar kelime + tür + orijinal yarıçap
    var results = await _doSearch(radius, k: keywords, t: types);
    // 2. Sadece tür + orijinal yarıçap
    if (results.isEmpty && types != null) {
      results = await _doSearch(radius, t: types);
    }
    // 3. Sadece anahtar kelime + orijinal yarıçap
    if (results.isEmpty && keywords != null) {
      results = await _doSearch(radius, k: keywords);
    }
    // 4. Anahtar kelime + tür + daha geniş yarıçap
    if (results.isEmpty) {
      results = await _doSearch(radius * 2, k: keywords, t: types);
    }
    // 5. Sadece tür + daha geniş yarıçap
    if (results.isEmpty && types != null) {
      results = await _doSearch(radius * 2, t: types);
    }
    // 6. Sadece anahtar kelime + daha geniş yarıçap
    if (results.isEmpty && keywords != null) {
      results = await _doSearch(radius * 2, k: keywords);
    }
    return results;
  }

  TimeSlot _getTimeSlot(String type) {
    switch (type) {
      case 'restaurant':
        return TimeSlot.lunch;
      case 'cafe':
        return TimeSlot.cafe;
      case 'bar':
        return TimeSlot.bar;
      case 'beach':
        return TimeSlot.beach;
      default:
        return TimeSlot.morning;
    }
  }

  ActivityType _getActivityType(String type) {
    switch (type) {
      case 'restaurant':
        return ActivityType.lunch;
      case 'cafe':
        return ActivityType.cafe;
      case 'bar':
        return ActivityType.bar;
      case 'beach':
        return ActivityType.beach;
      default:
        return ActivityType.start;
    }
  }

  double _getPriceLevel(int? priceLevel) {
    switch (priceLevel) {
      case 1:
        return 50.0;
      case 2:
        return 100.0;
      case 3:
        return 200.0;
      case 4:
        return 300.0;
      default:
        return 50.0;
    }
  }

  Future<int> getTravelDuration(LatLng origin, LatLng destination) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&mode=driving&key=${ApiKeys.googleMapsApiKey}',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final duration = data['routes'][0]['legs'][0]['duration']['value'];
        return duration; // saniye cinsinden
      }
    }
    return 0;
  }

  Future<List<DayPlan>> generatePlan({
    required String location,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> preferences,
  }) async {
    // ... algoritman buraya
    return <DayPlan>[];
  }

  TimeSlot _mapTimeSlot(String slotStr) {
    switch (slotStr) {
      case 'breakfast': return TimeSlot.breakfast;
      case 'lunch':     return TimeSlot.lunch;
      case 'afternoon': return TimeSlot.afternoon;
      case 'dinner':    return TimeSlot.dinner;
      case 'beach':     return TimeSlot.beach;
      case 'cafe':      return TimeSlot.cafe;
      case 'bar':       return TimeSlot.bar;
      case 'night':     return TimeSlot.night;
      case 'returnHome':return TimeSlot.returnHome;
      default:          return TimeSlot.breakfast;
    }
  }

  /// Örnek: konaklama lokasyonu, tarih aralığı, seçimler
  Future<List<DayPlan>> generateDayPlans({
    required LatLng home,
    required DateTime startDate,
    required DateTime endDate,
    required List<TimeSlot> slots,
  }) async {
    final days = endDate.difference(startDate).inDays + 1;
    List<DayPlan> result = [];

    for (var i = 0; i < days; i++) {
      final dayStart = startDate.add(Duration(days: i));
      List<Activity> activities = [];

      for (var slot in slots) {
        final act = await _selectBest(
          from: activities.isEmpty ? home : activities.last.position,
          slot: slot,
          day: dayStart,
        );
        activities.add(act);
      }

      // dönüş aktivitesi
      activities.add(Activity(
        id: 'return_${i}',
        placeId: 'return_${i}',
        name: 'Dönüş',
        position: home,
        tags: ['return'],
        type: ActivityType.returnHome,
        startTime: endDate,
        endTime: endDate,
        timeSlot: TimeSlot.returnHome,
        reviews: 0,
        rating: 0,
        price: 0,
        travelDurationSec: 0,
        address: '',
      ));

      result.add(DayPlan(
        dayIndex: i + 1,
        title: 'Gün ${i + 1}',
        numberOfDays: days,
        location: home.toString(),
        activities: activities,
      ));
    }

    return result;
  }

  Future<Activity> _selectBest({
    required LatLng from,
    required TimeSlot slot,
    required DateTime day,
  }) async {
    // 1. Hangi place type?
    String type;
    switch (slot) {
      case TimeSlot.breakfast:
        type = 'cafe|bakery';
        break;
      case TimeSlot.lunch:
      case TimeSlot.dinner:
        type = 'restaurant';
        break;
      case TimeSlot.afternoon:
        type = 'beach';
        break;
      case TimeSlot.cafe:
        type = 'cafe';
        break;
      case TimeSlot.bar:
        type = 'bar';
        break;
      default:
        type = 'point_of_interest';
    }

    // 2. Arama URL'si (en yakın + yüksek rating)
    final url = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/nearbysearch/json',
      {
        'key': ApiKeys.googlePlacesApiKey,
        'location': '${from.latitude},${from.longitude}',
        'rankby': 'distance',
        'type': type,
      },
    );

    final resp = await http.get(url);
    if (resp.statusCode != 200) {
      throw Exception('Places API error: ${resp.statusCode}');
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final results = (json['results'] as List).cast<Map<String, dynamic>>();
    if (results.isEmpty) {
      // fallback: aynı konuma dönüş aktivitesi
      return Activity(
        id: 'fallback_${slot.toString()}',
        placeId: 'fallback_${slot.toString()}',
        name: 'No ${slot.name} found',
        position: from,
        tags: ['fallback'],
        type: ActivityType.start,
        startTime: day,
        endTime: day,
        timeSlot: slot,
        reviews: 0,
        rating: 0,
        price: 0,
        travelDurationSec: 0,
        address: '',
      );
    }

    // 3. En yüksek puanlı ilki seç
    results.sort((a, b) {
      final ra = (a['rating'] as num?) ?? 0;
      final rb = (b['rating'] as num?) ?? 0;
      return rb.compareTo(ra);
    });
    final place = results.first;

    // 4. Başlangıç/bitiş zamanını slot'a göre ayarla
    DateTime start, end;
    switch (slot) {
      case TimeSlot.breakfast:
        start = DateTime(day.year, day.month, day.day, 8, 0);
        end = start.add(const Duration(hours: 1));
        break;
      case TimeSlot.lunch:
        start = DateTime(day.year, day.month, day.day, 12, 0);
        end = start.add(const Duration(hours: 1));
        break;
      case TimeSlot.dinner:
        start = DateTime(day.year, day.month, day.day, 18, 30);
        end = start.add(const Duration(hours: 1));
        break;
      case TimeSlot.afternoon:
        start = DateTime(day.year, day.month, day.day, 10, 30);
        end = DateTime(day.year, day.month, day.day, 19, 0);
        break;
      case TimeSlot.cafe:
        start = DateTime(day.year, day.month, day.day, 20, 0);
        end = DateTime(day.year, day.month, day.day, 22, 0);
        break;
      case TimeSlot.bar:
        start = DateTime(day.year, day.month, day.day, 22, 0);
        end = DateTime(day.year, day.month, day.day, 24, 0);
        break;
      default:
        start = day;
        end = day;
    }

    return Activity.fromJson({
      ...place,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'timeSlot': slot.toString(),
    });
  }

  Future<List<Activity>> _getActivitiesForSlot(
    String home,
    TimeSlot slot,
    DateTime date,
    List<String> preferences,
  ) async {
    final activities = await _getActivitiesForTimeSlot(
      home,
      slot,
      date,
      preferences,
    );

    if (activities.isEmpty) {
      return [
        Activity(
          id: const Uuid().v4(),
          placeId: 'no_activity',
          name: 'No ${slot.name} found',
          position: LatLng(0, 0),
          tags: [],
          type: ActivityType.start,
          startTime: date,
          endTime: date.add(const Duration(hours: 2)),
          timeSlot: slot,
          reviews: 0,
          rating: 0,
          price: 0,
          travelDurationSec: 0,
          address: '',
        ),
      ];
    }

    return activities;
  }

  Future<List<Activity>> _getActivitiesForTimeSlot(
    String home,
    TimeSlot slot,
    DateTime date,
    List<String> preferences,
  ) async {
    final activities = await searchNearbyPlaces(
      LatLng(0, 0), // TODO: Get actual location
      slot.toString(),
      5000,
      keywords: preferences,
    );

    return activities;
  }
}

extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
} 