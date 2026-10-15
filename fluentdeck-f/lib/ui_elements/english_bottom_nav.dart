import 'package:fluentdeck/ui_elements/screen_tutorial_targets.dart';
import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/services/analytics_service.dart';
import 'package:fluentdeck/services/click_tracking.dart';
import 'package:fluentdeck/services/interaction_haptics.dart';
import 'package:fluentdeck/services/main_tab_config.dart';

class EnglishBottomNav extends StatelessWidget {
  const EnglishBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final tabs = MainTabConfig.definitions;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.black.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: BottomNavigationBar(
        key: ScreenTutorialKeys.mainBottomNav,
        backgroundColor: Colors.white,
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
        selectedItemColor: AppColors.brandPrimary,
        unselectedItemColor: AppColors.navInactive,
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
