import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';

class AnalyticsService {
  AnalyticsService._();
  static final instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Last route name reported by [routeObserver]. Used by ClickTracker so
  /// each tap event can be tagged with the screen the user is on without
  /// every call site having to pass it.
  String? currentScreen;

  /// Sibling observer to FirebaseAnalyticsObserver. We can't read the
  /// "current screen" out of FirebaseAnalyticsObserver, so we keep our
  /// own tiny one and update [currentScreen] on every push/pop/replace.
  late final NavigatorObserver routeObserver = _ScreenNameObserver(this);

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// [screenClass] helps GA4 distinguish the main shell from generic `FlutterViewController`.
  Future<void> logScreenView(
    String screenName, {
    String? screenClass,
  }) {
    currentScreen = screenName;
    return _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );
  }

  Future<void> logEvent(String name, {Map<String, Object>? parameters}) {
    return _analytics.logEvent(name: name, parameters: parameters);
  }

  /// Generic UI tap. Use a stable [targetId] (snake_case, dot-namespaced is
  /// fine — e.g. `onboarding.next`, `bottom_nav.topics`) so reports stay
  /// consistent. Anything passed via [extra] is merged into the GA4
  /// parameters bag.
  ///
  /// `screen` defaults to [currentScreen] (set by [routeObserver]).
  Future<void> logTap({
    required String targetId,
    String? screen,
    Map<String, Object>? extra,
  }) {
    final params = <String, Object>{
      'target_id': targetId,
    };
    final s = screen ?? currentScreen;
    if (s != null && s.isNotEmpty) {
      params['screen'] = s;
    }
    if (extra != null) {
      for (final entry in extra.entries) {
        params[entry.key] = entry.value;
      }
    }
    return _analytics.logEvent(name: 'ui_tap', parameters: params);
  }

  /// GA4 recommended `login` (uses Firebase SDK mapping for `method`).
  Future<void> logLoginEvent({required String method}) {
    return _analytics.logLogin(loginMethod: method);
  }

  /// GA4 recommended `sign_up` (uses Firebase SDK mapping for `method`).
  Future<void> logSignUpEvent({required String method}) {
    return _analytics.logSignUp(signUpMethod: method);
  }

  Future<void> setUserId(String? id) {
    return _analytics.setUserId(id: id);
  }

  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) {
    return _analytics.setUserProperty(name: name, value: value);
  }
}

/// Updates [AnalyticsService.currentScreen] on every navigator change so
/// click events can be tagged with the current screen automatically.
class _ScreenNameObserver extends NavigatorObserver {
  _ScreenNameObserver(this._service);

  final AnalyticsService _service;

  void _updateFor(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name != null && name.isNotEmpty) {
      _service.currentScreen = name;
    }
  }

  @override
  void didPush(Route route, Route? previousRoute) => _updateFor(route);

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) => _updateFor(newRoute);

  @override
  void didPop(Route route, Route? previousRoute) => _updateFor(previousRoute);

  @override
  void didRemove(Route route, Route? previousRoute) => _updateFor(previousRoute);
}
