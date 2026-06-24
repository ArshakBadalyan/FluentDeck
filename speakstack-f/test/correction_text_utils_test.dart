import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled2/models/grammar_correction.dart';
import 'package:untitled2/utils/correction_text_utils.dart';

void main() {
  test('typo uses highlight span only', () {
    final spans = buildCorrectedMessageSpans(
      text: 'I went to the liberary yesterday',
      corrections: const [
        GrammarCorrection(
          originalText: 'liberary',
          correctedText: 'library',
          explanation: 'Spelling',
          errorType: 'spelling',
          inlineStyle: CorrectionInlineStyle.highlight,
        ),
      ],
      baseStyle: const TextStyle(color: Colors.white),
    );
    expect(spans.length, greaterThan(1));
  });

  test('wrong word uses replace spans', () {
    final spans = buildCorrectedMessageSpans(
      text: 'I am very exhaust',
      corrections: const [
        GrammarCorrection(
          originalText: 'exhaust',
          correctedText: 'exhausted',
          explanation: 'Use adjective',
          errorType: 'vocabulary',
          inlineStyle: CorrectionInlineStyle.replace,
        ),
      ],
      baseStyle: const TextStyle(color: Colors.white),
    );
    expect(spans.length, greaterThan(2));
  });

  test('grammar correction shows card not inline', () {
    const correction = GrammarCorrection(
      originalText: 'I go to store yesterday',
      correctedText: 'I went to the store yesterday',
      explanation: 'Past tense',
      errorType: 'grammar',
    );
    expect(correction.showsInline, isFalse);
    expect(correction.showsCard, isTrue);
  });
}
