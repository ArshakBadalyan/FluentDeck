import 'package:flutter/material.dart';
import 'package:riovox/ui_elements/modern_page_widgets.dart';
import 'package:riovox/widgets/rio.dart';

/// Professor Rio's faces (assets/professor/), from the Otter Professor sheet.
enum ProfessorFace {
  happy,
  excited,
  thoughtful,
  winking,
  surprised,
  laughing,
  encouraging,
  determined;

  String get asset => 'assets/professor/face-$name.webp';

  /// A face picked steadily from [seed] (same text, same face).
  static ProfessorFace forSeed(String seed, {List<ProfessorFace>? from}) {
    final options = from ?? values;
    return options[seed.hashCode.abs() % options.length];
  }
}

/// Professor Rio full body, cut out: standing, teaching at the board,
/// explaining from a book, sharing knowledge with a thumbs-up.
enum ProfessorPose {
  front,
  teaching,
  explaining,
  sharing;

  String get asset => 'assets/professor/pose-$name.webp';
}

/// Professor Rio beside a speech bubble: a tip or explanation at the top of
/// help and learning screens.
class ProfessorTip extends StatelessWidget {
  const ProfessorTip({
    super.key,
    required this.text,
    this.pose = ProfessorPose.explaining,
    this.height = 110,
  });

  final String text;
  final ProfessorPose pose;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        RioImage.asset(pose.asset, height: height, motion: RioMotion.float),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: height * 0.35),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppPageColors.cardBgOf(context),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: AppPageColors.subtleBorderOf(context)),
            ),
            child: Text(
              text,
              style: TextStyle(fontSize: 14, height: 1.4, color: AppPageColors.textPrimaryOf(context)),
            ),
          ),
        ),
      ],
    );
  }
}
