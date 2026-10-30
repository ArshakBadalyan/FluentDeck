import 'package:flutter/material.dart';
import 'package:riovox/widgets/rio.dart';

/// Rio's reaction to a session score (0–10): a transparent animated clip
/// that plays once and holds its last frame. Tap to replay. Scores with no
/// clip yet, reduced motion, or a clip that fails to load show a still Rio.
class RioScoreClip extends StatefulWidget {
  const RioScoreClip({super.key, required this.score, this.size = 220});

  final int score;
  final double size;

  static String? assetFor(int score) => score >= 8
      ? 'assets/rio/video/rio_score_great.webp'
      : score < 5
      ? 'assets/rio/video/rio_score_keep_going.webp'
      : null; // GOOD (5–7): no clip yet

  @override
  State<RioScoreClip> createState() => _RioScoreClipState();
}

class _RioScoreClipState extends State<RioScoreClip> {
  int _plays = 0;

  String? get _asset => RioScoreClip.assetFor(widget.score);

  @override
  void initState() {
    super.initState();
    _restart();
  }

  /// A finished one-shot animation stays finished in the image cache, so
  /// evict it to play from the first frame again.
  void _restart() {
    final asset = _asset;
    if (asset != null) AssetImage(asset).evict();
  }

  void _replay() {
    _restart();
    setState(() => _plays++);
  }

  RioPose get _stillPose => widget.score >= 8
      ? RioPose.excited
      : widget.score >= 5
      ? RioPose.star
      : RioPose.determined;

  @override
  Widget build(BuildContext context) {
    final asset = _asset;
    final still = Center(
      child: RioImage(_stillPose, height: widget.size * 0.8, motion: RioMotion.pop),
    );
    return Semantics(
      image: true,
      label: 'Rio reacting to your score',
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: asset == null || MediaQuery.disableAnimationsOf(context)
            ? still
            : GestureDetector(
                onTap: _replay,
                child: Image.asset(
                  asset,
                  key: ValueKey(_plays),
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => still,
                ),
              ),
      ),
    );
  }
}

/// "Rio is scoring your conversation…": Rio reading his clipboard, looping,
/// over the dimmed screen.
class RioScoringLoader extends StatelessWidget {
  const RioScoringLoader({super.key, this.label = 'Rio is scoring your conversation…'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: MediaQuery.disableAnimationsOf(context)
                ? const RioImage(RioPose.curious, height: 170, motion: RioMotion.none)
                : Image.asset(
                    'assets/rio/video/rio_scoring.webp',
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        const RioImage(RioPose.curious, height: 170, motion: RioMotion.float),
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
