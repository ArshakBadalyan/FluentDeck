import 'dart:async';

import 'package:untitled2/services/analytics_service.dart';

/// GA4-oriented events for Ads / Firebase Analytics.
///
/// **Auth (recommended GA4 events)**
/// - [logLogin] → `login` (param `method`, e.g. `email`)
/// - [logSignUp] → `sign_up` (param `method`: `password` | `nickname`)
///
/// **Navigation (custom)**
/// - [logViewMainSection] → `view_main_section` (`section`, `main_index`)
/// - [logViewSubTab] → `view_sub_tab` (`section`, `sub_index`, `sub_tab_key`,
///   optional `category_class_id` for Themen)
///
/// **Categories (custom)**
/// - [logCategoryOpen] → `view_category` (`category_id`, `category_class_id`, `entry`)
class CampaignAnalytics {
  CampaignAnalytics._();

  static const sectionActivity = 'activity';
  static const sectionTopics = 'topics';
  static const sectionPractice = 'practice';
  static const sectionProfile = 'profile';
  static const sectionAdminStatistics = 'admin_statistics';
  static const sectionTeacherClasses = 'teacher_classes';

  static List<String> _mainSectionOrder({
    bool isAdmin = false,
    bool showTeacherClasses = false,
  }) {
    return [
      sectionActivity,
      sectionTopics,
      sectionPractice,
      if (showTeacherClasses) sectionTeacherClasses,
      if (isAdmin) sectionAdminStatistics,
      sectionProfile,
    ];
  }

  static String mainSectionKey(
    int mainIndex, {
    bool isAdmin = false,
    bool showTeacherClasses = false,
  }) {
    final order = _mainSectionOrder(
      isAdmin: isAdmin,
      showTeacherClasses: showTeacherClasses,
    );
    if (mainIndex >= 0 && mainIndex < order.length) {
      return order[mainIndex];
    }
    return 'unknown';
  }

  /// Semantic sub-tab ids (stable for reporting; not localized labels).
  static String activitySubTabKey(int subIndex) {
    const keys = <String>[
      'status',
      'top_list',
      'answers',
      'progress',
    ];
    return subIndex >= 0 && subIndex < keys.length
        ? keys[subIndex]
        : 'activity_$subIndex';
  }

  static String practiceSubTabKey(int subIndex) {
    const keys = <String>['vs_machine', 'vs_friend'];
    return subIndex >= 0 && subIndex < keys.length
        ? keys[subIndex]
        : 'practice_$subIndex';
  }

  static String profileSubTabKey(int subIndex) {
    const keys = <String>[
      'account',
      'notifications',
      'security',
      'about',
      'share',
      'sound',
    ];
    return subIndex >= 0 && subIndex < keys.length
        ? keys[subIndex]
        : 'profile_$subIndex';
  }

  /// [categoryClassId] required for topics section sub-tabs.
  static String topicsSubTabKey(int subIndex, int? categoryClassId) {
    if (categoryClassId != null) {
      return 'class_$categoryClassId';
    }
    return 'topics_$subIndex';
  }

  static Future<void> logLogin({required String method}) {
    return AnalyticsService.instance.logLoginEvent(method: method);
  }

  /// [method] `password` = email+password registration; `nickname` = without password.
  static Future<void> logSignUp({required String method}) {
    return AnalyticsService.instance.logSignUpEvent(method: method);
  }

  static void logViewMainSection({
    required String section,
    required int mainIndex,
  }) {
    unawaited(
      AnalyticsService.instance.logEvent(
        'view_main_section',
        parameters: <String, Object>{
          'section': section,
          'main_index': mainIndex,
        },
      ),
    );
  }

  static void logViewSubTab({
    required String section,
    required int subIndex,
    required String subTabKey,
    int? categoryClassId,
  }) {
    final params = <String, Object>{
      'section': section,
      'sub_index': subIndex,
      'sub_tab_key': subTabKey,
    };
    if (categoryClassId != null) {
      params['category_class_id'] = categoryClassId;
    }
    unawaited(
      AnalyticsService.instance.logEvent('view_sub_tab', parameters: params),
    );
  }

  /// User opened a topic category (by Strapi category id).
  static void logCategoryOpen({
    required int categoryId,
    int? categoryClassId,
    required String entry,
  }) {
    final params = <String, Object>{
      'category_id': categoryId,
      'entry': entry,
    };
    if (categoryClassId != null) {
      params['category_class_id'] = categoryClassId;
    }
    unawaited(
      AnalyticsService.instance.logEvent('view_category', parameters: params),
    );
  }

  static String subTabKeyFor({
    required int mainIndex,
    required int subIndex,
    int? categoryClassId,
    bool isAdmin = false,
    bool showTeacherClasses = false,
  }) {
    final section = mainSectionKey(
      mainIndex,
      isAdmin: isAdmin,
      showTeacherClasses: showTeacherClasses,
    );
    switch (section) {
      case sectionActivity:
        return activitySubTabKey(subIndex);
      case sectionTopics:
        return topicsSubTabKey(subIndex, categoryClassId);
      case sectionPractice:
        return practiceSubTabKey(subIndex);
      case sectionAdminStatistics:
        return 'overview';
      case sectionProfile:
        return profileSubTabKey(subIndex);
      default:
        return 'unknown_$subIndex';
    }
  }

  /// Logs main bottom-nav section and current sub-tab in one place.
  static void logMainAndSubTab({
    required int mainIndex,
    required int subIndex,
    int? categoryClassId,
    bool isAdmin = false,
    bool showTeacherClasses = false,
  }) {
    final section = mainSectionKey(
      mainIndex,
      isAdmin: isAdmin,
      showTeacherClasses: showTeacherClasses,
    );
    final cc = section == sectionTopics ? categoryClassId : null;
    final subKey = subTabKeyFor(
      mainIndex: mainIndex,
      subIndex: subIndex,
      categoryClassId: cc,
      isAdmin: isAdmin,
      showTeacherClasses: showTeacherClasses,
    );
    logViewMainSection(section: section, mainIndex: mainIndex);
    logViewSubTab(
      section: section,
      subIndex: subIndex,
      subTabKey: subKey,
      categoryClassId: cc,
    );
    final path = '/main/$section/$subKey';
    unawaited(
      AnalyticsService.instance.logScreenView(
        path,
        screenClass: 'MainShell',
      ),
    );
  }
}
