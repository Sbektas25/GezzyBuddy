import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:location/location.dart';
import 'package:gezzy_buddy/providers/plan_provider.dart';
import 'package:gezzy_buddy/services/location_service.dart';
import 'package:gezzy_buddy/services/map_service.dart';

@GenerateMocks([LocationService, MapService])
import 'plan_provider_test.mocks.dart';

void main() {
  late PlanProvider planProvider;
  late MockLocationService mockLocationService;
  late MockMapService mockMapService;

  setUp(() {
    mockLocationService = MockLocationService();
    mockMapService = MockMapService();
    planProvider = PlanProvider(
      locationService: mockLocationService,
      mapService: mockMapService,
    );

    // Set up default mock behavior
    when(mockLocationService.getLocationInfo()).thenAnswer((_) async => {
      'latitude': '36.8969',
      'longitude': '30.7133',
      'address': 'Antalya, Turkey',
    });
  });

  group('PlanProvider Tests', () {
    test('generatePlan creates correct number of days and activities', () async {
      final locationData = LocationData.fromMap({
        'latitude': 36.8969,
        'longitude': 30.7133,
        'accuracy': 0.0,
        'altitude': 0.0,
        'speed': 0.0,
        'speed_accuracy': 0.0,
        'heading': 0.0,
        'time': 0.0,
        'is_mock': false,
        'vertical_accuracy': 0.0,
        'heading_accuracy': 0.0,
        'elapsed_real_time_nanos': 0,
        'elapsed_real_time_uncertainty_nanos': 0,
        'satellites': 0,
        'provider': '',
      });

      await planProvider.generatePlan(
        type: 'Plaj & Deniz',
        location: 'Antalya',
        days: 2,
        start: 'Sabah',
        end: 'Akşam',
        beachRec: true,
        restaurantRec: true,
        cafeRec: false,
        cafeTime: 'Öğle',
        origin: locationData,
      );

      final itinerary = planProvider.itinerary;
      expect(itinerary, isNotNull);
      expect(itinerary!.dayPlans.length, 2);
      expect(itinerary.type, 'Plaj & Deniz');
      expect(itinerary.location, 'Antalya');
    });

    test('error is set when location service fails', () async {
      when(mockLocationService.getLocationInfo()).thenThrow(Exception('Location service failed'));

      try {
        await planProvider.generatePlan(
          type: 'Plaj & Deniz',
          location: 'Antalya',
          days: 2,
          start: 'Sabah',
          end: 'Akşam',
          beachRec: true,
          restaurantRec: true,
          cafeRec: false,
          cafeTime: 'Öğle',
          origin: LocationData.fromMap({
            'latitude': 36.8969,
            'longitude': 30.7133,
            'accuracy': 0.0,
            'altitude': 0.0,
            'speed': 0.0,
            'speed_accuracy': 0.0,
            'heading': 0.0,
            'time': 0.0,
            'is_mock': false,
            'vertical_accuracy': 0.0,
            'heading_accuracy': 0.0,
            'elapsed_real_time_nanos': 0,
            'elapsed_real_time_uncertainty_nanos': 0,
            'satellites': 0,
            'provider': '',
          }),
        );
        fail('Should throw an exception');
      } catch (e) {
        expect(e.toString(), contains('Location service failed'));
        expect(planProvider.error, contains('Location service failed'));
      }
    });

    test('clearPlan resets itinerary to null', () {
      planProvider.clearPlan();
      expect(planProvider.itinerary, isNull);
    });

    test('updatePlan modifies existing itinerary', () async {
      final locationData = LocationData.fromMap({
        'latitude': 36.8969,
        'longitude': 30.7133,
        'accuracy': 0.0,
        'altitude': 0.0,
        'speed': 0.0,
        'speed_accuracy': 0.0,
        'heading': 0.0,
        'time': 0.0,
        'is_mock': false,
        'vertical_accuracy': 0.0,
        'heading_accuracy': 0.0,
        'elapsed_real_time_nanos': 0,
        'elapsed_real_time_uncertainty_nanos': 0,
        'satellites': 0,
        'provider': '',
      });

      await planProvider.generatePlan(
        type: 'Plaj & Deniz',
        location: 'Antalya',
        days: 2,
        start: 'Sabah',
        end: 'Akşam',
        beachRec: true,
        restaurantRec: true,
        cafeRec: false,
        cafeTime: 'Öğle',
        origin: locationData,
      );

      final originalItinerary = planProvider.itinerary;
      await planProvider.updatePlan(
        type: 'Kültür',
        days: 3,
      );

      final updatedItinerary = planProvider.itinerary;
      expect(updatedItinerary, isNotNull);
      expect(updatedItinerary!.type, 'Kültür');
      expect(updatedItinerary.dayPlans.length, 3);
      expect(updatedItinerary.id, originalItinerary!.id);
    });
  });
} 