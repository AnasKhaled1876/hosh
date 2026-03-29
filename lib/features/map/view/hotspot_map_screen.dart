import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hosh/core/models/app_models.dart';
import 'package:hosh/core/theme/app_tokens.dart';
import 'package:hosh/core/widgets/hoosh_widgets.dart';
import 'package:hosh/features/map/cubit/hotspot_map_cubit.dart';

class HotspotMapScreen extends StatelessWidget {
  const HotspotMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HotspotMapCubit, HotspotMapState>(
      builder: (BuildContext context, HotspotMapState state) {
        final GeoLocation center =
            state.currentLocation ??
            const GeoLocation(latitude: 30.0444, longitude: 31.2357);
        final bool hasHotspots = state.hotspots.isNotEmpty;
        final bool hasDangerHotspots = state.summary.dangerHotspots > 0;
        final bool hasCautionHotspots = state.summary.cautionHotspots > 0;
        final String statusTitle = hasDangerHotspots
            ? 'High-alert area'
            : hasCautionHotspots
            ? 'Caution in your area'
            : 'Area clear';
        final String statusBody = hasDangerHotspots
            ? '${state.summary.dangerHotspots} high-risk hotspot${state.summary.dangerHotspots == 1 ? '' : 's'} visible near your current area.'
            : hasHotspots
            ? '${state.summary.totalHotspots} recent hotspot report${state.summary.totalHotspots == 1 ? '' : 's'} visible on the live map.'
            : 'No recent hotspot reports are visible around your current area.';
        final List<Color> statusColors = hasDangerHotspots
            ? const <Color>[HooshColors.primary, HooshColors.primaryContainer]
            : hasCautionHotspots
            ? const <Color>[HooshColors.tertiary, Color(0xFFB48600)]
            : const <Color>[HooshColors.secondary, Color(0xFF5F8AA5)];

        return Stack(
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Color(0xFFF3F3F3),
                      Color(0xFFE8E8E8),
                      Color(0xFFF9F9F9),
                    ],
                  ),
                ),
              ),
            ),
            ListView(
              padding: const EdgeInsets.fromLTRB(24, 96, 24, 132),
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: HooshRadii.xl,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: statusColors,
                    ),
                    boxShadow: HooshShadows.hero,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        height: 52,
                        width: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.place_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              statusTitle,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(color: Colors.white, fontSize: 22),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              statusBody,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.white70),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              state.summary.lastReportedAt == null
                                  ? 'No recent activity recorded.'
                                  : 'Last activity ${_formatRelativeTime(state.summary.lastReportedAt!)}.',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.errorMessage != null) ...<Widget>[
                  const SizedBox(height: 16),
                  const HooshInfoCard(
                    title: 'Live sync issue',
                    subtitle:
                        'Hotspot activity could not be refreshed. The last visible map state may be incomplete.',
                    icon: Icons.cloud_off_rounded,
                    tint: Color(0xFFF5D6CC),
                  ),
                ],
                const SizedBox(height: 24),
                HooshMapSurface(
                  center: center,
                  hotspots: state.hotspots,
                  height: 280,
                  overlayLabel: 'Live Hotspot Map',
                  onHotspotTap: context.read<HotspotMapCubit>().selectHotspot,
                ),
                const SizedBox(height: 20),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _SummaryCard(
                        label: 'Total',
                        value: '${state.summary.totalHotspots}',
                        accent: HooshColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        label: 'High Risk',
                        value: '${state.summary.dangerHotspots}',
                        accent: HooshColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Last Activity',
                        value: state.summary.lastReportedAt == null
                            ? 'Clear'
                            : _formatRelativeTime(
                                state.summary.lastReportedAt!,
                              ),
                        accent: HooshColors.tertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: HooshRadii.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const HooshSectionLabel('Hotspot Summary'),
                      const SizedBox(height: 16),
                      _SummaryMetricRow(
                        label: 'High-risk hotspots',
                        value: '${state.summary.dangerHotspots}',
                        color: HooshColors.primary,
                      ),
                      const SizedBox(height: 14),
                      _SummaryMetricRow(
                        label: 'Caution hotspots',
                        value: '${state.summary.cautionHotspots}',
                        color: HooshColors.tertiary,
                      ),
                      const SizedBox(height: 14),
                      _SummaryMetricRow(
                        label: 'Active reports',
                        value: '${state.summary.totalHotspots}',
                        color: HooshColors.secondary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const HooshSectionLabel('Live Hotspots'),
                const SizedBox(height: 16),
                if (state.isLoading)
                  const _HotspotEmptyCard(
                    title: 'Loading hotspot activity',
                    subtitle: 'Pulling live community reports for this area.',
                    icon: Icons.sync_rounded,
                    tint: Color(0xFFE8E8E8),
                  )
                else if (!hasHotspots)
                  const _HotspotEmptyCard(
                    title: 'No active hotspots',
                    subtitle:
                        'No recent community reports are visible in this area right now.',
                    icon: Icons.verified_outlined,
                    tint: HooshColors.sky,
                  )
                else
                  ...state.recentHotspots.map(
                    (Hotspot hotspot) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: GestureDetector(
                        onTap: () => context
                            .read<HotspotMapCubit>()
                            .selectHotspot(hotspot),
                        child: _HotspotCard(hotspot: hotspot),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                HooshGradientButton(
                  label: 'REPORT A SIGHTING',
                  icon: Icons.shield_outlined,
                  onPressed: () {
                    context.read<HotspotMapCubit>().trackReportCta();
                    goToBranch(context, 2);
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: HooshRadii.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: accent,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetricRow extends StatelessWidget {
  const _SummaryMetricRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          height: 10,
          width: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _HotspotCard extends StatelessWidget {
  const _HotspotCard({required this.hotspot});

  final Hotspot hotspot;

  @override
  Widget build(BuildContext context) {
    final Color accent = hotspot.dangerLevel == RouteRiskLevel.danger
        ? HooshColors.primary
        : HooshColors.tertiary;
    final Color tint = hotspot.dangerLevel == RouteRiskLevel.danger
        ? const Color(0xFFF5D6CC)
        : const Color(0xFFF7E8BA);
    final String severity = hotspot.dangerLevel == RouteRiskLevel.danger
        ? 'HIGH RISK'
        : 'CAUTION';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: HooshRadii.lg,
        border: Border(left: BorderSide(color: accent, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  hotspot.note.isEmpty
                      ? 'Recent community hotspot report'
                      : hotspot.note,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  severity,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              const Icon(
                Icons.groups_2_outlined,
                size: 16,
                color: HooshColors.onSurfaceSoft,
              ),
              const SizedBox(width: 6),
              Text(
                '${hotspot.reportCount} reports',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: 18),
              const Icon(
                Icons.schedule_rounded,
                size: 16,
                color: HooshColors.onSurfaceSoft,
              ),
              const SizedBox(width: 6),
              Text(
                _formatRelativeTime(hotspot.lastReported),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HotspotEmptyCard extends StatelessWidget {
  const _HotspotEmptyCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tint,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return HooshInfoCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      tint: tint,
    );
  }
}

String _formatRelativeTime(DateTime timestamp) {
  final Duration diff = DateTime.now().difference(timestamp);
  if (diff.inMinutes < 1) {
    return 'just now';
  }
  if (diff.inHours < 1) {
    return '${diff.inMinutes}m ago';
  }
  if (diff.inDays < 1) {
    return '${diff.inHours}h ago';
  }
  return '${diff.inDays}d ago';
}
