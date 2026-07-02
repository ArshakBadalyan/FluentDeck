/// Home Screen Components & Models

import 'package:flutter/material.dart';

class DeckItem {
  final String title;
  final int cardCount;
  final int dueCards;
  final double progress; // 0.0 to 1.0
  final String category;
  final Color color;

  DeckItem({
    required this.title,
    required this.cardCount,
    required this.dueCards,
    required this.progress,
    required this.category,
    required this.color,
  });
}
