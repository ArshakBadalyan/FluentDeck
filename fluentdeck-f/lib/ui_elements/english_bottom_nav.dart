import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
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
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final tabs = MainTabConfig.definitions;
    final surface = AppPageColors.cardBgOf(context);
    final border = AppPageColors.subtleBorderOf(context);
    final unselected = AppPageColors.subtitleOf(context);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border(
          top: BorderSide(color: border, width: 0.5),
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: surface,
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
        selectedItemColor: AppColors.primaryPurple,
        unselectedItemColor: unselected,
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
