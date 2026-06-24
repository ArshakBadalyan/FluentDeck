import 'package:flutter/material.dart';
import 'package:speakstack/app_colors.dart';
import 'package:speakstack/models/grammar_correction.dart';

class _TextRange {
  const _TextRange(this.start, this.end);

  final int start;
  final int end;
}

class _InlineMatch {
  const _InlineMatch({
    required this.start,
    required this.end,
    required this.correction,
  });

  final int start;
  final int end;
  final GrammarCorrection correction;
}

/// Builds rich text for a user message with inline spelling/vocabulary fixes.
List<InlineSpan> buildCorrectedMessageSpans({
  required String text,
  required List<GrammarCorrection> corrections,
  required TextStyle baseStyle,
  Color errorColor = AppColors.redWrong,
  Color correctionColor = AppColors.greenCorrect,
}) {
  final inline = corrections.where((c) => c.showsInline).toList();
  if (inline.isEmpty) {
    return [TextSpan(text: text, style: baseStyle)];
  }

  final matches = <_InlineMatch>[];
  final usedRanges = <_TextRange>[];

  for (final correction in inline) {
    final original = correction.originalText.trim();
    if (original.isEmpty) continue;

    final index = _findOriginalIndex(text, original);
    if (index < 0) continue;

    final end = index + original.length;
    final overlaps = usedRanges.any(
      (r) => !(end <= r.start || index >= r.end),
    );
    if (overlaps) continue;

    usedRanges.add(_TextRange(index, end));
    matches.add(
      _InlineMatch(start: index, end: end, correction: correction),
    );
  }

  if (matches.isEmpty) {
    return [TextSpan(text: text, style: baseStyle)];
  }

  matches.sort((a, b) => a.start.compareTo(b.start));

  final spans = <InlineSpan>[];
  var cursor = 0;

  for (final match in matches) {
    if (match.start > cursor) {
      spans.add(
        TextSpan(text: text.substring(cursor, match.start), style: baseStyle),
      );
    }

    final original = text.substring(match.start, match.end);
    if (match.correction.inlineStyle == CorrectionInlineStyle.highlight) {
      spans.add(
        TextSpan(
          text: original,
          style: baseStyle.copyWith(color: errorColor),
        ),
      );
    } else {
      spans.add(
        TextSpan(
          text: original,
          style: baseStyle.copyWith(
            color: errorColor,
            decoration: TextDecoration.lineThrough,
            decorationColor: errorColor,
          ),
        ),
      );
      final corrected = match.correction.correctedText.trim();
      if (corrected.isNotEmpty) {
        spans.add(const TextSpan(text: ' '));
        spans.add(
          TextSpan(
            text: corrected,
            style: baseStyle.copyWith(
              color: correctionColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }
    }

    cursor = match.end;
  }

  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor), style: baseStyle));
  }

  return spans;
}

int _findOriginalIndex(String text, String original) {
  final direct = text.indexOf(original);
  if (direct >= 0) return direct;

  final lowerText = text.toLowerCase();
  final lowerOriginal = original.toLowerCase();
  return lowerText.indexOf(lowerOriginal);
}
