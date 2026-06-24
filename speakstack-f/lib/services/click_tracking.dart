import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'analytics_service.dart';

/// Wraps the whole app and emits a `ui_tap` event on every pointer-up.
/// Pair it with named [TrackedTap] / [PrimaryButton(analyticsId: ...)]
/// usages for higher-fidelity reporting on important buttons.
///
/// We also de-dupe taps so a single tap that resolves to a named handler
/// doesn't show up twice (the named event is preferred).
class ClickTracker extends StatefulWidget {
  const ClickTracker({
    super.key,
    required this.child,
    this.minIntervalMs = 150,
  });

  final Widget child;

  /// Minimum gap between two emitted taps from the same pointer position.
  /// Prevents flooding when users drag/scroll and the framework synthesises
  /// many pointer events.
  final int minIntervalMs;

  /// Marks an event as "already named" so [ClickTracker] skips emitting
  /// the generic `ui_tap` for it. Called from [TrackedTap] /
  /// [recordNamedTap].
  static void recordNamedTap() {
    _ClickTrackerNotifier.instance.markNamed();
  }

  @override
  State<ClickTracker> createState() => _ClickTrackerState();
}

class _ClickTrackerState extends State<ClickTracker> {
  DateTime _lastEmitted = DateTime.fromMillisecondsSinceEpoch(0);
  Offset? _lastDownPosition;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      child: widget.child,
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    _lastDownPosition = event.position;
  }

  void _onPointerUp(PointerUpEvent event) {
    // Skip secondary mouse buttons / stylus side buttons.
    if (event.buttons != 0 && event.buttons != kPrimaryButton) return;

    // Reject "drags": if the pointer travelled too far between down and
    // up, treat it as a scroll/drag, not a tap.
    final downPos = _lastDownPosition;
    _lastDownPosition = null;
    if (downPos != null && (event.position - downPos).distance > 12) {
      return;
    }

    // Throttle rapid duplicates from the same gesture chain.
    final now = DateTime.now();
    if (now.difference(_lastEmitted).inMilliseconds < widget.minIntervalMs) {
      return;
    }

    // If a named TrackedTap fired during this gesture chain, skip the
    // generic event so the report isn't doubled.
    if (_ClickTrackerNotifier.instance.consumeNamedFlag()) {
      _lastEmitted = now;
      return;
    }

    _lastEmitted = now;
    final extra = <String, Object>{
      'x': event.position.dx.round(),
      'y': event.position.dy.round(),
    };
    unawaited(
      AnalyticsService.instance.logTap(
        targetId: 'screen',
        extra: extra,
      ),
    );
  }
}

/// Internal cross-tree signal so [TrackedTap] can tell the surrounding
/// [ClickTracker] to skip the generic event for a specific tap.
class _ClickTrackerNotifier {
  _ClickTrackerNotifier._();
  static final _ClickTrackerNotifier instance = _ClickTrackerNotifier._();

  bool _named = false;

  void markNamed() {
    _named = true;
  }

  bool consumeNamedFlag() {
    final v = _named;
    _named = false;
    return v;
  }
}

/// Drop-in wrapper around any tappable area that should emit a named
/// `ui_tap` event in addition to (or instead of) the generic one from
/// [ClickTracker].
///
/// Use a stable [id] (e.g. `onboarding.school.skip`) so reports stay
/// consistent across releases.
class TrackedTap extends StatelessWidget {
  const TrackedTap({
    super.key,
    required this.id,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.behavior = HitTestBehavior.opaque,
    this.extra,
  });

  final String id;
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final HitTestBehavior behavior;
  final Map<String, Object>? extra;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: behavior,
      onTap: onTap == null
          ? null
          : () {
              ClickTracker.recordNamedTap();
              unawaited(
                AnalyticsService.instance.logTap(
                  targetId: id,
                  extra: extra,
                ),
              );
              onTap!();
            },
      onLongPress: onLongPress == null
          ? null
          : () {
              ClickTracker.recordNamedTap();
              unawaited(
                AnalyticsService.instance.logTap(
                  targetId: '$id.long_press',
                  extra: extra,
                ),
              );
              onLongPress!();
            },
      child: child,
    );
  }
}

/// Helper for wrapping an existing handler (e.g. `onPressed` of a button)
/// so it logs a named `ui_tap` before invoking the original callback.
VoidCallback? wrapWithTapTracking(
  VoidCallback? original, {
  required String id,
  Map<String, Object>? extra,
}) {
  if (original == null) return null;
  return () {
    ClickTracker.recordNamedTap();
    unawaited(
      AnalyticsService.instance.logTap(targetId: id, extra: extra),
    );
    original();
  };
}
