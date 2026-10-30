import 'html_text_utils.dart';

/// Normalize answer text for comparison (case, whitespace, punctuation).
String normalizeAnswer(String input) {
  return stripHtml(input)
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Case-insensitive match with light typo tolerance (Levenshtein).
bool isTypeAnswerCorrect(String typed, String expected) {
  final a = normalizeAnswer(typed);
  final b = normalizeAnswer(expected);
  if (a.isEmpty || b.isEmpty) return false;
  if (a == b) return true;

  final maxDist = (b.length * 0.15).floor().clamp(1, 3);
  return levenshtein(a, b) <= maxDist;
}

int levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  final rows = a.length + 1;
  final cols = b.length + 1;
  final matrix = List.generate(rows, (_) => List<int>.filled(cols, 0));

  for (var i = 0; i < rows; i++) {
    matrix[i][0] = i;
  }
  for (var j = 0; j < cols; j++) {
    matrix[0][j] = j;
  }

  for (var i = 1; i < rows; i++) {
    for (var j = 1; j < cols; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      matrix[i][j] = [
        matrix[i - 1][j] + 1,
        matrix[i][j - 1] + 1,
        matrix[i - 1][j - 1] + cost,
      ].reduce((x, y) => x < y ? x : y);
    }
  }

  return matrix[a.length][b.length];
}

/// Strip the type-answer prompt suffix from generated card fronts.
String typeAnswerQuestionHtml(String front) {
  const suffix = '\n\nType your answer:';
  if (front.endsWith(suffix)) {
    return front.substring(0, front.length - suffix.length);
  }
  final idx = front.indexOf(suffix);
  if (idx >= 0) return front.substring(0, idx);
  return front;
}
