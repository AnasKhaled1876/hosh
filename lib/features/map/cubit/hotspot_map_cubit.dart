import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hosh/core/analytics/app_analytics.dart';
import 'package:hosh/core/models/app_models.dart';
import 'package:hosh/core/repositories/contracts.dart';

class HotspotMapSummary {
  const HotspotMapSummary({
    required this.totalHotspots,
    required this.dangerHotspots,
    required this.cautionHotspots,
    required this.lastReportedAt,
  });

  static const HotspotMapSummary empty = HotspotMapSummary(
    totalHotspots: 0,
    dangerHotspots: 0,
    cautionHotspots: 0,
    lastReportedAt: null,
  );

  factory HotspotMapSummary.fromHotspots(List<Hotspot> hotspots) {
    if (hotspots.isEmpty) {
      return empty;
    }

    final int dangerHotspots = hotspots
        .where(
          (Hotspot hotspot) => hotspot.dangerLevel == RouteRiskLevel.danger,
        )
        .length;
    final int cautionHotspots = hotspots
        .where(
          (Hotspot hotspot) => hotspot.dangerLevel == RouteRiskLevel.caution,
        )
        .length;

    final List<Hotspot> sorted = List<Hotspot>.from(
      hotspots,
    )..sort((Hotspot a, Hotspot b) => b.lastReported.compareTo(a.lastReported));

    return HotspotMapSummary(
      totalHotspots: hotspots.length,
      dangerHotspots: dangerHotspots,
      cautionHotspots: cautionHotspots,
      lastReportedAt: sorted.first.lastReported,
    );
  }

  final int totalHotspots;
  final int dangerHotspots;
  final int cautionHotspots;
  final DateTime? lastReportedAt;
}

class HotspotMapState {
  static const Object _sentinel = Object();

  const HotspotMapState({
    required this.isLoading,
    required this.hotspots,
    required this.summary,
    required this.locationSource,
    this.currentLocation,
    this.errorMessage,
  });

  factory HotspotMapState.initial() {
    return const HotspotMapState(
      isLoading: true,
      hotspots: <Hotspot>[],
      summary: HotspotMapSummary.empty,
      locationSource: LocationSource.fallback,
    );
  }

  final bool isLoading;
  final List<Hotspot> hotspots;
  final HotspotMapSummary summary;
  final LocationSource locationSource;
  final GeoLocation? currentLocation;
  final String? errorMessage;

  List<Hotspot> get recentHotspots {
    final List<Hotspot> sorted = List<Hotspot>.from(
      hotspots,
    )..sort((Hotspot a, Hotspot b) => b.lastReported.compareTo(a.lastReported));
    return sorted.take(3).toList(growable: false);
  }

  HotspotMapState copyWith({
    bool? isLoading,
    List<Hotspot>? hotspots,
    HotspotMapSummary? summary,
    LocationSource? locationSource,
    Object? currentLocation = _sentinel,
    Object? errorMessage = _sentinel,
  }) {
    return HotspotMapState(
      isLoading: isLoading ?? this.isLoading,
      hotspots: hotspots ?? this.hotspots,
      summary: summary ?? this.summary,
      locationSource: locationSource ?? this.locationSource,
      currentLocation: identical(currentLocation, _sentinel)
          ? this.currentLocation
          : currentLocation as GeoLocation?,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

class HotspotMapCubit extends Cubit<HotspotMapState> {
  HotspotMapCubit({
    required this.locationRepository,
    required this.hotspotRepository,
    required this.analyticsService,
  }) : super(HotspotMapState.initial());

  final LocationRepository locationRepository;
  final HotspotRepository hotspotRepository;
  final AnalyticsService analyticsService;
  bool _hasLoggedOpen = false;

  Future<void> initialize() async {
    await refresh();
  }

  Future<void> refresh() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    GeoLocation location =
        state.currentLocation ??
        const GeoLocation(latitude: 30.0444, longitude: 31.2357);
    LocationSource locationSource = state.locationSource;
    try {
      if (state.currentLocation == null) {
        final LocationSnapshot locationSnapshot = await locationRepository
            .getCurrentLocation(sourceScreen: 'map');
        location = locationSnapshot.location;
        locationSource = locationSnapshot.source;
        if (!_hasLoggedOpen) {
          analyticsService.logMapScreenOpened(
            locationAvailable: locationSource == LocationSource.device,
          );
          _hasLoggedOpen = true;
        }
      } else {
        location = state.currentLocation!;
      }
      analyticsService.logMapLoadStarted(locationSource: locationSource);
      final List<Hotspot> hotspots = await hotspotRepository
          .fetchNearbyHotspots(location);
      analyticsService.logMapLoadCompleted(
        hotspots: hotspots,
        location: location,
        locationSource: locationSource,
      );
      emit(
        state.copyWith(
          isLoading: false,
          currentLocation: location,
          locationSource: locationSource,
          hotspots: hotspots,
          summary: HotspotMapSummary.fromHotspots(hotspots),
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          currentLocation: location,
          locationSource: locationSource,
          hotspots: const <Hotspot>[],
          summary: HotspotMapSummary.empty,
          errorMessage: 'Unable to load hotspot activity right now.',
        ),
      );
      analyticsService.logMapLoadFailed(
        errorType: analyticsErrorTypeFromObject(error),
        locationSource: locationSource,
      );
    }
  }

  void selectHotspot(Hotspot hotspot) {
    analyticsService.logHotspotMarkerSelected(hotspot: hotspot);
  }

  void trackReportCta() {
    analyticsService.logMapReportCtaTapped(location: state.currentLocation);
  }
}
