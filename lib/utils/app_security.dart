import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppSecurity {
  static const _storage = FlutterSecureStorage();
  static const _prefix = 'secure_';

  // Hassas verileri güvenli depolama
  static Future<void> secureSet(String key, String value) async {
    await _storage.write(key: _prefix + key, value: value);
  }

  static Future<String?> secureGet(String key) async {
    return await _storage.read(key: _prefix + key);
  }

  static Future<void> secureDelete(String key) async {
    await _storage.delete(key: _prefix + key);
  }

  static Future<void> secureClear() async {
    await _storage.deleteAll();
  }

  // Hash oluşturma
  static String hashString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // API anahtarı doğrulama
  static bool isValidApiKey(String apiKey) {
    if (apiKey.isEmpty) return false;
    if (apiKey.length < 32) return false;
    
    // API anahtarı formatını kontrol et
    final pattern = RegExp(r'^[A-Za-z0-9-_]+$');
    return pattern.hasMatch(apiKey);
  }

  // Veri doğrulama
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  static bool isValidPassword(String password) {
    if (password.isEmpty) return false;
    if (password.length < 8) return false;
    
    // En az bir büyük harf, bir küçük harf, bir rakam ve bir özel karakter
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasDigits = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecialCharacters = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
    
    return hasUppercase && hasLowercase && hasDigits && hasSpecialCharacters;
  }

  static bool isValidPhoneNumber(String phone) {
    if (phone.isEmpty) return false;
    
    // Türkiye telefon numarası formatı
    final phoneRegex = RegExp(r'^\+90[0-9]{10}$');
    return phoneRegex.hasMatch(phone);
  }

  // Veri temizleme
  static String sanitizeInput(String input) {
    // HTML ve tehlikeli karakterleri temizle
    input = input.replaceAll(RegExp(r'<[^>]*>'), '');
    input = input.replaceAll(RegExp(r'[<>"\\/]'), '');
    return input.trim();
  }

  // Token yönetimi
  static Future<void> saveToken(String token) async {
    await secureSet('auth_token', token);
  }

  static Future<String?> getToken() async {
    return await secureGet('auth_token');
  }

  static Future<void> deleteToken() async {
    await secureDelete('auth_token');
  }

  static Future<void> saveTokenExpiry(DateTime expiryDate) async {
    await secureSet('token_expiry', expiryDate.toIso8601String());
  }

  static Future<DateTime?> getTokenExpiry() async {
    final expiryString = await secureGet('token_expiry');
    if (expiryString == null) return null;
    return DateTime.parse(expiryString);
  }

  static Future<void> deleteTokenExpiry() async {
    await secureDelete('token_expiry');
  }

  // Oturum kontrolü
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    if (token == null) return false;

    final expiry = await getTokenExpiry();
    if (expiry == null) return false;

    return expiry.isAfter(DateTime.now());
  }

  // Güvenli rastgele string oluşturma
  static String generateRandomString(int length) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64Url.encode(values).substring(0, length);
  }
} 