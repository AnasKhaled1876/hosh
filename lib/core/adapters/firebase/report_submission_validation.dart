import 'package:hosh/core/models/app_models.dart';

const int reportDescriptionMaxLength = 280;
const int reportDogCountMax = 12;

DogReportDraft normalizeSubmittedReportDraft(DogReportDraft draft) {
  final String normalizedDescription = draft.description.trim().replaceAll(
    RegExp(r'\s+'),
    ' ',
  );
  final String? normalizedPhotoPath = switch (draft.photoPath?.trim()) {
    final String value when value.isNotEmpty => value,
    _ => null,
  };

  return draft.copyWith(
    dogCount: draft.dogCount.clamp(1, reportDogCountMax),
    description: normalizedDescription,
    photoPath: normalizedPhotoPath,
  );
}

void validateSubmittedReportDraft(DogReportDraft draft) {
  if (draft.severity == null) {
    throw const ReportSubmissionFailure(
      type: ReportSubmissionFailureType.validation,
      message: 'Select the report severity before submitting.',
    );
  }

  final GeoLocation? location = draft.location;
  if (location == null) {
    throw const ReportSubmissionFailure(
      type: ReportSubmissionFailureType.validation,
      message: 'Pick a location on the map before submitting.',
    );
  }

  if (location.latitude < -90 ||
      location.latitude > 90 ||
      location.longitude < -180 ||
      location.longitude > 180) {
    throw const ReportSubmissionFailure(
      type: ReportSubmissionFailureType.validation,
      message: 'The selected location is outside valid map coordinates.',
    );
  }

  if (draft.dogCount < 1 || draft.dogCount > reportDogCountMax) {
    throw const ReportSubmissionFailure(
      type: ReportSubmissionFailureType.validation,
      message: 'Dog count must be between 1 and 12.',
    );
  }

  if (draft.description.length > reportDescriptionMaxLength) {
    throw const ReportSubmissionFailure(
      type: ReportSubmissionFailureType.validation,
      message: 'Description is too long. Keep it under 280 characters.',
    );
  }
}
