import 'package:flutter/foundation.dart';

import 'notifications_service.dart';

/// What the bell shows: a number for new notifications, a dot when some were
/// marked unread by the user, or both.
@immutable
class NotificationBadgeState {
  const NotificationBadgeState({this.newCount = 0, this.dot = false});

  final int newCount;
  final bool dot;
}

/// Shared bell state, so every bell (top bar, Today) updates together.
class NotificationBadge {
  NotificationBadge._();

  static final ValueNotifier<NotificationBadgeState> state =
      ValueNotifier(const NotificationBadgeState());

  static Future<void> refresh() async {
    try {
      final s = await NotificationsService.unreadSummary();
      state.value = NotificationBadgeState(newCount: s.newCount, dot: s.hasMarkedUnread);
    } catch (_) {
      // Offline: keep what the bell shows.
    }
  }

  /// The panel opened: the number clears at once (the server catches up).
  static void clearCount() {
    state.value = NotificationBadgeState(dot: state.value.dot);
  }
}
