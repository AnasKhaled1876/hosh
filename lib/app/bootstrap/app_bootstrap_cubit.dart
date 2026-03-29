import 'dart:io' show Platform;

import 'package:equatable/equatable.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hosh/core/analytics/app_analytics.dart';
import 'package:hosh/core/models/app_models.dart';
import 'package:hosh/core/repositories/contracts.dart';

typedef FirebaseInitializer = Future<void> Function(FirebaseOptions options);

class AppBootstrapState extends Equatable {
  const AppBootstrapState({
    required this.status,
    required this.usingLiveServices,
    this.userId,
    this.message,
  });

  const AppBootstrapState.loading()
    : this(status: BootstrapStatus.loading, usingLiveServices: false);

  final BootstrapStatus status;
  final bool usingLiveServices;
  final String? userId;
  final String? message;

  AppBootstrapState copyWith({
    BootstrapStatus? status,
    bool? usingLiveServices,
    Object? userId = _unsetBootstrap,
    Object? message = _unsetBootstrap,
  }) {
    return AppBootstrapState(
      status: status ?? this.status,
      usingLiveServices: usingLiveServices ?? this.usingLiveServices,
      userId: identical(userId, _unsetBootstrap)
          ? this.userId
          : userId as String?,
      message: identical(message, _unsetBootstrap)
          ? this.message
          : message as String?,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    usingLiveServices,
    userId,
    message,
  ];
}

class AppBootstrapCubit extends Cubit<AppBootstrapState> {
  AppBootstrapCubit({
    required this.authRepository,
    required this.notificationService,
    required this.firebaseOptions,
    required this.analyticsService,
    FirebaseInitializer? firebaseInitializer,
  }) : firebaseInitializer = firebaseInitializer ?? _initializeFirebase,
       super(const AppBootstrapState.loading());

  final AuthRepository authRepository;
  final NotificationService notificationService;
  final FirebaseOptions? firebaseOptions;
  final AnalyticsService analyticsService;
  final FirebaseInitializer firebaseInitializer;

  Future<void> initialize() async {
    analyticsService.logAppBootstrapStarted(
      platform: Platform.operatingSystem,
      firebaseExpected: firebaseOptions != null,
    );
    if (firebaseOptions == null) {
      analyticsService.setAppMode('local_safe');
      analyticsService.logAppReady(mode: 'local_safe');
      emit(
        state.copyWith(
          status: BootstrapStatus.ready,
          usingLiveServices: false,
          message: 'Local-safe mode is active on this platform.',
        ),
      );
      return;
    }

    try {
      await firebaseInitializer(firebaseOptions!);
      analyticsService.logFirebaseInitCompleted(success: true);
      final NotificationInitializationResult notificationResult;
      try {
        notificationResult = await notificationService.initialize();
      } catch (error) {
        analyticsService.logNotificationsInitCompleted(
          success: false,
          permissionStatus: AppPermissionStatus.unknown,
        );
        rethrow;
      }
      analyticsService.logNotificationsInitCompleted(
        success: true,
        permissionStatus: notificationResult.permissionStatus,
      );
      final String? userId;
      try {
        userId = await authRepository.signInAnonymously();
      } catch (error) {
        analyticsService.logAnonymousAuthCompleted(
          success: false,
          errorType: analyticsErrorTypeFromObject(error),
        );
        rethrow;
      }
      if (userId == null) {
        analyticsService.logAnonymousAuthCompleted(
          success: false,
          errorType: AnalyticsErrorType.backend,
        );
        throw StateError('Anonymous authentication is unavailable.');
      }
      analyticsService.setUserId(userId);
      analyticsService.setAuthModeAnonymous();
      analyticsService.logAnonymousAuthCompleted(success: true);
      analyticsService.setAppMode('live');
      analyticsService.logAppReady(mode: 'live');
      emit(
        state.copyWith(
          status: BootstrapStatus.ready,
          usingLiveServices: true,
          userId: userId,
          message: null,
        ),
      );
    } catch (error) {
      final AnalyticsErrorType errorType = analyticsErrorTypeFromObject(error);
      if (Firebase.apps.isEmpty) {
        analyticsService.logFirebaseInitCompleted(
          success: false,
          errorType: errorType,
        );
      }
      analyticsService.setAppMode('degraded');
      analyticsService.logAppReady(mode: 'degraded');
      emit(
        state.copyWith(
          status: BootstrapStatus.degraded,
          usingLiveServices: false,
          message:
              'Live safety sync is temporarily unavailable. Local protections remain active.',
        ),
      );
    }
  }
}

const Object _unsetBootstrap = Object();

Future<void> _initializeFirebase(FirebaseOptions options) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: options);
  }
}
