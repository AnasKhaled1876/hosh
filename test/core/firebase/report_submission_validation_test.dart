import 'package:flutter_test/flutter_test.dart';
import 'package:hosh/core/adapters/firebase/report_submission_validation.dart';
import 'package:hosh/core/models/app_models.dart';

void main() {
  test('normalizeSubmittedReportDraft trims descriptions and photo paths', () {
    final DogReportDraft normalized = normalizeSubmittedReportDraft(
      DogReportDraft(
        detectedAt: DateTime(2026, 1, 1, 12),
        behavior: DogBehavior.aggressive,
        dogCount: 2,
        description: '  Aggressive barking near gate   ',
        severity: ReportSeverity.high,
        location: const GeoLocation(latitude: 30.04441, longitude: 31.23571),
        photoPath: '  /tmp/photo.jpg  ',
      ),
    );

    expect(normalized.description, 'Aggressive barking near gate');
    expect(normalized.photoPath, '/tmp/photo.jpg');
  });

  test('validateSubmittedReportDraft rejects malformed coordinates', () {
    expect(
      () => validateSubmittedReportDraft(
        DogReportDraft(
          detectedAt: DateTime(2026, 1, 1),
          behavior: DogBehavior.calm,
          dogCount: 1,
          severity: ReportSeverity.low,
          location: const GeoLocation(latitude: 91, longitude: 31),
        ),
      ),
      throwsA(isA<ReportSubmissionFailure>()),
    );
  });

  test('validateSubmittedReportDraft requires severity', () {
    expect(
      () => validateSubmittedReportDraft(
        DogReportDraft(
          detectedAt: DateTime(2026, 1, 1),
          behavior: DogBehavior.calm,
          dogCount: 1,
          location: const GeoLocation(latitude: 30.0444, longitude: 31.2357),
        ),
      ),
      throwsA(isA<ReportSubmissionFailure>()),
    );
  });
}
