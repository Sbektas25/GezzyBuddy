import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AppCache {
  static const String _prefix = 'cache_';
  static const Duration _defaultExpiration = Duration(hours: 24);

  static Future<void> set(
    String key,
    dynamic value, {
    Duration expiration = _defaultExpiration,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final expirationTime = DateTime.now().add(expiration);
    final cacheData = {
      'value': value,
      'expiration': expirationTime.toIso8601String(),
    };
    await prefs.setString(_prefix + key, json.encode(cacheData));
  }

  static Future<T?> get<T>(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_prefix + key);
    
    if (cachedData == null) return null;

    final data = json.decode(cachedData);
    final expiration = DateTime.parse(data['expiration']);
    
    if (DateTime.now().isAfter(expiration)) {
      await remove(key);
      return null;
    }

    return data['value'] as T;
  }

  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefix + key);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_prefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  static Future<bool> exists(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_prefix + key);
  }

  static Future<DateTime?> getExpiration(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_prefix + key);
    
    if (cachedData == null) return null;

    final data = json.decode(cachedData);
    return DateTime.parse(data['expiration']);
  }

  static Future<void> refresh(
    String key, {
    Duration expiration = _defaultExpiration,
  }) async {
    final value = await get(key);
    if (value != null) {
      await set(key, value, expiration: expiration);
    }
  }

  static Future<void> refreshAll({
    Duration expiration = _defaultExpiration,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_prefix));
    
    for (final key in keys) {
      final value = await get(key.substring(_prefix.length));
      if (value != null) {
        await set(
          key.substring(_prefix.length),
          value,
          expiration: expiration,
        );
      }
    }
  }
} 