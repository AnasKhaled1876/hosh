import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hosh/core/analytics/app_analytics.dart';
import 'package:hosh/core/models/app_models.dart';

void main() {
  test('area bucket is coarse and does not expose raw coordinates', () {
    const GeoLocation location = GeoLocation(
      latitude: 30.0444,
      longitude: 31.2357,
    );

    expect(areaBucket(location), '30.0_31.2');
    expect(areaBucket(location), isNot(contains('30.0444')));
    expect(areaBucket(location), isNot(contains('31.2357')));
  });

  test('numeric values are mapped into the expected buckets', () {
    expect(bucketDogCount(1), '1');
    expect(bucketDogCount(3), '2_3');
    expect(bucketHotspotCount(0), '0');
    expect(bucketHotspotCount(8), '6_10');
    expect(bucketDuration(const Duration(seconds: 15)), '10_30s');
    expect(bucketFrequency(16.5), '16_17');
  });

  test('error mapping sanitizes errors to the approved enum set', () {
    expect(
      analyticsErrorTypeFromObject(
        const ReportSubmissionFailure(
          type: ReportSubmissionFailureType.validation,
          message: 'validation failed',
        ),
      ),
      AnalyticsErrorType.validation,
    );
    expect(
      analyticsErrorTypeFromObject(TimeoutException('slow')),
      AnalyticsErrorType.timeout,
    );
    expect(
      analyticsErrorTypeFromObject(StateError('permission denied')),
      AnalyticsErrorType.permissionDenied,
    );
    expect(
      analyticsErrorTypeFromObject(StateError('speaker output unavailable')),
      AnalyticsErrorType.unsupported,
    );
  });
}
