import 'package:flutter/material.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';

enum DeckCountKind { newCards, learning, review }

enum DeckCountButtonSize { compact, large }

/// Deck counts: blue = new, red = learning, green = review.
class DeckCountButtons extends StatelessWidget {
  const DeckCountButtons({
    super.key,
    required this.newCount,
    required this.learningCount,
    required this.reviewCount,
    this.onTap,
    this.size = DeckCountButtonSize.compact,
  });

  final int newCount;
  final int learningCount;
  final int reviewCount;
  final VoidCallback? onTap;
  final DeckCountButtonSize size;

  @override
  Widget build(BuildContext context) {
    final counts = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DeckCountButton(
            count: newCount,
            kind: DeckCountKind.newCards,
            size: size,
          ),
          SizedBox(width: size == DeckCountButtonSize.compact ? 6 : 10),
          DeckCountButton(
            count: learningCount,
            kind: DeckCountKind.learning,
            size: size,
          ),
          SizedBox(width: size == DeckCountButtonSize.compact ? 6 : 10),
          DeckCountButton(
            count: reviewCount,
            kind: DeckCountKind.review,
            size: size,
          ),
        ],
      ),
    );

    if (onTap == null) return counts;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: counts,
    );
  }
}

class DeckCountButton extends StatelessWidget {
  const DeckCountButton({
    super.key,
    required this.count,
    required this.kind,
    this.size = DeckCountButtonSize.compact,
  });

  final int count;
  final DeckCountKind kind;
  final DeckCountButtonSize size;

  Color get _color {
    switch (kind) {
      case DeckCountKind.newCards:
        return const Color(0xFF4994EC);
      case DeckCountKind.learning:
        return const Color(0xFFED7249);
      case DeckCountKind.review:
        return const Color(0xFF7FFB66);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = size == DeckCountButtonSize.large;
    if (isLarge) {
      return SizedBox(
        width: 72,
        child: Text(
          '$count',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _color,
          ),
        ),
      );
    }
    // Compact: a soft tinted pill (blue new, red learning, green to review);
    // zero counts go quiet grey so the decks with work waiting stand out.
    final tint = count <= 0
        ? AppTint.neutral
        : switch (kind) {
            DeckCountKind.newCards => AppTint.info,
            DeckCountKind.learning => AppTint.danger,
            DeckCountKind.review => AppTint.success,
          };
    final colors = AppPageColors.tintOf(context, tint);
    return Container(
      constraints: const BoxConstraints(minWidth: 26),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.fg),
      ),
    );
  }
}
