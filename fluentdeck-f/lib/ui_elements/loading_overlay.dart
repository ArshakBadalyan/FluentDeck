import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';

/// Centered loading animation for cold start. Use with a [Scaffold] whose
/// [Scaffold.backgroundColor] is solid so the screen does not show the
/// default window color around the indicator.
class LaunchLoadingIndicator extends StatelessWidget {
  const LaunchLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) => const FluentDeckLoader();
}

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(
            color: AppPageColors.pageBgOf(context).withValues(alpha: 0.9),
          ),
        ),
        const Center(child: FluentDeckLoader()),
      ],
    );
  }
}

/// Animated FluentDeck mark: card stack with the sound bars pulsing like a voice.
class FluentDeckLoader extends StatefulWidget {
  const FluentDeckLoader({super.key, this.size = 90});

  final double size;

  @override
  State<FluentDeckLoader> createState() => _FluentDeckLoaderState();
}

class _FluentDeckLoaderState extends State<FluentDeckLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0.25;
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
    return Semantics(
      label: 'Loading',
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _MarkPainter(_controller.value),
          ),
        ),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.t);

  /// Animation phase 0..1.
  final double t;

  static const _barHeights = [0.30, 0.56, 0.40];

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final cw = s * 0.50, ch = s * 0.62;
    final radius = Radius.circular(s * 0.075);
    final bob = math.sin(t * 2 * math.pi) * s * 0.012;

    // Back card (reward yellow).
    canvas.save();
    canvas.translate(s / 2 - s * 0.07, s / 2 - s * 0.035);
    canvas.rotate(-12 * math.pi / 180);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: cw, height: ch),
        radius,
      ),
      Paint()..color = AppColors.primaryYellow,
    );
    canvas.restore();

    // Front card with speech tail.
    canvas.save();
    canvas.translate(s / 2 + s * 0.05, s / 2 + s * 0.03 + bob);
    canvas.rotate(6 * math.pi / 180);
    final card = Rect.fromCenter(center: Offset.zero, width: cw, height: ch);
    final tailX = card.left + cw * 0.18;
    final front = Path()
      ..addRRect(RRect.fromRectAndRadius(card, radius))
      ..addPolygon([
        Offset(tailX, card.bottom - radius.y),
        Offset(tailX + cw * 0.24, card.bottom - 1),
        Offset(tailX - cw * 0.06, card.bottom + ch * 0.2),
      ], true);
    canvas.drawShadow(front, Colors.black, s * 0.03, false);
    canvas.drawPath(front, Paint()..color = Colors.white);

    // Sound bars, staggered like speech.
    final bw = cw * 0.13, gap = cw * 0.09;
    var x = -(3 * bw + 2 * gap) / 2;
    final barPaint = Paint()..color = AppColors.brandPrimary;
    for (var i = 0; i < 3; i++) {
      final phase = math.sin((t + i * 0.22) * 2 * math.pi);
      final h = ch * _barHeights[i] * (0.75 + 0.25 * phase);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, -h / 2, bw, h),
          Radius.circular(bw / 2),
        ),
        barPaint,
      );
      x += bw + gap;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => oldDelegate.t != t;
}
