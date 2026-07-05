import 'package:flutter/material.dart';

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
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
      ),
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
        return const Color(0xFF2196F3);
      case DeckCountKind.learning:
        return const Color(0xFFE53935);
      case DeckCountKind.review:
        return const Color(0xFF43A047);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = size == DeckCountButtonSize.large;
    return SizedBox(
      width: isLarge ? 72 : 28,
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: isLarge ? 22 : 15,
          fontWeight: FontWeight.w700,
          color: _color,
        ),
      ),
    );
  }
}
