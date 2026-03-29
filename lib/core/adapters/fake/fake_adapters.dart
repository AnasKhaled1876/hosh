import 'dart:async';

import 'package:hosh/core/models/app_models.dart';
import 'package:hosh/core/repositories/contracts.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  Future<String?> signInAnonymously() async => 'demo-anon-user';

  @override
  Future<String?> currentUserId() async => 'demo-anon-user';
}

class FakeHotspotRepository implements HotspotRepository {
  @override
  Future<List<Hotspot>> fetchNearbyHotspots(GeoLocation origin) async {
    return <Hotspot>[
      Hotspot(
        id: 'hs-1',
        location: GeoLocation(
          latitude: origin.latitude + 0.0012,
          longitude: origin.longitude - 0.0017,
        ),
        reportCount: 4,
        dangerLevel: RouteRiskLevel.caution,
        lastReported: DateTime.now().subtract(const Duration(minutes: 35)),
        areaRadiusMeters: 180,
        note: 'Pack near the northern park gate.',
      ),
      Hotspot(
        id: 'hs-2',
        location: GeoLocation(
          latitude: origin.latitude - 0.0015,
          longitude: origin.longitude + 0.0013,
        ),
        reportCount: 7,
        dangerLevel: RouteRiskLevel.danger,
        lastReported: DateTime.now().subtract(const Duration(minutes: 12)),
        areaRadiusMeters: 220,
        note: 'Aggressive barking around side street food stalls.',
      ),
    ];
  }
}

class FakeReportRepository implements ReportRepository {
  @override
  Future<ReportSubmissionResult> submitReport(DogReportDraft draft) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return ReportSubmissionResult(
      id: 'demo-report-${draft.detectedAt.microsecondsSinceEpoch}',
      submittedAt: DateTime.now(),
      source: SubmissionSource.fallback,
    );
  }
}

class FakeRepelEventRepository implements RepelEventRepository {
  int _counter = 0;

  @override
  Future<RepelEventRecord?> createRepelEvent(RepelEventDraft draft) async {
    _counter += 1;
    return RepelEventRecord(
      id: 'repel-event-$_counter',
      userId: 'demo-anon-user',
      location: draft.location,
      timestamp: draft.timestamp,
    );
  }
}

class FakeRepelDeviceService implements RepelDeviceService {
  @override
  Future<RepelSessionState> startRepel(RepelSettings settings) async {
    return RepelSessionState(
      isActive: true,
      frequencyKhz: settings.frequencyKhz,
      torchEnabled: settings.strobeEnabled,
      audioEnabled: true,
      outputLabel: settings.outputLabel,
    );
  }

  @override
  Future<RepelSessionState> stopRepel(RepelSessionState current) async {
    return current.copyWith(
      isActive: false,
      audioEnabled: false,
      torchEnabled: false,
    );
  }

  @override
  Future<bool> setTorchEnabled(bool enabled) async => enabled;

  @override
  Future<String?> triggerPanicMode() async {
    return 'Panic mode triggered. Share location with trusted contacts immediately.';
  }
}

class NoopNotificationService implements NotificationService {
  @override
  Future<NotificationInitializationResult> initialize() async {
    return const NotificationInitializationResult(
      permissionStatus: AppPermissionStatus.unknown,
      prompted: false,
    );
  }
}
