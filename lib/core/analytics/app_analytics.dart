import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:hosh/core/models/app_models.dart';

enum AnalyticsErrorType {
  permissionDenied,
  network,
  timeout,
  unsupported,
  backend,
  validation,
  unknown,
}

enum AnalyticsPermissionType { notifications, location, camera, photos }

enum AnalyticsCountBucket { zero, one, twoToFive, sixToTen, elevenPlus }

enum AnalyticsDurationBucket {
  lessThanTenSeconds,
  tenToThirtySeconds,
  thirtyToOneHundredTwentySeconds,
  twoToTenMinutes,
  overTenMinutes,
}

abstract class AnalyticsService {
  void setUserId(String? userId);

  void setAppMode(String mode);

  void setAuthModeAnonymous();

  void updatePermissionProperty(
    AnalyticsPermissionType permission,
    AppPermissionStatus status,
  );

  void updateCapabilityProperties({bool? audioAvailable, bool? torchAvailable});

  void logAppBootstrapStarted({
    required String platform,
    required bool firebaseExpected,
  });

  void logFirebaseInitCompleted({
    required bool success,
    AnalyticsErrorType? errorType,
  });

  void logNotificationsInitCompleted({
    required bool success,
    required AppPermissionStatus permissionStatus,
  });

  void logAnonymousAuthCompleted({
    required bool success,
    AnalyticsErrorType? errorType,
  });

  void logAppReady({required String mode});

  void logScreenView({required String screenName, required String screenClass});

  void logTabSelected({required String tabName, required String sourceTab});

  void logPermissionPromptShown({
    required AnalyticsPermissionType permission,
    required String sourceScreen,
  });

  void logPermissionResult({
    required AnalyticsPermissionType permission,
    required AppPermissionStatus status,
    required String sourceScreen,
  });

  void logRepelScreenOpened({required String appMode});

  void logRepelStartTapped({required double frequencyKhz});

  void logRepelStarted({required RepelSessionState session});

  void logRepelPartialCapability({
    required RepelSessionState session,
    required AnalyticsErrorType errorType,
  });

  void logRepelStopTapped();

  void logRepelStopped({
    required RepelSessionState previousSession,
    required Duration duration,
  });

  void logRepelTorchToggled({
    required bool enabled,
    required bool duringSession,
  });

  void logPanicTapped({required String sourceScreen});

  void logRepelFailure({
    required String stage,
    required AnalyticsErrorType errorType,
    required String mode,
  });

  void logReportScreenOpened({required String sourceTab});

  void logReportLocationSet({required GeoLocation? location});

  void logReportBehaviorSelected({required DogBehavior behavior});

  void logReportSeveritySet({required ReportSeverity severity});

  void logReportDescriptionAdded();

  void logReportPhotoAdded({required String source});

  void logReportPhotoRemoved();

  void logReportSubmitAttempted({required DogReportDraft draft});

  void logReportValidationFailed({
    required bool missingLocation,
    required bool missingBehavior,
    required bool missingSeverity,
    required bool invalidDogCount,
  });

  void logReportSubmitSucceeded({
    required DogReportDraft draft,
    required ReportSubmissionResult result,
  });

  void logReportSubmitFailed({
    required DogReportDraft draft,
    required String stage,
    required AnalyticsErrorType errorType,
    required bool hasPhoto,
  });

  void logMapScreenOpened({required bool locationAvailable});

  void logMapLoadStarted({required LocationSource locationSource});

  void logMapLoadCompleted({
    required List<Hotspot> hotspots,
    required GeoLocation location,
    required LocationSource locationSource,
  });

  void logMapLoadFailed({
    required AnalyticsErrorType errorType,
    required LocationSource locationSource,
  });

  void logHotspotMarkerSelected({required Hotspot hotspot});

  void logMapReportCtaTapped({required GeoLocation? location});

  void logHotspotSyncCompleted({
    required Hotspot hotspot,
    required HotspotSyncAction action,
  });

  void logHotspotSyncFailed({
    required GeoLocation? location,
    required AnalyticsErrorType errorType,
  });

  void logStorageUploadCompleted({
    required bool success,
    AnalyticsErrorType? errorType,
  });
}

class NoopAnalyticsService implements AnalyticsService {
  @override
  void logAnonymousAuthCompleted({
    required bool success,
    AnalyticsErrorType? errorType,
  }) {}

  @override
  void logAppBootstrapStarted({
    required String platform,
    required bool firebaseExpected,
  }) {}

  @override
  void logAppReady({required String mode}) {}

  @override
  void logFirebaseInitCompleted({
    required bool success,
    AnalyticsErrorType? errorType,
  }) {}

  @override
  void logHotspotMarkerSelected({required Hotspot hotspot}) {}

  @override
  void logHotspotSyncCompleted({
    required Hotspot hotspot,
    required HotspotSyncAction action,
  }) {}

  @override
  void logHotspotSyncFailed({
    required GeoLocation? location,
    required AnalyticsErrorType errorType,
  }) {}

  @override
  void logMapLoadCompleted({
    required List<Hotspot> hotspots,
    required GeoLocation location,
    required LocationSource locationSource,
  }) {}

  @override
  void logMapLoadFailed({
    required AnalyticsErrorType errorType,
    required LocationSource locationSource,
  }) {}

  @override
  void logMapLoadStarted({required LocationSource locationSource}) {}

  @override
  void logMapReportCtaTapped({required GeoLocation? location}) {}

  @override
  void logMapScreenOpened({required bool locationAvailable}) {}

  @override
  void logNotificationsInitCompleted({
    required bool success,
    required AppPermissionStatus permissionStatus,
  }) {}

  @override
  void logPanicTapped({required String sourceScreen}) {}

  @override
  void logPermissionPromptShown({
    required AnalyticsPermissionType permission,
    required String sourceScreen,
  }) {}

  @override
  void logPermissionResult({
    required AnalyticsPermissionType permission,
    required AppPermissionStatus status,
    required String sourceScreen,
  }) {}

  @override
  void logRepelFailure({
    required String stage,
    required AnalyticsErrorType errorType,
    required String mode,
  }) {}

  @override
  void logRepelPartialCapability({
    required RepelSessionState session,
    required AnalyticsErrorType errorType,
  }) {}

  @override
  void logRepelScreenOpened({required String appMode}) {}

  @override
  void logRepelStartTapped({required double frequencyKhz}) {}

  @override
  void logRepelStarted({required RepelSessionState session}) {}

  @override
  void logRepelStopTapped() {}

  @override
  void logRepelStopped({
    required RepelSessionState previousSession,
    required Duration duration,
  }) {}

  @override
  void logRepelTorchToggled({
    required bool enabled,
    required bool duringSession,
  }) {}

  @override
  void logReportBehaviorSelected({required DogBehavior behavior}) {}

  @override
  void logReportDescriptionAdded() {}

  @override
  void logReportLocationSet({required GeoLocation? location}) {}

  @override
  void logReportPhotoAdded({required String source}) {}

  @override
  void logReportPhotoRemoved() {}

  @override
  void logReportScreenOpened({required String sourceTab}) {}

  @override
  void logReportSeveritySet({required ReportSeverity severity}) {}

  @override
  void logReportSubmitAttempted({required DogReportDraft draft}) {}

  @override
  void logReportSubmitFailed({
    required DogReportDraft draft,
    required String stage,
    required AnalyticsErrorType errorType,
    required bool hasPhoto,
  }) {}

  @override
  void logReportSubmitSucceeded({
    required DogReportDraft draft,
    required ReportSubmissionResult result,
  }) {}

  @override
  void logReportValidationFailed({
    required bool missingLocation,
    required bool missingBehavior,
    required bool missingSeverity,
    required bool invalidDogCount,
  }) {}

  @override
  void logScreenView({
    required String screenName,
    required String screenClass,
  }) {}

  @override
  void logStorageUploadCompleted({
    required bool success,
    AnalyticsErrorType? errorType,
  }) {}

  @override
  void logTabSelected({required String tabName, required String sourceTab}) {}

  @override
  void setAppMode(String mode) {}

  @override
  void setAuthModeAnonymous() {}

  @override
  void setUserId(String? userId) {}

  @override
  void updateCapabilityProperties({
    bool? audioAvailable,
    bool? torchAvailable,
  }) {}

  @override
  void updatePermissionProperty(
    AnalyticsPermissionType permission,
    AppPermissionStatus status,
  ) {}
}

class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService();

  @override
  void setUserId(String? userId) {
    unawaited(_guard((FirebaseAnalytics analytics) => analytics.setUserId(id: userId)));
  }

  @override
  void setAppMode(String mode) => _setUserProperty('app_mode', mode);

  @override
  void setAuthModeAnonymous() => _setUserProperty('auth_mode', 'anonymous');

  @override
  void updatePermissionProperty(
    AnalyticsPermissionType permission,
    AppPermissionStatus status,
  ) {
    final String name = switch (permission) {
      AnalyticsPermissionType.notifications => 'notif_perm',
      AnalyticsPermissionType.location => 'location_perm',
      AnalyticsPermissionType.camera => 'camera_perm',
      AnalyticsPermissionType.photos => 'photos_perm',
    };
    _setUserProperty(name, status.name);
  }

  @override
  void updateCapabilityProperties({
    bool? audioAvailable,
    bool? torchAvailable,
  }) {
    if (audioAvailable != null) {
      _setUserProperty(
        'audio_capability',
        audioAvailable ? 'available' : 'unavailable',
      );
    }
    if (torchAvailable != null) {
      _setUserProperty(
        'torch_capability',
        torchAvailable ? 'available' : 'unavailable',
      );
    }
  }

  @override
  void logAppBootstrapStarted({
    required String platform,
    required bool firebaseExpected,
  }) => _logEvent('app_bootstrap_started', <String, Object>{
    'platform': platform,
    'firebase_expected': firebaseExpected,
  });

  @override
  void logFirebaseInitCompleted({
    required bool success,
    AnalyticsErrorType? errorType,
  }) => _logEvent('firebase_init_completed', <String, Object?>{
    'result': success ? 'success' : 'degraded',
    'error_type': errorType?.name,
  });

  @override
  void logNotificationsInitCompleted({
    required bool success,
    required AppPermissionStatus permissionStatus,
  }) => _logEvent('notifications_init_completed', <String, Object>{
    'result': success ? 'success' : 'failed',
    'permission_status': permissionStatus.name,
  });

  @override
  void logAnonymousAuthCompleted({
    required bool success,
    AnalyticsErrorType? errorType,
  }) => _logEvent('anonymous_auth_completed', <String, Object?>{
    'result': success ? 'success' : 'failed',
    'error_type': errorType?.name,
  });

  @override
  void logAppReady({required String mode}) =>
      _logEvent('app_ready', <String, Object>{'mode': mode});

  @override
  void logScreenView({
    required String screenName,
    required String screenClass,
  }) {
    unawaited(
      _guard(
        (FirebaseAnalytics analytics) => analytics.logScreenView(
          screenName: screenName,
          screenClass: screenClass,
        ),
      ),
    );
  }

  @override
  void logTabSelected({required String tabName, required String sourceTab}) =>
      _logEvent('tab_selected', <String, Object>{
        'tab_name': tabName,
        'source_tab': sourceTab,
      });

  @override
  void logPermissionPromptShown({
    required AnalyticsPermissionType permission,
    required String sourceScreen,
  }) => _logEvent('permission_prompt_shown', <String, Object>{
    'permission': permission.name,
    'source_screen': sourceScreen,
  });

  @override
  void logPermissionResult({
    required AnalyticsPermissionType permission,
    required AppPermissionStatus status,
    required String sourceScreen,
  }) {
    updatePermissionProperty(permission, status);
    _logEvent('permission_result', <String, Object>{
      'permission': permission.name,
      'status': status.name,
      'source_screen': sourceScreen,
    });
  }

  @override
  void logRepelScreenOpened({required String appMode}) =>
      _logEvent('repel_screen_opened', <String, Object>{'app_mode': appMode});

  @override
  void logRepelStartTapped({required double frequencyKhz}) => _logEvent(
    'repel_start_tapped',
    <String, Object>{'frequency_bucket': bucketFrequency(frequencyKhz)},
  );

  @override
  void logRepelStarted({required RepelSessionState session}) =>
      _logEvent('repel_started', <String, Object>{
        'mode': modeForSession(session),
        'audio_available': session.audioEnabled,
        'torch_available': session.torchEnabled,
        'frequency_bucket': bucketFrequency(session.frequencyKhz),
      });

  @override
  void logRepelPartialCapability({
    required RepelSessionState session,
    required AnalyticsErrorType errorType,
  }) => _logEvent('repel_partial_capability', <String, Object>{
    'mode': modeForSession(session),
    'missing': missingCapabilityForSession(session),
    'error_type': errorType.name,
  });

  @override
  void logRepelStopTapped() => _logEvent('repel_stop_tapped');

  @override
  void logRepelStopped({
    required RepelSessionState previousSession,
    required Duration duration,
  }) => _logEvent('repel_stopped', <String, Object>{
    'mode': modeForSession(previousSession),
    'duration_bucket': bucketDuration(duration),
  });

  @override
  void logRepelTorchToggled({
    required bool enabled,
    required bool duringSession,
  }) => _logEvent('repel_torch_toggled', <String, Object>{
    'state': enabled ? 'on' : 'off',
    'during_session': duringSession,
  });

  @override
  void logPanicTapped({required String sourceScreen}) => _logEvent(
    'panic_tapped',
    <String, Object>{'source_screen': sourceScreen},
  );

  @override
  void logRepelFailure({
    required String stage,
    required AnalyticsErrorType errorType,
    required String mode,
  }) => _logEvent('repel_failure', <String, Object>{
    'stage': stage,
    'error_type': errorType.name,
    'mode': mode,
  });

  @override
  void logReportScreenOpened({required String sourceTab}) => _logEvent(
    'report_screen_opened',
    <String, Object>{'source_tab': sourceTab},
  );

  @override
  void logReportLocationSet({required GeoLocation? location}) => _logEvent(
    'report_location_set',
    <String, Object?>{'area_bucket': areaBucket(location)},
  );

  @override
  void logReportBehaviorSelected({required DogBehavior behavior}) => _logEvent(
    'report_behavior_selected',
    <String, Object>{'behavior': behavior.name},
  );

  @override
  void logReportSeveritySet({required ReportSeverity severity}) => _logEvent(
    'report_severity_set',
    <String, Object>{'severity': severity.name},
  );

  @override
  void logReportDescriptionAdded() => _logEvent(
    'report_description_added',
    <String, Object>{'has_description': true},
  );

  @override
  void logReportPhotoAdded({required String source}) =>
      _logEvent('report_photo_added', <String, Object>{'source': source});

  @override
  void logReportPhotoRemoved() => _logEvent('report_photo_removed');

  @override
  void logReportSubmitAttempted({required DogReportDraft draft}) =>
      _logEvent('report_submit_attempted', _reportDraftParams(draft));

  @override
  void logReportValidationFailed({
    required bool missingLocation,
    required bool missingBehavior,
    required bool missingSeverity,
    required bool invalidDogCount,
  }) => _logEvent('report_validation_failed', <String, Object>{
    'missing_location': missingLocation,
    'missing_behavior': missingBehavior,
    'missing_severity': missingSeverity,
    'invalid_dog_count': invalidDogCount,
  });

  @override
  void logReportSubmitSucceeded({
    required DogReportDraft draft,
    required ReportSubmissionResult result,
  }) => _logEvent('report_submit_succeeded', <String, Object?>{
    ..._reportDraftParams(draft),
    'photo_uploaded': result.photoUploaded,
    'hotspot_action': result.hotspotAction?.name,
  });

  @override
  void logReportSubmitFailed({
    required DogReportDraft draft,
    required String stage,
    required AnalyticsErrorType errorType,
    required bool hasPhoto,
  }) => _logEvent('report_submit_failed', <String, Object?>{
    ..._reportDraftParams(draft),
    'stage': stage,
    'error_type': errorType.name,
    'has_photo': hasPhoto,
  });

  @override
  void logMapScreenOpened({required bool locationAvailable}) => _logEvent(
    'map_screen_opened',
    <String, Object>{'location_available': locationAvailable},
  );

  @override
  void logMapLoadStarted({required LocationSource locationSource}) => _logEvent(
    'map_load_started',
    <String, Object>{'location_source': locationSource.name},
  );

  @override
  void logMapLoadCompleted({
    required List<Hotspot> hotspots,
    required GeoLocation location,
    required LocationSource locationSource,
  }) {
    final DateTime? latest = hotspots.isEmpty
        ? null
        : hotspots
              .map((Hotspot hotspot) => hotspot.lastReported)
              .reduce((DateTime a, DateTime b) => a.isAfter(b) ? a : b);
    _logEvent('map_load_completed', <String, Object?>{
      'result': hotspots.isEmpty ? 'empty' : 'success',
      'area_bucket': areaBucket(location),
      'total_hotspots_bucket': bucketHotspotCount(hotspots.length),
      'danger_hotspots_bucket': bucketHotspotCount(
        hotspots
            .where(
              (Hotspot hotspot) => hotspot.dangerLevel == RouteRiskLevel.danger,
            )
            .length,
      ),
      'caution_hotspots_bucket': bucketHotspotCount(
        hotspots
            .where(
              (Hotspot hotspot) =>
                  hotspot.dangerLevel == RouteRiskLevel.caution,
            )
            .length,
      ),
      'freshness_bucket': latest == null ? null : bucketFreshness(latest),
      'location_source': locationSource.name,
    });
  }

  @override
  void logMapLoadFailed({
    required AnalyticsErrorType errorType,
    required LocationSource locationSource,
  }) => _logEvent('map_load_failed', <String, Object>{
    'error_type': errorType.name,
    'location_source': locationSource.name,
  });

  @override
  void logHotspotMarkerSelected({required Hotspot hotspot}) =>
      _logEvent('hotspot_marker_selected', <String, Object>{
        'severity': hotspot.dangerLevel.name,
        'report_count_bucket': bucketHotspotCount(hotspot.reportCount),
        'freshness_bucket': bucketFreshness(hotspot.lastReported),
      });

  @override
  void logMapReportCtaTapped({required GeoLocation? location}) => _logEvent(
    'map_report_cta_tapped',
    <String, Object?>{'area_bucket': areaBucket(location)},
  );

  @override
  void logHotspotSyncCompleted({
    required Hotspot hotspot,
    required HotspotSyncAction action,
  }) => _logEvent('hotspot_sync_completed', <String, Object>{
    'action': action.name,
    'severity': hotspot.dangerLevel.name,
    'report_count_bucket': bucketHotspotCount(hotspot.reportCount),
    'area_bucket': areaBucket(hotspot.location),
  });

  @override
  void logHotspotSyncFailed({
    required GeoLocation? location,
    required AnalyticsErrorType errorType,
  }) => _logEvent('hotspot_sync_failed', <String, Object?>{
    'error_type': errorType.name,
    'area_bucket': areaBucket(location),
  });

  @override
  void logStorageUploadCompleted({
    required bool success,
    AnalyticsErrorType? errorType,
  }) => _logEvent('storage_upload_completed', <String, Object?>{
    'result': success ? 'success' : 'failed',
    'error_type': errorType?.name,
    'source_flow': 'report',
  });

  void _setUserProperty(String name, String value) {
    unawaited(
      _guard(
        (FirebaseAnalytics analytics) =>
            analytics.setUserProperty(name: name, value: value),
      ),
    );
  }

  void _logEvent(String name, [Map<String, Object?>? params]) {
    final Map<String, Object> filtered = <String, Object>{};
    params?.forEach((String key, Object? value) {
      if (value != null) {
        filtered[key] = value;
      }
    });
    unawaited(
      _guard(
        (FirebaseAnalytics analytics) =>
            analytics.logEvent(name: name, parameters: filtered),
      ),
    );
  }

  Future<void> _guard(Future<void> Function(FirebaseAnalytics analytics) action) async {
    final FirebaseAnalytics? analytics = _analyticsOrNull;
    if (analytics == null) {
      return;
    }
    try {
      await action(analytics);
    } catch (_) {}
  }

  FirebaseAnalytics? get _analyticsOrNull {
    if (Firebase.apps.isEmpty) {
      return null;
    }
    return FirebaseAnalytics.instance;
  }
}

class HooshAnalyticsObserver extends NavigatorObserver {
  HooshAnalyticsObserver(this.analyticsService);

  final AnalyticsService analyticsService;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _logRoute(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      _logRoute(newRoute);
    }
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  void _logRoute(Route<dynamic> route) {
    final String? routeName = route.settings.name;
    if (routeName == null) {
      return;
    }
    switch (routeName) {
      case 'map':
      case 'repel':
      case 'report':
      case 'info':
        analyticsService.logScreenView(
          screenName: routeName,
          screenClass: '${routeName}_screen',
        );
    }
  }
}

Map<String, Object?> _reportDraftParams(DogReportDraft draft) {
  return <String, Object?>{
    'behavior': draft.behavior?.name,
    'severity': draft.severity?.name,
    'dog_count_bucket': bucketDogCount(draft.dogCount),
    'has_photo': draft.photoPath != null,
    'anonymous': draft.anonymous,
    'area_bucket': areaBucket(draft.location),
  };
}

String areaBucket(GeoLocation? location) {
  if (location == null) {
    return 'unknown';
  }
  final double latBucket = (location.latitude * 10).floorToDouble() / 10;
  final double lngBucket = (location.longitude * 10).floorToDouble() / 10;
  return '${latBucket.toStringAsFixed(1)}_${lngBucket.toStringAsFixed(1)}';
}

String bucketDogCount(int dogCount) {
  if (dogCount <= 1) {
    return '1';
  }
  if (dogCount <= 3) {
    return '2_3';
  }
  if (dogCount <= 6) {
    return '4_6';
  }
  return '7_plus';
}

String bucketHotspotCount(int count) {
  if (count <= 0) {
    return '0';
  }
  if (count == 1) {
    return '1';
  }
  if (count <= 5) {
    return '2_5';
  }
  if (count <= 10) {
    return '6_10';
  }
  return '11_plus';
}

String bucketDuration(Duration duration) {
  if (duration < const Duration(seconds: 10)) {
    return 'lt_10s';
  }
  if (duration < const Duration(seconds: 30)) {
    return '10_30s';
  }
  if (duration < const Duration(seconds: 120)) {
    return '30_120s';
  }
  if (duration < const Duration(minutes: 10)) {
    return '2_10m';
  }
  return '10m_plus';
}

String bucketFreshness(DateTime timestamp) {
  final Duration age = DateTime.now().difference(timestamp);
  if (age < const Duration(minutes: 15)) {
    return 'lt_15m';
  }
  if (age < const Duration(hours: 1)) {
    return '15_60m';
  }
  if (age < const Duration(hours: 6)) {
    return '1_6h';
  }
  if (age < const Duration(hours: 24)) {
    return '6_24h';
  }
  if (age < const Duration(days: 7)) {
    return '1_7d';
  }
  return '7d_plus';
}

String bucketFrequency(double frequencyKhz) {
  if (frequencyKhz < 16) {
    return '15_16';
  }
  if (frequencyKhz < 17) {
    return '16_17';
  }
  return '17_18';
}

String modeForSession(RepelSessionState session) {
  if (session.audioEnabled && session.torchEnabled) {
    return 'full';
  }
  if (session.audioEnabled) {
    return 'audio_only';
  }
  if (session.torchEnabled) {
    return 'torch_only';
  }
  return 'none';
}

String missingCapabilityForSession(RepelSessionState session) {
  if (!session.audioEnabled && !session.torchEnabled) {
    return 'both';
  }
  if (!session.audioEnabled) {
    return 'audio';
  }
  return 'torch';
}

AnalyticsErrorType analyticsErrorTypeFromObject(Object? error) {
  if (error is TimeoutException) {
    return AnalyticsErrorType.timeout;
  }
  if (error is ReportSubmissionFailure) {
    return switch (error.type) {
      ReportSubmissionFailureType.validation => AnalyticsErrorType.validation,
      ReportSubmissionFailureType.storage => AnalyticsErrorType.backend,
      ReportSubmissionFailureType.database => AnalyticsErrorType.backend,
      ReportSubmissionFailureType.auth => AnalyticsErrorType.backend,
      ReportSubmissionFailureType.unknown => AnalyticsErrorType.unknown,
    };
  }
  final String message = (error ?? '').toString().toLowerCase();
  if (message.contains('permission')) {
    return AnalyticsErrorType.permissionDenied;
  }
  if (message.contains('network')) {
    return AnalyticsErrorType.network;
  }
  if (message.contains('timeout')) {
    return AnalyticsErrorType.timeout;
  }
  if (message.contains('unavailable') ||
      message.contains('unsupported') ||
      message.contains('not available')) {
    return AnalyticsErrorType.unsupported;
  }
  if (message.contains('firebase') ||
      message.contains('firestore') ||
      message.contains('storage') ||
      message.contains('auth')) {
    return AnalyticsErrorType.backend;
  }
  return AnalyticsErrorType.unknown;
}

String appModeFromBootstrap(AppBootstrapStatus bootstrapStatus) {
  return switch (bootstrapStatus) {
    AppBootstrapStatus.live => 'live',
    AppBootstrapStatus.degraded => 'degraded',
    AppBootstrapStatus.localSafe => 'local_safe',
  };
}

enum AppBootstrapStatus { live, degraded, localSafe }

String tabNameForIndex(int index) {
  return switch (index) {
    0 => 'map',
    1 => 'repel',
    2 => 'report',
    _ => 'info',
  };
}
