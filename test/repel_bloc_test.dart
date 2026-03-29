import 'package:flutter_test/flutter_test.dart';
import 'package:hosh/core/models/app_models.dart';
import 'package:hosh/core/repositories/contracts.dart';
import 'package:hosh/features/repel/bloc/repel_bloc.dart';
import 'test_support/fake_analytics_service.dart';

void main() {
  test('repel bloc activates and stops cleanly', () async {
    final FakeAnalyticsService analytics = FakeAnalyticsService();
    final RepelBloc bloc = RepelBloc(
      _FakeRepelService(),
      analyticsService: analytics,
      locationRepository: _DeviceLocationRepository(),
      repelEventRepository: _FakeRepelEventRepository(),
    );

    bloc.add(const RepelStarted());
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(bloc.state.session.isActive, isTrue);
    expect(
      bloc.state.statusMessage,
      'Thermal-safe repel pulses active across speaker and strobe.',
    );

    bloc.add(const RepelStopped());
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(bloc.state.session.isActive, isFalse);
    expect(bloc.state.pendingReportPrompt, isNotNull);
    expect(analytics.sawEvent('repel_start_tapped'), isTrue);
    expect(analytics.sawEvent('repel_started'), isTrue);
    expect(analytics.sawEvent('repel_stopped'), isTrue);

    await bloc.close();
  });

  test('repel bloc surfaces hardware fallback state', () async {
    final FakeAnalyticsService analytics = FakeAnalyticsService();
    final RepelBloc bloc = RepelBloc(
      _FailingRepelService(),
      analyticsService: analytics,
      locationRepository: _DeviceLocationRepository(),
      repelEventRepository: _FakeRepelEventRepository(),
    );

    bloc.add(const RepelStarted());
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(bloc.state.session.isActive, isFalse);
    expect(
      bloc.state.statusMessage,
      'No deterrent output is available on this device right now.',
    );
    expect(analytics.sawEvent('repel_failure'), isTrue);

    await bloc.close();
  });

  test(
    'repel bloc reports partial capability when only audio is available',
    () async {
      final FakeAnalyticsService analytics = FakeAnalyticsService();
      final RepelBloc bloc = RepelBloc(
        _AudioOnlyRepelService(),
        analyticsService: analytics,
        locationRepository: _DeviceLocationRepository(),
        repelEventRepository: _FakeRepelEventRepository(),
      );

      bloc.add(const RepelStarted());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(bloc.state.session.isActive, isTrue);
      expect(bloc.state.session.audioEnabled, isTrue);
      expect(bloc.state.session.torchEnabled, isFalse);
      expect(
        bloc.state.statusMessage,
        'Audio repel pulses active. Strobe support is unavailable.',
      );
      expect(analytics.sawEvent('repel_partial_capability'), isTrue);

      await bloc.close();
    },
  );
}

class _DeviceLocationRepository implements LocationRepository {
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

class _FakeRepelEventRepository implements RepelEventRepository {
  @override
  Future<RepelEventRecord?> createRepelEvent(RepelEventDraft draft) async {
    return RepelEventRecord(
      id: 'repel-event-1',
      userId: 'user-1',
      location: draft.location,
      timestamp: draft.timestamp,
    );
  }
}

class _FakeRepelService implements RepelDeviceService {
  @override
  Future<RepelSessionState> startRepel(RepelSettings settings) async {
    return RepelSessionState(
      isActive: true,
      frequencyKhz: settings.frequencyKhz,
      torchEnabled: settings.strobeEnabled,
      audioEnabled: true,
      outputLabel: settings.outputLabel,
    );
  }

  @override
  Future<RepelSessionState> stopRepel(RepelSessionState current) async {
    return current.copyWith(
      isActive: false,
      audioEnabled: false,
      torchEnabled: false,
    );
  }

  @override
  Future<bool> setTorchEnabled(bool enabled) async => enabled;

  @override
  Future<String?> triggerPanicMode() async => 'panic';
}

class _FailingRepelService implements RepelDeviceService {
  @override
  Future<RepelSessionState> startRepel(RepelSettings settings) async {
    return RepelSessionState(
      isActive: false,
      frequencyKhz: settings.frequencyKhz,
      torchEnabled: false,
      audioEnabled: false,
      outputLabel: settings.outputLabel,
      lastError: 'No deterrent output is available on this device right now.',
    );
  }

  @override
  Future<RepelSessionState> stopRepel(RepelSessionState current) async {
    return current.copyWith(
      isActive: false,
      audioEnabled: false,
      torchEnabled: false,
    );
  }

  @override
  Future<bool> setTorchEnabled(bool enabled) async => false;

  @override
  Future<String?> triggerPanicMode() async => null;
}

class _AudioOnlyRepelService implements RepelDeviceService {
  @override
  Future<RepelSessionState> startRepel(RepelSettings settings) async {
    return RepelSessionState(
      isActive: true,
      frequencyKhz: settings.frequencyKhz,
      torchEnabled: false,
      audioEnabled: true,
      outputLabel: settings.outputLabel,
    );
  }

  @override
  Future<RepelSessionState> stopRepel(RepelSessionState current) async {
    return current.copyWith(
      isActive: false,
      audioEnabled: false,
      torchEnabled: false,
    );
  }

  @override
  Future<bool> setTorchEnabled(bool enabled) async => false;

  @override
  Future<String?> triggerPanicMode() async => null;
}
