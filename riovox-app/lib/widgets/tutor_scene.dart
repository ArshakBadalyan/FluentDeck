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
  fishing,

  /// Professor Rio reading on a rock by a lake (Otter Professor sheet).
  mentor,

  /// Professor Rio hiking in the mountains with his backpack (Otter
  /// Professor sheet, "Exploring").
  explorer;

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
      case TutorScene.mentor:
        return const Alignment(0.15, 0);
      case TutorScene.explorer:
        return const Alignment(0, -0.2);
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
    this.fit = BoxFit.cover,
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

  /// [BoxFit.cover] crops wide scenes to the card; [BoxFit.fitHeight] shows a
  /// tall scene whole, at the card's height.
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, c) {
              final width = c.maxWidth;
              final imageWidth = (width * widthFactor).clamp(0.0, maxImageWidth).roundToDouble();
              // Fade over the first 30% of the picture, from its inner edge.
              final fade = (imageWidth * 0.3).roundToDouble();
              if (width <= 0 || imageWidth <= 0) return const SizedBox.shrink();
              // The mask spans the whole card, not just the picture: the
              // picture's own edge sits where the mask is fully transparent,
              // so the web renderer can't leave a hairline seam there.
              final edge = (width - imageWidth) / width;
              final opaque = (width - imageWidth + fade) / width;
              return ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (rect) => LinearGradient(
                  begin: onLeft ? Alignment.centerRight : Alignment.centerLeft,
                  end: onLeft ? Alignment.centerLeft : Alignment.centerRight,
                  colors: const [Color(0x00000000), Color(0x00000000), Color(0xFF000000)],
                  stops: [0, edge + 2 / width, opaque.clamp(0.0, 1.0)],
                ).createShader(rect),
                child: Align(
                  alignment: onLeft ? Alignment.centerLeft : Alignment.centerRight,
                  child: SizedBox(
                    width: imageWidth,
                    height: c.maxHeight,
                    child: Image.asset(
                      scene.asset,
                      fit: fit,
                      alignment: fit == BoxFit.cover
                          ? scene.focus
                          : (onLeft ? Alignment.centerLeft : Alignment.centerRight),
                      filterQuality: FilterQuality.medium,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        child,
      ],
    );
  }
}
