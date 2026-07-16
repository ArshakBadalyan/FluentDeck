import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';

/// Shows a modal bottom sheet with a light frosted-glass surface.
Future<T?> showFrostedBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useSafeArea = false,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useSafeArea: useSafeArea,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.28),
    builder: (ctx) {
      final bottomInset = MediaQuery.viewInsetsOf(ctx).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: FrostedSheetSurface(child: builder(ctx)),
      );
    },
  );
}

/// Frosted surface for bottom sheets — use inside [showFrostedBottomSheet].
class FrostedSheetSurface extends StatelessWidget {
  const FrostedSheetSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark
        ? AppPageColors.darkRaisedBg.withValues(alpha: 0.94)
        : Colors.white.withValues(alpha: 0.88);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Material(
          color: fill,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.65),
                ),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
