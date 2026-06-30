import 'package:flutter/material.dart';
import 'package:fluentdeck/localization/app_localizations.dart';

void showSpeakingPremiumSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        AppLocalizations.instance.t('speaking-premium.locked-message'),
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
