import 'package:flutter/material.dart';

abstract final class HooshColors {
  static const Color primary = Color(0xFFAC2D00);
  static const Color primaryContainer = Color(0xFFD53E0B);
  static const Color secondary = Color(0xFF3D627D);
  static const Color tertiary = Color(0xFF765700);
  static const Color danger = Color(0xFFBA1A1A);
  static const Color surface = Color(0xFFF9F9F9);
  static const Color surfaceLow = Color(0xFFF3F3F3);
  static const Color surfaceLowest = Color(0xFFFFFFFF);
  static const Color surfaceHigh = Color(0xFFE8E8E8);
  static const Color sky = Color(0xFFB9DFFE);
  static const Color onSurface = Color(0xFF1A1C1C);
  static const Color onSurfaceSoft = Color(0xFF5B4139);
  static const Color muted = Color(0xFF94A3B8);
  static const Color activeNav = Color(0xFFFFEDD5);
}

abstract final class HooshRadii {
  static const BorderRadius xl = BorderRadius.all(Radius.circular(32));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(24));
  static const BorderRadius md = BorderRadius.all(Radius.circular(16));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));
}

abstract final class HooshShadows {
  static const List<BoxShadow> ambient = <BoxShadow>[
    BoxShadow(color: Color(0x0F1A1C1C), blurRadius: 32, offset: Offset(0, 12)),
  ];

  static const List<BoxShadow> hero = <BoxShadow>[
    BoxShadow(color: Color(0x4DAC2D00), blurRadius: 40, offset: Offset(0, 20)),
  ];
}
