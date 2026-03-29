import 'package:flutter_test/flutter_test.dart';
import 'package:hosh/core/models/app_models.dart';
import 'package:hosh/core/repositories/contracts.dart';
import 'package:hosh/features/map/cubit/hotspot_map_cubit.dart';
import '../../test_support/fake_analytics_service.dart';

void main() {
  test('loads hotspots and derives summary correctly', () async {
    final FakeAnalyticsService analytics = FakeAnalyticsService();
    final HotspotMapCubit cubit = HotspotMapCubit(
      locationRepository: _StaticLocationRepository(),
      hotspotRepository: _PopulatedHotspotRepository(),
      analyticsService: analytics,
    );

    await cubit.initialize();

    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.hotspots, hasLength(3));
    expect(cubit.state.summary.totalHotspots, 3);
    expect(cubit.state.summary.dangerHotspots, 1);
    expect(cubit.state.summary.cautionHotspots, 2);
    expect(cubit.state.recentHotspots, hasLength(3));
    expect(analytics.sawEvent('map_load_completed'), isTrue);
  });

  test('handles empty hotspot collections without errors', () async {
    final FakeAnalyticsService analytics = FakeAnalyticsService();
    final HotspotMapCubit cubit = HotspotMapCubit(
      locationRepository: _StaticLocationRepository(),
      hotspotRepository: _EmptyHotspotRepository(),
      analyticsService: analytics,
    );

    await cubit.initialize();

    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.errorMessage, isNull);
    expect(cubit.state.hotspots, isEmpty);
    expect(cubit.state.summary.totalHotspots, 0);
    expect(cubit.state.summary.lastReportedAt, isNull);
    expect(
      analytics.firstEvent('map_load_completed')?.parameters['result'],
      'empty',
    );
  });

  test('handles repository failure with a clean error state', () async {
    final FakeAnalyticsService analytics = FakeAnalyticsService();
    final HotspotMapCubit cubit = HotspotMapCubit(
      locationRepository: _StaticLocationRepository(),
      hotspotRepository: _FailingHotspotRepository(),
      analyticsService: analytics,
    );

    await cubit.initialize();

    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.hotspots, isEmpty);
    expect(
      cubit.state.errorMessage,
      'Unable to load hotspot activity right now.',
    );
    expect(analytics.sawEvent('map_load_failed'), isTrue);
  });
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

class _EmptyHotspotRepository implements HotspotRepository {
  @override
  Future<List<Hotspot>> fetchNearbyHotspots(GeoLocation origin) async {
    return const <Hotspot>[];
  }
}

class _FailingHotspotRepository implements HotspotRepository {
  @override
  Future<List<Hotspot>> fetchNearbyHotspots(GeoLocation origin) async {
    throw StateError('boom');
  }
}

class _PopulatedHotspotRepository implements HotspotRepository {
  @override
  Future<List<Hotspot>> fetchNearbyHotspots(GeoLocation origin) async {
    return <Hotspot>[
      Hotspot(
        id: 'hs-1',
        location: origin,
        reportCount: 3,
        dangerLevel: RouteRiskLevel.caution,
        lastReported: DateTime.now().subtract(const Duration(minutes: 45)),
        areaRadiusMeters: 120,
        note: 'Dogs gathering near the northern gate.',
      ),
      Hotspot(
        id: 'hs-2',
        location: origin,
        reportCount: 5,
        dangerLevel: RouteRiskLevel.danger,
        lastReported: DateTime.now().subtract(const Duration(minutes: 8)),
        areaRadiusMeters: 180,
        note: 'Aggressive behavior near food stalls.',
      ),
      Hotspot(
        id: 'hs-3',
        location: origin,
        reportCount: 2,
        dangerLevel: RouteRiskLevel.caution,
        lastReported: DateTime.now().subtract(const Duration(hours: 2)),
        areaRadiusMeters: 90,
        note: 'Barking reported near side street.',
      ),
    ];
  }
}
