import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hosh/core/analytics/app_analytics.dart';
import 'package:hosh/core/adapters/firebase/report_submission_validation.dart';
import 'package:hosh/core/models/app_models.dart';
import 'package:hosh/core/repositories/contracts.dart';

class FirebaseAuthRepository implements AuthRepository {
  @override
  Future<String?> currentUserId() async =>
      FirebaseAuth.instance.currentUser?.uid;

  @override
  Future<String?> signInAnonymously() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      return currentUser.uid;
    }
    final UserCredential credential = await FirebaseAuth.instance
        .signInAnonymously();
    return credential.user?.uid;
  }
}

class GeolocatorLocationRepository implements LocationRepository {
  GeolocatorLocationRepository({
    required this.fallbackLocation,
    required this.analyticsService,
  });

  final GeoLocation fallbackLocation;
  final AnalyticsService analyticsService;

  @override
  Future<LocationSnapshot> getCurrentLocation({
    String sourceScreen = 'unknown',
  }) async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationSnapshot(
          location: fallbackLocation,
          source: LocationSource.fallback,
          permissionStatus: AppPermissionStatus.unknown,
        );
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        analyticsService.logPermissionPromptShown(
          permission: AnalyticsPermissionType.location,
          sourceScreen: sourceScreen,
        );
        permission = await Geolocator.requestPermission();
        analyticsService.logPermissionResult(
          permission: AnalyticsPermissionType.location,
          status: _permissionStatusFromLocationPermission(permission),
          sourceScreen: sourceScreen,
        );
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        analyticsService.updatePermissionProperty(
          AnalyticsPermissionType.location,
          _permissionStatusFromLocationPermission(permission),
        );
        return LocationSnapshot(
          location: fallbackLocation,
          source: LocationSource.fallback,
          permissionStatus: _permissionStatusFromLocationPermission(permission),
        );
      }
      final Position position = await Geolocator.getCurrentPosition();
      analyticsService.updatePermissionProperty(
        AnalyticsPermissionType.location,
        _permissionStatusFromLocationPermission(permission),
      );
      return LocationSnapshot(
        location: GeoLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
        source: LocationSource.device,
        permissionStatus: _permissionStatusFromLocationPermission(permission),
      );
    } catch (_) {
      return LocationSnapshot(
        location: fallbackLocation,
        source: LocationSource.fallback,
        permissionStatus: AppPermissionStatus.unknown,
      );
    }
  }
}

class FirestoreHotspotRepository implements HotspotRepository {
  @override
  Future<List<Hotspot>> fetchNearbyHotspots(GeoLocation origin) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
        .instance
        .collection('hotspots')
        .orderBy('lastReported', descending: true)
        .limit(30)
        .get();
    return snapshot.docs
        .map(
          (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              Hotspot.fromMap(doc.id, _normalizeHotspotData(doc.data())),
        )
        .toList(growable: false);
  }
}

class FirestoreReportRepository implements ReportRepository {
  FirestoreReportRepository(this.authRepository, this.analyticsService);

  final AuthRepository authRepository;
  final AnalyticsService analyticsService;

  @override
  Future<ReportSubmissionResult> submitReport(DogReportDraft draft) async {
    final DogReportDraft normalizedDraft = normalizeSubmittedReportDraft(draft);
    validateSubmittedReportDraft(normalizedDraft);

    final String userId;
    try {
      userId =
          await authRepository.currentUserId() ??
          await authRepository.signInAnonymously() ??
          (throw const ReportSubmissionFailure(
            type: ReportSubmissionFailureType.auth,
            message: 'Anonymous authentication is unavailable right now.',
          ));
    } on FirebaseAuthException {
      throw const ReportSubmissionFailure(
        type: ReportSubmissionFailureType.auth,
        message: 'Unable to verify your anonymous session right now.',
      );
    } on ReportSubmissionFailure {
      rethrow;
    } catch (_) {
      throw const ReportSubmissionFailure(
        type: ReportSubmissionFailureType.auth,
        message: 'Unable to verify your anonymous session right now.',
      );
    }

    String? photoUrl;
    bool photoUploaded = false;
    if (normalizedDraft.photoPath case final String localPath?) {
      try {
        final String uploadId = DateTime.now().microsecondsSinceEpoch
            .toString();
        final Reference ref = FirebaseStorage.instance.ref(
          'reports/$uploadId.jpg',
        );
        final UploadTask task = ref.putFile(File(localPath));
        await task.whenComplete(() {});
        photoUrl = await ref.getDownloadURL();
        photoUploaded = true;
        analyticsService.logStorageUploadCompleted(success: true);
      } on FirebaseException {
        analyticsService.logStorageUploadCompleted(
          success: false,
          errorType: AnalyticsErrorType.backend,
        );
        throw const ReportSubmissionFailure(
          type: ReportSubmissionFailureType.storage,
          message: 'Photo upload failed. Retry or submit without a photo.',
        );
      }
    }

    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final CollectionReference<Map<String, dynamic>> reports = firestore
        .collection('reports');
    final DocumentReference<Map<String, dynamic>> reportRef = reports.doc();

    final Map<String, dynamic> payload = normalizedDraft.toMap(userId: userId)
      ..remove('photoPath');
    payload['photoUrl'] = photoUrl;
    payload['timestamp'] = Timestamp.fromDate(normalizedDraft.detectedAt);
    payload['submittedAt'] = FieldValue.serverTimestamp();

    try {
      await reportRef.set(payload);
    } on ReportSubmissionFailure {
      rethrow;
    } on FirebaseException {
      throw const ReportSubmissionFailure(
        type: ReportSubmissionFailureType.database,
        message:
            'Live report submission failed. Check Firebase access and retry.',
      );
    }

    return ReportSubmissionResult(
      id: reportRef.id,
      submittedAt: DateTime.now(),
      source: SubmissionSource.live,
      photoUploaded: photoUploaded,
    );
  }
}

class FirestoreRepelEventRepository implements RepelEventRepository {
  FirestoreRepelEventRepository(this.authRepository);

  final AuthRepository authRepository;

  @override
  Future<RepelEventRecord?> createRepelEvent(RepelEventDraft draft) async {
    final String? userId =
        await authRepository.currentUserId() ??
        await authRepository.signInAnonymously();
    if (userId == null) {
      return null;
    }

    final CollectionReference<Map<String, dynamic>> repelEvents =
        FirebaseFirestore.instance.collection('repel_events');
    final DocumentReference<Map<String, dynamic>> docRef = repelEvents.doc();
    await docRef.set(<String, dynamic>{
      'userId': userId,
      'lat': draft.location.latitude,
      'lng': draft.location.longitude,
      'timestamp': Timestamp.fromDate(draft.timestamp),
    });

    return RepelEventRecord(
      id: docRef.id,
      userId: userId,
      location: draft.location,
      timestamp: draft.timestamp,
    );
  }
}

class FirebaseNotificationService implements NotificationService {
  FirebaseNotificationService(this.analyticsService);

  final AnalyticsService analyticsService;

  @override
  Future<NotificationInitializationResult> initialize() async {
    final NotificationSettings existingSettings = await FirebaseMessaging
        .instance
        .getNotificationSettings();
    final bool prompted =
        existingSettings.authorizationStatus ==
        AuthorizationStatus.notDetermined;
    if (prompted) {
      analyticsService.logPermissionPromptShown(
        permission: AnalyticsPermissionType.notifications,
        sourceScreen: 'bootstrap',
      );
    }
    final NotificationSettings settings = await FirebaseMessaging.instance
        .requestPermission();
    final AppPermissionStatus permissionStatus =
        _permissionStatusFromAuthorization(settings.authorizationStatus);
    analyticsService.logPermissionResult(
      permission: AnalyticsPermissionType.notifications,
      status: permissionStatus,
      sourceScreen: 'bootstrap',
    );
    return NotificationInitializationResult(
      permissionStatus: permissionStatus,
      prompted: prompted,
    );
  }
}

Map<String, dynamic> _normalizeHotspotData(Map<String, dynamic> data) {
  final Object? point = data['location'] ?? data['geoPoint'];
  double? latitude = (data['lat'] as num?)?.toDouble();
  double? longitude = (data['lng'] as num?)?.toDouble();
  if (point is GeoPoint) {
    latitude ??= point.latitude;
    longitude ??= point.longitude;
  }

  final Object? reportedAt =
      data['lastReported'] ?? data['timestamp'] ?? data['submittedAt'];
  final String? normalizedTimestamp = switch (reportedAt) {
    Timestamp value => value.toDate().toIso8601String(),
    DateTime value => value.toIso8601String(),
    String value => value,
    _ => null,
  };

  return <String, dynamic>{
    ...data,
    'lat': latitude,
    'lng': longitude,
    'lastReported': normalizedTimestamp,
  };
}

AppPermissionStatus _permissionStatusFromLocationPermission(
  LocationPermission permission,
) {
  return switch (permission) {
    LocationPermission.always ||
    LocationPermission.whileInUse => AppPermissionStatus.granted,
    LocationPermission.denied ||
    LocationPermission.deniedForever => AppPermissionStatus.denied,
    LocationPermission.unableToDetermine => AppPermissionStatus.unknown,
  };
}

AppPermissionStatus _permissionStatusFromAuthorization(
  AuthorizationStatus status,
) {
  return switch (status) {
    AuthorizationStatus.authorized => AppPermissionStatus.granted,
    AuthorizationStatus.provisional => AppPermissionStatus.limited,
    AuthorizationStatus.denied => AppPermissionStatus.denied,
    AuthorizationStatus.notDetermined => AppPermissionStatus.unknown,
  };
}
