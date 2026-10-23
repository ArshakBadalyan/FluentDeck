import 'package:fluentdeck/ui_elements/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:fluentdeck/localization/app_localizations.dart';
import 'package:fluentdeck/services/main_navigation_coordinator.dart';
import 'package:fluentdeck/services/main_tab_config.dart';

void showSpeakingPremiumSnackBar(BuildContext context) {
  showPremiumUpgradeSnackBar(
    context,
    AppLocalizations.instance.t('speaking-premium.locked-message'),
  );
}

void showPremiumUpgradeSnackBar(BuildContext context, String message) {
  AppToast.dismissAll();
  AppToast.showSnackBar(
    context,
    SnackBar(
      content: Text(message),
      showCloseIcon: true,
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
