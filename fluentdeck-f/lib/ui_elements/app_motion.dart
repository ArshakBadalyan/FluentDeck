import 'package:flutter/material.dart';

/// Phase 4 — shared motion tokens and lightweight animation widgets.
abstract final class AppMotion {
  static const fast = Duration(milliseconds: 180);
  static const normal = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 420);

  static const curve = Curves.easeOutCubic;
  static const spring = Curves.easeOutBack;

  static Duration duration(BuildContext context, Duration fallback) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Duration.zero;
    }
    return fallback;
  }

  static Curve curveFor(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context) ? Curves.linear : curve;
  }
}

/// Fade + slight upward slide when content appears.
class AppFadeIn extends StatefulWidget {
  const AppFadeIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.normal,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  State<AppFadeIn> createState() => _AppFadeInState();
}

class _AppFadeInState extends State<AppFadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _controller, curve: AppMotion.curve);
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: AppMotion.curve));

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

/// Staggered fade-in for list/grid children.
class AppStaggeredFadeIn extends StatelessWidget {
  const AppStaggeredFadeIn({
    super.key,
    required this.index,
    required this.child,
    this.baseDelay = const Duration(milliseconds: 40),
  });

  final int index;
  final Widget child;
  final Duration baseDelay;

  @override
  Widget build(BuildContext context) {
    return AppFadeIn(
      delay: baseDelay * index,
      duration: AppMotion.fast,
      child: child,
    );
  }
}

/// Minimum 48dp touch target with subtle scale feedback.
class AppScaleTap extends StatefulWidget {
  const AppScaleTap({
    super.key,
    required this.onTap,
    required this.child,
    this.semanticLabel,
  });

  final VoidCallback? onTap;
  final Widget child;
  final String? semanticLabel;

  @override
  State<AppScaleTap> createState() => _AppScaleTapState();
}

class _AppScaleTapState extends State<AppScaleTap> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final scale = !enabled || _pressed ? 1.0 : 1.0;
    final pressedScale =
        enabled && _pressed && !MediaQuery.disableAnimationsOf(context)
            ? 0.97
            : scale;

    return Semantics(
      button: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: pressedScale,
          duration: AppMotion.fast,
          curve: AppMotion.curve,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Shared horizontal page transition for pushed routes.
class AppSharedAxisRoute<T> extends PageRouteBuilder<T> {
  AppSharedAxisRoute({required Widget page, RouteSettings? settings})
    : super(
        settings: settings,
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          if (MediaQuery.disableAnimationsOf(context)) return child;

          final offsetAnimation = Tween<Offset>(
            begin: const Offset(0.06, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: AppMotion.curve));

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offsetAnimation, child: child),
          );
        },
        transitionDuration: AppMotion.normal,
        reverseTransitionDuration: AppMotion.fast,
      );
}
