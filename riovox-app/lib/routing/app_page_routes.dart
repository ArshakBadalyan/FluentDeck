import 'package:flutter/material.dart';

/// Named [MaterialPageRoute] for analytics observers (Firebase, Clarity).
MaterialPageRoute<T> appMaterialPageRoute<T>({
  required WidgetBuilder builder,
  String? name,
  RouteSettings? settings,
  bool fullscreenDialog = false,
  bool maintainState = true,
}) {
  final resolvedSettings =
      settings ?? (name != null ? RouteSettings(name: name) : null);

  return MaterialPageRoute<T>(
    builder: builder,
    settings: resolvedSettings,
    fullscreenDialog: fullscreenDialog,
    maintainState: maintainState,
  );
}
