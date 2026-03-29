import 'package:flutter_test/flutter_test.dart';
import 'package:hosh/core/models/app_models.dart';
import 'package:hosh/core/repositories/contracts.dart';
import 'package:hosh/features/report/cubit/report_cubit.dart';
import '../../test_support/fake_analytics_service.dart';

void main() {
  test('submit emits live success copy for live repository results', () async {
    final FakeAnalyticsService analytics = FakeAnalyticsService();
    final ReportCubit cubit = ReportCubit(
      reportRepository: _LiveReportRepository(),
      locationRepository: _StaticLocationRepository(),
      analyticsService: analytics,
    );

    await cubit.initialize();
    await cubit.submit();

    expect(cubit.state.submissionStatus, SubmissionStatus.success);
    expect(
      cubit.state.successMessage,
      'Report shared. Hotspot intelligence will refresh shortly.',
    );
    expect(analytics.sawEvent('report_submit_attempted'), isTrue);
    expect(analytics.sawEvent('report_submit_succeeded'), isTrue);
  });

  test('post-repel prefill requires severity before submit', () async {
    final FakeAnalyticsService analytics = FakeAnalyticsService();
    final ReportCubit cubit = ReportCubit(
      reportRepository: _LiveReportRepository(),
      locationRepository: _StaticLocationRepository(),
      analyticsService: analytics,
    );

    await cubit.initialize(
      prefill: ReportPrefill(
        location: const GeoLocation(latitude: 30.0444, longitude: 31.2357),
        detectedAt: DateTime(2026, 1, 1, 12),
        source: ReportSource.postRepel,
        repelEventId: 'repel-1',
      ),
    );

    expect(cubit.state.draft.reportSource, ReportSource.postRepel);
    expect(cubit.state.draft.repelEventId, 'repel-1');
    expect(cubit.state.draft.severity, isNull);
    expect(cubit.state.canSubmit, isFalse);
  });
}

class _LiveReportRepository implements ReportRepository {
  @override
  Future<ReportSubmissionResult> submitReport(DogReportDraft draft) async {
    return ReportSubmissionResult(
      id: 'live-report-1',
      submittedAt: DateTime(2026, 1, 1),
      source: SubmissionSource.live,
      photoUploaded: true,
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
