'use strict';

const INITIAL_EASE = 2.5;
const MIN_EASE = 1.3;
const LEARNING_STEPS_MINUTES = [1, 10];

function addMinutes(date, minutes) {
  return new Date(date.getTime() + minutes * 60 * 1000);
}

function addDays(date, days) {
  return new Date(date.getTime() + days * 24 * 60 * 60 * 1000);
}

function resolveSchedulingOptions(deckOptions) {
  const o = deckOptions && typeof deckOptions === 'object' ? deckOptions : {};
  const learningSteps =
    Array.isArray(o.learningStepsMinutes) && o.learningStepsMinutes.length
      ? o.learningStepsMinutes
      : LEARNING_STEPS_MINUTES;
  const lapseSteps =
    Array.isArray(o.lapseStepsMinutes) && o.lapseStepsMinutes.length
      ? o.lapseStepsMinutes
      : [10];
  return {
    learningSteps,
    lapseSteps,
    graduatingInterval:
      Math.max(1, parseFloat(String(o.graduatingIntervalDays ?? 1)) || 1),
    easyInterval: Math.max(1, parseFloat(String(o.easyIntervalDays ?? 4)) || 4),
    easyBonus: Math.max(1, parseFloat(String(o.easyBonus ?? 1.3)) || 1.3),
    minimumInterval:
      Math.max(1, parseFloat(String(o.minimumIntervalDays ?? 1)) || 1),
  };
}

function initialReviewState(now = new Date()) {
  return {
    state: 'new',
    intervalDays: 0,
    easeFactor: INITIAL_EASE,
    dueAt: now,
    lapses: 0,
    repetitions: 0,
    learningStep: 0,
    lastReviewedAt: null,
  };
}

function formatReviewState(row) {
  if (!row) return null;
  return {
    id: row.id,
    state: row.state ?? 'new',
    intervalDays: row.intervalDays ?? row.interval_days ?? 0,
    easeFactor: row.easeFactor ?? row.ease_factor ?? INITIAL_EASE,
    dueAt: row.dueAt ?? row.due_at,
    lapses: row.lapses ?? 0,
    repetitions: row.repetitions ?? 0,
    learningStep: row.learningStep ?? row.learning_step ?? 0,
    lastReviewedAt: row.lastReviewedAt ?? row.last_reviewed_at,
    firstStudiedAt: row.firstStudiedAt ?? row.first_studied_at,
    suspended: row.suspended === true,
    buriedUntil: row.buriedUntil ?? row.buried_until ?? null,
  };
}

function isAvailableForReview(review, now = new Date()) {
  if (!review) return true;
  if (review.suspended === true) return false;
  const buried = review.buriedUntil ?? review.buried_until;
  if (buried) {
    const until = new Date(buried);
    if (until.getTime() > now.getTime()) return false;
  }
  return true;
}

function endOfLocalDay(now = new Date()) {
  const d = new Date(now);
  d.setHours(23, 59, 59, 999);
  return d;
}

/**
 * Anki-style scheduling with Again / Hard / Good / Easy.
 * @param {object} deckOptions - normalized deck options (learning steps, intervals, etc.)
 */
function applySm2Rating(current, rating, now = new Date(), deckOptions = null) {
  const sched = resolveSchedulingOptions(deckOptions);
  const { learningSteps, lapseSteps, graduatingInterval, easyInterval, easyBonus, minimumInterval } =
    sched;

  const state = {
    state: current.state ?? 'new',
    intervalDays: current.intervalDays ?? 0,
    easeFactor: current.easeFactor ?? INITIAL_EASE,
    dueAt: current.dueAt ? new Date(current.dueAt) : now,
    lapses: current.lapses ?? 0,
    repetitions: current.repetitions ?? 0,
    learningStep: current.learningStep ?? 0,
    lastReviewedAt: now,
  };

  const again = rating === 'again';
  const hard = rating === 'hard';
  const good = rating === 'good';
  const easy = rating === 'easy';

  const activeSteps = state.state === 'relearning' ? lapseSteps : learningSteps;

  if (state.state === 'new' || state.state === 'learning' || state.state === 'relearning') {
    if (again) {
      state.state = state.state === 'new' ? 'learning' : 'relearning';
      state.learningStep = 0;
      state.dueAt = addMinutes(now, activeSteps[0]);
      if (state.state === 'relearning') state.lapses += 1;
      return state;
    }

    if (easy && state.state === 'new') {
      state.state = 'review';
      state.intervalDays = easyInterval;
      state.repetitions = 1;
      state.easeFactor = Math.min(state.easeFactor + 0.15, 3.0);
      state.dueAt = addDays(now, state.intervalDays);
      state.learningStep = 0;
      return state;
    }

    const step = state.learningStep;
    if (good || hard) {
      const nextStep = step + (hard ? 0 : 1);
      if (nextStep >= activeSteps.length) {
        state.state = 'review';
        state.intervalDays = hard
          ? Math.max(minimumInterval, Math.floor(graduatingInterval / 2))
          : graduatingInterval;
        state.repetitions = 1;
        state.dueAt = addDays(now, state.intervalDays);
        state.learningStep = 0;
        return state;
      }
      state.state = state.state === 'new' ? 'learning' : state.state;
      state.learningStep = nextStep;
      const minutes = activeSteps[nextStep];
      state.dueAt = addMinutes(
        now,
        hard ? Math.max(1, Math.floor(minutes / 2)) : minutes,
      );
      return state;
    }

    if (easy) {
      state.state = 'review';
      state.intervalDays = easyInterval;
      state.repetitions = 1;
      state.easeFactor = Math.min(state.easeFactor + 0.15, 3.0);
      state.dueAt = addDays(now, state.intervalDays);
      state.learningStep = 0;
      return state;
    }
  }

  // Review state
  if (again) {
    state.state = 'relearning';
    state.lapses += 1;
    state.repetitions = 0;
    state.intervalDays = 0;
    state.learningStep = 0;
    state.easeFactor = Math.max(MIN_EASE, state.easeFactor - 0.2);
    state.dueAt = addMinutes(now, lapseSteps[0]);
    return state;
  }

  if (hard) {
    state.easeFactor = Math.max(MIN_EASE, state.easeFactor - 0.15);
    state.intervalDays = Math.max(
      minimumInterval,
      Math.round(state.intervalDays * 1.2),
    );
    state.dueAt = addDays(now, state.intervalDays);
    return state;
  }

  if (good) {
    state.repetitions += 1;
    if (state.repetitions === 1) {
      state.intervalDays = graduatingInterval;
    } else if (state.repetitions === 2) {
      state.intervalDays = Math.max(graduatingInterval * 6, easyInterval);
    } else {
      state.intervalDays = Math.max(
        minimumInterval,
        Math.round(state.intervalDays * state.easeFactor),
      );
    }
    state.dueAt = addDays(now, state.intervalDays);
    return state;
  }

  if (easy) {
    state.repetitions += 1;
    state.easeFactor = Math.min(state.easeFactor + 0.15, 3.0);
    state.intervalDays = Math.max(
      minimumInterval,
      Math.round(state.intervalDays * state.easeFactor * easyBonus),
    );
    state.dueAt = addDays(now, state.intervalDays);
    return state;
  }

  return state;
}

function isDue(reviewState, now = new Date()) {
  if (!reviewState) return false;
  if (reviewState.state === 'new') return true;
  const due = reviewState.dueAt ? new Date(reviewState.dueAt) : null;
  if (!due) return true;
  return due.getTime() <= now.getTime();
}

module.exports = {
  INITIAL_EASE,
  LEARNING_STEPS_MINUTES,
  resolveSchedulingOptions,
  initialReviewState,
  formatReviewState,
  applySm2Rating,
  isDue,
  isAvailableForReview,
  endOfLocalDay,
};
