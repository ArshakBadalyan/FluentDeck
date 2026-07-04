import 'package:fluentdeck/services/main_tab_config.dart';

/// Index of the "Subscription" tab within Profile's sub-tabs
/// (Account, Settings, Subscription, Notifications, Sound, Security, About).
/// Keep in sync with `_profileSubTabs` in `EnglishMainScreenState`.
const int kProfileSubscriptionTabIndex = 2;

/// Registered by [EnglishMainScreenState] so pushed routes can switch tabs.
class MainNavigationCoordinator {
  MainNavigationCoordinator._();

  static void Function(int index, {int? subIndex})? navigateToMainTab;

  static void goToMainTab(int index, {int? subIndex}) {
    navigateToMainTab?.call(index, subIndex: subIndex);
  }

  static void goToTab(MainTabId tab, {int? subIndex}) {
    goToMainTab(MainTabConfig.indexOf(tab), subIndex: subIndex);
  }
}
