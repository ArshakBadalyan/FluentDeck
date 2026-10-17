import 'package:fluentdeck/ui_elements/screen_tutorial_targets.dart';
import 'package:flutter/material.dart';
import 'package:fluentdeck/services/analytics_service.dart';
import 'package:fluentdeck/services/click_tracking.dart';
import 'package:fluentdeck/services/interaction_haptics.dart';
import 'package:fluentdeck/services/main_tab_config.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';

class EnglishBottomNav extends StatelessWidget {
  const EnglishBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.showShadow = false,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  /// True while the current tab's content is scrolled away from its
  /// bottom edge — shows a shadow above the bar to hint there's more
  /// content below, mirroring the top app bar's own scrolled-under shadow.
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final tabs = MainTabConfig.definitionsFor(context);

    final navBg = AppPageColors.cardBgOf(context);
    return Container(
      decoration: BoxDecoration(
        color: navBg,
        border: Border(
          top: BorderSide(
            color: AppPageColors.subtleBorderOf(context),
            width: 0.5,
          ),
        ),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ]
            : null,
      ),
      child: BottomNavigationBar(
        key: ScreenTutorialKeys.mainBottomNav,
        backgroundColor: navBg,
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex.clamp(0, tabs.length - 1),
        onTap: (index) {
          InteractionHaptics.pulse();
          ClickTracker.recordNamedTap();
          AnalyticsService.instance.logTap(
            targetId: 'bottom_nav.english.${tabs[index].id.name}',
            extra: {
              'main_index': index,
              'main_tab': tabs[index].id.name,
            },
          );
          onTap(index);
        },
        showUnselectedLabels: true,
        selectedItemColor: AppPageColors.accentOf(context),
        unselectedItemColor: AppPageColors.subtitleOf(context),
        elevation: 0,
        items: [
          for (var i = 0; i < tabs.length; i++)
            BottomNavigationBarItem(
              icon: tabs[i].iconBuilder(currentIndex == i),
              label: tabs[i].navLabel,
            ),
        ],
      ),
    );
  }
}
