import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Flutter's default [MaterialScrollBehavior] only allows touch/stylus to
/// drag-scroll — on web/desktop a mouse click-drag does nothing, which
/// silently breaks horizontal-only scroll views (e.g. filter chip rows) since
/// the vertical mouse wheel doesn't map to horizontal scroll either.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };
}
