import 'package:flutter/material.dart';

import '../app_colors.dart';

class _VocabMatch {
  const _VocabMatch(this.start, this.end);
  final int start;
  final int end;
}

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

  final matches = <_VocabMatch>[];
  for (final term in terms) {
    final escaped = RegExp.escape(term);
    // Web/JS RegExp does not support (?i); use caseSensitive: false.
    // Phrases with spaces cannot use \\b word boundaries reliably.
    final regex =
        term.contains(RegExp(r'\s'))
            ? RegExp(escaped, caseSensitive: false)
            : RegExp('\\b$escaped\\b', caseSensitive: false);
    for (final match in regex.allMatches(text)) {
      matches.add(_VocabMatch(match.start, match.end));
    }
  }

  if (matches.isEmpty) {
    return [TextSpan(text: text, style: baseStyle)];
  }

  matches.sort((a, b) => a.start.compareTo(b.start));
  final merged = <_VocabMatch>[];
  for (final match in matches) {
    if (merged.isEmpty || match.start >= merged.last.end) {
      merged.add(match);
    } else if (match.end > merged.last.end) {
      merged[merged.length - 1] = _VocabMatch(merged.last.start, match.end);
    }
  }

  final highlightStyle = baseStyle.copyWith(
    backgroundColor: AppColors.primaryYellow.withValues(alpha: 0.45),
    fontWeight: FontWeight.w600,
  );

  final spans = <InlineSpan>[];
  var last = 0;
  for (final match in merged) {
    if (match.start > last) {
      spans.add(
        TextSpan(text: text.substring(last, match.start), style: baseStyle),
      );
    }
    spans.add(
      TextSpan(text: text.substring(match.start, match.end), style: highlightStyle),
    );
    last = match.end;
  }

  if (last < text.length) {
    spans.add(TextSpan(text: text.substring(last), style: baseStyle));
  }

  return spans;
}
