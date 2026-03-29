import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hosh/core/analytics/app_analytics.dart';
import 'package:hosh/core/models/app_models.dart';
import 'package:hosh/core/repositories/contracts.dart';

sealed class RepelEvent extends Equatable {
  const RepelEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class RepelStarted extends RepelEvent {
  const RepelStarted();
}

class RepelStopped extends RepelEvent {
  const RepelStopped();
}

class PanicRequested extends RepelEvent {
  const PanicRequested();
}

class TorchToggled extends RepelEvent {
  const TorchToggled(this.enabled);

  final bool enabled;

  @override
  List<Object?> get props => <Object?>[enabled];
}

class RepelPromptCleared extends RepelEvent {
  const RepelPromptCleared();
}

class RepelState extends Equatable {
  const RepelState({
    required this.session,
    required this.strobeEnabled,
    required this.isWorking,
    required this.statusMessage,
    this.pendingReportPrompt,
  });

  factory RepelState.initial() {
    return RepelState(
      session: RepelSessionState.idle(),
      strobeEnabled: true,
      isWorking: false,
      statusMessage: 'Scanning for high-risk hotspots',
    );
  }

  final RepelSessionState session;
  final bool strobeEnabled;
  final bool isWorking;
  final String statusMessage;
  final ReportPrefill? pendingReportPrompt;

  RepelState copyWith({
    RepelSessionState? session,
    bool? strobeEnabled,
    bool? isWorking,
    String? statusMessage,
    Object? pendingReportPrompt = _repelSentinel,
  }) {
    return RepelState(
      session: session ?? this.session,
      strobeEnabled: strobeEnabled ?? this.strobeEnabled,
      isWorking: isWorking ?? this.isWorking,
      statusMessage: statusMessage ?? this.statusMessage,
      pendingReportPrompt: identical(pendingReportPrompt, _repelSentinel)
          ? this.pendingReportPrompt
          : pendingReportPrompt as ReportPrefill?,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    session,
    strobeEnabled,
    isWorking,
    statusMessage,
    pendingReportPrompt,
  ];
}

class RepelBloc extends Bloc<RepelEvent, RepelState> {
  RepelBloc(
    this.deviceService, {
    required this.analyticsService,
    required this.locationRepository,
    required this.repelEventRepository,
  }) : super(RepelState.initial()) {
    on<RepelStarted>(_onStart);
    on<RepelStopped>(_onStop);
    on<PanicRequested>(_onPanic);
    on<TorchToggled>(_onTorchToggle);
    on<RepelPromptCleared>(_onPromptCleared);
  }

  final RepelDeviceService deviceService;
  final AnalyticsService analyticsService;
  final LocationRepository locationRepository;
  final RepelEventRepository repelEventRepository;
  DateTime? _sessionStartedAt;
  ReportPrefill? _latestRepelPrompt;

  Future<void> _onStart(RepelStarted event, Emitter<RepelState> emit) async {
    _latestRepelPrompt = null;
    analyticsService.logRepelStartTapped(
      frequencyKhz: state.session.frequencyKhz,
    );
    emit(state.copyWith(isWorking: true, pendingReportPrompt: null));
    try {
      final RepelSessionState session = await deviceService.startRepel(
        RepelSettings(
          frequencyKhz: state.session.frequencyKhz,
          strobeEnabled: state.strobeEnabled,
        ),
      );
      emit(
        state.copyWith(
          isWorking: false,
          session: session,
          statusMessage: _statusMessageForSession(session),
        ),
      );
      analyticsService.updateCapabilityProperties(
        audioAvailable: session.audioEnabled,
        torchAvailable: state.strobeEnabled ? session.torchEnabled : null,
      );
      analyticsService.logRepelStarted(session: session);
      if (session.isActive) {
        _sessionStartedAt = DateTime.now();
        _latestRepelPrompt = await _buildRepelPrompt();
        if (!(session.audioEnabled && session.torchEnabled)) {
          analyticsService.logRepelPartialCapability(
            session: session,
            errorType: analyticsErrorTypeFromObject(session.lastError),
          );
        }
      } else {
        analyticsService.logRepelFailure(
          stage: 'start',
          errorType: analyticsErrorTypeFromObject(session.lastError),
          mode: modeForSession(session),
        );
      }
    } catch (_) {
      emit(
        state.copyWith(
          isWorking: false,
          session: RepelSessionState.idle(
            frequencyKhz: state.session.frequencyKhz,
          ),
          statusMessage: 'Protection hardware is unavailable.',
        ),
      );
      analyticsService.logRepelFailure(
        stage: 'start',
        errorType: AnalyticsErrorType.unknown,
        mode: 'none',
      );
    }
  }

  Future<void> _onStop(RepelStopped event, Emitter<RepelState> emit) async {
    analyticsService.logRepelStopTapped();
    final RepelSessionState previousSession = state.session;
    emit(state.copyWith(isWorking: true));
    final RepelSessionState session = await deviceService.stopRepel(
      state.session,
    );
    emit(
      state.copyWith(
        isWorking: false,
        session: session,
        statusMessage: 'Protection idle but ready.',
      ),
    );
    final Duration duration = _sessionStartedAt == null
        ? Duration.zero
        : DateTime.now().difference(_sessionStartedAt!);
    analyticsService.logRepelStopped(
      previousSession: previousSession,
      duration: duration,
    );
    _sessionStartedAt = null;
    if (previousSession.isActive && _latestRepelPrompt != null) {
      emit(state.copyWith(pendingReportPrompt: _latestRepelPrompt));
      _latestRepelPrompt = null;
    }
  }

  Future<void> _onPanic(PanicRequested event, Emitter<RepelState> emit) async {
    analyticsService.logPanicTapped(sourceScreen: 'repel');
    final String? message = await deviceService.triggerPanicMode();
    emit(state.copyWith(statusMessage: message ?? 'Panic mode requested.'));
  }

  Future<void> _onTorchToggle(
    TorchToggled event,
    Emitter<RepelState> emit,
  ) async {
    try {
      final bool enabled = await deviceService.setTorchEnabled(event.enabled);
      analyticsService.logRepelTorchToggled(
        enabled: enabled,
        duringSession: state.session.isActive,
      );
      emit(
        state.copyWith(
          strobeEnabled: enabled,
          session: state.session.copyWith(torchEnabled: enabled),
          statusMessage: enabled
              ? 'Visual deterrent enabled.'
              : 'Torch unavailable or disabled.',
        ),
      );
      if (event.enabled && !enabled) {
        analyticsService.updateCapabilityProperties(torchAvailable: false);
      }
    } catch (_) {
      analyticsService.logRepelTorchToggled(
        enabled: false,
        duringSession: state.session.isActive,
      );
      emit(
        state.copyWith(
          strobeEnabled: false,
          session: state.session.copyWith(torchEnabled: false),
          statusMessage: 'Torch unavailable or disabled.',
        ),
      );
    }
  }

  Future<void> _onPromptCleared(
    RepelPromptCleared event,
    Emitter<RepelState> emit,
  ) async {
    emit(state.copyWith(pendingReportPrompt: null));
  }

  Future<ReportPrefill?> _buildRepelPrompt() async {
    final DateTime detectedAt = DateTime.now();
    try {
      final LocationSnapshot snapshot = await locationRepository
          .getCurrentLocation(sourceScreen: 'repel');
      if (snapshot.source != LocationSource.device) {
        return ReportPrefill(
          detectedAt: detectedAt,
          source: ReportSource.postRepel,
        );
      }
      final RepelEventRecord? record = await repelEventRepository
          .createRepelEvent(
            RepelEventDraft(location: snapshot.location, timestamp: detectedAt),
          );
      if (record != null) {
        return record.toReportPrefill();
      }
      return ReportPrefill(
        location: snapshot.location,
        detectedAt: detectedAt,
        source: ReportSource.postRepel,
      );
    } catch (_) {
      return ReportPrefill(
        detectedAt: detectedAt,
        source: ReportSource.postRepel,
      );
    }
  }

  @override
  Future<void> close() async {
    await deviceService.stopRepel(state.session);
    return super.close();
  }
}

const Object _repelSentinel = Object();

String _statusMessageForSession(RepelSessionState session) {
  if (!session.isActive) {
    return session.lastError ?? 'Protection hardware is unavailable.';
  }
  if (session.audioEnabled && session.torchEnabled) {
    return session.lastError ??
        'Thermal-safe repel pulses active across speaker and strobe.';
  }
  if (session.audioEnabled) {
    return session.lastError ??
        'Audio repel pulses active. Strobe support is unavailable.';
  }
  if (session.torchEnabled) {
    return session.lastError ??
        'Strobe-only deterrent active. Speaker output is unavailable.';
  }
  return session.lastError ?? 'Protection hardware is unavailable.';
}
