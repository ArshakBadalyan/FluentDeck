import '../models/flashcard_model.dart';

const _initialEase = 2.5;
const _minEase = 1.3;
const _defaultLearningSteps = [1, 10];
const _defaultLapseSteps = [10];

DateTime _addMinutes(DateTime date, int minutes) {
  return date.add(Duration(minutes: minutes));
}

DateTime _addDays(DateTime date, num days) {
  return date.add(Duration(milliseconds: (days * 24 * 60 * 60 * 1000).round()));
}

/// Mirrors backend [applySm2Rating] for interval button previews.
CardReviewStateModel previewAfterRating(
  CardReviewStateModel current,
  String rating, {
  DateTime? now,
  DeckOptionsModel? deckOptions,
}) {
  final opts = deckOptions ?? const DeckOptionsModel();
  final learningSteps =
      opts.learningStepsMinutes.isNotEmpty
          ? opts.learningStepsMinutes
          : _defaultLearningSteps;
  final lapseSteps =
      opts.lapseStepsMinutes.isNotEmpty ? opts.lapseStepsMinutes : _defaultLapseSteps;
  final graduatingInterval = opts.graduatingIntervalDays.clamp(1, 36500).toDouble();
  final easyInterval = opts.easyIntervalDays.clamp(1, 36500).toDouble();
  final easyBonus = opts.easyBonus.clamp(1, 3).toDouble();
  final minimumInterval = opts.minimumIntervalDays.clamp(1, 36500).toDouble();

  final base = now ?? DateTime.now();
  var state = current.state;
  var intervalDays = current.intervalDays;
  var easeFactor = current.easeFactor;
  var dueAt = current.dueAt ?? base;
  var lapses = current.lapses;
  var repetitions = current.repetitions;
  var learningStep = current.learningStep;

  final again = rating == 'again';
  final hard = rating == 'hard';
  final good = rating == 'good';
  final easy = rating == 'easy';

  final activeSteps = state == 'relearning' ? lapseSteps : learningSteps;

  if (state == 'new' || state == 'learning' || state == 'relearning') {
    if (again) {
      state = state == 'new' ? 'learning' : 'relearning';
      learningStep = 0;
      dueAt = _addMinutes(base, activeSteps.first);
      if (state == 'relearning') lapses += 1;
      return _build(
        state,
        intervalDays,
        easeFactor,
        dueAt,
        lapses,
        repetitions,
        learningStep,
      );
    }

    if (easy && state == 'new') {
      return _build(
        'review',
        easyInterval,
        (easeFactor + 0.15).clamp(_initialEase, 3.0),
        _addDays(base, easyInterval),
        lapses,
        1,
        0,
      );
    }

    if (good || hard) {
      final nextStep = learningStep + (hard ? 0 : 1);
      if (nextStep >= activeSteps.length) {
        final grad =
            hard
                ? minimumInterval.clamp(1, graduatingInterval / 2).floor()
                : graduatingInterval;
        return _build(
          'review',
          grad.toDouble(),
          easeFactor,
          _addDays(base, grad),
          lapses,
          1,
          0,
        );
      }
      final minutes = activeSteps[nextStep];
      final wait = hard ? (minutes / 2).floor().clamp(1, minutes) : minutes;
      final nextState = state == 'new' ? 'learning' : state;
      return _build(
        nextState,
        intervalDays,
        easeFactor,
        _addMinutes(base, wait),
        lapses,
        repetitions,
        nextStep,
      );
    }

    if (easy) {
      return _build(
        'review',
        easyInterval,
        (easeFactor + 0.15).clamp(_initialEase, 3.0),
        _addDays(base, easyInterval),
        lapses,
        1,
        0,
      );
    }
  }

  if (again) {
    return _build(
      'relearning',
      0,
      (easeFactor - 0.2).clamp(_minEase, 3.0),
      _addMinutes(base, lapseSteps.first),
      lapses + 1,
      0,
      0,
    );
  }

  if (hard) {
    final nextEase = (easeFactor - 0.15).clamp(_minEase, 3.0);
    final nextInterval =
        (intervalDays * 1.2).ceil().clamp(minimumInterval.round(), 36500);
    return _build(
      state,
      nextInterval.toDouble(),
      nextEase,
      _addDays(base, nextInterval),
      lapses,
      repetitions,
      learningStep,
    );
  }

  if (good) {
    var nextReps = repetitions + 1;
    double nextInterval;
    if (nextReps == 1) {
      nextInterval = graduatingInterval;
    } else if (nextReps == 2) {
      nextInterval = (graduatingInterval * 6).clamp(easyInterval, 36500);
    } else {
      nextInterval =
          (intervalDays * easeFactor).round().clamp(minimumInterval.round(), 36500).toDouble();
    }
    return _build(
      state,
      nextInterval,
      easeFactor,
      _addDays(base, nextInterval),
      lapses,
      nextReps,
      learningStep,
    );
  }

  if (easy) {
    final nextEase = (easeFactor + 0.15).clamp(_initialEase, 3.0);
    final nextInterval =
        (intervalDays * nextEase * easyBonus)
            .round()
            .clamp(minimumInterval.round(), 36500);
    return _build(
      state,
      nextInterval.toDouble(),
      nextEase,
      _addDays(base, nextInterval),
      lapses,
      repetitions + 1,
      learningStep,
    );
  }

  return current;
}

CardReviewStateModel _build(
  String state,
  double intervalDays,
  double easeFactor,
  DateTime dueAt,
  int lapses,
  int repetitions,
  int learningStep,
) {
  return CardReviewStateModel(
    state: state,
    intervalDays: intervalDays,
    easeFactor: easeFactor,
    dueAt: dueAt,
    lapses: lapses,
    repetitions: repetitions,
    learningStep: learningStep,
  );
}

Map<String, String> intervalPreviewsForCard(
  FlashcardModel card, {
  DeckOptionsModel? deckOptions,
}) {
  final rs = card.reviewState ?? const CardReviewStateModel();
  final now = DateTime.now();
  return {
    for (final rating in ['again', 'hard', 'good', 'easy'])
      rating: formatIntervalPreview(
        previewAfterRating(
          rs,
          rating,
          now: now,
          deckOptions: deckOptions,
        ).dueAt ??
            now,
        now,
      ),
  };
}

/// Human-readable interval like Anki ("1m", "4d", "<1m").
String formatIntervalPreview(DateTime dueAt, DateTime now) {
  final diff = dueAt.difference(now);
  if (diff.inSeconds <= 0) return '<1m';
  if (diff.inMinutes < 1) return '<1m';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 30) return '${diff.inDays}d';
  if (diff.inDays < 365) return '${(diff.inDays / 30).round()}mo';
  return '${(diff.inDays / 365).round()}y';
}

List<int> parseStepsField(String text, List<int> fallback) {
  final parsed =
      text
          .split(RegExp(r'[,;\s]+'))
          .map((s) => int.tryParse(s.trim()))
          .whereType<int>()
          .where((n) => n > 0)
          .toList();
  return parsed.isEmpty ? fallback : parsed;
}

String formatStepsField(List<int> steps) => steps.join(', ');
