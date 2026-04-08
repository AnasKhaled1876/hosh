import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:hosh/app/bootstrap/app_bootstrap_cubit.dart';
import 'package:hosh/core/analytics/app_analytics.dart';
import 'package:hosh/core/adapters/device/plugin_repel_device_service.dart';
import 'package:hosh/core/adapters/fake/fake_adapters.dart';
import 'package:hosh/core/adapters/firebase/firebase_adapters.dart';
import 'package:hosh/core/config/firebase_runtime.dart';
import 'package:hosh/core/models/app_models.dart';
import 'package:hosh/core/repositories/contracts.dart';

class AppDependencies {
  AppDependencies({
    required this.liveFirebase,
    required this.firebaseOptions,
    required this.authRepository,
    required this.repelDeviceService,
    required this.locationRepository,
    required this.hotspotRepository,
    required this.reportRepository,
    required this.repelEventRepository,
    required this.notificationService,
    required this.analyticsService,
  });

  factory AppDependencies.create() {
    const GeoLocation cairoFallback = GeoLocation(
      latitude: 30.0444,
      longitude: 31.2357,
    );
    final bool isTest = Platform.environment.containsKey('FLUTTER_TEST');
    final FirebaseOptions? firebaseOptions = isTest
        ? null
        : resolveFirebaseOptions();
    final bool liveFirebase = firebaseOptions != null;
    final AnalyticsService analyticsService = liveFirebase
        ? FirebaseAnalyticsService()
        : NoopAnalyticsService();

    final AuthRepository authRepository = liveFirebase
        ? FirebaseAuthRepository()
        : FakeAuthRepository();
    final HotspotRepository hotspotRepository = liveFirebase
        ? FirestoreHotspotRepository()
        : FakeHotspotRepository();
    final ReportRepository reportRepository = liveFirebase
        ? FirestoreReportRepository(authRepository, analyticsService)
        : FakeReportRepository();
    final RepelEventRepository repelEventRepository = liveFirebase
        ? FirestoreRepelEventRepository(authRepository)
        : FakeRepelEventRepository();

    return AppDependencies(
      liveFirebase: liveFirebase,
      firebaseOptions: firebaseOptions,
      analyticsService: analyticsService,
      authRepository: authRepository,
      repelDeviceService: isTest
          ? FakeRepelDeviceService()
          : PluginRepelDeviceService(analyticsService: analyticsService),
      locationRepository: GeolocatorLocationRepository(
        fallbackLocation: cairoFallback,
        analyticsService: analyticsService,
      ),
      hotspotRepository: hotspotRepository,
      reportRepository: reportRepository,
      repelEventRepository: repelEventRepository,
      notificationService: liveFirebase
          ? FirebaseNotificationService(analyticsService)
          : NoopNotificationService(),
    );
  }

  final bool liveFirebase;
  final FirebaseOptions? firebaseOptions;
  final AuthRepository authRepository;
  final RepelDeviceService repelDeviceService;
  final LocationRepository locationRepository;
  final HotspotRepository hotspotRepository;
  final ReportRepository reportRepository;
  final RepelEventRepository repelEventRepository;
  final NotificationService notificationService;
  final AnalyticsService analyticsService;

  AppBootstrapCubit buildBootstrapCubit() {
    return AppBootstrapCubit(
      authRepository: authRepository,
      notificationService: notificationService,
      firebaseOptions: firebaseOptions,
      analyticsService: analyticsService,
    )..initialize();
  }
}
