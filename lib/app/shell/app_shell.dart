import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hosh/core/analytics/app_analytics.dart';
import 'package:hosh/core/widgets/hoosh_widgets.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
    required this.analyticsService,
  });

  final StatefulNavigationShell navigationShell;
  final AnalyticsService analyticsService;

  @override
  Widget build(BuildContext context) {
    return HooshChromeScaffold(
      currentIndex: navigationShell.currentIndex,
      onNavTap: (int index) {
        analyticsService.logTabSelected(
          tabName: tabNameForIndex(index),
          sourceTab: tabNameForIndex(navigationShell.currentIndex),
        );
        navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        );
      },
      child: navigationShell,
    );
  }
}
