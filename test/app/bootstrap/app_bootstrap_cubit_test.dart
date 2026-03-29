import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hosh/app/bootstrap/app_bootstrap_cubit.dart';
import 'package:hosh/core/adapters/fake/fake_adapters.dart';
import 'package:hosh/core/models/app_models.dart';
import '../../test_support/fake_analytics_service.dart';

void main() {
  const FirebaseOptions testOptions = FirebaseOptions(
    apiKey: 'test-key',
    appId: 'test-app',
    messagingSenderId: 'test-sender',
    projectId: 'test-project',
  );

  test('initializes live bootstrap when Firebase succeeds', () async {
    final FakeAnalyticsService analytics = FakeAnalyticsService();
    final AppBootstrapCubit cubit = AppBootstrapCubit(
      authRepository: FakeAuthRepository(),
      notificationService: NoopNotificationService(),
      firebaseOptions: testOptions,
      analyticsService: analytics,
      firebaseInitializer: (FirebaseOptions _) async {},
    );

    await cubit.initialize();

    expect(cubit.state.status, BootstrapStatus.ready);
    expect(cubit.state.usingLiveServices, isTrue);
    expect(cubit.state.userId, 'demo-anon-user');
    expect(cubit.state.message, isNull);
    expect(analytics.sawEvent('app_bootstrap_started'), isTrue);
    expect(analytics.sawEvent('firebase_init_completed'), isTrue);
    expect(analytics.sawEvent('anonymous_auth_completed'), isTrue);
    expect(analytics.firstEvent('app_ready')?.parameters['mode'], 'live');
  });

  test('falls back gracefully when Firebase initialization fails', () async {
    final FakeAnalyticsService analytics = FakeAnalyticsService();
    final AppBootstrapCubit cubit = AppBootstrapCubit(
      authRepository: FakeAuthRepository(),
      notificationService: NoopNotificationService(),
      firebaseOptions: testOptions,
      analyticsService: analytics,
      firebaseInitializer: (FirebaseOptions _) async {
        throw StateError('boom');
      },
    );

    await cubit.initialize();

    expect(cubit.state.status, BootstrapStatus.degraded);
    expect(cubit.state.usingLiveServices, isFalse);
    expect(
      cubit.state.message,
      'Live safety sync is temporarily unavailable. Local protections remain active.',
    );
    expect(analytics.firstEvent('app_ready')?.parameters['mode'], 'degraded');
  });
}
