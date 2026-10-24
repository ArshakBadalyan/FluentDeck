import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/ui_elements/app_motion.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';

/// What Rio is doing on the conversation screen.
enum RioMood { idle, speaking, listening, thinking, cheering }

/// Rio the otter above the chat: breathes when idle, moves its mouth while the
/// tutor speaks, listens while the learner records, hops when it starts
/// talking or cheers. Still (no animation) with reduce-motion on.
class RioStage extends StatefulWidget {
  const RioStage({super.key, required this.mood, this.onTap});

  final RioMood mood;

  /// Tapping Rio (e.g. replay the last tutor reply).
  final VoidCallback? onTap;

  @override
  State<RioStage> createState() => _RioStageState();
}

class _RioStageState extends State<RioStage> with TickerProviderStateMixin {
  static const _happy = 'assets/rio/rio-happy.webp';
  static const _talkMid = 'assets/rio/rio-talk-mid.webp';
  static const _talk = 'assets/rio/rio-talk.webp';
  static const _curious = 'assets/rio/rio-curious.webp';
  static const _excited = 'assets/rio/rio-excited.webp';
  // Mouth shapes in a loose, speech-like order (closed / half / open).
  static const _mouth = [
    _talkMid,
    _talk,
    _talkMid,
    _happy,
    _talk,
    _talkMid,
    _talk,
    _talkMid,
    _happy,
  ];

  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  late final AnimationController _hop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  final _random = math.Random();
  Timer? _mouthTimer;
  int _mouthStep = 0;
  String _frame = _happy;
  bool _still = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final f in [_happy, _talkMid, _talk, _curious, _excited]) {
      precacheImage(AssetImage(f), context);
    }
    final still = MediaQuery.disableAnimationsOf(context);
    if (still) {
      _breath.stop();
    } else if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
    // Also runs when e.g. the keyboard opens; only re-apply when it matters.
    if (!_started || still != _still) {
      _started = true;
      _still = still;
      _applyMood(hop: false);
    }
  }

  @override
  void didUpdateWidget(RioStage old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood) {
      _applyMood(
        hop: widget.mood == RioMood.speaking || widget.mood == RioMood.cheering,
      );
    }
  }

  void _applyMood({required bool hop}) {
    _mouthTimer?.cancel();
    _mouthTimer = null;
    if (widget.mood == RioMood.speaking && !_still) {
      // First shape now (a rebuild follows anyway), the rest on the timer.
      _frame = _mouth[0];
      _mouthStep = 1;
      _mouthTimer = Timer(const Duration(milliseconds: 110), _nextMouth);
    } else {
      _frame = switch (widget.mood) {
        RioMood.listening || RioMood.thinking => _curious,
        RioMood.cheering => _excited,
        RioMood.speaking => _talkMid, // reduce motion: one "talking" frame
        RioMood.idle => _happy,
      };
    }
    if (hop && !_still) _hop.forward(from: 0);
  }

  void _nextMouth() {
    if (!mounted) return;
    setState(() => _frame = _mouth[_mouthStep % _mouth.length]);
    _mouthStep += 1;
    _mouthTimer = Timer(
      Duration(milliseconds: 80 + _random.nextInt(70)),
      _nextMouth,
    );
  }

  void _onTap() {
    if (!_still) _hop.forward(from: 0);
    widget.onTap?.call();
  }

  @override
  void dispose() {
    _mouthTimer?.cancel();
    _breath.dispose();
    _hop.dispose();
    super.dispose();
  }

  String get _line => switch (widget.mood) {
    RioMood.idle => 'Hi, I\'m Rio! Tap the mic and say hello 👋',
    RioMood.speaking => 'Rio is speaking…',
    RioMood.listening => 'I\'m listening…',
    RioMood.thinking => 'Hmm, let me think…',
    RioMood.cheering => 'You did it! 🎉',
  };

  @override
  Widget build(BuildContext context) {
    final accent = AppPageColors.accentOf(context);
    return Semantics(
      label: 'Rio the otter. $_line',
      button: widget.onTap != null,
      child: Container(
        height: 118,
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.brandPrimary.withValues(alpha: 0.04),
              AppColors.brandPrimary.withValues(alpha: 0.14),
            ],
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _onTap,
              child: AnimatedBuilder(
                animation: Listenable.merge([_breath, _hop]),
                builder: (context, child) {
                  final b = Curves.easeInOut.transform(_breath.value);
                  final hopY = -12 * math.sin(math.pi * _hop.value);
                  return Transform.translate(
                    offset: Offset(0, hopY),
                    child: Transform(
                      alignment: Alignment.bottomCenter,
                      transform: Matrix4.diagonal3Values(
                        1 + 0.02 * b,
                        1 - 0.015 * b,
                        1,
                      ),
                      child: child,
                    ),
                  );
                },
                child: SizedBox(
                  width: 92,
                  height: 112,
                  child: Image.asset(
                    _frame,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    gaplessPlayback:
                        true, // no blank flash between mouth frames
                    excludeFromSemantics: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedSwitcher(
                  duration: AppMotion.duration(context, AppMotion.fast),
                  child: Container(
                    key: ValueKey(widget.mood),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: AppPageColors.cardBgOf(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: accent.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      _line,
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppPageColors.textPrimaryOf(context),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
