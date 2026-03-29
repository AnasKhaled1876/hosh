import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hosh/core/analytics/app_analytics.dart';
import 'package:hosh/core/models/app_models.dart';
import 'package:hosh/core/theme/app_tokens.dart';
import 'package:hosh/core/widgets/hoosh_widgets.dart';
import 'package:hosh/features/report/cubit/report_cubit.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReportCubit, ReportState>(
      listener: (BuildContext context, ReportState state) {
        if (_descriptionController.text != state.draft.description) {
          _descriptionController.text = state.draft.description;
          _descriptionController.selection = TextSelection.fromPosition(
            TextPosition(offset: _descriptionController.text.length),
          );
        }
      },
      builder: (BuildContext context, ReportState state) {
        final GeoLocation location =
            state.draft.location ??
            const GeoLocation(latitude: 30.0444, longitude: 31.2357);
        final double sliderValue = switch (state.draft.severity) {
          ReportSeverity.low => 0.15,
          ReportSeverity.caution => 0.5,
          ReportSeverity.high => 0.85,
          null => 0.5,
        };

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 112, 24, 132),
          children: <Widget>[
            Text(
              'Report Sighting',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            const HooshSectionLabel('Step 1 of 2: Details & Location'),
            const SizedBox(height: 24),
            HooshMapSurface(
              center: location,
              hotspots: const <Hotspot>[],
              height: 256,
              overlayLabel: 'Current: Central Park North',
              onPickLocation: context.read<ReportCubit>().updateLocation,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: HooshColors.sky,
                borderRadius: HooshRadii.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(
                    Icons.gps_fixed_rounded,
                    color: HooshColors.secondary,
                  ),
                  const SizedBox(height: 12),
                  const HooshSectionLabel('Time detected'),
                  const SizedBox(height: 4),
                  Text(
                    _formattedTime(state.draft.detectedAt),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: HooshColors.secondary,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: HooshColors.surfaceLow,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const HooshSectionLabel('Dog Behavior'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<DogBehavior>(
                    initialValue: state.draft.behavior,
                    items: DogBehavior.values
                        .map(
                          (DogBehavior behavior) =>
                              DropdownMenuItem<DogBehavior>(
                                value: behavior,
                                child: Text(behavior.label),
                              ),
                        )
                        .toList(),
                    onChanged: context.read<ReportCubit>().updateBehavior,
                  ),
                  const SizedBox(height: 20),
                  const HooshSectionLabel('Number of Dogs'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: HooshRadii.md,
                    ),
                    child: Row(
                      children: <Widget>[
                        _SquareIconButton(
                          icon: Icons.remove_rounded,
                          onPressed: context
                              .read<ReportCubit>()
                              .decrementDogCount,
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              '${state.draft.dogCount}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ),
                        _SquareIconButton(
                          icon: Icons.add_rounded,
                          onPressed: context
                              .read<ReportCubit>()
                              .incrementDogCount,
                          color: HooshColors.secondary,
                          foreground: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const HooshSectionLabel('Description'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    onChanged: context.read<ReportCubit>().updateDescription,
                    decoration: const InputDecoration(
                      hintText:
                          'e.g. Large brown dog near the park entrance, no collar visible...',
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const HooshSectionLabel('Risk Severity'),
                      Text(
                        state.draft.severity?.shortLabel ?? 'LVL ?: UNKNOWN',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: HooshColors.primary),
                      ),
                    ],
                  ),
                  Slider(
                    value: sliderValue,
                    onChanged: context.read<ReportCubit>().updateSeverity,
                  ),
                  Row(
                    children: <Widget>[
                      Text(
                        'LOW',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: HooshColors.muted),
                      ),
                      const Spacer(),
                      Text(
                        'HIGH',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: HooshColors.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _pickPhoto,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: HooshColors.surfaceHigh,
                      foregroundColor: HooshColors.onSurfaceSoft,
                      minimumSize: const Size.fromHeight(56),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(
                      state.draft.photoPath == null
                          ? 'Upload Photo'
                          : 'Photo Attached',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: HooshRadii.md,
                    ),
                    child: Row(
                      children: <Widget>[
                        const Expanded(child: HooshSectionLabel('Anonymous')),
                        Switch.adaptive(
                          value: state.draft.anonymous,
                          onChanged: context
                              .read<ReportCubit>()
                              .toggleAnonymous,
                          activeTrackColor: HooshColors.primary,
                          activeThumbColor: HooshColors.primaryContainer,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Opacity(
              opacity: state.canSubmit ? 1 : 0.5,
              child: HooshGradientButton(
                label: 'SUBMIT REPORT',
                icon: Icons.chevron_right_rounded,
                onPressed: state.canSubmit
                    ? context.read<ReportCubit>().submit
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              state.successMessage ??
                  state.errorMessage ??
                  'VERIFIED SAFETY DATA HELPS EVERYONE',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: state.errorMessage != null
                    ? HooshColors.danger
                    : HooshColors.muted,
                letterSpacing: 2,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickPhoto() async {
    final AnalyticsService analyticsService = context.read<AnalyticsService>();
    final Permission permission = Platform.isIOS
        ? Permission.photos
        : Permission.photos;
    final PermissionStatus existingStatus = await permission.status;
    if (!existingStatus.isGranted && !existingStatus.isLimited) {
      analyticsService.logPermissionPromptShown(
        permission: AnalyticsPermissionType.photos,
        sourceScreen: 'report',
      );
    }
    final PermissionStatus status = await permission.request();
    final AppPermissionStatus permissionStatus = status.isGranted
        ? AppPermissionStatus.granted
        : status.isLimited
        ? AppPermissionStatus.limited
        : AppPermissionStatus.denied;
    analyticsService.logPermissionResult(
      permission: AnalyticsPermissionType.photos,
      status: permissionStatus,
      sourceScreen: 'report',
    );
    if (!status.isGranted && !status.isLimited) {
      return;
    }
    final XFile? file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (!mounted) {
      return;
    }
    context.read<ReportCubit>().attachPhoto(file?.path);
  }

  String _formattedTime(DateTime time) {
    final String hour = time.hour.toString().padLeft(2, '0');
    final String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute PM';
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({
    required this.icon,
    required this.onPressed,
    this.color = HooshColors.surfaceHigh,
    this.foreground = HooshColors.onSurface,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: foreground),
      ),
    );
  }
}
