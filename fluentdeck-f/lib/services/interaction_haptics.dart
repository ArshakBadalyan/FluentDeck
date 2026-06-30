import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Central place for deliberate haptics (narrow list of gestures only).
abstract final class InteractionHaptics {
  static void pulse() {
    HapticFeedback.selectionClick();
  }

  static DateTime _lastSwipeAt =
      DateTime.fromMillisecondsSinceEpoch(0);

  /// One pulse per thumb-driven scroll/swipe gesture start ([dragDetails] present).
  /// Nested scroll surfaces are debounced.
  static bool handleScrollGestureStart(DateTime now) {
    if (now.difference(_lastSwipeAt).inMilliseconds < 140) {
      return false;
    }
    _lastSwipeAt = now;
    pulse();
    return false;
  }
}

/// Covers drag-based scrolling/swipe surfaces with a pulse at gesture start only.
/// Programmatic moves have no [dragDetails].
class InteractionSwipeHapticsScope extends StatelessWidget {
  const InteractionSwipeHapticsScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollStartNotification>(
      onNotification: (ScrollStartNotification n) {
        if (n.dragDetails == null) {
          return false;
        }
        return InteractionHaptics.handleScrollGestureStart(DateTime.now());
      },
      child: child,
    );
  }
}
