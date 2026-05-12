import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../models/user_role.dart';

abstract class MonitoringService {
  Future<void> logEvent(
    String name, {
    Map<String, Object?> parameters = const {},
  });

  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    Map<String, Object?> parameters = const {},
  });
}

class NoopMonitoringService implements MonitoringService {
  const NoopMonitoringService();

  @override
  Future<void> logEvent(
    String name, {
    Map<String, Object?> parameters = const {},
  }) async {}

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    Map<String, Object?> parameters = const {},
  }) async {}
}

class DebugMonitoringService implements MonitoringService {
  const DebugMonitoringService();

  @override
  Future<void> logEvent(
    String name, {
    Map<String, Object?> parameters = const {},
  }) async {
    debugPrint('monitoring.event $name $parameters');
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    Map<String, Object?> parameters = const {},
  }) async {
    debugPrint('monitoring.error ${reason ?? ''} $error $parameters');
  }
}

class FirebaseMonitoringService implements MonitoringService {
  FirebaseAnalytics? _analytics;
  FirebaseCrashlytics? _crashlytics;

  FirebaseMonitoringService() {
    if (Firebase.apps.isNotEmpty) {
      _analytics = FirebaseAnalytics.instance;
      _crashlytics = FirebaseCrashlytics.instance;
      if (kReleaseMode) {
        _crashlytics?.setCrashlyticsCollectionEnabled(true);
      }
    }
  }

  @override
  Future<void> logEvent(String name,
      {Map<String, Object?> parameters = const {}}) async {
    final nonNullParameters = <String, Object>{};
    for (final entry in parameters.entries) {
      if (entry.value != null) {
        nonNullParameters[entry.key] = entry.value!;
      }
    }
    await _analytics?.logEvent(
        name: name,
        parameters: nonNullParameters.isEmpty ? null : nonNullParameters);
  }

  @override
  Future<void> recordError(Object error, StackTrace stackTrace,
      {String? reason, Map<String, Object?> parameters = const {}}) async {
    await _crashlytics?.recordError(error, stackTrace,
        reason: reason, fatal: false);
    if (parameters.isNotEmpty) {
      _crashlytics?.setCustomKey('error_params', parameters.toString());
    }
  }
}

class MonitoringEvents {
  static const loginSuccess = 'login_success';
  static const loginFailure = 'login_failure';
  static const homeworkSubmitted = 'homework_submitted';
  static const gradeCreated = 'grade_created';
  static const attendanceSaved = 'attendance_saved';
  static const fileUploaded = 'file_uploaded';
  static const adminAction = 'admin_action';
  static const securityDenied = 'security_denied';
}

Map<String, Object?> roleParameter(UserRole? role) {
  return {
    if (role != null) 'role': role.name,
  };
}
