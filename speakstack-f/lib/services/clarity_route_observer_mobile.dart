import 'package:flutter/widgets.dart';

import 'package:untitled2/services/clarity_screen_sync.dart';

class ClarityRouteObserver extends NavigatorObserver {
  void _apply(Route<dynamic>? route) {
    final n = route?.settings.name;
    if (n == null || n.isEmpty) {
      return;
    }
    syncClarityScreenName(n);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _apply(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _apply(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _apply(previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _apply(previousRoute);
  }
}
