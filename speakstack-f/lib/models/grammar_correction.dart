enum CorrectionInlineStyle {
  none,
  highlight,
  replace,
}

class GrammarCorrection {
  final String originalText;
  final String correctedText;
  final String explanation;
  final String errorType;
  final CorrectionInlineStyle inlineStyle;

  const GrammarCorrection({
    required this.originalText,
    required this.correctedText,
    required this.explanation,
    required this.errorType,
    this.inlineStyle = CorrectionInlineStyle.none,
  });

  bool get showsInline => inlineStyle != CorrectionInlineStyle.none;

  bool get showsCard {
    if (inlineStyle == CorrectionInlineStyle.replace) return true;
    if (inlineStyle == CorrectionInlineStyle.highlight) return false;
    return _isSentenceLevel;
  }

  bool get _isSentenceLevel {
    final type = errorType.toLowerCase();
    return type == 'grammar' ||
        type == 'phrasing' ||
        type == 'pronunciation' ||
        originalText.contains(' ');
  }

  factory GrammarCorrection.fromJson(Map<String, dynamic> json) {
    return GrammarCorrection(
      originalText:
          json['original'] as String? ?? json['originalText'] as String? ?? '',
      correctedText:
          json['corrected'] as String? ??
          json['correctedText'] as String? ??
          '',
      explanation: json['explanation'] as String? ?? '',
      errorType: json['errorType'] as String? ?? 'grammar',
      inlineStyle: _parseInlineStyle(json),
    );
  }

  static CorrectionInlineStyle _parseInlineStyle(Map<String, dynamic> json) {
    final raw = json['inlineStyle']?.toString().toLowerCase();
    if (raw == 'highlight') return CorrectionInlineStyle.highlight;
    if (raw == 'replace') return CorrectionInlineStyle.replace;
    if (raw == 'none') return CorrectionInlineStyle.none;

    final type = (json['errorType'] as String? ?? 'grammar').toLowerCase();
    if (type == 'spelling' || type == 'typo') {
      return CorrectionInlineStyle.highlight;
    }
    if (type == 'vocabulary') return CorrectionInlineStyle.replace;
    return CorrectionInlineStyle.none;
  }

  Map<String, dynamic> toJson() => {
    'original': originalText,
    'corrected': correctedText,
    'explanation': explanation,
    'errorType': errorType,
    'inlineStyle': inlineStyle.name,
  };
}
