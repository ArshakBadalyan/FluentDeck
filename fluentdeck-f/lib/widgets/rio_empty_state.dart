import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:riovox/ui_elements/modern_page_widgets.dart';
import 'package:riovox/widgets/rio.dart';

/// Sleepy Rio rocking gently with "z"s drifting up: nothing to do here yet.
/// Still (no z's) when the system asks for reduced motion.
class RioSleeping extends StatefulWidget {
  const RioSleeping({super.key, this.height = 110});

  final double height;

  @override
  State<RioSleeping> createState() => _RioSleepingState();
}

class _RioSleepingState extends State<RioSleeping> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
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
    final still = MediaQuery.disableAnimationsOf(context);
    final color = AppPageColors.accentOf(context);
    final h = widget.height;
    return SizedBox(
      width: h * 1.25,
      height: h * 1.15,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          RioImage(RioPose.sleepy, height: h, motion: RioMotion.sway),
          if (!still)
            for (var i = 0; i < 3; i++)
              AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  // Three z's, a third of a loop apart, rise and fade out.
                  final t = (_c.value + i / 3) % 1.0;
                  final opacity = t < 0.2 ? t / 0.2 : (1 - t) / 0.8;
                  return Positioned(
                    right: h * 0.05 - t * h * 0.12 + math.sin(t * math.pi * 2) * 4,
                    bottom: h * 0.7 + t * h * 0.45,
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0) * 0.8,
                      child: Text(
                        'z',
                        style: TextStyle(
                          fontSize: 14 + t * 10,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                  );
                },
              ),
        ],
      ),
    );
  }
}

/// An empty screen with Rio instead of plain text: sleepy when there's
/// nothing to do, curious (floating) when there's nothing yet to find.
class RioEmptyState extends StatelessWidget {
  const RioEmptyState({
    super.key,
    required this.title,
    this.message,
    this.sleepy = true,
    this.action,
    this.height = 110,
  });

  final String title;
  final String? message;
  final bool sleepy;
  final Widget? action;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            sleepy
                ? RioSleeping(height: height)
                : RioImage(RioPose.curious, height: height, motion: RioMotion.float),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppPageColors.textPrimaryOf(context),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppPageColors.subtitleOf(context), height: 1.4),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
