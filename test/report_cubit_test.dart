import 'package:flutter_test/flutter_test.dart';
import 'package:hosh/core/adapters/fake/fake_adapters.dart';
import 'package:hosh/core/models/app_models.dart';
import 'package:hosh/core/repositories/contracts.dart';
import 'package:hosh/features/report/cubit/report_cubit.dart';
import 'test_support/fake_analytics_service.dart';

void main() {
  test('report cubit initializes, validates, and submits', () async {
    final FakeAnalyticsService analytics = FakeAnalyticsService();
    final ReportCubit cubit = ReportCubit(
      reportRepository: FakeReportRepository(),
      locationRepository: _FakeLocationRepository(),
      analyticsService: analytics,
    );

    await cubit.initialize();
    expect(cubit.state.draft.location, isNotNull);
    expect(cubit.state.canSubmit, isTrue);

    cubit.updateDescription('Pack near the gate');
    cubit.attachPhoto('/tmp/photo.jpg');
    await cubit.submit();

    expect(cubit.state.submissionStatus, SubmissionStatus.success);
    expect(cubit.state.successMessage, isNotNull);
    expect(analytics.sawEvent('report_submit_attempted'), isTrue);

    await cubit.close();
  });
}

class _FakeLocationRepository implements LocationRepository {
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
