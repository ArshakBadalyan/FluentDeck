/// Learn Screen Components & Models

import 'package:flutter/material.dart';

class LessonItem {
  final String title;
  final String description;
  final String level;
  final String category;
  final int cardCount;
  final int difficulty; // 0-3 (A1, B1, B2, C1)
  final Color color;

  LessonItem({
    required this.title,
    required this.description,
    required this.level,
    required this.category,
    required this.cardCount,
    required this.difficulty,
    required this.color,
  });
}
