import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hosh/app/bootstrap/app_bootstrap_cubit.dart';
import 'package:hosh/app/di/app_dependencies.dart';
import 'package:hosh/app/router/app_router.dart';
import 'package:hosh/core/analytics/app_analytics.dart';
import 'package:hosh/core/repositories/contracts.dart';
import 'package:hosh/core/theme/app_theme.dart';

class HooshApp extends StatefulWidget {
  const HooshApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<HooshApp> createState() => _HooshAppState();
}

class _HooshAppState extends State<HooshApp> {
  late final GoRouter _router = buildAppRouter(
    widget.dependencies.analyticsService,
  );

  @override
  Widget build(BuildContext context) {
    final AppDependencies deps = widget.dependencies;
    return MultiRepositoryProvider(
      providers: <RepositoryProvider>[
        RepositoryProvider<AppDependencies>.value(value: deps),
        RepositoryProvider<AuthRepository>.value(value: deps.authRepository),
        RepositoryProvider<RepelDeviceService>.value(
          value: deps.repelDeviceService,
        ),
        RepositoryProvider<LocationRepository>.value(
          value: deps.locationRepository,
        ),
        RepositoryProvider<HotspotRepository>.value(
          value: deps.hotspotRepository,
        ),
        RepositoryProvider<ReportRepository>.value(
          value: deps.reportRepository,
        ),
        RepositoryProvider<RepelEventRepository>.value(
          value: deps.repelEventRepository,
        ),
        RepositoryProvider<NotificationService>.value(
          value: deps.notificationService,
        ),
        RepositoryProvider<AnalyticsService>.value(
          value: deps.analyticsService,
        ),
      ],
      child: BlocProvider<AppBootstrapCubit>(
        create: (_) => deps.buildBootstrapCubit(),
        child: MaterialApp.router(
          title: 'Hoosh',
          debugShowCheckedModeBanner: false,
          theme: buildHooshTheme(),
          routerConfig: _router,
        ),
      ),
    );
  }
}
