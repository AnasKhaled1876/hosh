import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hosh/core/models/app_models.dart';
import 'package:hosh/core/theme/app_tokens.dart';

class HooshGlassPanel extends StatelessWidget {
  const HooshGlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = HooshRadii.lg,
    this.color = const Color(0xCCFFFFFF),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color,
            borderRadius: radius,
            boxShadow: HooshShadows.ambient,
          ),
          child: child,
        ),
      ),
    );
  }
}

class HooshGradientButton extends StatelessWidget {
  const HooshGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.radius = 32,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double radius;
  final EdgeInsetsGeometry padding;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final Widget content = InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(radius),
      child: Ink(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[HooshColors.primary, HooshColors.primaryContainer],
          ),
          boxShadow: HooshShadows.hero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );

    if (!expanded) {
      return content;
    }
    return SizedBox(width: double.infinity, child: content);
  }
}

class HooshSectionLabel extends StatelessWidget {
  const HooshSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: HooshColors.secondary,
        letterSpacing: 1.2,
      ),
    );
  }
}

class HooshHeaderBar extends StatelessWidget {
  const HooshHeaderBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: HooshGlassPanel(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          radius: HooshRadii.lg,
          child: Row(
            children: <Widget>[
              Container(
                height: 40,
                width: 40,
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: HooshColors.sky,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Vigilant Guardian',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HooshBottomNavBar extends StatelessWidget {
  const HooshBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const List<_NavItem> items = <_NavItem>[
      _NavItem('Map', Icons.map_outlined),
      _NavItem('Repel', Icons.graphic_eq_rounded),
      _NavItem('Report', Icons.shield_outlined),
      _NavItem('Info', Icons.info_outline_rounded),
    ];
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: HooshGlassPanel(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          radius: HooshRadii.lg,
          child: Row(
            children: List<Widget>.generate(items.length, (int index) {
              final bool active = index == currentIndex;
              final _NavItem item = items[index];
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: active
                          ? HooshColors.activeNav
                          : Colors.transparent,
                      borderRadius: HooshRadii.md,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          item.icon,
                          size: 18,
                          color: active
                              ? const Color(0xFF9A3412)
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label.toUpperCase(),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: active
                                    ? const Color(0xFF9A3412)
                                    : const Color(0xFF64748B),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class HooshMapSurface extends StatelessWidget {
  const HooshMapSurface({
    super.key,
    required this.center,
    required this.hotspots,
    required this.height,
    this.overlayLabel,
    this.onPickLocation,
    this.onHotspotTap,
  });

  final GeoLocation center;
  final List<Hotspot> hotspots;
  final double height;
  final String? overlayLabel;
  final ValueChanged<GeoLocation>? onPickLocation;
  final ValueChanged<Hotspot>? onHotspotTap;

  bool get _showPlaceholder =>
      kIsWeb || Platform.environment.containsKey('FLUTTER_TEST');

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: HooshRadii.xl,
      child: SizedBox(
        height: height,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: _showPlaceholder
                  ? _PlaceholderMap(
                      hotspots: hotspots,
                      center: center,
                      onTap: onPickLocation,
                      onHotspotTap: onHotspotTap,
                    )
                  : GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(center.latitude, center.longitude),
                        zoom: 14.5,
                      ),
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      onTap: onPickLocation == null
                          ? null
                          : (LatLng latLng) {
                              onPickLocation!(
                                GeoLocation(
                                  latitude: latLng.latitude,
                                  longitude: latLng.longitude,
                                ),
                              );
                            },
                      markers: <Marker>{
                        Marker(
                          markerId: const MarkerId('current'),
                          position: LatLng(center.latitude, center.longitude),
                        ),
                        ...hotspots.map(
                          (Hotspot hotspot) => Marker(
                            markerId: MarkerId(hotspot.id),
                            position: LatLng(
                              hotspot.location.latitude,
                              hotspot.location.longitude,
                            ),
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              hotspot.dangerLevel == RouteRiskLevel.danger
                                  ? BitmapDescriptor.hueRed
                                  : BitmapDescriptor.hueOrange,
                            ),
                            onTap: onHotspotTap == null
                                ? null
                                : () => onHotspotTap!(hotspot),
                          ),
                        ),
                      },
                    ),
            ),
            if (overlayLabel != null)
              Positioned(
                left: 16,
                bottom: 16,
                child: HooshGlassPanel(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  radius: HooshRadii.pill,
                  child: Text(
                    overlayLabel!.toUpperCase(),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: HooshColors.secondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderMap extends StatelessWidget {
  const _PlaceholderMap({
    required this.hotspots,
    required this.center,
    this.onTap,
    this.onHotspotTap,
  });

  final List<Hotspot> hotspots;
  final GeoLocation center;
  final ValueChanged<GeoLocation>? onTap;
  final ValueChanged<Hotspot>? onHotspotTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap == null ? null : () => onTap!(center),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF8FAEAA), Color(0xFF6C9D98)],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned.fill(child: CustomPaint(painter: _MapGridPainter())),
            ...hotspots.asMap().entries.map((MapEntry<int, Hotspot> entry) {
              final int index = entry.key;
              return Positioned(
                left: 80 + (index * 86),
                top: 70 + (index * 40),
                child: GestureDetector(
                  onTap: onHotspotTap == null
                      ? null
                      : () => onHotspotTap!(entry.value),
                  child: Container(
                    height: 16,
                    width: 16,
                    decoration: BoxDecoration(
                      color: entry.value.dangerLevel == RouteRiskLevel.danger
                          ? HooshColors.primary
                          : HooshColors.tertiary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: HooshShadows.ambient,
                    ),
                  ),
                ),
              );
            }),
            const Center(
              child: Icon(Icons.place_rounded, color: Colors.white, size: 28),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (double x = -20; x < size.width + 20; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x + 50, size.height), paint);
    }
    for (double y = 10; y < size.height; y += 28) {
      final Path path = Path()
        ..moveTo(0, y)
        ..quadraticBezierTo(size.width / 2, y - 18, size.width, y + 12);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HooshChromeScaffold extends StatelessWidget {
  const HooshChromeScaffold({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onNavTap,
  });

  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onNavTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HooshColors.surface,
      extendBody: true,
      body: Stack(
        children: <Widget>[
          Positioned.fill(child: child),
          const Positioned(top: 0, left: 0, right: 0, child: HooshHeaderBar()),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: HooshBottomNavBar(
              currentIndex: currentIndex,
              onTap: onNavTap,
            ),
          ),
        ],
      ),
    );
  }
}

class HooshInfoCard extends StatelessWidget {
  const HooshInfoCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.tint = HooshColors.surfaceHigh,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: tint, borderRadius: HooshRadii.lg),
      child: Row(
        children: <Widget>[
          Icon(icon, color: HooshColors.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void goToBranch(BuildContext context, int index) {
  final String route = switch (index) {
    0 => 'map',
    1 => 'repel',
    2 => 'report',
    _ => 'info',
  };
  context.goNamed(route);
}

class _NavItem {
  const _NavItem(this.label, this.icon);

  final String label;
  final IconData icon;
}
