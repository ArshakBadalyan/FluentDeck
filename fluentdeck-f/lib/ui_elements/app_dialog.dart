import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

/// [showDialog] with the Material "fade" pattern: the dialog fades and
/// scales in from 80% (m2.material.io/design/motion, `FadeScaleTransition`).
/// Same parameters as [showDialog]; falls back to it with reduced motion.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
}) {
  if (MediaQuery.disableAnimationsOf(context)) {
    return showDialog<T>(
      context: context,
      builder: builder,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
    );
  }
  return showModal<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    configuration: FadeScaleTransitionConfiguration(
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black54,
    ),
    // showDialog keeps dialogs clear of notches/system bars; do the same.
    builder: (context) => SafeArea(child: Builder(builder: builder)),
  );
}
