import 'package:flutter/material.dart';

enum DeckCountKind { newCards, learning, review }

enum DeckCountButtonSize { compact, large }

/// Deck counts: blue = new, orange = learning, green = review.
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
    // Compact: a soft tinted pill; zero counts go quiet grey so the decks
    // with work waiting stand out.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = count > 0;
    final fill = active
        ? _color.withValues(alpha: isDark ? 0.2 : 0.14)
        : (isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF3F7F7));
    final text = !active
        ? (isDark ? const Color(0xFF9AB0B3) : const Color(0xFF6B7A7D))
        : isDark
            ? _color
            : Color.lerp(_color, Colors.black, 0.5)!;
    return Container(
      constraints: const BoxConstraints(minWidth: 30),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: text),
      ),
    );
  }
}
