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
  /// True when this correction was auto-saved to the From speaking deck.
  final bool autoSaved;

  const GrammarCorrection({
    required this.originalText,
    required this.correctedText,
    required this.explanation,
    required this.errorType,
    this.inlineStyle = CorrectionInlineStyle.none,
    this.autoSaved = false,
  });

  bool get showsInline => inlineStyle != CorrectionInlineStyle.none;

  GrammarCorrection copyWith({
    String? originalText,
    String? correctedText,
    String? explanation,
    String? errorType,
    CorrectionInlineStyle? inlineStyle,
    bool? autoSaved,
  }) {
    return GrammarCorrection(
      originalText: originalText ?? this.originalText,
      correctedText: correctedText ?? this.correctedText,
      explanation: explanation ?? this.explanation,
      errorType: errorType ?? this.errorType,
      inlineStyle: inlineStyle ?? this.inlineStyle,
      autoSaved: autoSaved ?? this.autoSaved,
    );
  }

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
      autoSaved: json['autoSaved'] == true,
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
    if (autoSaved) 'autoSaved': true,
  };
}
