import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:riovox/localization/app_localizations.dart';

import 'modern_page_widgets.dart';
import 'screen_tutorial_targets.dart';
import 'package:riovox/ui_elements/notification_bell.dart';
import 'package:riovox/ui_elements/app_circle_icon_button.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Tab>? tabs;
  final TabController? controller;
  final VoidCallback? onSearchTap;

  /// Opens the “Explain one part” segment picker (main shell only).
  final VoidCallback? onExplainOnePartTap;

  /// Student homework launcher (Topics tab).
  final VoidCallback? onConversationHistoryTap;
  final VoidCallback? onNewConversationTap;
  final VoidCallback? onDecksSettingsTap;

  /// Optional widget pinned to the right end of the sub-tab row (e.g. help).
  final Widget? tabBarTrailing;

  /// Optional action shown just left of the notifications bell (e.g. help).
  final Widget? helpAction;

  /// Optional action shown to the right of the bell (e.g. log out on Profile).
  final Widget? trailingAction;

  /// True when another colored header (e.g. the Speak tab's in-session chat
  /// header) sits directly beneath this bar with no light content between
  /// them — the shadow would just smear across that header instead of
  /// separating it from the page, so it's suppressed in that case.
  final bool suppressShadow;

  const MainAppBar({
    super.key,
    required this.title,
    this.tabs,
    this.controller,
    this.onSearchTap,
    this.onExplainOnePartTap,
    this.onConversationHistoryTap,
    this.onNewConversationTap,
    this.onDecksSettingsTap,
    this.tabBarTrailing,
    this.helpAction,
    this.trailingAction,
    this.suppressShadow = false,
  });

  static const double _toolbarHeight = 56.0;

  @override
  Widget build(BuildContext context) {
    // On the very first frame (web especially, but seen elsewhere too), the
    // engine can hand this AppBar a degenerate ~0x0 size before the real
    // viewport syncs in. AppBar's own internals lay out title/actions/bottom
    // as separate Row/Column children (NavigationToolbar for the toolbar,
    // a spaceBetween Column when `bottom` is set) — any of them can throw a
    // RenderFlex overflow when squeezed to ~0 logical pixels, not just one.
    // Rather than patch each internal Flex individually, render nothing but
    // an empty bar for that one frame: with no title/actions/leading/bottom,
    // AppBar has no multi-child Flex to lay out, so nothing can overflow.
    // MediaQuery.sizeOf makes this rebuild automatically once a real size
    // arrives, a frame or two later, with no visible flicker.
    final viewSize = MediaQuery.sizeOf(context);
    final hasValidSize = viewSize.width > 1 && viewSize.height > 1;

    if (!hasValidSize) {
      return AppBar(
        elevation: 0,
        backgroundColor: AppPageColors.pageBgOf(context),
        toolbarHeight: _toolbarHeight,
      );
    }

    // Light header on the page background (Lagoon Daylight): teal is kept
    // for actions and the selected tab, not painted across the whole bar.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barBg = AppPageColors.pageBgOf(context);
    final fg = AppPageColors.textPrimaryOf(context);

    return AppBar(
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: barBg,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      elevation: 0,
      scrolledUnderElevation: 0,
      // Material3 tints an elevated AppBar's surface with colorScheme.surfaceTint
      // by default; keep the bar the exact page color.
      surfaceTintColor: Colors.transparent,
      backgroundColor: barBg,
      foregroundColor: fg,
      titleSpacing: 20,
      centerTitle: false,
      toolbarHeight: _toolbarHeight,
      actions: [
        if (onNewConversationTap != null)
          AppCircleIconButton(
            tooltip: 'New conversation',
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: onNewConversationTap,
          ),
        if (onConversationHistoryTap != null)
          AppCircleIconButton(
            tooltip: 'Conversation history',
            icon: const Icon(Icons.history),
            onPressed: onConversationHistoryTap,
          ),
        if (onExplainOnePartTap != null)
          AppCircleIconButton(
            tooltip: AppLocalizations.instance.t(
              'top-bar.explain-one-part-hint',
            ),
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: onExplainOnePartTap,
          ),
        if (onSearchTap != null)
          AppCircleIconButton(
            key: ScreenTutorialKeys.mainAppBarSearch,
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: onSearchTap,
          ),
        if (onDecksSettingsTap != null)
          AppCircleIconButton(
            tooltip: 'Decks settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: onDecksSettingsTap,
          ),
        if (helpAction != null) helpAction!,
        Builder(
          builder: (context) => Padding(
            padding: EdgeInsets.only(right: trailingAction != null ? 0 : 16),
            child: AppCircleIconButton(
              key: ScreenTutorialKeys.mainAppBarNotifications,
              tooltip: 'Notifications',
              // Number for new ones, dot for ones marked unread (shared state).
              icon: const NotificationBellIcon(size: AppCircleIconButton.iconSize),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ),
        if (trailingAction != null)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: trailingAction!,
          ),
      ],

      title: Text(
        title,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 24,
          letterSpacing: -0.4,
        ),
      ),

      bottom: tabs == null ? null : _buildTabBar(context),
    );
  }

  /// Sub-tabs as pills: the selected one sits on a soft teal tint.
  PreferredSizeWidget _buildTabBar(BuildContext context) {
    final tint = AppPageColors.tintOf(context, AppTint.teal);
    return PreferredSize(
      preferredSize: const Size.fromHeight(kTextTabBarHeight),
      child: Material(
        color: AppPageColors.pageBgOf(context),
        child: Row(
          children: [
            Expanded(
              child: TabBar(
                key: ScreenTutorialKeys.mainAppBarTabs,
                controller: controller,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: const EdgeInsets.only(left: 12),
                labelPadding: const EdgeInsets.symmetric(horizontal: 14),
                labelColor: tint.fg,
                unselectedLabelColor: AppPageColors.subtitleOf(context),
                indicator: BoxDecoration(
                  color: tint.bg,
                  borderRadius: BorderRadius.circular(999),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                // 34 dp pills in the 46 dp strip.
                indicatorPadding: const EdgeInsets.symmetric(vertical: 6),
                splashBorderRadius: BorderRadius.circular(999),
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                tabs: tabs!,
              ),
            ),
            if (tabBarTrailing != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: tabBarTrailing,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize {
    final tabsHeight = tabs == null ? 0.0 : kTextTabBarHeight;
    return Size.fromHeight(_toolbarHeight + tabsHeight);
  }
}
