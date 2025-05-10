import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // API Keys
  static final Map<String, String> apiKeys = {
    'googleMaps': dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '',
  };
  
  // Firebase Collection Names
  static const String usersCollection = 'users';
  static const String plansCollection = 'plans';
  
  // Shared Preferences Keys
  static const String userTokenKey = 'user_token';
  static const String userEmailKey = 'user_email';
  static const String lastLocationKey = 'last_location';
  
  // Package Types
  static const Map<String, String> packageTypes = {
    'beach': 'Plaj Paketi',
    'cultural': 'Kültür Paketi',
    'adventure': 'Macera Paketi',
    'food': 'Gurme Paketi',
  };
  
  // Time Slots
  static const Map<String, String> startHours = {
    '09:00': '09:00',
    '10:00': '10:00',
    '11:00': '11:00',
    '12:00': '12:00',
  };
  
  static const Map<String, String> endHours = {
    '17:00': '17:00',
    '18:00': '18:00',
    '19:00': '19:00',
    '20:00': '20:00',
  };
  
  // Error Messages
  static const Map<String, String> errorMessages = {
    'location': 'Konum bilgisi alınamadı.',
    'locationServiceDisabled': 'Konum servisi kapalı. Lütfen konum servisini açın.',
    'locationPermissionDenied': 'Konum izni reddedildi. Lütfen konum iznini verin.',
    'locationPermissionDeniedForever': 'Konum izni kalıcı olarak reddedildi. Lütfen ayarlardan konum iznini verin.',
    'network': 'İnternet bağlantısı hatası.',
    'auth': 'Kimlik doğrulama hatası.',
    'database': 'Veritabanı hatası.',
    'storage': 'Depolama hatası.',
    'plan': 'Plan oluşturma hatası.',
  };
  
  // Success Messages
  static const Map<String, String> successMessages = {
    'planCreated': 'Plan başarıyla oluşturuldu.',
    'locationUpdated': 'Konum başarıyla güncellendi.',
    'planSaved': 'Plan başarıyla kaydedildi.',
    'planShared': 'Plan başarıyla paylaşıldı.',
  };
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 8.0;
  static const double defaultIconSize = 24.0;
  
  // Animation Durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
} 