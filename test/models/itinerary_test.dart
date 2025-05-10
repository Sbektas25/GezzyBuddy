import 'package:flutter_test/flutter_test.dart';
import 'package:gezzy_buddy/models/itinerary.dart';

void main() {
  group('Itinerary Model Tests', () {
    test('Itinerary creation with valid data', () {
      final itinerary = Itinerary(
        id: '1',
        userId: 'user1',
        title: 'Plaj & Deniz Tatili',
        location: 'Antalya',
        destination: 'Antalya',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 2)),
        type: 'Plaj & Deniz',
        dayPlans: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        items: [],
        days: 2,
        tags: [],
        isPublic: false,
        budget: 0.0,
      );

      expect(itinerary.id, '1');
      expect(itinerary.userId, 'user1');
      expect(itinerary.title, 'Plaj & Deniz Tatili');
      expect(itinerary.location, 'Antalya');
      expect(itinerary.destination, 'Antalya');
      expect(itinerary.type, 'Plaj & Deniz');
      expect(itinerary.dayPlans, isEmpty);
    });

    test('Itinerary.fromJson creates valid object', () {
      final now = DateTime.now();
      final json = {
        'id': '1',
        'userId': 'user1',
        'title': 'Plaj & Deniz Tatili',
        'location': 'Antalya',
        'destination': 'Antalya',
        'startDate': now.toIso8601String(),
        'endDate': now.add(const Duration(days: 2)).toIso8601String(),
        'type': 'Plaj & Deniz',
        'dayPlans': [],
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'items': [],
        'days': 2,
        'tags': [],
        'isPublic': false,
        'budget': 0.0,
      };

      final itinerary = Itinerary.fromJson(json);
      expect(itinerary.id, '1');
      expect(itinerary.title, 'Plaj & Deniz Tatili');
      expect(itinerary.type, 'Plaj & Deniz');
    });

    test('Itinerary.toJson creates valid map', () {
      final now = DateTime.now();
      final itinerary = Itinerary(
        id: '1',
        userId: 'user1',
        title: 'Plaj & Deniz Tatili',
        location: 'Antalya',
        destination: 'Antalya',
        startDate: now,
        endDate: now.add(const Duration(days: 2)),
        type: 'Plaj & Deniz',
        dayPlans: [],
        createdAt: now,
        updatedAt: now,
        items: [],
        days: 2,
        tags: [],
        isPublic: false,
        budget: 0.0,
      );

      final json = itinerary.toJson();
      expect(json['id'], '1');
      expect(json['title'], 'Plaj & Deniz Tatili');
      expect(json['type'], 'Plaj & Deniz');
    });
  });
} 