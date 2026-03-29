import 'package:hosh/core/models/app_models.dart';

abstract class AuthRepository {
  Future<String?> signInAnonymously();

  Future<String?> currentUserId();
}

abstract class RepelDeviceService {
  Future<RepelSessionState> startRepel(RepelSettings settings);

  Future<RepelSessionState> stopRepel(RepelSessionState current);

  Future<String?> triggerPanicMode();

  Future<bool> setTorchEnabled(bool enabled);
}

abstract class LocationRepository {
  Future<LocationSnapshot> getCurrentLocation({
    String sourceScreen = 'unknown',
  });
}

abstract class HotspotRepository {
  Future<List<Hotspot>> fetchNearbyHotspots(GeoLocation origin);
}

abstract class ReportRepository {
  Future<ReportSubmissionResult> submitReport(DogReportDraft draft);
}

abstract class RepelEventRepository {
  Future<RepelEventRecord?> createRepelEvent(RepelEventDraft draft);
}

abstract class NotificationService {
  Future<NotificationInitializationResult> initialize();
}
