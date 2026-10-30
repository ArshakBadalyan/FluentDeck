import 'package:fluentdeck/ui_elements/riovox_wordmark.dart';
import 'package:fluentdeck/ui_elements/screen_tutorial_targets.dart';
import 'package:flutter/material.dart';
import 'package:fluentdeck/services/analytics_service.dart';
import 'package:fluentdeck/services/click_tracking.dart';
import 'package:fluentdeck/services/flashcard_service.dart';
import 'package:fluentdeck/services/user_progress_service.dart';
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
                    ? AppPageColors.tintOf(context, AppTint.teal).bg
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

/// Wide screens: the main tabs as a left side menu (icon + label rows), with
/// the app name on top, cards due on Decks, and the streak at the bottom.
/// Same tabs and taps as [EnglishBottomNav].
class EnglishSideNav extends StatefulWidget {
  const EnglishSideNav({super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  State<EnglishSideNav> createState() => _EnglishSideNavState();
}

class _EnglishSideNavState extends State<EnglishSideNav> {
  int? _due;
  int? _streak;

  int get currentIndex => widget.currentIndex;
  ValueChanged<int> get onTap => widget.onTap;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void didUpdateWidget(EnglishSideNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reviews and conversations happen on the tabs; refresh on each switch.
    if (oldWidget.currentIndex != widget.currentIndex) _refresh();
  }

  Future<void> _refresh() async {
    int? due;
    int? streak;
    try {
      final decks = await FlashcardService.instance.fetchDecksWithCache();
      // Parent decks already include their sub-decks' cards.
      due = decks
          .where((d) => d.parentDeckId == null && !d.isFiltered)
          .fold<int>(0, (sum, d) => sum + d.reviewDueCount + d.learningCount);
    } catch (_) {}
    try {
      streak = (await UserProgressService.instance.fetchForCurrentUser())?.streakDays;
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _due = due;
      _streak = streak;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = MainTabConfig.definitionsFor(context);
    final selected = currentIndex.clamp(0, tabs.length - 1);
    final accent = AppPageColors.accentOf(context);
    return SafeArea(
      right: false,
      child: Container(
        key: ScreenTutorialKeys.mainBottomNav,
        width: 232,
        margin: const EdgeInsets.fromLTRB(16, 16, 0, 16),
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
        decoration: BoxDecoration(
          color: AppPageColors.cardBgOf(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppPageColors.subtleBorderOf(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: RiovoxWordmark(height: 26),
              ),
            ),
            for (var i = 0; i < tabs.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Material(
                  color: i == selected ? AppPageColors.tintOf(context, AppTint.teal).bg : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      InteractionHaptics.pulse();
                      ClickTracker.recordNamedTap();
                      AnalyticsService.instance.logTap(
                        targetId: 'side_nav.english.${tabs[i].id.name}',
                        extra: {'main_index': i, 'main_tab': tabs[i].id.name},
                      );
                      onTap(i);
                    },
                    child: Semantics(
                      button: true,
                      selected: i == selected,
                      child: SizedBox(
                        height: 48,
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: FittedBox(child: tabs[i].iconBuilder(i == selected)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                tabs[i].navLabel,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: i == selected ? FontWeight.w700 : FontWeight.w500,
                                  color: i == selected ? accent : AppPageColors.subtitleOf(context),
                                ),
                              ),
                            ),
                            if (tabs[i].id == MainTabId.decks && (_due ?? 0) > 0) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppPageColors.tintOf(context, AppTint.voice).bg,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  _due! > 99 ? '99+' : '$_due',
                                  semanticsLabel: '$_due cards due',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppPageColors.tintOf(context, AppTint.voice).fg,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            const Spacer(),
            if ((_streak ?? 0) > 0) _StreakCard(days: _streak!),
          ],
        ),
      ),
    );
  }
}

/// Soft-yellow streak note at the foot of the side menu.
class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final tint = AppPageColors.tintOf(context, AppTint.reward);
    // Material: the side menu has none above it, so text would fall back to
    // the debug style (huge, double-underlined).
    return Material(
      color: tint.bg,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_fire_department_rounded, size: 18, color: AppPageColors.tintIconOf(context, AppTint.reward)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$days-day streak',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: tint.fg),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Practice today to keep it going.',
            style: TextStyle(fontSize: 13, color: AppPageColors.subtitleOf(context)),
          ),
        ],
      ),
      ),
    );
  }
}
