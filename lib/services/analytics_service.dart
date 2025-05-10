import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  bool _enabled = true;

  // Enable/disable analytics (e.g., for GDPR compliance)
  Future<void> setAnalyticsEnabled(bool enabled) async {
    _enabled = enabled;
    await _analytics.setAnalyticsCollectionEnabled(enabled);
  }

  // User Properties
  Future<void> setUserProperties({
    String? userId,
    String? userRole,
    String? subscriptionType,
  }) async {
    if (!_enabled) return;

    try {
      if (userId != null) {
        await _analytics.setUserId(id: userId);
      }
      if (userRole != null) {
        await _analytics.setUserProperty(name: 'user_role', value: userRole);
      }
      if (subscriptionType != null) {
        await _analytics.setUserProperty(
          name: 'subscription_type',
          value: subscriptionType,
        );
      }
    } catch (e) {
      debugPrint('Error setting user properties: $e');
    }
  }

  // Authentication Events
  Future<void> logLogin({required String method}) async {
    if (!_enabled) return;

    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (e) {
      debugPrint('Error logging login: $e');
    }
  }

  Future<void> logSignUp({required String method}) async {
    if (!_enabled) return;

    try {
      await _analytics.logSignUp(signUpMethod: method);
    } catch (e) {
      debugPrint('Error logging sign up: $e');
    }
  }

  // Plan Events
  Future<void> logPlanCreated({
    required String planId,
    required String planType,
    required int duration,
    required double budget,
  }) async {
    if (!_enabled) return;

    try {
      await _analytics.logEvent(
        name: 'plan_created',
        parameters: {
          'plan_id': planId,
          'plan_type': planType,
          'duration_days': duration,
          'budget': budget,
        },
      );
    } catch (e) {
      debugPrint('Error logging plan creation: $e');
    }
  }

  Future<void> logPlanModified({
    required String planId,
    required String modificationType,
  }) async {
    if (!_enabled) return;

    try {
      await _analytics.logEvent(
        name: 'plan_modified',
        parameters: {
          'plan_id': planId,
          'modification_type': modificationType,
        },
      );
    } catch (e) {
      debugPrint('Error logging plan modification: $e');
    }
  }

  Future<void> logPlanShared({
    required String planId,
    required String shareMethod,
  }) async {
    if (!_enabled) return;

    try {
      await _analytics.logShare(
        contentType: 'plan',
        itemId: planId,
        method: shareMethod,
      );
    } catch (e) {
      debugPrint('Error logging plan share: $e');
    }
  }

  // Activity Events
  Future<void> logActivityAdded({
    required String planId,
    required String activityType,
    required String activityId,
  }) async {
    if (!_enabled) return;

    try {
      await _analytics.logEvent(
        name: 'activity_added',
        parameters: {
          'plan_id': planId,
          'activity_type': activityType,
          'activity_id': activityId,
        },
      );
    } catch (e) {
      debugPrint('Error logging activity addition: $e');
    }
  }

  Future<void> logActivityCompleted({
    required String planId,
    required String activityId,
    required double rating,
  }) async {
    if (!_enabled) return;

    try {
      await _analytics.logEvent(
        name: 'activity_completed',
        parameters: {
          'plan_id': planId,
          'activity_id': activityId,
          'rating': rating,
        },
      );
    } catch (e) {
      debugPrint('Error logging activity completion: $e');
    }
  }

  // Search Events
  Future<void> logSearch({
    required String searchTerm,
    required String searchType,
  }) async {
    if (!_enabled) return;

    try {
      await _analytics.logSearch(searchTerm: searchTerm);
      await _analytics.logEvent(
        name: 'custom_search',
        parameters: {
          'search_term': searchTerm,
          'search_type': searchType,
        },
      );
    } catch (e) {
      debugPrint('Error logging search: $e');
    }
  }

  // Error Events
  Future<void> logError({
    required String errorCode,
    required String errorMessage,
    required String errorContext,
  }) async {
    if (!_enabled) return;

    try {
      await _analytics.logEvent(
        name: 'app_error',
        parameters: {
          'error_code': errorCode,
          'error_message': errorMessage,
          'error_context': errorContext,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Error logging error event: $e');
    }
  }

  // Performance Events
  Future<void> logPerformanceMetric({
    required String metricName,
    required double value,
    Map<String, dynamic>? additionalParams,
  }) async {
    if (!_enabled) return;

    try {
      await _analytics.logEvent(
        name: 'performance_metric',
        parameters: {
          'metric_name': metricName,
          'value': value,
          'timestamp': DateTime.now().toIso8601String(),
          if (additionalParams != null) ...additionalParams,
        },
      );
    } catch (e) {
      debugPrint('Error logging performance metric: $e');
    }
  }

  // Screen Tracking
  Future<void> setCurrentScreen({
    required String screenName,
    String screenClass = 'Flutter',
  }) async {
    if (!_enabled) return;

    try {
      await _analytics.setCurrentScreen(
        screenName: screenName,
        screenClassOverride: screenClass,
      );
    } catch (e) {
      debugPrint('Error setting current screen: $e');
    }
  }

  // Custom Events
  Future<void> logCustomEvent({
    required String eventName,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_enabled) return;

    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters,
      );
    } catch (e) {
      debugPrint('Error logging custom event: $e');
    }
  }
} 