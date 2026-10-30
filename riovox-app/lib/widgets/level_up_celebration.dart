import 'package:flutter/material.dart';
import 'package:riovox/app_colors.dart';
import 'package:riovox/ui_elements/app_dialog.dart';
import 'package:riovox/ui_elements/app_motion.dart';
import 'package:riovox/widgets/rio.dart';
import 'package:riovox/ui_elements/modern_page_widgets.dart';

/// Full-screen "Level up!": Rio swims in, the new level stamps down as a
/// badge with confetti, then "Keep going".
Future<void> showLevelUpCelebration(BuildContext context, String level) {
  return showAppDialog<void>(
    context: context,
    // The screen paints its own app background; nothing shows through.
    barrierColor: Colors.transparent,
    builder: (_) => _LevelUpView(level: level),
  );
}

class _LevelUpView extends StatefulWidget {
  const _LevelUpView({required this.level});

  final String level;

  @override
  State<_LevelUpView> createState() => _LevelUpViewState();
}

class _LevelUpViewState extends State<_LevelUpView> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else if (_c.value == 0) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 0–0.35 Rio swims up · 0.35–0.65 the badge stamps · 0.6–1 text and button.
    final rio = CurvedAnimation(parent: _c, curve: const Interval(0, 0.4, curve: Curves.easeOutBack));
    final stamp = CurvedAnimation(parent: _c, curve: const Interval(0.35, 0.65, curve: Curves.easeInCubic));
    final text = CurvedAnimation(parent: _c, curve: const Interval(0.6, 1, curve: Curves.easeOut));
    final bg = AppPageColors.pageBgOf(context);
    return Material(
      color: bg,
      child: DecoratedBox(
        // App page background with a soft gold glow behind the badge.
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.1),
            radius: 0.8,
            colors: [AppColors.primaryYellow.withValues(alpha: 0.22), bg],
          ),
        ),
        child: SafeArea(child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.translate(
                  offset: Offset(0, 60 * (1 - rio.value)),
                  child: Opacity(
                    opacity: rio.value.clamp(0.0, 1.0),
                    child: const RioImage(RioPose.cheer, height: 170, motion: RioMotion.float),
                  ),
                ),
                const SizedBox(height: 8),
                // Drops from big and tilted to its place, like a stamp.
                Opacity(
                  opacity: stamp.value == 0 ? 0 : 1,
                  child: Transform.rotate(
                    angle: -0.5 * (1 - stamp.value),
                    child: Transform.scale(
                      scale: 2.6 - 1.6 * stamp.value,
                      child: _badge(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Opacity(
                  opacity: text.value,
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - text.value)),
                    child: Column(
                      children: [
                        Text(
                          'Level up!',
                          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppPageColors.textPrimaryOf(context)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'You reached ${widget.level}. Rio is proud of you.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: AppPageColors.subtitleOf(context)),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryYellow,
                            foregroundColor: const Color(0xFF3D2A00),
                            minimumSize: const Size(200, 52),
                            shape: const StadiumBorder(),
                            textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                          ),
                          child: const Text('Keep going'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ))),
    );
  }

  Widget _badge() {
    final badge = Container(
      width: 112,
      height: 112,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryYellow,
        border: Border.all(color: AppPageColors.cardBgOf(context), width: 5),
        boxShadow: [
          BoxShadow(color: AppColors.primaryYellow.withValues(alpha: 0.6), blurRadius: 30, spreadRadius: 4),
        ],
      ),
      child: Text(
        widget.level,
        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFF3D2A00)),
      ),
    );
    // Confetti bursts as the stamp lands.
    return _c.value >= 0.65
        ? AppConfettiBurst(
            colors: const [AppColors.primaryYellow, AppColors.greenCorrect, AppColors.voice, Colors.white],
            child: badge,
          )
        : badge;
  }
}
