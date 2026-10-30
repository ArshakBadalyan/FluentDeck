import 'package:riovox/services/main_tab_config.dart';

/// Index of the "Settings" tab within Profile's sub-tabs
/// (Account, Settings, Subscription, Security, About).
/// Notifications and Sound are pages opened from Settings.
/// Keep in sync with `_profileSubTabs` in `EnglishMainScreenState`.
const int kProfileSettingsTabIndex = 1;

/// Index of the "Subscription" tab within Profile's sub-tabs
/// (Account, Settings, Subscription, Security, About).
/// Keep in sync with `_profileSubTabs` in `EnglishMainScreenState`.
const int kProfileSubscriptionTabIndex = 2;

/// Registered by [EnglishMainScreenState] so pushed routes can switch tabs.
class MainNavigationCoordinator {
  MainNavigationCoordinator._();

  static void Function(int index, {int? subIndex})? navigateToMainTab;

  /// Opens the Speak chat UI for a session already loaded into ConversationService.
  static void Function()? enterSpeakChatSession;

  static void goToMainTab(int index, {int? subIndex}) {
    navigateToMainTab?.call(index, subIndex: subIndex);
  }

  static void goToTab(MainTabId tab, {int? subIndex}) {
    goToMainTab(MainTabConfig.indexOf(tab), subIndex: subIndex);
  }

  static void enterSpeakSession() {
    enterSpeakChatSession?.call();
  }

  /// Switches the Today tab to one of its sub-tabs by id ('topics', 'roleplay', …).
  static void Function(String id)? openSpeakSubTab;

  static void goToSpeakSubTab(String id) {
    openSpeakSubTab?.call(id);
  }
}
