import 'package:flutter/material.dart';

import '../app_colors.dart';

/// Highlights [vocabulary] terms when they appear in tutor messages.
List<InlineSpan> buildVocabularyHighlightSpans({
  required String text,
  required List<String> vocabulary,
  required TextStyle baseStyle,
}) {
  final terms =
      vocabulary
          .map((v) => v.trim())
          .where((v) => v.length >= 2)
          .toList()
        ..sort((a, b) => b.length.compareTo(a.length));

  if (terms.isEmpty) {
    return [TextSpan(text: text, style: baseStyle)];
  }

  final pattern = terms.map(RegExp.escape).join('|');
  final regex = RegExp('(?i)\\b(?:$pattern)\\b');
  final highlightStyle = baseStyle.copyWith(
    backgroundColor: AppColors.primaryYellow.withValues(alpha: 0.45),
    fontWeight: FontWeight.w600,
  );

  final spans = <InlineSpan>[];
  var last = 0;
  for (final match in regex.allMatches(text)) {
    if (match.start > last) {
      spans.add(
        TextSpan(text: text.substring(last, match.start), style: baseStyle),
      );
    }
    spans.add(TextSpan(text: match.group(0), style: highlightStyle));
    last = match.end;
  }

  if (last < text.length) {
    spans.add(TextSpan(text: text.substring(last), style: baseStyle));
  }

  return spans.isEmpty ? [TextSpan(text: text, style: baseStyle)] : spans;
}
