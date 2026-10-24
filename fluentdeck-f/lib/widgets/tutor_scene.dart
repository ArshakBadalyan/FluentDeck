import 'package:flutter/material.dart';

/// The English tutor otter's "In Action" scenes (assets/tutor/), from the
/// character sheet. Used as card art via [SceneBackdrop].
enum TutorScene {
  teaching,
  reading,
  online,
  encouraging,
  listening,
  exploring;

  String get asset => 'assets/tutor/scene-$name.webp';
}

/// Puts a [TutorScene] on one side of a card, with the card's own colour
/// fading over the picture's inner edge (so text on the other side stays
/// readable). Put it directly inside the card's clipped decoration, with the
/// card's padding inside [child].
class SceneBackdrop extends StatelessWidget {
  const SceneBackdrop({
    super.key,
    required this.scene,
    required this.color,
    required this.child,
    this.onLeft = false,
    this.widthFactor = 0.55,
  });

  final TutorScene scene;

  /// The card colour on the picture's side (what the fade blends into).
  final Color color;
  final Widget child;
  final bool onLeft;

  /// How much of the card's width the picture covers.
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    final start =
        1 - widthFactor; // where the picture begins, from the text side
    return Stack(
      children: [
        Positioned.fill(
          child: Align(
            alignment: onLeft ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: widthFactor,
              heightFactor: 1,
              child: Image.asset(
                scene.asset,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: onLeft ? Alignment.centerRight : Alignment.centerLeft,
                  end: onLeft ? Alignment.centerLeft : Alignment.centerRight,
                  colors: [
                    color,
                    color,
                    color.withValues(alpha: 0.55),
                    color.withValues(alpha: 0),
                  ],
                  stops: [
                    0,
                    start - 0.02,
                    start + 0.18,
                    (start + 0.42).clamp(0.0, 1.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
