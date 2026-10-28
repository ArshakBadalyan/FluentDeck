import 'package:flutter/material.dart';

/// Single source of truth for Riovox's brand identity.
///
/// Change colors here — `AppColors`, `AppPageColors` and `AppTheme` read from
/// this file, so a rebrand is an edit to this file only. Keep `landing/index.html`
/// in sync by hand (it is plain HTML and cannot import Dart).
///
/// Palette: "Lagoon teal" (chosen 2026-10). Contrast checked against WCAG AA:
/// - white on [primary]                4.95:1
/// - [onPrimaryDark] on [primaryOnDark] 8.55:1
/// - [primaryOnDark] on [darkPageBg]    8.97:1
/// - [textPrimary] on [pageBg]         15.08:1
abstract final class BrandConfig {
  // ── Identity ────────────────────────────────────────────────────────────
  static const String appName = 'Riovox';
  static const String fontFamily = 'Rubik';

  // ── Brand ───────────────────────────────────────────────────────────────
  /// Buttons, progress, links, selected tab — light theme.
  static const Color primary = Color(0xFF0D7C86);

  /// App bar, headers, gradient end. Darker than [primary].
  static const Color primaryDeep = Color(0xFF0A6870);

  /// Primary in dark theme (fills and text on dark surfaces).
  static const Color primaryOnDark = Color(0xFF2EC4CF);

  /// Text/icons on [primary] / [primaryDeep].
  static const Color onPrimary = Colors.white;

  /// Text/icons on [primaryOnDark].
  static const Color onPrimaryDark = Color(0xFF04191B);

  /// Hero / banner fill — both stops equal so every hero card renders as a
  /// flat [primaryDeep], matching the header and buttons exactly instead of
  /// visibly fading between two shades.
  static const List<Color> heroGradient = [primaryDeep, primaryDeep];

  // ── Accents ─────────────────────────────────────────────────────────────
  /// Speaking features: mic, voice waves, speaking highlights.
  static const Color voice = Color(0xFFFF7A59);

  /// Filled voice controls carrying a white icon (mic button).
  static const Color voiceDeep = Color(0xFFE2553A);

  /// Rewards only: streak, XP, achievements, badges.
  static const Color reward = Color(0xFFFFC400);

  /// Reward color when used as text on light backgrounds.
  static const Color rewardText = Color(0xFF9A6B00);

  // ── Light surfaces ──────────────────────────────────────────────────────
  static const Color pageBg = Color(0xFFF3F7F7);
  static const Color cardBg = Colors.white;
  static const Color fieldBg = Color(0xFFEDF2F2);
  static const Color border = Color(0xFFE1EAEA);
  static const Color textPrimary = Color(0xFF102326);
  static const Color textSecondary = Color(0xFF5B6B6E);

  /// Unselected tab / nav icons.
  static const Color navInactive = Color(0xFF6B7A7D);

  // ── Dark surfaces ───────────────────────────────────────────────────────
  static const Color darkPageBg = Color(0xFF071214);
  static const Color darkCardBg = Color(0xFF0E1C1F);

  /// Dialogs, sheets, menus, inputs.
  static const Color darkRaisedBg = Color(0xFF152A2E);
  static const Color darkTextPrimary = Color(0xFFE9F2F2);
  static const Color darkTextSecondary = Color(0xFF9AB0B3);

  // ── Semantic (reserved — never use as brand color) ──────────────────────
  static const Color correct = Color(0xFF2EE66B); // Good / correct answer
  static const Color wrong = Color(0xFFE53935); // Again / wrong answer
  static const Color hard = Color(0xFFFF8F3D); // Hard
  static const Color skipped = Color(0xFF9E9E9E);
  static const Color newCards = Color(0xFF2196F3); // New-card count (Anki)

  // ── Tints (light theme): soft fill + readable text on it ────────────────
  // Chips, icon tiles, count badges and notices (Riovox App Redesign).
  static const Color tealTint = Color(0xFFE6F3F4);
  static const Color tealTintStrong = Color(0xFFCDE8EA);
  static const Color tealGlow = Color(0xFFDDF0F1);
  static const Color voiceTint = Color(0xFFFFE9E2);
  static const Color voiceTintText = Color(0xFFC2410C);
  static const Color rewardTint = Color(0xFFFFF6D6);
  static const Color successTint = Color(0xFFE3F8EB);
  static const Color successText = Color(0xFF0B6B3A);
  static const Color successBody = Color(0xFF2F5D44);
  static const Color warningTint = Color(0xFFFFF1E6);
  static const Color warningText = Color(0xFFB54708);
  static const Color dangerTint = Color(0xFFFDECEC);
  static const Color dangerText = Color(0xFFB42318);
  static const Color infoTint = Color(0xFFE8F1FD);
  static const Color infoText = Color(0xFF1D5FB8);
  static const Color pinkTint = Color(0xFFFDECF2);
  static const Color pinkText = Color(0xFFB4235A);

  /// Hairline between rows inside a card.
  static const Color rowDivider = Color(0xFFEEF3F3);
}
