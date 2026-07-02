import 'package:flutter/material.dart';

/// Default readable width for phone/tablet/web layouts.
const double kResponsiveMaxWidth = 720;

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
    this.gutterColor = const Color(0xFFE8E8EC),
  });

  final Widget child;
  final double maxWidth;
  final Color gutterColor;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width > maxWidth;
    final contentWidth = isWide ? maxWidth : size.width;

    final framed = SizedBox(
      width: contentWidth,
      height: size.height,
      child: child,
    );

    if (!isWide) return framed;

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
