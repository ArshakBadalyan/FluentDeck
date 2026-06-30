import 'package:flutter/material.dart';

/// Stable identifiers referenced by [ScreenTutorialCatalog] step payloads.
abstract final class ScreenTutorialTargetIds {
  /// Highlight rects keyed onto widgets ([ScreenTutorialKeys]).
  static const mainBottomNav = 'main.bottom_nav';

  /// Horizontal tab strip under title (depends on Activity / Topics / Practice / Profile).
  static const mainAppBarTabs = 'main.app_bar_tabs';

  /// "Today's goal" line under purple headline (`MainAppBar` daily goal hint).
  static const mainAppBarTodayGoal = 'main.app_bar_today_goal';

  /// Topics-only search icon (`MainAppBar.onSearchTap`).
  static const mainAppBarSearch = 'main.app_bar_search';

  /// Bell action opening the notification/end drawer tray.
  static const mainAppBarNotifications = 'main.app_bar_notifications';

  static const activityStatusDailyGoal = 'activity.status_daily_goal';

  static const activityTopListBody = 'activity.top_list_body';

  static const activityTopListCardCourse = 'activity.top_list_card_course';

  static const activityTopListCardInstitution =
      'activity.top_list_card_institution';

  static const activityTopListCardCity = 'activity.top_list_card_city';

  static const activityTopListCardCountry = 'activity.top_list_card_country';

  /// Spotlight target for a ranking row (`course`, `institution`, …).
  static String topListCardTargetId(String rankingKey) => switch (rankingKey) {
    'course' => activityTopListCardCourse,
    'institution' => activityTopListCardInstitution,
    'city' => activityTopListCardCity,
    'country' => activityTopListCardCountry,
    _ => activityTopListBody,
  };

  static const activityAnswersBody = 'activity.answers_body';

  static const activityProgressPeriodPivot = 'activity.progress_period';
  static const activityProgressDiagramPivot =
      'activity.progress_chart_viewport';

  static const topicsTopicListViewport = 'topics.topic_scroll_viewport';

  static const practiceRemixSearchField = 'practice.remix_search_bar';

  /// Remix flow: Continue button after picking topics/classes.
  static const practiceRemixContinueCta = 'practice.remix_continue_cta';

  /// Slider (+ label) for how many exercises in the remix round (configure step).
  static const practiceRemixExerciseCount = 'practice.remix_exercise_count';

  /// Topics list grouped by school class (scroll to other grades).
  static const practiceRemixClassGroupedList = 'practice.remix_class_group_list';

  static const practiceMachineListPivot = 'practice.machine_pick_viewport';

  static const practicePlayerIntroStartPivot =
      'practice.player_friend_intro_cta';

  /// Learning / topic exercise screen (question, options, solution link).
  static const learningQuizQuestionStem = 'learning.quiz_question_stem';
  static const learningQuizAnswerOptions = 'learning.quiz_answer_options';
  static const learningQuizSolutionLink = 'learning.quiz_solution_link';

  /// Public lookup for overlays / tooling.
  static Iterable<String> get allRegistered =>
      ScreenTutorialKeys.allTargetIds();
}

/// [GlobalKey] anchors — attach via [KeyedSubtree]/widget keys on real UI blocks.
abstract final class ScreenTutorialKeys {
  ScreenTutorialKeys._();

  static final GlobalKey mainBottomNav = GlobalKey(debugLabel: 'coach_bn');

  static final GlobalKey mainAppBarTabs = GlobalKey(debugLabel: 'coach_tabs');

  static final GlobalKey mainAppBarTodayGoal = GlobalKey(
    debugLabel: 'coach_goal_banner',
  );

  static final GlobalKey mainAppBarSearch = GlobalKey(debugLabel: 'coach_lens');

  static final GlobalKey mainAppBarNotifications = GlobalKey(
    debugLabel: 'coach_notes',
  );

  static final GlobalKey activityStatusDailyGoalOnly = GlobalKey(
    debugLabel: 'coach_daily_goal_only',
  );

  static final GlobalKey activityTopListBody = GlobalKey(
    debugLabel: 'coach_leaderboard_body',
  );

  static final GlobalKey activityTopListCardCourseKey = GlobalKey(
    debugLabel: 'coach_top_list_class',
  );

  static final GlobalKey activityTopListCardInstitutionKey = GlobalKey(
    debugLabel: 'coach_top_list_school',
  );

  static final GlobalKey activityTopListCardCityKey = GlobalKey(
    debugLabel: 'coach_top_list_city',
  );

  static final GlobalKey activityTopListCardCountryKey = GlobalKey(
    debugLabel: 'coach_top_list_country',
  );

  /// Coach spotlight anchor for a Top List menu row (`course` / `institution` / …).
  static GlobalKey? globalKeyForTopListRankingCard(String rankingKey) =>
      switch (rankingKey) {
        'course' => activityTopListCardCourseKey,
        'institution' => activityTopListCardInstitutionKey,
        'city' => activityTopListCardCityKey,
        'country' => activityTopListCardCountryKey,
        _ => null,
      };

  static final GlobalKey activityAnswersBody = GlobalKey(
    debugLabel: 'coach_answer_donuts_scroll',
  );

  static final GlobalKey activityProgressPeriodStrip = GlobalKey(
    debugLabel: 'coach_prog_week_month',
  );

  static final GlobalKey activityProgressChartHost = GlobalKey(
    debugLabel: 'coach_prog_bar_chart',
  );

  static final GlobalKey topicsTopicScrollViewport = GlobalKey(
    debugLabel: 'coach_topics_cards',
  );

  static final GlobalKey practiceRemixSearchBar = GlobalKey(
    debugLabel: 'coach_remix_query',
  );

  static final GlobalKey practiceRemixContinue = GlobalKey(
    debugLabel: 'coach_remix_next',
  );

  static final GlobalKey practiceRemixExerciseCountSlider = GlobalKey(
    debugLabel: 'coach_remix_exercise_count',
  );

  static final GlobalKey practiceRemixTopicsByClassViewport = GlobalKey(
    debugLabel: 'coach_remix_class_groups',
  );

  static final GlobalKey practiceVsMachineListViewport = GlobalKey(
    debugLabel: 'coach_ai_round_picker',
  );

  static final GlobalKey practiceVsPlayerIntroCta = GlobalKey(
    debugLabel: 'coach_friend_green_cta',
  );

  static final GlobalKey learningQuizQuestionStem = GlobalKey(
    debugLabel: 'coach_learn_q_stem',
  );

  static final GlobalKey learningQuizAnswerOptions = GlobalKey(
    debugLabel: 'coach_learn_q_options',
  );

  static final GlobalKey learningQuizSolutionLink = GlobalKey(
    debugLabel: 'coach_learn_q_solution',
  );

  /// Scrolls scrollable ancestor(s) so the spotlight target lays in view before overlay measures.
  static Future<void> ensureTargetScrollVisible(String? targetId) async {
    final k = keyFor(targetId);
    if (k == null) return;
    final ctx = k.currentContext;
    if (ctx == null || !ctx.mounted) return;
    try {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeInOutCubic,
        alignment: 0.38,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
    } catch (_) {
      // No scroll ancestor (chrome keys) — safe to ignore.
    }
  }

  static Iterable<String> allTargetIds() sync* {
    yield ScreenTutorialTargetIds.mainBottomNav;
    yield ScreenTutorialTargetIds.mainAppBarTabs;
    yield ScreenTutorialTargetIds.mainAppBarTodayGoal;
    yield ScreenTutorialTargetIds.mainAppBarSearch;
    yield ScreenTutorialTargetIds.mainAppBarNotifications;
    yield ScreenTutorialTargetIds.activityStatusDailyGoal;
    yield ScreenTutorialTargetIds.activityTopListBody;
    yield ScreenTutorialTargetIds.activityTopListCardCourse;
    yield ScreenTutorialTargetIds.activityTopListCardInstitution;
    yield ScreenTutorialTargetIds.activityTopListCardCity;
    yield ScreenTutorialTargetIds.activityTopListCardCountry;
    yield ScreenTutorialTargetIds.activityAnswersBody;
    yield ScreenTutorialTargetIds.activityProgressPeriodPivot;
    yield ScreenTutorialTargetIds.activityProgressDiagramPivot;
    yield ScreenTutorialTargetIds.topicsTopicListViewport;
    yield ScreenTutorialTargetIds.practiceRemixSearchField;
    yield ScreenTutorialTargetIds.practiceRemixContinueCta;
    yield ScreenTutorialTargetIds.practiceRemixExerciseCount;
    yield ScreenTutorialTargetIds.practiceRemixClassGroupedList;
    yield ScreenTutorialTargetIds.practiceMachineListPivot;
    yield ScreenTutorialTargetIds.practicePlayerIntroStartPivot;
    yield ScreenTutorialTargetIds.learningQuizQuestionStem;
    yield ScreenTutorialTargetIds.learningQuizAnswerOptions;
    yield ScreenTutorialTargetIds.learningQuizSolutionLink;
  }

  static GlobalKey? keyFor(String? id) {
    if (id == null || id.isEmpty) return null;
    return switch (id) {
      ScreenTutorialTargetIds.mainBottomNav => mainBottomNav,
      ScreenTutorialTargetIds.mainAppBarTabs => mainAppBarTabs,
      ScreenTutorialTargetIds.mainAppBarTodayGoal => mainAppBarTodayGoal,
      ScreenTutorialTargetIds.mainAppBarSearch => mainAppBarSearch,
      ScreenTutorialTargetIds.mainAppBarNotifications =>
        mainAppBarNotifications,
      ScreenTutorialTargetIds.activityStatusDailyGoal =>
        activityStatusDailyGoalOnly,
      ScreenTutorialTargetIds.activityTopListBody => activityTopListBody,
      ScreenTutorialTargetIds.activityTopListCardCourse =>
        activityTopListCardCourseKey,
      ScreenTutorialTargetIds.activityTopListCardInstitution =>
        activityTopListCardInstitutionKey,
      ScreenTutorialTargetIds.activityTopListCardCity =>
        activityTopListCardCityKey,
      ScreenTutorialTargetIds.activityTopListCardCountry =>
        activityTopListCardCountryKey,
      ScreenTutorialTargetIds.activityAnswersBody => activityAnswersBody,
      ScreenTutorialTargetIds.activityProgressPeriodPivot =>
        activityProgressPeriodStrip,
      ScreenTutorialTargetIds.activityProgressDiagramPivot =>
        activityProgressChartHost,
      ScreenTutorialTargetIds.topicsTopicListViewport =>
        topicsTopicScrollViewport,
      ScreenTutorialTargetIds.practiceRemixSearchField =>
        practiceRemixSearchBar,
      ScreenTutorialTargetIds.practiceRemixContinueCta => practiceRemixContinue,
      ScreenTutorialTargetIds.practiceRemixExerciseCount =>
        practiceRemixExerciseCountSlider,
      ScreenTutorialTargetIds.practiceRemixClassGroupedList =>
        practiceRemixTopicsByClassViewport,
      ScreenTutorialTargetIds.practiceMachineListPivot =>
        practiceVsMachineListViewport,
      ScreenTutorialTargetIds.practicePlayerIntroStartPivot =>
        practiceVsPlayerIntroCta,
      ScreenTutorialTargetIds.learningQuizQuestionStem =>
        learningQuizQuestionStem,
      ScreenTutorialTargetIds.learningQuizAnswerOptions =>
        learningQuizAnswerOptions,
      ScreenTutorialTargetIds.learningQuizSolutionLink =>
        learningQuizSolutionLink,
      _ => null,
    };
  }

  /// Global bounds for cut‑out spotlight; expands [paddingPx] uniformly.
  static Rect? spotlightRect(GlobalKey marker, {double paddingPx = 9}) {
    final ctx = marker.currentContext;
    if (ctx == null) return null;
    final rb = ctx.findRenderObject();
    if (rb is! RenderBox || !rb.hasSize || !rb.attached) return null;
    final origin = rb.localToGlobal(Offset.zero);
    var r = Rect.fromLTWH(
      origin.dx,
      origin.dy,
      rb.size.width,
      rb.size.height,
    ).inflate(paddingPx);
    // Clamp to plausible screen-ish region (overlay uses full navigator box).
    r = Rect.fromLTRB(
      r.left.clamp(0, double.infinity),
      r.top.clamp(0, double.infinity),
      r.right,
      r.bottom,
    );
    return r;
  }

  static Rect? spotlightRectFromId(String? id, {double paddingPx = 9}) {
    final k = keyFor(id);
    if (k == null) return null;
    return spotlightRect(k, paddingPx: paddingPx);
  }
}
