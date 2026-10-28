import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/config/brand_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluentdeck/localization/app_localizations.dart';

enum MainTabId {
  activity,
  decks,
  speak,
  profile;

  static MainTabId? tryParse(String raw) {
    final key = raw.trim().toLowerCase();
    for (final tab in MainTabId.values) {
      if (tab.name == key) return tab;
    }
    return null;
  }
}

class MainTabDefinition {
  const MainTabDefinition({
    required this.id,
    required this.title,
    required this.navLabel,
    required this.iconBuilder,
  });

  final MainTabId id;
  final String title;
  final String navLabel;
  final Widget Function(bool active) iconBuilder;
}

class MainTabConfig {
  MainTabConfig._();

  /// Today, Decks, Progress, Profile (Riovox App Redesign).
  static const defaultOrder = [
    MainTabId.speak,
    MainTabId.decks,
    MainTabId.activity,
    MainTabId.profile,
  ];

  static List<MainTabId>? _order;

  static List<MainTabId> get order {
    _order ??= _parseOrder();
    return _order!;
  }

  static int get tabCount => order.length;

  static int indexOf(MainTabId id) => order.indexOf(id);

  static MainTabId tabAt(int index) {
    if (index < 0 || index >= order.length) {
      return order.first;
    }
    return order[index];
  }

  static bool isTab(int index, MainTabId id) => tabAt(index) == id;

  static List<MainTabId> _parseOrder() {
    final raw = dotenv.env['MAIN_TAB_ORDER']?.trim();
    if (raw == null || raw.isEmpty) {
      return List<MainTabId>.from(defaultOrder);
    }

    final parsed = <MainTabId>[];
    for (final part in raw.split(',')) {
      final id = MainTabId.tryParse(part);
      if (id != null && !parsed.contains(id)) {
        parsed.add(id);
      }
    }

    if (parsed.length != defaultOrder.length) {
      return List<MainTabId>.from(defaultOrder);
    }
    return parsed;
  }

  // `context` is only available when a widget actually needs to paint these
  // icons (English bottom nav); callers that just want e.g. a tab's title
  // (english_main_screen.dart) don't have one and don't need icon color, so
  // this falls back to the light-mode color rather than requiring context
  // everywhere `MainTabDefinition` is touched.
  static Color _iconColor(bool active, BuildContext? context) {
    final isDark = context != null &&
        Theme.of(context).brightness == Brightness.dark;
    if (active) {
      return isDark ? AppColors.brandPrimaryOnDark : AppColors.brandPrimary;
    }
    return isDark ? BrandConfig.darkTextSecondary : AppColors.navInactive;
  }

  static MainTabDefinition definition(MainTabId id, [BuildContext? context]) {
    switch (id) {
      case MainTabId.speak:
        return MainTabDefinition(
          id: id,
          // The speaking hub is the home tab: today's practice and the
          // start button come first.
          title: 'Today',
          navLabel: 'Today',
          iconBuilder:
              (active) => Icon(
                active ? Icons.home_rounded : Icons.home_outlined,
                color: _iconColor(active, context),
              ),
        );
      case MainTabId.decks:
        return MainTabDefinition(
          id: id,
          title: 'Decks',
          navLabel: 'Decks',
          iconBuilder:
              (active) => Icon(
                Icons.filter_none_rounded,
                color: _iconColor(active, context),
              ),
        );
      case MainTabId.activity:
        return MainTabDefinition(
          id: id,
          title: AppLocalizations.instance.t('activity.tabs.Progress'),
          navLabel: AppLocalizations.instance.t('activity.tabs.Progress'),
          iconBuilder:
              (active) => Icon(
                Icons.bar_chart_rounded,
                color: _iconColor(active, context),
              ),
        );
      case MainTabId.profile:
        return MainTabDefinition(
          id: id,
          title: AppLocalizations.instance.t('profile.profile'),
          navLabel: AppLocalizations.instance.t('profile.profile'),
          iconBuilder:
              (active) => Icon(
                active ? Icons.person_rounded : Icons.person_outline_rounded,
                color: _iconColor(active, context),
              ),
        );
    }
  }

  static List<MainTabDefinition> get definitions =>
      order.map((id) => definition(id)).toList();

  static List<MainTabDefinition> definitionsFor(BuildContext context) =>
      order.map((id) => definition(id, context)).toList();
}
