import 'package:flutter/material.dart';

/// Kinds of toast. [AppToast.showSnackBar] infers one from the message text;
/// call [AppToast.success] / [AppToast.error] etc. to pick it explicitly.
enum ToastType { info, success, warning, error }

/// Where a toast appears.
enum ToastPlacement { top, topRight, bottom, bottomRight }

/// Look of one toast type.
class ToastStyle {
  const ToastStyle({
    required this.background,
    required this.foreground,
    required this.icon,
    required this.duration,
  });

  final Color background;
  final Color foreground;
  final IconData icon;

  /// Base time on screen; long messages get extra reading time
  /// ([ToastConfig.extraMsPerChar]) up to [ToastConfig.maxDuration].
  final Duration duration;
}

/// Single source of truth for in-app toast notifications (shown above every
/// page, bottom sheet and dialog). Tune timing, colours and position here.
abstract final class ToastConfig {
  // ── Position ────────────────────────────────────────────────────────────
  /// Screens at least this wide (tablet / web) use [widePlacement].
  static const double wideBreakpoint = 600;

  /// Phones: top centre, clear of the keyboard and the bottom sheet's buttons.
  static const ToastPlacement mobilePlacement = ToastPlacement.top;

  /// Tablet / web: top-right corner.
  static const ToastPlacement widePlacement = ToastPlacement.topRight;

  /// Gap from the screen edges (added to the safe-area insets).
  static const EdgeInsets margin = EdgeInsets.fromLTRB(12, 12, 16, 12);

  /// Max toast width on wide screens; phones use full width minus [margin].
  static const double maxWidth = 380;

  /// Toasts shown at once; older ones are dropped.
  static const int maxVisible = 3;

  /// Space between stacked toasts.
  static const double spacing = 8;

  // ── Timing ──────────────────────────────────────────────────────────────
  /// Extra time per character beyond [readingFreeChars], so long errors can
  /// be read (~200 words/min).
  static const int extraMsPerChar = 50;
  static const int readingFreeChars = 40;
  static const Duration maxDuration = Duration(seconds: 7);

  /// Toasts with an action button (e.g. "Upgrade") stay at least this long.
  static const Duration minDurationWithAction = Duration(seconds: 5);

  static const Duration animationDuration = Duration(milliseconds: 220);

  // ── Look ────────────────────────────────────────────────────────────────
  static const double borderRadius = 14;
  static const double elevation = 6;
  static const EdgeInsets padding = EdgeInsets.fromLTRB(14, 12, 8, 12);
  static const double fontSize = 14;

  static const Map<ToastType, ToastStyle> styles = {
    ToastType.info: ToastStyle(
      background: Color(0xFF263238),
      foreground: Colors.white,
      icon: Icons.info_outline_rounded,
      duration: Duration(milliseconds: 2500),
    ),
    ToastType.success: ToastStyle(
      // Was the brand teal (BrandConfig.primaryDeep), which reads as green on
      // some screens and blended into the teal app bar — matched to the
      // neutral dark slate the other toast types already use.
      background: Color(0xFF263238),
      foreground: Colors.white,
      icon: Icons.check_circle_outline_rounded,
      duration: Duration(milliseconds: 2000),
    ),
    ToastType.warning: ToastStyle(
      background: Color(0xFFB45309),
      foreground: Colors.white,
      icon: Icons.warning_amber_rounded,
      duration: Duration(milliseconds: 3500),
    ),
    ToastType.error: ToastStyle(
      background: Color(0xFFC62828),
      foreground: Colors.white,
      icon: Icons.error_outline_rounded,
      duration: Duration(milliseconds: 4000),
    ),
  };

  // ── Type detection (for messages passed without a type) ─────────────────
  static final RegExp errorPattern = RegExp(
    r"(could ?n[o']t|cannot|can't|failed|failure|error|exception|invalid|"
    r'denied|not found|unable|try again|requires|required)',
    caseSensitive: false,
  );
  static final RegExp warningPattern = RegExp(
    r'(enter |choose |select |first\b|limit|premium|offline|no internet)',
    caseSensitive: false,
  );
  static final RegExp successPattern = RegExp(
    r'(saved|added|deleted|removed|updated|copied|created|imported|exported|'
    r'done|success|sent|restored)',
    caseSensitive: false,
  );
}
