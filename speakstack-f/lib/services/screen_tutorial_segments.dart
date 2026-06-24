import 'package:untitled2/services/screen_tutorial_service.dart';
import 'package:untitled2/ui_elements/screen_tutorial_targets.dart';

/// Short, on-demand replays (Profile → pick one). Auto tab tours stay unique.
abstract final class ScreenTutorialSegmentIds {
  static const chromeBottomNav = 'seg.chrome.bottom_nav';
  static const chromeSubTabs = 'seg.chrome.sub_tabs';
  static const chromeTodayGoal = 'seg.chrome.today_goal';
  static const chromeNotifications = 'seg.chrome.notifications';
  static const chromeSearch = 'seg.chrome.search';

  static const activityTopList = 'seg.activity.top_list';
  static const activityAnswers = 'seg.activity.answers';
  static const activityProgressPeriod = 'seg.activity.progress_period';
  static const activityProgressChart = 'seg.activity.progress_chart';

  static const topicsClassTabs = 'seg.topics.class_tabs';
  static const topicsList = 'seg.topics.list';
  static const topicsSearch = 'seg.topics.search';

  static const practiceRemixSearch = 'seg.practice.remix_search';
  static const practiceRemixClassTopics = 'seg.practice.remix_class_topics';
  static const practiceRemixContinue = 'seg.practice.remix_continue';
  static const practiceRemixExerciseCount = 'seg.practice.remix_exercise_count';
  static const practiceMachineList = 'seg.practice.machine_list';
  static const practicePlayerStart = 'seg.practice.player_start';
}

class ScreenTutorialSegmentOption {
  const ScreenTutorialSegmentOption({required this.id, required this.labelKey});

  final String id;
  final String labelKey;
}

abstract final class ScreenTutorialSegmentCatalog {
  /// When [includeChromeSegments] is false (e.g. header help icon), only the
  /// current tab’s body segments are listed. Full list (navigation + chrome)
  /// stays under Profile → About → Show tips.
  static List<ScreenTutorialSegmentOption> optionsFor(
    int mainIndex,
    int subIndex, {
    bool includeChromeSegments = true,
  }) {
    final out = <ScreenTutorialSegmentOption>[];

    void push(String id, String labelKey) {
      out.add(ScreenTutorialSegmentOption(id: id, labelKey: labelKey));
    }

    if (includeChromeSegments) {
      push(
        ScreenTutorialSegmentIds.chromeBottomNav,
        'screen-tutorial.segments.chrome_bottom_nav',
      );
      push(
        ScreenTutorialSegmentIds.chromeSubTabs,
        'screen-tutorial.segments.chrome_sub_tabs',
      );
      push(
        ScreenTutorialSegmentIds.chromeTodayGoal,
        'screen-tutorial.segments.chrome_today_goal',
      );
      push(
        ScreenTutorialSegmentIds.chromeNotifications,
        'screen-tutorial.segments.chrome_notifications',
      );

      if (mainIndex == 1) {
        push(
          ScreenTutorialSegmentIds.chromeSearch,
          'screen-tutorial.segments.chrome_search',
        );
      }
    }

    switch (mainIndex) {
      case 0:
        switch (subIndex) {
          case 0:
            break;
          case 1:
            push(
              ScreenTutorialSegmentIds.activityTopList,
              'screen-tutorial.segments.activity_top_list',
            );
            break;
          case 2:
            push(
              ScreenTutorialSegmentIds.activityAnswers,
              'screen-tutorial.segments.activity_answers',
            );
            break;
          case 3:
            push(
              ScreenTutorialSegmentIds.activityProgressPeriod,
              'screen-tutorial.segments.activity_progress_period',
            );
            push(
              ScreenTutorialSegmentIds.activityProgressChart,
              'screen-tutorial.segments.activity_progress_chart',
            );
            break;
        }
        break;
      case 1:
        push(
          ScreenTutorialSegmentIds.topicsClassTabs,
          'screen-tutorial.segments.topics_class_tabs',
        );
        push(
          ScreenTutorialSegmentIds.topicsList,
          'screen-tutorial.segments.topics_list',
        );
        push(
          ScreenTutorialSegmentIds.topicsSearch,
          'screen-tutorial.segments.topics_search',
        );
        break;
      case 2:
        switch (subIndex) {
          case 0:
            push(
              ScreenTutorialSegmentIds.practiceRemixClassTopics,
              'screen-tutorial.segments.practice_remix_class_topics',
            );
            push(
              ScreenTutorialSegmentIds.practiceRemixSearch,
              'screen-tutorial.segments.practice_remix_search',
            );
            push(
              ScreenTutorialSegmentIds.practiceRemixContinue,
              'screen-tutorial.segments.practice_remix_continue',
            );
            push(
              ScreenTutorialSegmentIds.practiceRemixExerciseCount,
              'screen-tutorial.segments.practice_remix_exercise_count',
            );
            break;
          case 1:
            push(
              ScreenTutorialSegmentIds.practiceMachineList,
              'screen-tutorial.segments.practice_machine_list',
            );
            break;
          case 2:
            push(
              ScreenTutorialSegmentIds.practicePlayerStart,
              'screen-tutorial.segments.practice_player_start',
            );
            break;
        }
        break;
    }

    return out;
  }

  static List<ScreenTutorialStep> stepsFor(String segmentId) {
    return List<ScreenTutorialStep>.from(
      _segmentSteps[segmentId] ?? const <ScreenTutorialStep>[],
    );
  }
}

final Map<String, List<ScreenTutorialStep>> _segmentSteps = {
  ScreenTutorialSegmentIds.chromeBottomNav: [
    ScreenTutorialStep(
      titleKey: 'screen-tutorial.shared_app_chrome.bottom_nav.title',
      bodyKey: 'screen-tutorial.shared_app_chrome.bottom_nav.body',
      targetId: ScreenTutorialTargetIds.mainBottomNav,
    ),
  ],
  ScreenTutorialSegmentIds.chromeSubTabs: [
    ScreenTutorialStep(
      titleKey: 'screen-tutorial.shared_app_chrome.sub_tabs.title',
      bodyKey: 'screen-tutorial.shared_app_chrome.sub_tabs.body',
      targetId: ScreenTutorialTargetIds.mainAppBarTabs,
    ),
  ],
  ScreenTutorialSegmentIds.chromeTodayGoal: [
    ScreenTutorialStep(
      titleKey: 'screen-tutorial.shared_app_chrome.today_goal.title',
      bodyKey: 'screen-tutorial.shared_app_chrome.today_goal.body',
      targetId: ScreenTutorialTargetIds.mainAppBarTodayGoal,
    ),
  ],
  ScreenTutorialSegmentIds.chromeNotifications: [
    ScreenTutorialStep(
      titleKey: 'screen-tutorial.shared_app_chrome.notifications.title',
      bodyKey: 'screen-tutorial.shared_app_chrome.notifications.body',
      targetId: ScreenTutorialTargetIds.mainAppBarNotifications,
    ),
  ],
  ScreenTutorialSegmentIds.chromeSearch: [
    ScreenTutorialStep(
      titleKey: 'screen-tutorial.topics_browse.s3_title',
      bodyKey: 'screen-tutorial.topics_browse.s3_body',
      targetId: ScreenTutorialTargetIds.mainAppBarSearch,
    ),
  ],
  ScreenTutorialSegmentIds.activityTopList: [
    ScreenTutorialStep(
      titleKey: 'screen-tutorial.activity_top_list.complete_title',
      bodyKey: 'screen-tutorial.activity_top_list.complete_body',
      targetId: ScreenTutorialTargetIds.activityTopListBody,
    ),
  ],
  ScreenTutorialSegmentIds.activityAnswers: [
    ScreenTutorialStep(
      titleKey: 'screen-tutorial.activity_answers.s4_title',
      bodyKey: 'screen-tutorial.activity_answers.s4_body',
      targetId: ScreenTutorialTargetIds.activityAnswersBody,
    ),
  ],
  ScreenTutorialSegmentIds.activityProgressPeriod: [
    ScreenTutorialStep(
      titleKey: 'screen-tutorial.activity_progress.s3_title',
      bodyKey: 'screen-tutorial.activity_progress.s3_body',
      targetId: ScreenTutorialTargetIds.activityProgressPeriodPivot,
    ),
  ],
  ScreenTutorialSegmentIds.activityProgressChart: [
    ScreenTutorialStep(
      titleKey: 'screen-tutorial.activity_progress.s4_title',
      bodyKey: 'screen-tutorial.activity_progress.s4_body',
      targetId: ScreenTutorialTargetIds.activityProgressDiagramPivot,
    ),
  ],
  ScreenTutorialSegmentIds.topicsClassTabs: [
    ScreenTutorialStep(
      titleKey: 'screen-tutorial.topics_browse.s2_title',
      bodyKey: 'screen-tutorial.topics_browse.s2_body',
      targetId: ScreenTutorialTargetIds.mainAppBarTabs,
    ),
  ],
  ScreenTutorialSegmentIds.topicsList: [
    ScreenTutorialStep(
      titleKey: 'screen-tutorial.topics_browse.s5_title',
      bodyKey: 'screen-tutorial.topics_browse.s5_body',
      targetId: ScreenTutorialTargetIds.topicsTopicListViewport,
    ),
  ],
  ScreenTutorialSegmentIds.topicsSearch: [
    ScreenTutorialStep(
      titleKey: 'screen-tutorial.topics_browse.s3_title',
      bodyKey: 'screen-tutorial.topics_browse.s3_body',
      targetId: ScreenTutorialTargetIds.mainAppBarSearch,
    ),
  ],
  ScreenTutorialSegmentIds.practiceRemixSearch: [
    ScreenTutorialStep(
      titleKey: 'screen-tutorial.practice_remix.s3_title',
      bodyKey: 'screen-tutorial.practice_remix.s3_body',
      targetId: ScreenTutorialTargetIds.practiceRemixSearchField,
    ),
  ],
  ScreenTutorialSegmentIds.practiceRemixClassTopics: [
    ScreenTutorialStep(
      titleKey: 'screen-tutorial.practice_remix.s5_title',
      bodyKey: 'screen-tutorial.practice_remix.s5_body',
      targetId: ScreenTutorialTargetIds.practiceRemixClassGroupedList,
    ),
  ],
  ScreenTutorialSegmentIds.practiceRemixContinue: [
    ScreenTutorialStep(
      titleKey: 'screen-tutorial.practice_remix.s4_title',
      bodyKey: 'screen-tutorial.practice_remix.s4_body',
      targetId: ScreenTutorialTargetIds.practiceRemixContinueCta,
    ),
  ],
  ScreenTutorialSegmentIds.practiceRemixExerciseCount: [
    ScreenTutorialStep(
      titleKey: 'screen-tutorial.practice_remix_configure.s1_title',
      bodyKey: 'screen-tutorial.practice_remix_configure.s1_body',
      targetId: ScreenTutorialTargetIds.practiceRemixExerciseCount,
    ),
  ],
  ScreenTutorialSegmentIds.practiceMachineList: [
    ScreenTutorialStep(
      titleKey: 'screen-tutorial.practice_vs_machine.s3_title',
      bodyKey: 'screen-tutorial.practice_vs_machine.s3_body',
      targetId: ScreenTutorialTargetIds.practiceMachineListPivot,
    ),
  ],
  ScreenTutorialSegmentIds.practicePlayerStart: [
    ScreenTutorialStep(
      titleKey: 'screen-tutorial.practice_vs_player.s3_title',
      bodyKey: 'screen-tutorial.practice_vs_player.s3_body',
      targetId: ScreenTutorialTargetIds.practicePlayerIntroStartPivot,
    ),
  ],
};
