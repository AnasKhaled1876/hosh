import 'package:flutter_test/flutter_test.dart';
import 'package:hosh/core/models/app_models.dart';
import 'package:hosh/core/repositories/contracts.dart';
import 'package:hosh/features/report/cubit/report_cubit.dart';
import '../test_support/fake_analytics_service.dart';

void main() {
  test(
    'report submission creates only a report and leaves hotspot aggregation to the backend',
    () async {
      final _InMemorySafetyBackend backend = _InMemorySafetyBackend();
      final _StaticLocationRepository locationRepository =
          _StaticLocationRepository();
      final FakeAnalyticsService analytics = FakeAnalyticsService();

      final ReportCubit reportCubit = ReportCubit(
        reportRepository: backend,
        locationRepository: locationRepository,
        analyticsService: analytics,
      );
      await reportCubit.initialize();
      reportCubit.updateBehavior(DogBehavior.aggressive);
      reportCubit.updateDescription('Aggressive pack near the north gate');
      reportCubit.updateSeverity(0.9);
      await reportCubit.submit();

      expect(reportCubit.state.submissionStatus, SubmissionStatus.success);
      expect(
        reportCubit.state.successMessage,
        'Report shared. Hotspot intelligence will refresh shortly.',
      );
      expect(backend.reportCount, 1);
      expect(backend.hotspotCount, 0);
    },
  );
}

class _InMemorySafetyBackend implements ReportRepository, HotspotRepository {
  final Map<String, Map<String, dynamic>> _hotspotStore =
      <String, Map<String, dynamic>>{};
  final List<Map<String, dynamic>> _reportStore = <Map<String, dynamic>>[];

  int get reportCount => _reportStore.length;
  int get hotspotCount => _hotspotStore.length;

  @override
  Future<List<Hotspot>> fetchNearbyHotspots(GeoLocation origin) async {
    return const <Hotspot>[];
  }

  @override
  Future<ReportSubmissionResult> submitReport(DogReportDraft draft) async {
    final String reportId = 'report-${_reportStore.length + 1}';

    _reportStore.add(<String, dynamic>{
      'id': reportId,
      ...draft.toMap(userId: 'integration-user'),
    });

    return ReportSubmissionResult(
      id: reportId,
      submittedAt: DateTime(2026, 1, 1, 12),
      source: SubmissionSource.live,
    );
  }
}

class _StaticLocationRepository implements LocationRepository {
  @override
  Future<LocationSnapshot> getCurrentLocation({
    String sourceScreen = 'unknown',
  }) async {
    return const LocationSnapshot(
      location: GeoLocation(latitude: 30.0444, longitude: 31.2357),
      source: LocationSource.device,
      permissionStatus: AppPermissionStatus.granted,
    );
  }
}
