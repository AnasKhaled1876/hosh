import 'package:flutter/material.dart';
import 'package:hosh/core/widgets/hoosh_widgets.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 112, 24, 132),
      children: const <Widget>[
        HooshSectionLabel('App Purpose'),
        SizedBox(height: 12),
        HooshInfoCard(
          title: 'Non-lethal street safety',
          subtitle:
              'Hoosh helps pedestrians respond to aggressive stray dogs with deterrent tools, reporting, and a live hotspot map.',
          icon: Icons.health_and_safety_outlined,
        ),
        SizedBox(height: 16),
        HooshSectionLabel('Safety Notes'),
        SizedBox(height: 12),
        HooshInfoCard(
          title: 'Deterrent, not a guarantee',
          subtitle:
              'High-frequency sound and light should buy time and attention, not replace retreat, awareness, or emergency services.',
          icon: Icons.warning_amber_rounded,
          tint: Color(0xFFE8E8E8),
        ),
        SizedBox(height: 16),
        HooshSectionLabel('Roadmap'),
        SizedBox(height: 12),
        HooshInfoCard(
          title: 'Next layers',
          subtitle:
              'Trusted contacts, push alerts, moderation tooling, and stronger analytics hooks are planned into this scaffold.',
          icon: Icons.timeline_outlined,
          tint: Color(0xFFB9DFFE),
        ),
      ],
    );
  }
}
