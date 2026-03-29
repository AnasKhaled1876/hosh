import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hosh/app/shell/app_shell.dart';
import 'package:hosh/core/analytics/app_analytics.dart';
import 'package:hosh/core/models/app_models.dart';
import 'package:hosh/core/repositories/contracts.dart';
import 'package:hosh/features/map/cubit/hotspot_map_cubit.dart';
import 'package:hosh/features/map/view/hotspot_map_screen.dart';
import 'package:hosh/features/info/view/info_screen.dart';
import 'package:hosh/features/repel/bloc/repel_bloc.dart';
import 'package:hosh/features/repel/view/repel_screen.dart';
import 'package:hosh/features/report/cubit/report_cubit.dart';
import 'package:hosh/features/report/view/report_screen.dart';

GoRouter buildAppRouter(AnalyticsService analyticsService) {
  return GoRouter(
    initialLocation: '/repel',
    observers: <NavigatorObserver>[HooshAnalyticsObserver(analyticsService)],
    routes: <RouteBase>[
      GoRoute(path: '/', redirect: (context, state) => '/repel'),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(
            navigationShell: navigationShell,
            analyticsService: analyticsService,
          );
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/map',
                name: 'map',
                builder: (context, state) {
                  return BlocProvider<HotspotMapCubit>(
                    create: (_) => HotspotMapCubit(
                      locationRepository: context.read<LocationRepository>(),
                      hotspotRepository: context.read<HotspotRepository>(),
                      analyticsService: context.read<AnalyticsService>(),
                    )..initialize(),
                    child: const HotspotMapScreen(),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/repel',
                name: 'repel',
                builder: (context, state) {
                  return BlocProvider<RepelBloc>(
                    create: (_) => RepelBloc(
                      context.read<RepelDeviceService>(),
                      analyticsService: context.read<AnalyticsService>(),
                      locationRepository: context.read<LocationRepository>(),
                      repelEventRepository: context
                          .read<RepelEventRepository>(),
                    ),
                    child: const RepelScreen(),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/report',
                name: 'report',
                builder: (context, state) {
                  final ReportPrefill? prefill = state.extra as ReportPrefill?;
                  return BlocProvider<ReportCubit>(
                    create: (_) => ReportCubit(
                      reportRepository: context.read<ReportRepository>(),
                      locationRepository: context.read<LocationRepository>(),
                      analyticsService: context.read<AnalyticsService>(),
                    )..initialize(prefill: prefill),
                    child: const ReportScreen(),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/info',
                name: 'info',
                builder: (context, state) => const InfoScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
