import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled2/ui_elements/screen_tutorial_targets.dart';

/// Persisted "seen" state for first-visit coach flows on main tabs.
///
/// Bump [_prefsVersion] after changing step copy or anchors so tours replay.
class ScreenTutorialService {
  ScreenTutorialService._();
  static final ScreenTutorialService instance = ScreenTutorialService._();

  static const _prefsVersion = 14;

  String _key(String tutorialId) =>
      'screen_tutorial_v${_prefsVersion}_$tutorialId';

  Future<bool> isComplete(String tutorialId) async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_key(tutorialId)) ?? false;
  }

  Future<void> markComplete(String tutorialId) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key(tutorialId), true);
  }

  Future<void> clearCompletion(String tutorialId) async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key(tutorialId));
  }

  Future<void> clearAll() async {
    final p = await SharedPreferences.getInstance();
    for (final id in ScreenTutorialCatalog.allTutorialIds) {
      await p.remove(_key(id));
    }
  }
}

/// Registered by the main shell (`MainScreenState`) so profile (and other
/// leaves) can replay intros without a circular import from `app_start.dart`.
class ScreenTutorialReplayCoordinator {
  ScreenTutorialReplayCoordinator._();

  static Future<void> Function()? replayCurrentTabIntro;
  static Future<void> Function()? resetAllTabIntros;

  /// Current bottom-nav index (registered by [MainScreenState]).
  static int Function()? currentMainTabIndex;

  /// Current sub-tab index under the purple header (or 0 if none).
  static int Function()? currentSubTabIndex;

  static Future<void> replayCurrent() async {
    final fn = replayCurrentTabIntro;
    if (fn != null) await fn();
  }

  static Future<void> resetAll() async {
    final fn = resetAllTabIntros;
    if (fn != null) await fn();
  }

  /// [MainScreenState] wires this so Remix tab load/pick UI updates refresh the app bar (?) and reschedule auto-tours.
  static VoidCallback? onRemixTutorialGateMayHaveChanged;

  static void notifyRemixTutorialGateChanged() {
    onRemixTutorialGateMayHaveChanged?.call();
  }

  static int? readMainTabIndex() => currentMainTabIndex?.call();

  static int readSubTabIndex() => currentSubTabIndex?.call() ?? 0;
}

class ScreenTutorialStep {
  const ScreenTutorialStep({
    required this.titleKey,
    required this.bodyKey,
    this.targetId,
    this.titleVars,
    this.bodyVars,
  });

  final String titleKey;
  final String bodyKey;

  /// [ScreenTutorialTargetIds] wired to concrete [ScreenTutorialKeys] anchors.
  final String? targetId;

  /// Passed to [AppLocalizations.t] / `context.tr` for `{placeholder}` replacement.
  final Map<String, dynamic>? titleVars;
  final Map<String, dynamic>? bodyVars;
}

abstract final class ScreenTutorialCatalog {
  static const List<String> allTutorialIds = [
    'activity_status',
    'activity_top_list',
    'activity_answers',
    'activity_progress',
    'topics_browse',
    'practice_remix_intro',
    'practice_remix',
    'practice_remix_configure',
    'practice_vs_machine',
    'practice_vs_player',
    'learning_exercise_intro',
  ];

  static String? idForMainAndSubTab({
    required int mainIndex,
    required int subIndex,
  }) {
    return null;
  }

  static List<ScreenTutorialStep> stepsFor(String tutorialId) {
    final steps = _steps[tutorialId];
    assert(steps != null, 'Missing tutorial catalog: $tutorialId');
    return steps!;
  }

  static final Map<String, List<ScreenTutorialStep>> _steps = {
    'activity_status': _activityStatusTour,
    'activity_top_list': _activityTopListTour,
    'activity_answers': _activityAnswersTour,
    'activity_progress': _activityProgressTour,
    'topics_browse': _topicsBrowseTour,
    'practice_remix_intro': _practiceRemixIntroTour,
    'practice_remix': _practiceRemixTour,
    'practice_remix_configure': _practiceRemixConfigureTour,
    'practice_vs_machine': _practiceMachineTour,
    'practice_vs_player': _practiceFriendTour,
    'learning_exercise_intro': _learningExerciseIntroTour,
  };
}

// ——— Tour payloads (localized copy under `screen-tutorial.{id}`) ———

final _activityStatusTour = [
  ScreenTutorialStep(
    titleKey: 'screen-tutorial.activity_status.s1_title',
    bodyKey: 'screen-tutorial.activity_status.s1_body',
    targetId: ScreenTutorialTargetIds.mainAppBarTabs,
  ),
  ScreenTutorialStep(
    titleKey: 'screen-tutorial.activity_status.s2_title',
    bodyKey: 'screen-tutorial.activity_status.s2_body',
    targetId: ScreenTutorialTargetIds.activityStatusDailyGoal,
  ),
];

final _activityTopListTour = [
  ScreenTutorialStep(
    titleKey: 'screen-tutorial.activity_top_list.complete_title',
    bodyKey: 'screen-tutorial.activity_top_list.complete_body',
    targetId: ScreenTutorialTargetIds.activityTopListBody,
  ),
];

final _activityAnswersTour = [
  ScreenTutorialStep(
    titleKey: 'screen-tutorial.activity_answers.s4_title',
    bodyKey: 'screen-tutorial.activity_answers.s4_body',
    targetId: ScreenTutorialTargetIds.activityAnswersBody,
  ),
];

final _activityProgressTour = [
  ScreenTutorialStep(
    titleKey: 'screen-tutorial.activity_progress.s3_title',
    bodyKey: 'screen-tutorial.activity_progress.s3_body',
    targetId: ScreenTutorialTargetIds.activityProgressPeriodPivot,
  ),
  ScreenTutorialStep(
    titleKey: 'screen-tutorial.activity_progress.s4_title',
    bodyKey: 'screen-tutorial.activity_progress.s4_body',
    targetId: ScreenTutorialTargetIds.activityProgressDiagramPivot,
  ),
];

final _topicsBrowseTour = [
  ScreenTutorialStep(
    titleKey: 'screen-tutorial.topics_browse.s2_title',
    bodyKey: 'screen-tutorial.topics_browse.s2_body',
    targetId: ScreenTutorialTargetIds.mainAppBarTabs,
  ),
  ScreenTutorialStep(
    titleKey: 'screen-tutorial.topics_browse.s5_title',
    bodyKey: 'screen-tutorial.topics_browse.s5_body',
    targetId: ScreenTutorialTargetIds.topicsTopicListViewport,
  ),
  ScreenTutorialStep(
    titleKey: 'screen-tutorial.topics_browse.s3_title',
    bodyKey: 'screen-tutorial.topics_browse.s3_body',
    targetId: ScreenTutorialTargetIds.mainAppBarSearch,
  ),
];

final _learningExerciseIntroTour = [
  ScreenTutorialStep(
    titleKey: 'screen-tutorial.learning_exercise.s1_title',
    bodyKey: 'screen-tutorial.learning_exercise.s1_body',
    targetId: ScreenTutorialTargetIds.learningQuizQuestionStem,
  ),
  ScreenTutorialStep(
    titleKey: 'screen-tutorial.learning_exercise.s2_title',
    bodyKey: 'screen-tutorial.learning_exercise.s2_body',
    targetId: ScreenTutorialTargetIds.learningQuizAnswerOptions,
  ),
  ScreenTutorialStep(
    titleKey: 'screen-tutorial.learning_exercise.s3_title',
    bodyKey: 'screen-tutorial.learning_exercise.s3_body',
    targetId: ScreenTutorialTargetIds.learningQuizSolutionLink,
  ),
];

/// Shown when the user has no completed topics yet (pick UI is hidden).
final _practiceRemixIntroTour = [
  ScreenTutorialStep(
    titleKey: 'screen-tutorial.practice_remix_intro.s1_title',
    bodyKey: 'screen-tutorial.practice_remix_intro.s1_body',
    targetId: null,
  ),
  ScreenTutorialStep(
    titleKey: 'screen-tutorial.practice_remix_intro.s2_title',
    bodyKey: 'screen-tutorial.practice_remix_intro.s2_body',
    targetId: null,
  ),
];

final _practiceRemixTour = [
  ScreenTutorialStep(
    titleKey: 'screen-tutorial.practice_remix.s5_title',
    bodyKey: 'screen-tutorial.practice_remix.s5_body',
    targetId: ScreenTutorialTargetIds.practiceRemixClassGroupedList,
  ),
  ScreenTutorialStep(
    titleKey: 'screen-tutorial.practice_remix.s3_title',
    bodyKey: 'screen-tutorial.practice_remix.s3_body',
    targetId: ScreenTutorialTargetIds.practiceRemixSearchField,
  ),
  ScreenTutorialStep(
    titleKey: 'screen-tutorial.practice_remix.s4_title',
    bodyKey: 'screen-tutorial.practice_remix.s4_body',
    targetId: ScreenTutorialTargetIds.practiceRemixContinueCta,
  ),
];

final _practiceRemixConfigureTour = [
  ScreenTutorialStep(
    titleKey: 'screen-tutorial.practice_remix_configure.s1_title',
    bodyKey: 'screen-tutorial.practice_remix_configure.s1_body',
    targetId: ScreenTutorialTargetIds.practiceRemixExerciseCount,
  ),
];

final _practiceMachineTour = [
  ScreenTutorialStep(
    titleKey: 'screen-tutorial.practice_vs_machine.s3_title',
    bodyKey: 'screen-tutorial.practice_vs_machine.s3_body',
    targetId: ScreenTutorialTargetIds.practiceMachineListPivot,
  ),
];

final _practiceFriendTour = [
  ScreenTutorialStep(
    titleKey: 'screen-tutorial.practice_vs_player.s3_title',
    bodyKey: 'screen-tutorial.practice_vs_player.s3_body',
    targetId: ScreenTutorialTargetIds.practicePlayerIntroStartPivot,
  ),
];
