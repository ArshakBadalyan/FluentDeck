/// Review Screen Components & Models

class FlashcardItem {
  final String front;
  final String frontLabel;
  final String back;
  final String backLabel;
  final String pronunciation;

  FlashcardItem({
    required this.front,
    required this.frontLabel,
    required this.back,
    required this.backLabel,
    required this.pronunciation,
  });
}

enum SM2Response {
  again,    // 1 - Incorrect
  hard,     // 2 - Correct with effort
  good,     // 3 - Correct
  easy,     // 4 - Correct easily
}
