import 'package:flutter/material.dart';

/// A named, visual "look" for a custom note type's cards — bundles font
/// size/weight and colors so users pick a whole coordinated style in one tap
/// instead of configuring HTML/CSS by hand.
class CardStylePreset {
  const CardStylePreset({
    required this.id,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.accentColor,
    required this.fontSize,
    required this.fontWeight,
  });

  final String id;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color accentColor;
  final double fontSize;
  final FontWeight fontWeight;

  /// CSS applied to the exported `.apkg` file (opened in other apps) — the
  /// in-app study screen renders this preset directly via Flutter widgets.
  String toCss() {
    final bg = _toHex(backgroundColor);
    final fg = _toHex(textColor);
    final accent = _toHex(accentColor);
    final weight = fontWeight == FontWeight.w700 ? '700' : '400';
    return '.card {\n'
        '  font-family: Rubik, sans-serif;\n'
        '  font-size: ${fontSize.round()}px;\n'
        '  font-weight: $weight;\n'
        '  color: $fg;\n'
        '  background-color: $bg;\n'
        '  text-align: center;\n'
        '  padding: 24px;\n'
        '}\n'
        'hr#answer {\n'
        '  border-color: $accent;\n'
        '}';
  }

  static String _toHex(Color c) {
    final value = ((c.a * 255).round() << 24) |
        ((c.r * 255).round() << 16) |
        ((c.g * 255).round() << 8) |
        (c.b * 255).round();
    return '#${(value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
  }

  static const List<CardStylePreset> all = [
    CardStylePreset(
      id: 'classic',
      label: 'Classic',
      backgroundColor: Color(0xFFFFFFFF),
      textColor: Color(0xFF1A1A1A),
      accentColor: Color(0xFF8A2CFF),
      fontSize: 20,
      fontWeight: FontWeight.w400,
    ),
    CardStylePreset(
      id: 'minimal',
      label: 'Minimal',
      backgroundColor: Color(0xFFFAFAFA),
      textColor: Color(0xFF333333),
      accentColor: Color(0xFF9E9E9E),
      fontSize: 18,
      fontWeight: FontWeight.w400,
    ),
    CardStylePreset(
      id: 'playful',
      label: 'Playful',
      backgroundColor: Color(0xFFFFF7E0),
      textColor: Color(0xFF4A2B7A),
      accentColor: Color(0xFF8A2CFF),
      fontSize: 22,
      fontWeight: FontWeight.w700,
    ),
    CardStylePreset(
      id: 'ocean',
      label: 'Ocean',
      backgroundColor: Color(0xFFE8F4FD),
      textColor: Color(0xFF0B3D5C),
      accentColor: Color(0xFF2196C4),
      fontSize: 20,
      fontWeight: FontWeight.w400,
    ),
    CardStylePreset(
      id: 'warm',
      label: 'Warm',
      backgroundColor: Color(0xFFFDF6E9),
      textColor: Color(0xFF5C3A21),
      accentColor: Color(0xFFE0863B),
      fontSize: 20,
      fontWeight: FontWeight.w400,
    ),
    CardStylePreset(
      id: 'dark',
      label: 'Dark',
      backgroundColor: Color(0xFF1E1E2E),
      textColor: Color(0xFFF5F5F5),
      accentColor: Color(0xFFB388FF),
      fontSize: 20,
      fontWeight: FontWeight.w400,
    ),
  ];

  static CardStylePreset byId(String id) =>
      all.firstWhere((p) => p.id == id, orElse: () => all.first);
}
