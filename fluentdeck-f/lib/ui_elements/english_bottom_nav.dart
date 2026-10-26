import 'package:fluentdeck/ui_elements/screen_tutorial_targets.dart';
import 'package:flutter/material.dart';
import 'package:fluentdeck/services/analytics_service.dart';
import 'package:fluentdeck/services/click_tracking.dart';
import 'package:fluentdeck/services/interaction_haptics.dart';
import 'package:fluentdeck/services/main_tab_config.dart';
import 'package:fluentdeck/ui_elements/app_motion.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = currentIndex.clamp(0, tabs.length - 1);

    // Floating rounded bar over the page background (Lagoon Daylight). The
    // shadow deepens while content is scrolled underneath it.
    return ColoredBox(
      color: AppPageColors.pageBgOf(context),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: AnimatedContainer(
            key: ScreenTutorialKeys.mainBottomNav,
            duration: AppMotion.duration(context, AppMotion.fast),
            height: 66,
            decoration: BoxDecoration(
              color: AppPageColors.cardBgOf(context),
              borderRadius: BorderRadius.circular(24),
              border: isDark
                  ? Border.all(color: AppPageColors.subtleBorderOf(context))
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isDark ? 0.4 : (showShadow ? 0.14 : 0.08),
                  ),
                  blurRadius: showShadow ? 24 : 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(
                    child: _NavItem(
                      label: tabs[i].navLabel,
                      selected: selected == i,
                      icon: tabs[i].iconBuilder(selected == i),
                      onTap: () {
                        InteractionHaptics.pulse();
                        ClickTracker.recordNamedTap();
                        AnalyticsService.instance.logTap(
                          targetId: 'bottom_nav.english.${tabs[i].id.name}',
                          extra: {
                            'main_index': i,
                            'main_tab': tabs[i].id.name,
                          },
                        );
                        onTap(i);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One destination: icon over label; the selected one gets a soft teal pill
/// behind its icon and a bolder label.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppPageColors.accentOf(context);
    final duration = AppMotion.duration(context, AppMotion.normal);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        highlightShape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: duration,
              curve: AppMotion.standardCurve,
              width: selected ? 56 : 40,
              height: 30,
              decoration: BoxDecoration(
                color: selected
                    ? accent.withValues(alpha: 0.14)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: AnimatedScale(
                scale: selected ? 1.06 : 1,
                duration: duration,
                curve: AppMotion.spring,
                child: SizedBox(width: 24, height: 24, child: FittedBox(child: icon)),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? accent : AppPageColors.subtitleOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
