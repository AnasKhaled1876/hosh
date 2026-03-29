import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hosh/core/analytics/app_analytics.dart';
import 'package:hosh/core/models/app_models.dart';
import 'package:hosh/core/repositories/contracts.dart';

class ReportState {
  const ReportState({
    required this.draft,
    required this.submissionStatus,
    required this.isLocating,
    this.errorMessage,
    this.successMessage,
  });

  factory ReportState.initial() {
    return ReportState(
      draft: DogReportDraft(detectedAt: DateTime.now()),
      submissionStatus: SubmissionStatus.idle,
      isLocating: true,
    );
  }

  final DogReportDraft draft;
  final SubmissionStatus submissionStatus;
  final bool isLocating;
  final String? errorMessage;
  final String? successMessage;

  bool get canSubmit =>
      draft.isValid && submissionStatus != SubmissionStatus.submitting;

  ReportState copyWith({
    DogReportDraft? draft,
    SubmissionStatus? submissionStatus,
    bool? isLocating,
    String? errorMessage,
    String? successMessage,
  }) {
    return ReportState(
      draft: draft ?? this.draft,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      isLocating: isLocating ?? this.isLocating,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class ReportCubit extends Cubit<ReportState> {
  ReportCubit({
    required this.reportRepository,
    required this.locationRepository,
    required this.analyticsService,
  }) : super(ReportState.initial());

  final ReportRepository reportRepository;
  final LocationRepository locationRepository;
  final AnalyticsService analyticsService;
  bool _loggedBehaviorSelection = false;
  bool _loggedSeveritySelection = false;
  bool _loggedDescriptionAdded = false;
  bool _loggedPhotoAdded = false;

  Future<void> initialize({ReportPrefill? prefill}) async {
    final bool isPostRepel = prefill?.source == ReportSource.postRepel;
    analyticsService.logReportScreenOpened(
      sourceTab: isPostRepel ? 'repel' : 'report',
    );
    if (prefill != null) {
      if (prefill.location != null) {
        analyticsService.logReportLocationSet(location: prefill.location);
      }
      emit(
        state.copyWith(
          isLocating: false,
          draft: state.draft.copyWith(
            reportSource: prefill.source,
            detectedAt: prefill.detectedAt,
            location: prefill.location,
            repelEventId: prefill.repelEventId,
            behavior: DogBehavior.calm,
            severity: isPostRepel ? null : ReportSeverity.caution,
          ),
        ),
      );
      return;
    }

    final LocationSnapshot location = await locationRepository
        .getCurrentLocation(sourceScreen: 'report');
    analyticsService.logReportLocationSet(location: location.location);
    emit(
      state.copyWith(
        isLocating: false,
        draft: state.draft.copyWith(
          reportSource: ReportSource.manual,
          location: location.location,
          behavior: DogBehavior.calm,
          severity: ReportSeverity.caution,
        ),
      ),
    );
  }

  void updateBehavior(DogBehavior? behavior) {
    if (behavior != null && !_loggedBehaviorSelection) {
      analyticsService.logReportBehaviorSelected(behavior: behavior);
      _loggedBehaviorSelection = true;
    }
    emit(state.copyWith(draft: state.draft.copyWith(behavior: behavior)));
  }

  void incrementDogCount() {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(dogCount: state.draft.dogCount + 1),
      ),
    );
  }

  void decrementDogCount() {
    if (state.draft.dogCount <= 1) {
      return;
    }
    emit(
      state.copyWith(
        draft: state.draft.copyWith(dogCount: state.draft.dogCount - 1),
      ),
    );
  }

  void updateDescription(String value) {
    if (value.trim().isNotEmpty && !_loggedDescriptionAdded) {
      analyticsService.logReportDescriptionAdded();
      _loggedDescriptionAdded = true;
    }
    emit(state.copyWith(draft: state.draft.copyWith(description: value)));
  }

  void updateSeverity(double sliderValue) {
    final ReportSeverity severity = sliderValue < 0.33
        ? ReportSeverity.low
        : sliderValue < 0.66
        ? ReportSeverity.caution
        : ReportSeverity.high;
    if (!_loggedSeveritySelection) {
      analyticsService.logReportSeveritySet(severity: severity);
      _loggedSeveritySelection = true;
    }
    emit(state.copyWith(draft: state.draft.copyWith(severity: severity)));
  }

  void updateLocation(GeoLocation location) {
    analyticsService.logReportLocationSet(location: location);
    emit(state.copyWith(draft: state.draft.copyWith(location: location)));
  }

  void toggleAnonymous(bool value) {
    emit(state.copyWith(draft: state.draft.copyWith(anonymous: value)));
  }

  void attachPhoto(String? path) {
    if (path == null) {
      analyticsService.logReportPhotoRemoved();
      _loggedPhotoAdded = false;
    } else if (!_loggedPhotoAdded) {
      analyticsService.logReportPhotoAdded(source: 'gallery');
      _loggedPhotoAdded = true;
    }
    emit(state.copyWith(draft: state.draft.copyWith(photoPath: path)));
  }

  Future<void> submit() async {
    if (!state.canSubmit) {
      if (state.submissionStatus != SubmissionStatus.submitting) {
        analyticsService.logReportValidationFailed(
          missingLocation: state.draft.location == null,
          missingBehavior: state.draft.behavior == null,
          missingSeverity: state.draft.severity == null,
          invalidDogCount: state.draft.dogCount < 1,
        );
      }
      return;
    }
    analyticsService.logReportSubmitAttempted(draft: state.draft);
    emit(
      state.copyWith(
        submissionStatus: SubmissionStatus.submitting,
        errorMessage: null,
        successMessage: null,
      ),
    );
    try {
      final ReportSubmissionResult result = await reportRepository.submitReport(
        state.draft,
      );
      emit(
        state.copyWith(
          submissionStatus: SubmissionStatus.success,
          successMessage: result.isLive
              ? 'Report shared. Hotspot intelligence will refresh shortly.'
              : 'Report saved locally until live sync is available.',
        ),
      );
      analyticsService.logReportSubmitSucceeded(
        draft: state.draft,
        result: result,
      );
    } on ReportSubmissionFailure catch (error) {
      analyticsService.logReportSubmitFailed(
        draft: state.draft,
        stage: switch (error.type) {
          ReportSubmissionFailureType.auth => 'auth',
          ReportSubmissionFailureType.storage => 'storage',
          ReportSubmissionFailureType.database => 'firestore',
          ReportSubmissionFailureType.validation => 'validation',
          ReportSubmissionFailureType.unknown => 'unknown',
        },
        errorType: analyticsErrorTypeFromObject(error),
        hasPhoto: state.draft.photoPath != null,
      );
      emit(
        state.copyWith(
          submissionStatus: SubmissionStatus.failure,
          errorMessage: error.message,
        ),
      );
    } catch (error) {
      analyticsService.logReportSubmitFailed(
        draft: state.draft,
        stage: 'unknown',
        errorType: analyticsErrorTypeFromObject(error),
        hasPhoto: state.draft.photoPath != null,
      );
      emit(
        state.copyWith(
          submissionStatus: SubmissionStatus.failure,
          errorMessage:
              'Unable to submit the report right now. Try again in a moment.',
        ),
      );
    }
  }
}
