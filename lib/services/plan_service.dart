import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/activity.dart';
import '../models/day_plan.dart';
import '../config/api_keys.dart';

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
          address: place['vicinity'],
          latitude: geometry['lat'],
          longitude: geometry['lng'],
          photoUrl: place['photos']?.isNotEmpty == true
              ? '$_baseUrl/photo?maxwidth=400&photoreference=${place['photos'][0]['photo_reference']}&key=${ApiKeys.googlePlacesApiKey}'
              : '',
          rating: (place['rating'] ?? 0.0).toDouble(),
          reviews: place['user_ratings_total'] ?? 0,
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 1)),
          timeSlot: _getTimeSlot(type),
          description: place['types']?.join(', ') ?? '',
          price: _getPriceLevel(place['price_level']),
          tags: List<String>.from(place['types'] ?? []),
          type: _getActivityType(type),
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
    required LatLng location,
    required DateTime startTime,
    required DateTime endTime,
    required List<String> preferences,
    required String accommodationName,
  }) async {
    final numberOfDays = endTime.difference(startTime).inDays + 1;
    final plans = <DayPlan>[];

    for (var i = 0; i < numberOfDays; i++) {
      final currentDate = startTime.add(Duration(days: i));
      final activities = <Activity>[];
      final random = Random();
      final usedPlaceIds = <String>{};
      DateTime currentTime = DateTime(currentDate.year, currentDate.month, currentDate.day, startTime.hour, startTime.minute);
      LatLng currentLocation = location;

      // Konaklama Noktası (günün başı)
      activities.add(Activity(
        id: _uuid.v4(),
        placeId: 'accommodation',
        name: accommodationName,
        address: accommodationName,
        latitude: location.latitude,
        longitude: location.longitude,
        photoUrl: '',
        rating: 0.0,
        reviews: 0,
        startTime: currentTime,
        endTime: currentTime,
        timeSlot: TimeSlot.morning,
        description: 'Konaklama',
        price: 0.0,
        tags: ['accommodation'],
        type: ActivityType.start,
      ));

      // Kahvaltı
      final breakfastPlaces = await searchNearbyPlaces(
        currentLocation,
        'Kahvaltı',
        2000,
        keywords: keywordMap['Kahvaltı'],
        types: ['bakery', 'cafe', 'restaurant'],
      );
      final breakfast = breakfastPlaces.firstWhereOrNull((a) => !usedPlaceIds.contains(a.placeId));
      if (breakfast != null) {
        final travelSec = await getTravelDuration(currentLocation, breakfast.position);
        currentTime = DateTime(currentDate.year, currentDate.month, currentDate.day, 8, 0).add(Duration(seconds: travelSec));
        final breakfastDuration = Duration(minutes: 45 + random.nextInt(16)); // 45-60dk
        final breakfastEnd = currentTime.add(breakfastDuration);
        activities.add(breakfast.copyWith(
          startTime: currentTime,
          endTime: breakfastEnd,
          timeSlot: TimeSlot.breakfast,
          type: ActivityType.breakfast,
          travelDurationSec: travelSec > 0 ? travelSec : 600, // fallback: 10dk
        ));
        usedPlaceIds.add(breakfast.placeId);
        currentTime = breakfastEnd;
        currentLocation = breakfast.position;
      }

      // Halk Plajı
      final publicBeachPlaces = await searchNearbyPlaces(
        currentLocation,
        'Halk Plajı',
        5000,
        keywords: keywordMap['Halk Plajı'],
        types: ['beach'],
      );
      final publicBeach = publicBeachPlaces.firstWhereOrNull((a) => !usedPlaceIds.contains(a.placeId));
      if (publicBeach != null) {
        final travelSec = await getTravelDuration(currentLocation, publicBeach.position);
        currentTime = DateTime(currentDate.year, currentDate.month, currentDate.day, 10, 0).add(Duration(seconds: travelSec));
        final beachDuration = Duration(hours: 5 + random.nextInt(5)); // 5-9 saat
        final beachEnd = currentTime.add(beachDuration);
        activities.add(publicBeach.copyWith(
          startTime: currentTime,
          endTime: beachEnd,
          timeSlot: TimeSlot.beach,
          type: ActivityType.beach,
          travelDurationSec: travelSec > 0 ? travelSec : 600, // fallback: 10dk
        ));
        usedPlaceIds.add(publicBeach.placeId);
        currentTime = beachEnd;
        currentLocation = publicBeach.position;

        // Plajdan sonra konaklama lokasyonuna dönüş
        var travelBackSec = await getTravelDuration(currentLocation, location);
        if (travelBackSec == 0) travelBackSec = 600; // fallback: 10dk
        final backStart = currentTime;
        final backEnd = backStart.add(Duration(seconds: travelBackSec));
        activities.add(Activity(
          id: _uuid.v4(),
          placeId: 'accommodation_return',
          name: accommodationName,
          address: accommodationName,
          latitude: location.latitude,
          longitude: location.longitude,
          photoUrl: '',
          rating: 0.0,
          reviews: 0,
          startTime: backStart,
          endTime: backEnd,
          timeSlot: TimeSlot.morning,
          description: 'Plajdan dönüş',
          price: 0.0,
          tags: ['accommodation'],
          type: ActivityType.start,
          travelDurationSec: travelBackSec,
        ));
        // 1 saat dinlenme
        final restStart = backEnd;
        final restEnd = restStart.add(const Duration(hours: 1));
        activities.add(Activity(
          id: _uuid.v4(),
          placeId: 'accommodation_rest',
          name: accommodationName,
          address: accommodationName,
          latitude: location.latitude,
          longitude: location.longitude,
          photoUrl: '',
          rating: 0.0,
          reviews: 0,
          startTime: restStart,
          endTime: restEnd,
          timeSlot: TimeSlot.morning,
          description: 'Dinlenme ve hazırlık',
          price: 0.0,
          tags: ['accommodation'],
          type: ActivityType.start,
          travelDurationSec: 0,
        ));
        currentTime = restEnd;
        currentLocation = location;
      }

      // Ücretli Plaj
      final paidBeachPlaces = await searchNearbyPlaces(
        currentLocation,
        'Ücretli Plaj',
        5000,
        keywords: keywordMap['Ücretli Plaj'],
        types: ['beach'],
      );
      final paidBeach = paidBeachPlaces.firstWhereOrNull((a) => !usedPlaceIds.contains(a.placeId));
      if (paidBeach != null) {
        final travelSec = await getTravelDuration(currentLocation, paidBeach.position);
        currentTime = currentTime.add(Duration(seconds: travelSec));
        final beachDuration = Duration(hours: 5 + random.nextInt(5));
        final beachEnd = currentTime.add(beachDuration);
        activities.add(paidBeach.copyWith(
          startTime: currentTime,
          endTime: beachEnd,
          timeSlot: TimeSlot.beach,
          type: ActivityType.beach,
        ));
        usedPlaceIds.add(paidBeach.placeId);
        currentTime = beachEnd;
        currentLocation = paidBeach.position;

        // Plajdan sonra konaklama lokasyonuna dönüş
        final travelBackSec = await getTravelDuration(currentLocation, location);
        print('DEBUG: Plajdan konaklamaya yol süresi (saniye): $travelBackSec');
        print('DEBUG: Plaj koordinat: ' + currentLocation.toString() + ', Konaklama koordinat: ' + location.toString());
        final backStart = currentTime;
        final backEnd = backStart.add(Duration(seconds: travelBackSec));
        activities.add(Activity(
          id: _uuid.v4(),
          placeId: 'accommodation_return',
          name: accommodationName,
          address: accommodationName,
          latitude: location.latitude,
          longitude: location.longitude,
          photoUrl: '',
          rating: 0.0,
          reviews: 0,
          startTime: backStart,
          endTime: backEnd,
          timeSlot: TimeSlot.morning,
          description: 'Plajdan dönüş',
          price: 0.0,
          tags: ['accommodation'],
          type: ActivityType.start,
        ));
        currentTime = backEnd;
        currentLocation = location;
      }

      // Restaurant / Lokanta (Akşam Yemeği)
      final dinnerPlaces = await searchNearbyPlaces(
        currentLocation,
        'Restaurant / Lokanta',
        2000,
        keywords: keywordMap['Restaurant / Lokanta'],
        types: ['restaurant'],
      );
      final dinner = dinnerPlaces.firstWhereOrNull((a) => !usedPlaceIds.contains(a.placeId));
      if (dinner != null) {
        final travelSec = await getTravelDuration(currentLocation, dinner.position);
        currentTime = DateTime(currentDate.year, currentDate.month, currentDate.day, 18, 30).add(Duration(seconds: travelSec));
        final dinnerDuration = Duration(minutes: 60 + random.nextInt(31)); // 1-1.5 saat
        final dinnerEnd = currentTime.add(dinnerDuration);
        activities.add(dinner.copyWith(
          startTime: currentTime,
          endTime: dinnerEnd,
          timeSlot: TimeSlot.dinner,
          type: ActivityType.dinner,
          travelDurationSec: travelSec > 0 ? travelSec : 600, // fallback: 10dk
        ));
        usedPlaceIds.add(dinner.placeId);
        currentTime = dinnerEnd;
        currentLocation = dinner.position;
      }

      // Kafe
      final cafePlaces = await searchNearbyPlaces(
        currentLocation,
        'Kafe',
        2000,
        keywords: keywordMap['Kafe'],
        types: ['cafe'],
      );
      final cafe = cafePlaces.firstWhereOrNull((a) => !usedPlaceIds.contains(a.placeId));
      if (cafe != null) {
        final travelSec = await getTravelDuration(currentLocation, cafe.position);
        currentTime = DateTime(currentDate.year, currentDate.month, currentDate.day, 20, 0).add(Duration(seconds: travelSec));
        final cafeDuration = Duration(hours: 1 + random.nextInt(2)); // 1-2 saat
        final cafeEnd = currentTime.add(cafeDuration);
        activities.add(cafe.copyWith(
          startTime: currentTime,
          endTime: cafeEnd,
          timeSlot: TimeSlot.cafe,
          type: ActivityType.cafe,
          travelDurationSec: travelSec > 0 ? travelSec : 600, // fallback: 10dk
        ));
        usedPlaceIds.add(cafe.placeId);
        currentTime = cafeEnd;
        currentLocation = cafe.position;
      }

      // Bar
      final barPlaces = await searchNearbyPlaces(
        currentLocation,
        'Bar',
        2000,
        keywords: keywordMap['Bar'],
        types: ['bar'],
      );
      final bar = barPlaces.firstWhereOrNull((a) => !usedPlaceIds.contains(a.placeId));
      if (bar != null) {
        final travelSec = await getTravelDuration(currentLocation, bar.position);
        currentTime = DateTime(currentDate.year, currentDate.month, currentDate.day, 22, 0).add(Duration(seconds: travelSec));
        final barDuration = Duration(hours: 1 + random.nextInt(2)); // 1-2 saat
        final barEnd = currentTime.add(barDuration);
        activities.add(bar.copyWith(
          startTime: currentTime,
          endTime: barEnd,
          timeSlot: TimeSlot.night,
          type: ActivityType.night,
          travelDurationSec: travelSec > 0 ? travelSec : 600, // fallback: 10dk
        ));
        usedPlaceIds.add(bar.placeId);
        currentTime = barEnd;
        currentLocation = bar.position;
      }

      // Konaklama Noktası (gün sonu)
      activities.add(Activity(
        id: _uuid.v4(),
        placeId: 'accommodation_end',
        name: accommodationName,
        address: accommodationName,
        latitude: location.latitude,
        longitude: location.longitude,
        photoUrl: '',
        rating: 0.0,
        reviews: 0,
        startTime: currentTime,
        endTime: currentTime,
        timeSlot: TimeSlot.night,
        description: 'Konaklama',
        price: 0.0,
        tags: ['accommodation'],
        type: ActivityType.end,
      ));

      plans.add(DayPlan(
        date: currentDate,
        activities: activities,
      ));
    }

    return plans;
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