import 'package:equatable/equatable.dart';

enum SafetyStatus { protected, caution, danger }

enum DogBehavior { calm, barking, chasing, aggressive }

extension DogBehaviorX on DogBehavior {
  String get label => switch (this) {
    DogBehavior.calm => 'Calm',
    DogBehavior.barking => 'Barking',
    DogBehavior.chasing => 'Chasing',
    DogBehavior.aggressive => 'Aggressive',
  };
}

enum ReportSeverity { low, caution, high }

extension ReportSeverityX on ReportSeverity {
  String get shortLabel => switch (this) {
    ReportSeverity.low => 'LVL 1: LOW',
    ReportSeverity.caution => 'LVL 2: CAUTION',
    ReportSeverity.high => 'LVL 3: HIGH',
  };

  String get badgeLabel => switch (this) {
    ReportSeverity.low => 'Low',
    ReportSeverity.caution => 'Caution',
    ReportSeverity.high => 'High',
  };
}

enum RouteRiskLevel { safe, caution, danger }

enum SubmissionStatus { idle, submitting, success, failure }

enum BootstrapStatus { loading, ready, degraded }

enum SubmissionSource { live, fallback }

enum ReportSource { manual, postRepel }

enum ReportSubmissionFailureType {
  auth,
  storage,
  database,
  validation,
  unknown,
}

enum AppPermissionStatus { granted, denied, limited, unknown }

enum LocationSource { device, fallback }

enum HotspotSyncAction { created, updated }

class GeoLocation extends Equatable {
  const GeoLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  List<Object> get props => <Object>[latitude, longitude];
}

class LocationSnapshot extends Equatable {
  const LocationSnapshot({
    required this.location,
    required this.source,
    required this.permissionStatus,
  });

  final GeoLocation location;
  final LocationSource source;
  final AppPermissionStatus permissionStatus;

  @override
  List<Object> get props => <Object>[location, source, permissionStatus];
}

class ReportPrefill extends Equatable {
  const ReportPrefill({
    required this.detectedAt,
    required this.source,
    this.location,
    this.repelEventId,
  });

  final GeoLocation? location;
  final DateTime detectedAt;
  final ReportSource source;
  final String? repelEventId;

  @override
  List<Object?> get props => <Object?>[
    location,
    detectedAt,
    source,
    repelEventId,
  ];
}

class RepelEventDraft extends Equatable {
  const RepelEventDraft({required this.location, required this.timestamp});

  final GeoLocation location;
  final DateTime timestamp;

  @override
  List<Object> get props => <Object>[location, timestamp];
}

class RepelEventRecord extends Equatable {
  const RepelEventRecord({
    required this.id,
    required this.userId,
    required this.location,
    required this.timestamp,
  });

  final String id;
  final String userId;
  final GeoLocation location;
  final DateTime timestamp;

  ReportPrefill toReportPrefill() {
    return ReportPrefill(
      location: location,
      detectedAt: timestamp,
      source: ReportSource.postRepel,
      repelEventId: id,
    );
  }

  @override
  List<Object> get props => <Object>[id, userId, location, timestamp];
}

class NotificationInitializationResult extends Equatable {
  const NotificationInitializationResult({
    required this.permissionStatus,
    required this.prompted,
  });

  final AppPermissionStatus permissionStatus;
  final bool prompted;

  @override
  List<Object> get props => <Object>[permissionStatus, prompted];
}

class Hotspot extends Equatable {
  const Hotspot({
    required this.id,
    required this.location,
    required this.reportCount,
    required this.dangerLevel,
    required this.lastReported,
    required this.areaRadiusMeters,
    required this.note,
  });

  final String id;
  final GeoLocation location;
  final int reportCount;
  final RouteRiskLevel dangerLevel;
  final DateTime lastReported;
  final double areaRadiusMeters;
  final String note;

  factory Hotspot.fromMap(String id, Map<String, dynamic> map) {
    return Hotspot(
      id: id,
      location: GeoLocation(
        latitude: (map['lat'] as num?)?.toDouble() ?? 30.0444,
        longitude: (map['lng'] as num?)?.toDouble() ?? 31.2357,
      ),
      reportCount: (map['reportCount'] as num?)?.toInt() ?? 1,
      dangerLevel: _dangerLevelFromString(map['dangerLevel'] as String?),
      lastReported:
          DateTime.tryParse(map['lastReported'] as String? ?? '') ??
          DateTime.now(),
      areaRadiusMeters: (map['areaRadiusMeters'] as num?)?.toDouble() ?? 180,
      note: map['note'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'lat': location.latitude,
      'lng': location.longitude,
      'reportCount': reportCount,
      'dangerLevel': dangerLevel.name,
      'lastReported': lastReported.toIso8601String(),
      'areaRadiusMeters': areaRadiusMeters,
      'note': note,
    };
  }

  @override
  List<Object> get props => <Object>[
    id,
    location,
    reportCount,
    dangerLevel,
    lastReported,
    areaRadiusMeters,
    note,
  ];
}

class DogReportDraft extends Equatable {
  const DogReportDraft({
    required this.detectedAt,
    this.reportSource = ReportSource.manual,
    this.behavior,
    this.dogCount = 1,
    this.description = '',
    this.severity,
    this.location,
    this.anonymous = true,
    this.photoPath,
    this.repelEventId,
  });

  final ReportSource reportSource;
  final DogBehavior? behavior;
  final int dogCount;
  final String description;
  final ReportSeverity? severity;
  final GeoLocation? location;
  final DateTime detectedAt;
  final bool anonymous;
  final String? photoPath;
  final String? repelEventId;

  bool get isValid =>
      behavior != null && severity != null && location != null && dogCount >= 1;

  DogReportDraft copyWith({
    ReportSource? reportSource,
    Object? behavior = _unset,
    int? dogCount,
    String? description,
    Object? severity = _unset,
    Object? location = _unset,
    DateTime? detectedAt,
    bool? anonymous,
    Object? photoPath = _unset,
    Object? repelEventId = _unset,
  }) {
    return DogReportDraft(
      reportSource: reportSource ?? this.reportSource,
      behavior: identical(behavior, _unset)
          ? this.behavior
          : behavior as DogBehavior?,
      dogCount: dogCount ?? this.dogCount,
      description: description ?? this.description,
      severity: identical(severity, _unset)
          ? this.severity
          : severity as ReportSeverity?,
      location: identical(location, _unset)
          ? this.location
          : location as GeoLocation?,
      detectedAt: detectedAt ?? this.detectedAt,
      anonymous: anonymous ?? this.anonymous,
      photoPath: identical(photoPath, _unset)
          ? this.photoPath
          : photoPath as String?,
      repelEventId: identical(repelEventId, _unset)
          ? this.repelEventId
          : repelEventId as String?,
    );
  }

  Map<String, dynamic> toMap({required String userId}) {
    return <String, dynamic>{
      'userId': userId,
      'timestamp': detectedAt.toIso8601String(),
      'lat': location?.latitude,
      'lng': location?.longitude,
      'behavior': behavior?.name,
      'dogCount': dogCount,
      'severity': severity?.name,
      'description': description,
      'photoPath': photoPath,
      'anonymous': anonymous,
      'reportSource': reportSource.name,
      'repelEventId': repelEventId,
    };
  }

  @override
  List<Object?> get props => <Object?>[
    reportSource,
    behavior,
    dogCount,
    description,
    severity,
    location,
    detectedAt,
    anonymous,
    photoPath,
    repelEventId,
  ];
}

class ReportSubmissionResult extends Equatable {
  const ReportSubmissionResult({
    required this.id,
    required this.submittedAt,
    required this.source,
    this.photoUploaded = false,
    this.hotspotAction,
  });

  final String id;
  final DateTime submittedAt;
  final SubmissionSource source;
  final bool photoUploaded;
  final HotspotSyncAction? hotspotAction;

  bool get isLive => source == SubmissionSource.live;

  @override
  List<Object?> get props => <Object?>[
    id,
    submittedAt,
    source,
    photoUploaded,
    hotspotAction,
  ];
}

class ReportSubmissionFailure implements Exception {
  const ReportSubmissionFailure({required this.type, required this.message});

  final ReportSubmissionFailureType type;
  final String message;

  @override
  String toString() => message;
}

class RepelSettings extends Equatable {
  const RepelSettings({
    required this.frequencyKhz,
    required this.strobeEnabled,
    this.outputLabel = 'MAX VOL',
  });

  final double frequencyKhz;
  final bool strobeEnabled;
  final String outputLabel;

  @override
  List<Object> get props => <Object>[frequencyKhz, strobeEnabled, outputLabel];
}

class RepelSessionState extends Equatable {
  const RepelSessionState({
    required this.isActive,
    required this.frequencyKhz,
    required this.torchEnabled,
    required this.audioEnabled,
    required this.outputLabel,
    this.lastError,
  });

  factory RepelSessionState.idle({double frequencyKhz = 16.5}) {
    return RepelSessionState(
      isActive: false,
      frequencyKhz: frequencyKhz,
      torchEnabled: false,
      audioEnabled: false,
      outputLabel: 'MAX VOL',
    );
  }

  final bool isActive;
  final double frequencyKhz;
  final bool torchEnabled;
  final bool audioEnabled;
  final String outputLabel;
  final String? lastError;

  RepelSessionState copyWith({
    bool? isActive,
    double? frequencyKhz,
    bool? torchEnabled,
    bool? audioEnabled,
    String? outputLabel,
    Object? lastError = _unset,
  }) {
    return RepelSessionState(
      isActive: isActive ?? this.isActive,
      frequencyKhz: frequencyKhz ?? this.frequencyKhz,
      torchEnabled: torchEnabled ?? this.torchEnabled,
      audioEnabled: audioEnabled ?? this.audioEnabled,
      outputLabel: outputLabel ?? this.outputLabel,
      lastError: identical(lastError, _unset)
          ? this.lastError
          : lastError as String?,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    isActive,
    frequencyKhz,
    torchEnabled,
    audioEnabled,
    outputLabel,
    lastError,
  ];
}

RouteRiskLevel _dangerLevelFromString(String? value) {
  return switch (value) {
    'danger' => RouteRiskLevel.danger,
    'caution' => RouteRiskLevel.caution,
    _ => RouteRiskLevel.safe,
  };
}

const Object _unset = Object();
