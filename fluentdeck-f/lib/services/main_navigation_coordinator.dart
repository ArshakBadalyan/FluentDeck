import 'package:fluentdeck/services/main_tab_config.dart';

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
