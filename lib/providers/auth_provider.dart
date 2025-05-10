import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/app_security.dart';
import '../constants/app_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/activity.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final String _baseUrl = 'http://10.0.2.2:3001/api';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _user;
  bool _isLoading = false;
  String? _error;
  String? _token;
  DateTime? _tokenExpiryDate;
  List<String> _favoriteActivities = [];
  List<String> _savedPlans = [];
  Map<String, dynamic> _userPreferences = {};

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get token => _token;
  bool get isAuthenticated => _user != null;
  List<String> get favoriteActivities => _favoriteActivities;
  List<String> get savedPlans => _savedPlans;
  Map<String, dynamic> get userPreferences => _userPreferences;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        _loadUserData();
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserData() async {
    if (_user == null) return;

    try {
      final userDoc = await _firestore.collection('users').doc(_user!.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        _favoriteActivities = List<String>.from(data['favoriteActivities'] ?? []);
        _savedPlans = List<String>.from(data['savedPlans'] ?? []);
        _userPreferences = Map<String, dynamic>.from(data['preferences'] ?? {});
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> toggleFavoriteActivity(String activityId) async {
    if (_user == null) return;

    try {
      if (_favoriteActivities.contains(activityId)) {
        _favoriteActivities.remove(activityId);
      } else {
        _favoriteActivities.add(activityId);
      }

      await _firestore.collection('users').doc(_user!.uid).update({
        'favoriteActivities': _favoriteActivities,
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling favorite activity: $e');
    }
  }

  Future<void> savePlan(String planId) async {
    if (_user == null) return;

    try {
      if (!_savedPlans.contains(planId)) {
        _savedPlans.add(planId);
        await _firestore.collection('users').doc(_user!.uid).update({
          'savedPlans': _savedPlans,
        });
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error saving plan: $e');
    }
  }

  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    if (_user == null) return;

    try {
      _userPreferences = preferences;
      await _firestore.collection('users').doc(_user!.uid).update({
        'preferences': preferences,
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user preferences: $e');
    }
  }

  Future<void> markActivityAsVisited(String activityId) async {
    if (_user == null) return;

    try {
      await _firestore.collection('users').doc(_user!.uid).collection('visitedActivities').doc(activityId).set({
        'visitedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error marking activity as visited: $e');
    }
  }

  Future<bool> isActivityVisited(String activityId) async {
    if (_user == null) return false;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('visitedActivities')
          .doc(activityId)
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking visited activity: $e');
      return false;
    }
  }

  Future<void> rateActivity(String activityId, double rating, String? comment) async {
    if (_user == null) return;

    try {
      await _firestore.collection('users').doc(_user!.uid).collection('activityRatings').doc(activityId).set({
        'rating': rating,
        'comment': comment,
        'ratedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error rating activity: $e');
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = userCredential.user;
      _token = await _user?.getIdToken();
      notifyListeners();
    } catch (e) {
      _setError('Giriş yapılırken bir hata oluştu: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signUp(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = userCredential.user;
      _token = await _user?.getIdToken();
      notifyListeners();
    } catch (e) {
      _setError('Kayıt olurken bir hata oluştu: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      _setLoading(true);
      _setError(null);

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      _user = userCredential.user;
      _token = await _user?.getIdToken();
      notifyListeners();
    } catch (e) {
      _setError('Google ile giriş yapılırken bir hata oluştu: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      _setError(null);

      await _auth.signOut();
      await _googleSignIn.signOut();
      _user = null;
      _token = null;
      _tokenExpiryDate = null;
      notifyListeners();
    } catch (e) {
      _setError('Çıkış yapılırken bir hata oluştu: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      _setLoading(true);
      _setError(null);

      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      _setError('Şifre sıfırlama e-postası gönderilirken bir hata oluştu: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      if (_user == null) {
        throw Exception('Kullanıcı oturum açmamış');
      }

      await _user!.updateDisplayName(displayName);
      await _user!.updatePhotoURL(photoURL);

      _user = _auth.currentUser;
      notifyListeners();
    } catch (e) {
      _setError('Profil güncellenirken bir hata oluştu: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      _setLoading(true);
      _setError(null);

      if (_user == null || _user!.email == null) {
        throw Exception('Kullanıcı oturum açmamış');
      }

      final credential = EmailAuthProvider.credential(
        email: _user!.email!,
        password: currentPassword,
      );

      await _user!.reauthenticateWithCredential(credential);
      await _user!.updatePassword(newPassword);
    } catch (e) {
      _setError('Şifre değiştirilirken bir hata oluştu: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteAccount(String password) async {
    try {
      _setLoading(true);
      _setError(null);

      if (_user == null || _user!.email == null) {
        throw Exception('Kullanıcı oturum açmamış');
      }

      final credential = EmailAuthProvider.credential(
        email: _user!.email!,
        password: password,
      );

      await _user!.reauthenticateWithCredential(credential);
      await _user!.delete();
      _user = null;
      _token = null;
      _tokenExpiryDate = null;
      notifyListeners();
    } catch (e) {
      _setError('Hesap silinirken bir hata oluştu: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }
} 