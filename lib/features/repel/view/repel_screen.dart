import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hosh/app/bootstrap/app_bootstrap_cubit.dart';
import 'package:hosh/core/analytics/app_analytics.dart';
import 'package:hosh/core/models/app_models.dart';
import 'package:hosh/core/theme/app_tokens.dart';
import 'package:hosh/core/widgets/hoosh_widgets.dart';
import 'package:hosh/features/repel/bloc/repel_bloc.dart';

class RepelScreen extends StatefulWidget {
  const RepelScreen({super.key});

  @override
  State<RepelScreen> createState() => _RepelScreenState();
}

class _RepelScreenState extends State<RepelScreen> {
  bool _loggedOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loggedOpen) {
      return;
    }
    final AppBootstrapState bootstrapState = context
        .read<AppBootstrapCubit>()
        .state;
    context.read<AnalyticsService>().logRepelScreenOpened(
      appMode: bootstrapState.status == BootstrapStatus.degraded
          ? 'degraded'
          : bootstrapState.usingLiveServices
          ? 'live'
          : 'local_safe',
    );
    _loggedOpen = true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RepelBloc, RepelState>(
      listener: (BuildContext context, RepelState state) async {
        final ReportPrefill? prompt = state.pendingReportPrompt;
        if (prompt == null) {
          return;
        }
        final RepelBloc repelBloc = context.read<RepelBloc>();
        final GoRouter router = GoRouter.of(context);
        final bool? shouldReport = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Report this encounter?'),
              content: const Text('Did you encounter an aggressive dog?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('NO'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('YES'),
                ),
              ],
            );
          },
        );
        if (!mounted) {
          return;
        }
        repelBloc.add(const RepelPromptCleared());
        if (shouldReport == true) {
          router.goNamed('report', extra: prompt);
        }
      },
      builder: (BuildContext context, RepelState state) {
        final AppBootstrapState bootstrapState = context
            .watch<AppBootstrapCubit>()
            .state;
        final bool syncLimited =
            bootstrapState.status == BootstrapStatus.degraded;
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 112, 24, 132),
          children: <Widget>[
            Center(
              child: Column(
                children: <Widget>[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 88,
                    width: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: HooshShadows.ambient,
                      border: Border.all(
                        color: HooshColors.primary.withValues(
                          alpha: state.session.isActive ? 0.32 : 0.14,
                        ),
                        width: 10,
                      ),
                    ),
                    child: Icon(
                      Icons.gpp_good_outlined,
                      color: state.session.isActive
                          ? HooshColors.primary
                          : HooshColors.secondary,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'ACTIVE PROTECTION',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineLarge?.copyWith(letterSpacing: -0.75),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    state.statusMessage.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: HooshColors.secondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: HooshRadii.xl,
                boxShadow: HooshShadows.ambient,
              ),
              child: Column(
                children: <Widget>[
                  const Icon(
                    Icons.surround_sound_outlined,
                    color: HooshColors.primary,
                    size: 42,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Ultrasonic Repel',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Emits high-frequency deterrent tones to discourage aggressive approach.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),
                  Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        context.read<RepelBloc>().add(
                          state.session.isActive
                              ? const RepelStopped()
                              : const RepelStarted(),
                        );
                      },
                      customBorder: const CircleBorder(),
                      child: Ink(
                        height: 220,
                        width: 220,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              HooshColors.primary,
                              HooshColors.primaryContainer,
                            ],
                          ),
                          boxShadow: HooshShadows.hero,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              state.session.isActive
                                  ? Icons.stop_circle_outlined
                                  : Icons.volume_up_rounded,
                              color: Colors.white,
                              size: 52,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              state.session.isActive ? 'STOP' : 'REPEL',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _MetricCard(
                          label: 'Frequency',
                          value:
                              '${state.session.frequencyKhz.toStringAsFixed(1)} kHz',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _MetricCard(
                          label: 'Output',
                          value: state.session.outputLabel,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF2F3131),
                borderRadius: HooshRadii.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'SOS Panic Mode',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFFF1F1F1),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Broadcast location to authorities and contacts immediately.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xB3F1F1F1),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () =>
                          context.read<RepelBloc>().add(const PanicRequested()),
                      style: FilledButton.styleFrom(
                        backgroundColor: HooshColors.danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.notifications_active_outlined),
                      label: const Text('TRIGGER PANIC'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: <Widget>[
                Expanded(
                  child: GestureDetector(
                    onTap: () => goToBranch(context, 2),
                    child: const HooshInfoCard(
                      title: 'Report Sighting',
                      subtitle: 'Update Map Now',
                      icon: Icons.shield_outlined,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.read<RepelBloc>().add(
                      TorchToggled(!state.strobeEnabled),
                    ),
                    child: HooshInfoCard(
                      title: 'Strobe Light',
                      subtitle: state.strobeEnabled
                          ? 'Visual Deterrent On'
                          : 'Visual Deterrent Off',
                      icon: Icons.flashlight_on_outlined,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: HooshColors.sky,
                borderRadius: HooshRadii.md,
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.verified_user_outlined,
                    color: HooshColors.secondary,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          syncLimited
                              ? 'Live Sync Limited'
                              : 'Safety Perimeter Active',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: HooshColors.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          bootstrapState.message ??
                              (bootstrapState.usingLiveServices
                                  ? 'Your device is monitoring live proximity alerts.'
                                  : 'Your device is monitoring local proximity safeguards.'),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: HooshColors.secondary.withValues(
                                  alpha: 0.82,
                                ),
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: HooshColors.secondary,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HooshColors.surfaceLow,
        borderRadius: HooshRadii.md,
      ),
      child: Column(
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: HooshColors.onSurfaceSoft,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
