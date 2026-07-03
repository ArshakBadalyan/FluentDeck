import 'package:flutter/material.dart';

/// Default readable width for phone/tablet/web layouts.
const double kResponsiveMaxWidth = 720;

/// Tablet portrait uses full width; wider viewports center at [kResponsiveMaxWidth].
const double kResponsiveTabletMaxWidth = 840;

/// Phase 4 — centers content on tablet/web with readable max width.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = kResponsiveMaxWidth,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  static bool isTabletOrWider(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 600;

  static bool isDesktopOrWider(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 960;

  /// True when the shell should cap content width (desktop / wide web).
  static bool shouldConstrainShell(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= kResponsiveMaxWidth) return false;
    if (width <= kResponsiveTabletMaxWidth) return false;
    return true;
  }

  static int gridCrossAxisCount(
    BuildContext context, {
    int phone = 2,
    int tablet = 3,
    int desktop = 3,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 960) return desktop;
    if (width >= 600) return tablet;
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Full-viewport shell for routes — app bar, tab bodies, and bottom nav share
/// the same max width on wide screens.
class ResponsiveShell extends StatelessWidget {
  const ResponsiveShell({
    super.key,
    required this.child,
    this.maxWidth = kResponsiveMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final constrain = ResponsiveContent.shouldConstrainShell(context);
    final contentWidth = constrain ? maxWidth : size.width;
    final gutterColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0A0A0A)
        : const Color(0xFFE8E8EC);

    final framed = SizedBox(
      width: contentWidth,
      height: size.height,
      child: child,
    );

    if (!constrain) return framed;

    return ColoredBox(
      color: gutterColor,
      child: Align(
        alignment: Alignment.topCenter,
        child: DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
              ),
            ],
          ),
          child: framed,
        ),
      ),
    );
  }
}
