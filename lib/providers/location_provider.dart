import 'package:flutter/foundation.dart';
import 'package:location/location.dart' as location;
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class LocationProvider with ChangeNotifier {
  final location.Location _location = location.Location();
  bool _serviceEnabled = false;
  location.PermissionStatus? _permissionGranted;
  location.LocationData? _locationData;
  geocoding.Location? _currentLocation;
  String? _address;
  String? _error;
  bool _isLoading = false;
  location.PermissionStatus _permissionStatus = location.PermissionStatus.denied;
  bool _hasPermission = false;
  String? _userName;
  List<geocoding.Placemark>? _placemarks;

  location.LocationData? get currentLocation => _locationData;
  String? get address => _address;
  String? get error => _error;
  bool get isLocationServiceEnabled => _serviceEnabled;
  location.PermissionStatus? get locationPermissionStatus => _permissionGranted;
  bool get hasPermission => _hasPermission;
  String? get userName => _userName;
  List<geocoding.Placemark>? get placemarks => _placemarks;

  LatLng? get latLng => _locationData != null
      ? LatLng(_locationData!.latitude!, _locationData!.longitude!)
      : null;

  LocationProvider() {
    _initLocationService();
    _loadUserName();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  String _getPermissionMessage(location.PermissionStatus status) {
    switch (status) {
      case location.PermissionStatus.denied:
        return 'Konum izni reddedildi';
      case location.PermissionStatus.deniedForever:
        return 'Konum izni kalıcı olarak reddedildi. Lütfen ayarlardan manuel olarak izin verin';
      case location.PermissionStatus.grantedLimited:
        return 'Sınırlı konum izni verildi';
      case location.PermissionStatus.granted:
        return 'Konum izni verildi';
      default:
        return 'Bilinmeyen izin durumu';
    }
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('user_name');
    notifyListeners();
  }

  Future<void> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    _userName = name;
    notifyListeners();
  }

  Future<void> _initLocationService() async {
    try {
      _setLoading(true);
      _setError(null);

      _serviceEnabled = await _location.serviceEnabled();
      if (!_serviceEnabled) {
        _serviceEnabled = await _location.requestService();
        if (!_serviceEnabled) {
          _setError('Konum servisi devre dışı.');
          return;
        }
      }

      _permissionGranted = await _location.hasPermission();
      if (_permissionGranted == location.PermissionStatus.denied) {
        _permissionGranted = await _location.requestPermission();
        if (_permissionGranted != location.PermissionStatus.granted) {
          _setError(_getPermissionMessage(_permissionGranted!));
          return;
        }
      }

      _hasPermission = true;
      _setError(null);
      notifyListeners();

      _location.onLocationChanged.listen((location.LocationData locationData) {
        _onLocationChanged(locationData);
      });

      _locationData = await _location.getLocation();
      await _getPlacemarks();
      notifyListeners();
    } catch (e) {
      _setError('Konum servisi başlatılırken bir hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _onLocationChanged(location.LocationData locationData) {
    _locationData = locationData;
    _updateAddress();
    notifyListeners();
  }

  Future<void> _getPlacemarks() async {
    if (_locationData != null) {
      try {
        _placemarks = await geocoding.placemarkFromCoordinates(
          _locationData!.latitude!,
          _locationData!.longitude!,
        );
        notifyListeners();
      } catch (e) {
        _setError('Adres bilgisi alınırken bir hata oluştu: $e');
      }
    }
  }

  Future<void> _updateAddress() async {
    if (_locationData == null) return;

    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        _locationData!.latitude!,
        _locationData!.longitude!,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        _address = '${place.locality}, ${place.country}';
        notifyListeners();
      }
    } catch (e) {
      _setError('Adres bilgisi alınırken bir hata oluştu: $e');
    }
  }

  Future<void> updateLocation() async {
    try {
      final granted = await requestPermission();
      if (!granted) {
        _setError('Konum izni reddedildi.');
        return;
      }

      _locationData = await _location.getLocation();
      await _getPlacemarks();
      _setError(null);
      notifyListeners();
    } catch (e) {
      _setError('Konum güncellenirken bir hata oluştu: $e');
    }
  }

  Future<bool> requestPermission() async {
    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == location.PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
    }
    return _permissionGranted == location.PermissionStatus.granted;
  }

  Future<void> enableLocationService() async {
    try {
      _setLoading(true);
      _setError(null);

      _serviceEnabled = await _location.requestService();
      
      if (_serviceEnabled) {
        await updateLocation();
      } else {
        _setError('Konum servisi etkinleştirilemedi');
      }
      
    } catch (e) {
      _setError('Konum servisi etkinleştirilirken bir hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> startLocationUpdates() async {
    try {
      await _location.enableBackgroundMode(enable: true);
      
      _location.changeSettings(
        accuracy: location.LocationAccuracy.high,
        interval: 10000, // 10 saniye
        distanceFilter: 10, // 10 metre
      );
      
    } catch (e) {
      _setError('Konum güncellemeleri başlatılırken bir hata oluştu: $e');
    }
  }

  Future<void> stopLocationUpdates() async {
    try {
      await _location.enableBackgroundMode(enable: false);
      
    } catch (e) {
      _setError('Konum güncellemeleri durdurulurken bir hata oluştu: $e');
    }
  }

  // Mesafe hesaplama (metre cinsinden)
  double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // metre cinsinden dünya yarıçapı
    
    // Radyana çevir
    final lat1 = point1.latitude * (pi / 180);
    final lat2 = point2.latitude * (pi / 180);
    final dLat = (point2.latitude - point1.latitude) * (pi / 180);
    final dLon = (point2.longitude - point1.longitude) * (pi / 180);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  Future<void> getCurrentLocation() async {
    if (_permissionGranted != location.PermissionStatus.granted) {
      final granted = await requestPermission();
      if (!granted) return;
    }

    try {
      _locationData = await _location.getLocation();
      if (_locationData != null) {
        final locations = await geocoding.locationFromAddress(
          '${_locationData!.latitude}, ${_locationData!.longitude}'
        );
        if (locations.isNotEmpty) {
          _currentLocation = locations.first;
        }
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<String?> getAddressFromLocation(double lat, double lng) async {
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        _address = '${place.street}, ${place.locality}, ${place.country}';
        notifyListeners();
      }
    } catch (e) {
      print('Error getting address: $e');
    }
    return _address;
  }

  LatLng? getCurrentLatLng() {
    if (_locationData != null) {
      return LatLng(_locationData!.latitude!, _locationData!.longitude!);
    }
    return null;
  }

  String? getCurrentAddress() {
    if (_placemarks != null && _placemarks!.isNotEmpty) {
      final place = _placemarks!.first;
      return '${place.street}, ${place.locality}, ${place.country}';
    }
    return null;
  }

  Future<void> initLocationService() async {
    await _initLocationService();
  }
} 