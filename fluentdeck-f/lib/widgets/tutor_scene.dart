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
  cave,
  fishing;

  String get asset => 'assets/tutor/scene-$name.webp';

  /// Where Rio's face is in the picture. Cards show only a narrow slice of
  /// these wide scenes, so the crop centres on him instead of the middle
  /// (which, in some scenes, is his backpack).
  Alignment get focus {
    switch (this) {
      case TutorScene.hiking:
        return const Alignment(0.75, 0);
      case TutorScene.teaching:
        return const Alignment(-0.6, 0);
      case TutorScene.cave:
        // Rio stands at the right of the cave mouth with his lantern.
        return const Alignment(0.62, 0);
      case TutorScene.encouraging:
        return const Alignment(-0.2, 0);
      case TutorScene.reading:
      case TutorScene.online:
        return const Alignment(0.05, 0);
      case TutorScene.fishing:
      case TutorScene.listening:
      case TutorScene.exploring:
        return Alignment.center;
    }
  }
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

  /// Kept for callers; the picture now fades to transparent, so the card's
  /// own background shows through.
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
              // Whole pixels: fractional edges left a hairline seam on the web.
              final imageWidth = (c.maxWidth * widthFactor)
                  .clamp(0.0, maxImageWidth)
                  .roundToDouble();
              // Fade only the picture's inner edge (first 30% of it).
              final fade = (imageWidth * 0.3).roundToDouble();
              return Stack(
                children: [
                  Positioned(
                    top: 0,
                    bottom: 0,
                    width: imageWidth,
                    left: onLeft ? 0 : null,
                    right: onLeft ? null : 0,
                    // The picture itself fades out at its inner edge, so the card's own
                    // background (even a gradient) shows through: no colour seam.
                    child: ShaderMask(
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (rect) => LinearGradient(
                        begin: onLeft ? Alignment.centerRight : Alignment.centerLeft,
                        end: onLeft ? Alignment.centerLeft : Alignment.centerRight,
                        colors: const [Color(0x00000000), Color(0xFF000000)],
                        stops: [0, fade / imageWidth],
                      ).createShader(rect),
                      child: Image.asset(
                        scene.asset,
                        fit: BoxFit.cover,
                        alignment: scene.focus,
                        filterQuality: FilterQuality.medium,
                        excludeFromSemantics: true,
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
