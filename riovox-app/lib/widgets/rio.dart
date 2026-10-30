import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:riovox/app_colors.dart';
import 'package:riovox/ui_elements/modern_page_widgets.dart';

/// Rio the otter's poses (assets/rio/). The talking frames live in rio_stage.dart.
enum RioPose {
  happy('rio-happy'),
  excited('rio-excited'),
  curious('rio-curious'),
  explore('rio-explore'),
  swim('rio-swim'),
  catchFish('rio-catch'),
  sleepy('rio-sleepy'),
  surprised('rio-surprised'),
  determined('rio-determined'),

  /// Fist pump with an orange burst (from the KEEP GOING clip): level up.
  cheer('rio-cheer'),

  /// Waving with a gold star (score sheet, GOOD row): a 5–7 score.
  star('rio-star'),

  /// Full body, facing you, paw up: onboarding's welcome.
  wave('rio-wave');

  const RioPose(this.file);
  final String file;
  String get asset => 'assets/rio/$file.webp';
}

/// How a [RioImage] moves.
enum RioMotion {
  none,

  /// Springs in once (a celebration, a new card).
  pop,

  /// Floats gently up and down, forever.
  float,

  /// Rocks side to side, forever (sleepy, waiting).
  sway,
}

/// One Rio pose, optionally animated. Still with reduce motion.
class RioImage extends StatefulWidget {
  const RioImage(
    this.pose, {
    super.key,
    this.height = 120,
    this.motion = RioMotion.float,
    this.semanticLabel,
  }) : asset = null;

  /// Any cut-out character image (e.g. Professor Rio) with Rio's motions.
  const RioImage.asset(
    String this.asset, {
    super.key,
    this.height = 120,
    this.motion = RioMotion.float,
    this.semanticLabel,
  }) : pose = RioPose.happy;

  final RioPose pose;

  /// Overrides [pose] when set.
  final String? asset;
  final double height;
  final RioMotion motion;
  final String? semanticLabel;

  @override
  State<RioImage> createState() => _RioImageState();
}

class _RioImageState extends State<RioImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _start();
  }

  @override
  void didUpdateWidget(RioImage old) {
    super.didUpdateWidget(old);
    if (old.motion != widget.motion || old.pose != widget.pose || old.asset != widget.asset) {
      _start();
    }
  }

  void _start() {
    _c.stop();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
      return;
    }
    switch (widget.motion) {
      case RioMotion.none:
        _c.value = 1;
      case RioMotion.pop:
        _c.duration = const Duration(milliseconds: 520);
        _c.forward(from: 0);
      case RioMotion.float:
        _c.duration = const Duration(milliseconds: 2600);
        _c.repeat(reverse: true);
      case RioMotion.sway:
        _c.duration = const Duration(milliseconds: 3000);
        _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      widget.asset ?? widget.pose.asset,
      height: widget.height,
      fit: BoxFit.contain,
      semanticLabel: widget.semanticLabel,
      excludeFromSemantics: widget.semanticLabel == null,
    );
    if (widget.motion == RioMotion.none) return image;
    return AnimatedBuilder(
      animation: _c,
      child: image,
      builder: (context, child) {
        final t = _c.value;
        switch (widget.motion) {
          case RioMotion.pop:
            final s = Curves.easeOutBack.transform(t);
            return Opacity(
              opacity: t.clamp(0, 1),
              child: Transform.scale(
                scale: 0.5 + 0.5 * s,
                alignment: Alignment.bottomCenter,
                child: child,
              ),
            );
          case RioMotion.float:
            final y = -6 * Curves.easeInOut.transform(t);
            return Transform.translate(offset: Offset(0, y), child: child);
          case RioMotion.sway:
            final a = (Curves.easeInOut.transform(t) - 0.5) * 0.08;
            return Transform.rotate(
              angle: a,
              alignment: Alignment.bottomCenter,
              child: child,
            );
          case RioMotion.none:
            return child!;
        }
      },
    );
  }
}

/// Rio swimming over a moving wave: a friendly "please wait".
class RioLoader extends StatefulWidget {
  const RioLoader({super.key, this.label, this.width = 160});

  final String? label;
  final double width;

  @override
  State<RioLoader> createState() => _RioLoaderState();
}

class _RioLoaderState extends State<RioLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    final water = Theme.of(context).brightness == Brightness.dark
        ? AppColors.brandPrimaryOnDark
        : AppColors.brandPrimary;
    return Semantics(
      label: widget.label ?? 'Loading',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: w,
            height: w * 0.62,
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final phase = _c.value * 2 * math.pi;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Rio bobs a little, in time with the waves.
                    Positioned(
                      left: w * 0.12,
                      right: w * 0.12,
                      bottom: w * 0.14 + 3 * math.sin(phase),
                      child: Image.asset(
                        RioPose.swim.asset,
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: w * 0.24,
                      child: CustomPaint(
                        painter: _WavePainter(phase: phase, color: water),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (widget.label != null) ...[
            const SizedBox(height: 10),
            Text(
              widget.label!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppPageColors.subtitleOf(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({required this.phase, required this.color});

  final double phase;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 4) {
      final y =
          size.height * 0.28 +
          4 * math.sin(x / size.width * 4 * math.pi + phase);
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.width, size.height)
      ..close();
    final rect = Offset.zero & size;
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.85), color.withValues(alpha: 0)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.phase != phase || old.color != color;
}
