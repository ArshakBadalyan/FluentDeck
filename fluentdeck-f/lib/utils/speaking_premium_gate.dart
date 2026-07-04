import 'package:flutter/material.dart';
import 'package:fluentdeck/localization/app_localizations.dart';
import 'package:fluentdeck/services/main_navigation_coordinator.dart';
import 'package:fluentdeck/services/main_tab_config.dart';

void showSpeakingPremiumSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        AppLocalizations.instance.t('speaking-premium.locked-message'),
      ),
      action: SnackBarAction(
        label: 'Upgrade',
        onPressed: () {
          MainNavigationCoordinator.goToTab(
            MainTabId.profile,
            subIndex: kProfileSubscriptionTabIndex,
          );
        },
      ),
    ),
  );
}

T? firstUnlocked<T>(Iterable<T> items, bool Function(T) isLocked) {
  for (final item in items) {
    if (!isLocked(item)) return item;
  }
  return null;
}
