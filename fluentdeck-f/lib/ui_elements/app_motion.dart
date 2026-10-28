import 'dart:math' as math;

import 'package:animations/animations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared motion tokens and lightweight animation widgets.
///
/// Timings and easing follow the Material 2 motion system
/// (m2.material.io/design/motion); the `animations` package provides its
/// transition patterns (shared axis, fade through, fade, container transform).
/// Plan and phases: docs/motion-and-material-plan.md.
abstract final class AppMotion {
  static const fast = Duration(milliseconds: 180);
  static const normal = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 420);

  /// Touch feedback (press in / out).
  static const press = Duration(milliseconds: 100);

  /// Material "enter" / "exit" durations for elements appearing/leaving.
  static const enter = Duration(milliseconds: 225);
  static const exit = Duration(milliseconds: 195);

  static const curve = Curves.easeOutCubic;
  static const spring = Curves.easeOutBack;

  /// Material standard easing, cubic(0.4, 0, 0.2, 1): moves between states.
  static const standardCurve = Curves.fastOutSlowIn;

  /// Material decelerate easing, cubic(0, 0, 0.2, 1): elements entering.
  static const decelerateCurve = Cubic(0.0, 0.0, 0.2, 1.0);

  /// Material accelerate easing, cubic(0.4, 0, 1, 1): elements leaving.
  static const accelerateCurve = Cubic(0.4, 0.0, 1.0, 1.0);

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
    this.animate = true,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Read once, when the widget first appears: false shows [child] at rest
  /// (e.g. an old chat message scrolled back into view) while keeping the same
  /// widget structure, so toggling it never remounts the child.
  final bool animate;

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
    // The delay is part of the animation (an Interval), not a Timer, so it is
    // cancelled with the widget and leaves nothing pending.
    final total = widget.delay + widget.duration;
    _controller = AnimationController(vsync: this, duration: total);
    final start = total.inMicroseconds == 0
        ? 0.0
        : widget.delay.inMicroseconds / total.inMicroseconds;
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: AppMotion.decelerateCurve),
    );
    _opacity = curved;
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(curved);
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1;
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

  /// Only the first screenful staggers in.
  static const maxStaggeredItems = 8;

  @override
  Widget build(BuildContext context) {
    // Items further down appear while scrolling — don't animate those.
    if (index >= maxStaggeredItems) return child;
    return AppFadeIn(
      delay: baseDelay * index,
      duration: AppMotion.fast,
      child: child,
    );
  }
}

/// Shrinks [child] slightly while a finger is down on it — tactile feedback
/// for any tappable surface. It only listens to pointers, so the child's own
/// InkWell / button still gets the tap and ripple. Moving the finger (e.g. a
/// list scroll that started on it) releases the press.
class AppPressScale extends StatefulWidget {
  const AppPressScale({
    super.key,
    required this.child,
    this.enabled = true,
    this.pressedScale = 0.97,
  });

  final Widget child;
  final bool enabled;
  final double pressedScale;

  @override
  State<AppPressScale> createState() => _AppPressScaleState();
}

class _AppPressScaleState extends State<AppPressScale> {
  bool _pressed = false;
  Offset? _downAt;

  void _setPressed(bool value) {
    if (_pressed != value && mounted) setState(() => _pressed = value);
  }

  @override
  void didUpdateWidget(AppPressScale oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) _pressed = false;
  }

  @override
  Widget build(BuildContext context) {
    // Same widget structure whether enabled or not: switching structure would
    // remount the child and lose its state (e.g. a button's loading switch).
    final active = widget.enabled && !MediaQuery.disableAnimationsOf(context);
    return Listener(
      onPointerDown: (event) {
        if (!active) return;
        _downAt = event.position;
        _setPressed(true);
      },
      onPointerMove: (event) {
        final start = _downAt;
        if (start != null && (event.position - start).distance > kTouchSlop) {
          _setPressed(false);
        }
      },
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: active && _pressed ? widget.pressedScale : 1,
        duration: active ? AppMotion.press : Duration.zero,
        curve: AppMotion.standardCurve,
        child: widget.child,
      ),
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
///
/// [transitionType]: horizontal (X) for sideways steps (the default for pushed
/// pages); scaled (Z) for a page "above" the current one — settings, search.
class AppSharedAxisRoute<T> extends PageRouteBuilder<T> {
  AppSharedAxisRoute({
    required Widget page,
    super.settings,
    SharedAxisTransitionType transitionType = SharedAxisTransitionType.horizontal,
  }) : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          if (MediaQuery.disableAnimationsOf(context)) return child;

          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: transitionType,
            fillColor: Colors.transparent,
            child: child,
          );
        },
        transitionDuration: AppMotion.normal,
        reverseTransitionDuration: AppMotion.fast,
      );
}

/// Material container transform for a FAB: the button grows into the page it
/// opens, and shrinks back into the button on close (codelab: Reply's compose
/// FAB). [fab] is the button's look; its own onPressed is ignored — tapping
/// opens the container. [onClosed] receives the page's pop result.
/// With reduced motion it falls back to a plain push.
class AppFabContainer<T> extends StatelessWidget {
  const AppFabContainer({
    super.key,
    required this.fab,
    required this.openBuilder,
    this.onClosed,
    this.extended = false,
  });

  final Widget fab;
  final WidgetBuilder openBuilder;
  final ValueChanged<T?>? onClosed;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shape = extended
        ? const StadiumBorder()
        : const CircleBorder() as ShapeBorder;
    if (MediaQuery.disableAnimationsOf(context)) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          final result = await Navigator.of(context).push<T>(
            MaterialPageRoute(builder: openBuilder),
          );
          onClosed?.call(result);
        },
        child: AbsorbPointer(child: fab),
      );
    }
    return OpenContainer<T>(
      transitionDuration: AppMotion.slow,
      openColor: theme.scaffoldBackgroundColor,
      closedColor: Colors.transparent,
      closedElevation: 0,
      openElevation: 0,
      closedShape: shape,
      onClosed: onClosed,
      openBuilder: (context, _) => openBuilder(context),
      closedBuilder: (context, open) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: open,
        // The FAB keeps its look and ripple, but the tap opens the container.
        child: AbsorbPointer(child: fab),
      ),
    );
  }
}

/// Material "fade through" when [child] swaps for a different one — icons,
/// labels, app-bar actions (codelab: Reply's FAB icon and app-bar actions).
/// Give each state's child a distinct key so the swap animates.
class AppFadeThroughSwitcher extends StatelessWidget {
  const AppFadeThroughSwitcher({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PageTransitionSwitcher(
      duration: AppMotion.duration(context, AppMotion.normal),
      transitionBuilder: (child, animation, secondaryAnimation) =>
          FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            fillColor: Colors.transparent,
            child: child,
          ),
      child: child,
    );
  }
}

/// Soft, repeating "breathing" ring behind [child] while [active] — e.g. the
/// mic while recording. Static with reduced motion. Isolated in a
/// RepaintBoundary so the loop doesn't repaint the screen around it.
class AppPulse extends StatefulWidget {
  const AppPulse({
    super.key,
    required this.active,
    required this.color,
    required this.child,
  });

  final bool active;
  final Color color;
  final Widget child;

  @override
  State<AppPulse> createState() => _AppPulseState();
}

class _AppPulseState extends State<AppPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  bool _shouldRun(BuildContext context) =>
      widget.active && !MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(AppPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (_shouldRun(context)) {
      if (!_controller.isAnimating) _controller.repeat();
    } else if (_controller.isAnimating || _controller.value != 0) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = Curves.easeOut.transform(_controller.value);
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (_controller.isAnimating)
                Positioned.fill(
                  child: Transform.scale(
                    scale: 1 + 0.45 * t,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.color.withValues(alpha: 0.35 * (1 - t)),
                      ),
                    ),
                  ),
                ),
              child!,
            ],
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Text that counts up to its number when it first appears and eases between
/// numbers when it changes ("12", "12 days", "1,240 XP"). Text that doesn't
/// start with a whole number is shown as is.
class AppCountUpText extends StatelessWidget {
  const AppCountUpText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  static final _leadingNumber = RegExp(r'^(\d{1,3}(?:,\d{3})*|\d+)(.*)$', dotAll: true);

  static String _format(int n, {required bool grouped}) {
    if (!grouped) return '$n';
    final digits = '$n';
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
      out.write(digits[i]);
    }
    return out.toString();
  }

  @override
  Widget build(BuildContext context) {
    final match = _leadingNumber.firstMatch(text);
    final number = match == null
        ? null
        : int.tryParse(match.group(1)!.replaceAll(',', ''));
    if (match == null || number == null) {
      return Text(text, style: style, maxLines: maxLines, overflow: overflow);
    }
    final grouped = match.group(1)!.contains(',');
    final suffix = match.group(2)!;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: number.toDouble()),
      duration: AppMotion.duration(context, AppMotion.slow * 2),
      curve: AppMotion.decelerateCurve,
      builder: (context, value, _) => Text(
        '${_format(value.round(), grouped: grouped)}$suffix',
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}

/// One-shot confetti burst behind [child] — celebrations (session complete,
/// goals, streaks). Plays once when it appears; nothing with reduced motion.
/// Painted on its own layer; ignores touches.
class AppConfettiBurst extends StatefulWidget {
  const AppConfettiBurst({
    super.key,
    required this.colors,
    required this.child,
    this.particleCount = 28,
    this.haptic = true,
  });

  final List<Color> colors;
  final Widget child;
  final int particleCount;

  /// A light "thud" with the burst (skipped with reduced motion, like the burst).
  final bool haptic;

  @override
  State<AppConfettiBurst> createState() => _AppConfettiBurstState();
}

class _AppConfettiBurstState extends State<AppConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  late final List<_ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    _particles = List.generate(widget.particleCount, (i) {
      // Spread upward and out, like a small burst from the centre.
      final angle = -math.pi / 2 + (random.nextDouble() - 0.5) * math.pi * 1.1;
      return _ConfettiParticle(
        angle: angle,
        speed: 90 + random.nextDouble() * 110,
        spin: (random.nextDouble() - 0.5) * 10,
        size: 5 + random.nextDouble() * 4,
        color: widget.colors[i % widget.colors.length],
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!MediaQuery.disableAnimationsOf(context) && _controller.value == 0) {
      _controller.forward();
      if (widget.haptic) HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _ConfettiPainter(_controller, _particles),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _ConfettiParticle {
  const _ConfettiParticle({
    required this.angle,
    required this.speed,
    required this.spin,
    required this.size,
    required this.color,
  });

  final double angle;
  final double speed;
  final double spin;
  final double size;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.animation, this.particles) : super(repaint: animation);

  final Animation<double> animation;
  final List<_ConfettiParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    if (t == 0 || t == 1) return;
    final center = size.center(Offset.zero);
    final paint = Paint();
    final fade = (1 - t).clamp(0.0, 1.0);
    for (final p in particles) {
      final distance = p.speed * Curves.easeOut.transform(t);
      final gravity = 140 * t * t;
      final pos = center +
          Offset(math.cos(p.angle) * distance, math.sin(p.angle) * distance + gravity);
      paint.color = p.color.withValues(alpha: fade);
      canvas
        ..save()
        ..translate(pos.dx, pos.dy)
        ..rotate(p.spin * t)
        ..drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          paint,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => false;
}

/// Cross-fades a screen's loading skeleton into its content. Return it from
/// *both* branches of `if (_loading) … else …` so the same element animates
/// between them:
///   if (_loading) return AppLoadingSwitcher(loading: true, child: skeleton);
///   return AppLoadingSwitcher(loading: false, child: content);
class AppLoadingSwitcher extends StatelessWidget {
  const AppLoadingSwitcher({
    super.key,
    required this.loading,
    required this.child,
  });

  final bool loading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.duration(context, AppMotion.normal),
      switchInCurve: AppMotion.decelerateCurve,
      switchOutCurve: AppMotion.accelerateCurve,
      // Top-aligned, so a short skeleton and tall content don't jump about;
      // passthrough keeps the parent's constraints, so layouts don't change.
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        fit: StackFit.passthrough,
        children: [...previous, ?current],
      ),
      child: KeyedSubtree(key: ValueKey(loading), child: child),
    );
  }
}

/// Three dots bouncing in turn — "the tutor is thinking". Static dots with
/// reduced motion.
class AppTypingDots extends StatefulWidget {
  const AppTypingDots({super.key, required this.color, this.dotSize = 7});

  final Color color;
  final double dotSize;

  @override
  State<AppTypingDots> createState() => _AppTypingDotsState();
}

class _AppTypingDotsState extends State<AppTypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: widget.dotSize * 0.25),
                child: Transform.translate(
                  offset: Offset(0, -widget.dotSize * 0.6 * _bounce(i)),
                  child: Container(
                    width: widget.dotSize,
                    height: widget.dotSize,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.45 + 0.55 * _bounce(i)),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 0→1→0 hump for dot [i], each dot a third of a cycle behind the last.
  double _bounce(int i) {
    final t = (_controller.value - i / 6) % 1.0;
    if (t > 0.5) return 0;
    return Curves.easeInOut.transform(1 - (t * 4 - 1).abs());
  }
}

/// How [AppChartReveal] brings a chart in.
enum AppChartRevealStyle {
  /// Wipes up from the baseline — bars grow.
  up,

  /// Wipes left to right — a line draws across.
  right,

  /// Grows from 85% and fades in — pies and rings.
  grow,
}

/// Reveals a chart once, when it first appears. Clips instead of resizing, so
/// the layout never moves. Shown at once with reduced motion.
class AppChartReveal extends StatelessWidget {
  const AppChartReveal({
    super.key,
    required this.style,
    required this.child,
  });

  final AppChartRevealStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.duration(context, const Duration(milliseconds: 700)),
      curve: AppMotion.decelerateCurve,
      child: child,
      builder: (context, t, child) {
        if (t >= 1) return child!;
        return switch (style) {
          AppChartRevealStyle.grow => Opacity(
            opacity: t,
            child: Transform.scale(scale: 0.85 + 0.15 * t, child: child),
          ),
          _ => ClipRect(
            clipper: _RevealClipper(t, style),
            child: child,
          ),
        };
      },
    );
  }
}

class _RevealClipper extends CustomClipper<Rect> {
  const _RevealClipper(this.t, this.style);

  final double t;
  final AppChartRevealStyle style;

  @override
  Rect getClip(Size size) => style == AppChartRevealStyle.up
      ? Rect.fromLTRB(0, size.height * (1 - t), size.width, size.height)
      : Rect.fromLTRB(0, 0, size.width * t, size.height);

  @override
  bool shouldReclip(_RevealClipper oldClipper) =>
      oldClipper.t != t || oldClipper.style != style;
}
