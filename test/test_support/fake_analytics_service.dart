import 'package:hosh/core/analytics/app_analytics.dart';
import 'package:hosh/core/models/app_models.dart';

class FakeAnalyticsService extends NoopAnalyticsService {
  final List<AnalyticsEventRecord> events = <AnalyticsEventRecord>[];
  final Map<String, String?> userProperties = <String, String?>{};
  String? userId;

  bool sawEvent(String name) =>
      events.any((AnalyticsEventRecord e) => e.name == name);

  AnalyticsEventRecord? firstEvent(String name) {
    for (final AnalyticsEventRecord event in events) {
      if (event.name == name) {
        return event;
      }
    }
    return null;
  }

  @override
  void setUserId(String? userId) {
    this.userId = userId;
  }

  @override
  void setAppMode(String mode) {
    userProperties['app_mode'] = mode;
  }

  @override
  void setAuthModeAnonymous() {
    userProperties['auth_mode'] = 'anonymous';
  }

  @override
  void updatePermissionProperty(
    AnalyticsPermissionType permission,
    AppPermissionStatus status,
  ) {
    userProperties['${permission.name}_perm'] = status.name;
  }

  @override
  void updateCapabilityProperties({
    bool? audioAvailable,
    bool? torchAvailable,
  }) {
    if (audioAvailable != null) {
      userProperties['audio_capability'] = audioAvailable
          ? 'available'
          : 'unavailable';
    }
    if (torchAvailable != null) {
      userProperties['torch_capability'] = torchAvailable
          ? 'available'
          : 'unavailable';
    }
  }

  @override
  void logAppBootstrapStarted({
    required String platform,
    required bool firebaseExpected,
  }) {
    events.add(
      AnalyticsEventRecord('app_bootstrap_started', <String, Object?>{
        'platform': platform,
        'firebase_expected': firebaseExpected,
      }),
    );
  }

  @override
  void logFirebaseInitCompleted({
    required bool success,
    AnalyticsErrorType? errorType,
  }) {
    events.add(
      AnalyticsEventRecord('firebase_init_completed', <String, Object?>{
        'result': success ? 'success' : 'degraded',
        'error_type': errorType?.name,
      }),
    );
  }

  @override
  void logAnonymousAuthCompleted({
    required bool success,
    AnalyticsErrorType? errorType,
  }) {
    events.add(
      AnalyticsEventRecord('anonymous_auth_completed', <String, Object?>{
        'result': success ? 'success' : 'failed',
        'error_type': errorType?.name,
      }),
    );
  }

  @override
  void logAppReady({required String mode}) {
    events.add(
      AnalyticsEventRecord('app_ready', <String, Object?>{'mode': mode}),
    );
  }

  @override
  void logNotificationsInitCompleted({
    required bool success,
    required AppPermissionStatus permissionStatus,
  }) {
    events.add(
      AnalyticsEventRecord('notifications_init_completed', <String, Object?>{
        'result': success ? 'success' : 'failed',
        'permission_status': permissionStatus.name,
      }),
    );
  }

  @override
  void logPermissionPromptShown({
    required AnalyticsPermissionType permission,
    required String sourceScreen,
  }) {
    events.add(
      AnalyticsEventRecord('permission_prompt_shown', <String, Object?>{
        'permission': permission.name,
        'source_screen': sourceScreen,
      }),
    );
  }

  @override
  void logPermissionResult({
    required AnalyticsPermissionType permission,
    required AppPermissionStatus status,
    required String sourceScreen,
  }) {
    events.add(
      AnalyticsEventRecord('permission_result', <String, Object?>{
        'permission': permission.name,
        'status': status.name,
        'source_screen': sourceScreen,
      }),
    );
  }

  @override
  void logReportLocationSet({required GeoLocation? location}) {
    events.add(
      AnalyticsEventRecord('report_location_set', <String, Object?>{
        'area_bucket': areaBucket(location),
      }),
    );
  }

  @override
  void logReportBehaviorSelected({required DogBehavior behavior}) {
    events.add(
      AnalyticsEventRecord('report_behavior_selected', <String, Object?>{
        'behavior': behavior.name,
      }),
    );
  }

  @override
  void logReportSeveritySet({required ReportSeverity severity}) {
    events.add(
      AnalyticsEventRecord('report_severity_set', <String, Object?>{
        'severity': severity.name,
      }),
    );
  }

  @override
  void logReportDescriptionAdded() {
    events.add(AnalyticsEventRecord('report_description_added'));
  }

  @override
  void logReportPhotoAdded({required String source}) {
    events.add(
      AnalyticsEventRecord('report_photo_added', <String, Object?>{
        'source': source,
      }),
    );
  }

  @override
  void logReportPhotoRemoved() {
    events.add(AnalyticsEventRecord('report_photo_removed'));
  }

  @override
  void logReportSubmitAttempted({required DogReportDraft draft}) {
    events.add(AnalyticsEventRecord('report_submit_attempted'));
  }

  @override
  void logReportSubmitSucceeded({
    required DogReportDraft draft,
    required ReportSubmissionResult result,
  }) {
    events.add(
      AnalyticsEventRecord('report_submit_succeeded', <String, Object?>{
        'photo_uploaded': result.photoUploaded,
        'hotspot_action': result.hotspotAction?.name,
      }),
    );
  }

  @override
  void logReportSubmitFailed({
    required DogReportDraft draft,
    required String stage,
    required AnalyticsErrorType errorType,
    required bool hasPhoto,
  }) {
    events.add(
      AnalyticsEventRecord('report_submit_failed', <String, Object?>{
        'stage': stage,
        'error_type': errorType.name,
        'has_photo': hasPhoto,
      }),
    );
  }

  @override
  void logReportValidationFailed({
    required bool missingLocation,
    required bool missingBehavior,
    required bool missingSeverity,
    required bool invalidDogCount,
  }) {
    events.add(AnalyticsEventRecord('report_validation_failed'));
  }

  @override
  void logMapScreenOpened({required bool locationAvailable}) {
    events.add(
      AnalyticsEventRecord('map_screen_opened', <String, Object?>{
        'location_available': locationAvailable,
      }),
    );
  }

  @override
  void logMapLoadStarted({required LocationSource locationSource}) {
    events.add(
      AnalyticsEventRecord('map_load_started', <String, Object?>{
        'location_source': locationSource.name,
      }),
    );
  }

  @override
  void logMapLoadCompleted({
    required List<Hotspot> hotspots,
    required GeoLocation location,
    required LocationSource locationSource,
  }) {
    events.add(
      AnalyticsEventRecord('map_load_completed', <String, Object?>{
        'result': hotspots.isEmpty ? 'empty' : 'success',
        'location_source': locationSource.name,
        'area_bucket': areaBucket(location),
      }),
    );
  }

  @override
  void logMapLoadFailed({
    required AnalyticsErrorType errorType,
    required LocationSource locationSource,
  }) {
    events.add(
      AnalyticsEventRecord('map_load_failed', <String, Object?>{
        'error_type': errorType.name,
        'location_source': locationSource.name,
      }),
    );
  }

  @override
  void logHotspotMarkerSelected({required Hotspot hotspot}) {
    events.add(
      AnalyticsEventRecord('hotspot_marker_selected', <String, Object?>{
        'severity': hotspot.dangerLevel.name,
      }),
    );
  }

  @override
  void logMapReportCtaTapped({required GeoLocation? location}) {
    events.add(
      AnalyticsEventRecord('map_report_cta_tapped', <String, Object?>{
        'area_bucket': areaBucket(location),
      }),
    );
  }

  @override
  void logRepelScreenOpened({required String appMode}) {
    events.add(
      AnalyticsEventRecord('repel_screen_opened', <String, Object?>{
        'app_mode': appMode,
      }),
    );
  }

  @override
  void logRepelStartTapped({required double frequencyKhz}) {
    events.add(
      AnalyticsEventRecord('repel_start_tapped', <String, Object?>{
        'frequency_bucket': bucketFrequency(frequencyKhz),
      }),
    );
  }

  @override
  void logRepelStarted({required RepelSessionState session}) {
    events.add(AnalyticsEventRecord('repel_started'));
  }

  @override
  void logRepelPartialCapability({
    required RepelSessionState session,
    required AnalyticsErrorType errorType,
  }) {
    events.add(
      AnalyticsEventRecord('repel_partial_capability', <String, Object?>{
        'error_type': errorType.name,
      }),
    );
  }

  @override
  void logRepelStopTapped() {
    events.add(AnalyticsEventRecord('repel_stop_tapped'));
  }

  @override
  void logRepelStopped({
    required RepelSessionState previousSession,
    required Duration duration,
  }) {
    events.add(
      AnalyticsEventRecord('repel_stopped', <String, Object?>{
        'duration_bucket': bucketDuration(duration),
      }),
    );
  }

  @override
  void logRepelTorchToggled({
    required bool enabled,
    required bool duringSession,
  }) {
    events.add(
      AnalyticsEventRecord('repel_torch_toggled', <String, Object?>{
        'state': enabled ? 'on' : 'off',
      }),
    );
  }

  @override
  void logPanicTapped({required String sourceScreen}) {
    events.add(AnalyticsEventRecord('panic_tapped'));
  }

  @override
  void logRepelFailure({
    required String stage,
    required AnalyticsErrorType errorType,
    required String mode,
  }) {
    events.add(
      AnalyticsEventRecord('repel_failure', <String, Object?>{
        'stage': stage,
        'error_type': errorType.name,
        'mode': mode,
      }),
    );
  }
}

class AnalyticsEventRecord {
  const AnalyticsEventRecord(
    this.name, [
    this.parameters = const <String, Object?>{},
  ]);

  final String name;
  final Map<String, Object?> parameters;
}
