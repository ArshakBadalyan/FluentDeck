import 'package:flutter/material.dart';

/// The otter's "In Action" scenes (assets/tutor/), from the character sheets
/// (English tutor and adventurer). Used as card art via [SceneBackdrop].
enum TutorScene {
  teaching,
  reading,
  online,
  encouraging,
  listening,
  exploring,
  hiking,
  cave;

  String get asset => 'assets/tutor/scene-$name.webp';
}

/// Puts a [TutorScene] on one side of a card, with the card's own colour
/// fading over the picture's inner edge (so text on the other side stays
/// readable). Put it directly inside the card's clipped decoration, with the
/// card's padding inside [child].
///
/// The picture is capped at [maxImageWidth]: the scenes are small, and on a
/// wide (web) card they would otherwise be stretched and look blurry.
class SceneBackdrop extends StatelessWidget {
  const SceneBackdrop({
    super.key,
    required this.scene,
    required this.color,
    required this.child,
    this.onLeft = false,
    this.widthFactor = 0.55,
    this.maxImageWidth = 300,
  });

  final TutorScene scene;

  /// The card colour on the picture's side (what the fade blends into).
  final Color color;
  final Widget child;
  final bool onLeft;

  /// How much of the card's width the picture covers (up to [maxImageWidth]).
  final double widthFactor;
  final double maxImageWidth;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, c) {
              final imageWidth = (c.maxWidth * widthFactor).clamp(
                0.0,
                maxImageWidth,
              );
              // Fade only the picture's inner edge (first 30% of it).
              final fade = imageWidth * 0.3;
              return Stack(
                children: [
                  Positioned(
                    top: 0,
                    bottom: 0,
                    width: imageWidth,
                    left: onLeft ? 0 : null,
                    right: onLeft ? null : 0,
                    child: Image.asset(
                      scene.asset,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      excludeFromSemantics: true,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    bottom: 0,
                    width: fade,
                    left: onLeft ? imageWidth - fade : null,
                    right: onLeft ? null : imageWidth - fade,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: onLeft
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            end: onLeft
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            colors: [color, color.withValues(alpha: 0)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        child,
      ],
    );
  }
}
