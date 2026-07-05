import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

  static const defaultOrder = [
    MainTabId.activity,
    MainTabId.decks,
    MainTabId.speak,
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

  static Color _iconColor(bool active) =>
      active ? const Color(0xFF8419FF) : const Color(0xFF777481);

  static MainTabDefinition definition(MainTabId id) {
    switch (id) {
      case MainTabId.speak:
        return MainTabDefinition(
          id: id,
          title: 'Speak',
          navLabel: 'Speak',
          iconBuilder:
              (active) => Icon(Icons.mic, color: _iconColor(active)),
        );
      case MainTabId.decks:
        return MainTabDefinition(
          id: id,
          title: 'Decks',
          navLabel: 'Decks',
          iconBuilder:
              (active) =>
                  Icon(Icons.style_outlined, color: _iconColor(active)),
        );
      case MainTabId.activity:
        return MainTabDefinition(
          id: id,
          title: AppLocalizations.instance.t('activity.Activity'),
          navLabel: AppLocalizations.instance.t('activity.Activity'),
          iconBuilder:
              (active) => SvgPicture.asset(
                'assets/buttons/activity.svg',
                width: 26,
                colorFilter: ColorFilter.mode(
                  _iconColor(active),
                  BlendMode.srcIn,
                ),
              ),
        );
      case MainTabId.profile:
        return MainTabDefinition(
          id: id,
          title: AppLocalizations.instance.t('profile.profile'),
          navLabel: AppLocalizations.instance.t('profile.profile'),
          iconBuilder:
              (active) => SvgPicture.asset(
                'assets/buttons/profile.svg',
                width: 26,
                colorFilter: ColorFilter.mode(
                  _iconColor(active),
                  BlendMode.srcIn,
                ),
              ),
        );
    }
  }

  static List<MainTabDefinition> get definitions =>
      order.map(definition).toList();
}
