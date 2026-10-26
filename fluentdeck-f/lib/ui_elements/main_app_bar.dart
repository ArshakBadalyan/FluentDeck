import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluentdeck/localization/app_localizations.dart';

import 'modern_page_widgets.dart';
import 'screen_tutorial_targets.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Tab>? tabs;
  final TabController? controller;
  final VoidCallback? onSearchTap;

  /// Opens the “Explain one part” segment picker (main shell only).
  final VoidCallback? onExplainOnePartTap;

  /// Student homework launcher (Topics tab).
  final VoidCallback? onAssignmentsTap;
  final int assignmentsBadgeCount;
  final VoidCallback? onConversationHistoryTap;
  final VoidCallback? onNewConversationTap;
  final VoidCallback? onDecksSettingsTap;
  final int notificationUnreadCount;

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
    this.onAssignmentsTap,
    this.assignmentsBadgeCount = 0,
    this.onConversationHistoryTap,
    this.onNewConversationTap,
    this.onDecksSettingsTap,
    this.notificationUnreadCount = 0,
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
      titleSpacing: 24,
      centerTitle: false,
      toolbarHeight: _toolbarHeight,
      actions: [
        if (onNewConversationTap != null)
          IconButton(
            tooltip: 'New conversation',
            icon: const Icon(Icons.add_comment_outlined, size: 26),
            color: fg,
            onPressed: onNewConversationTap,
          ),
        if (onConversationHistoryTap != null)
          IconButton(
            tooltip: 'Conversation history',
            icon: const Icon(Icons.history, size: 26),
            color: fg,
            onPressed: onConversationHistoryTap,
          ),
        if (onExplainOnePartTap != null)
          IconButton(
            tooltip: AppLocalizations.instance.t(
              'top-bar.explain-one-part-hint',
            ),
            icon: const Icon(Icons.help_outline_rounded, size: 26),
            color: fg,
            onPressed: onExplainOnePartTap,
          ),
        if (onSearchTap != null)
          IconButton(
            key: ScreenTutorialKeys.mainAppBarSearch,
            icon: const Icon(Icons.search, size: 26),
            color: fg,
            tooltip: 'Search',
            onPressed: onSearchTap,
          ),
        if (onAssignmentsTap != null)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              tooltip: AppLocalizations.instance.t(
                'student.assignments.icon-tooltip',
              ),
              icon: Badge(
                isLabelVisible: assignmentsBadgeCount > 0,
                label: Text('$assignmentsBadgeCount'),
                child: const Icon(Icons.assignment_outlined, size: 26),
              ),
              color: fg,
              onPressed: onAssignmentsTap,
            ),
          ),
        if (onDecksSettingsTap != null)
          IconButton(
            tooltip: 'Decks settings',
            icon: const Icon(Icons.settings_outlined, size: 26),
            color: fg,
            onPressed: onDecksSettingsTap,
          ),
        if (helpAction != null) helpAction!,
        Builder(
          builder: (context) => Padding(
            padding: EdgeInsets.only(
              right: trailingAction != null ? 0 : (onAssignmentsTap != null ? 12 : 24),
            ),
            child: IconButton(
              key: ScreenTutorialKeys.mainAppBarNotifications,
              tooltip: 'Notifications',
              icon: Badge(
                isLabelVisible: notificationUnreadCount > 0,
                label: Text(
                  notificationUnreadCount > 99
                      ? '99+'
                      : '$notificationUnreadCount',
                ),
                child: const Icon(Icons.notifications_none_outlined, size: 26),
              ),
              color: fg,
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
    final accent = AppPageColors.accentOf(context);
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
                labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                labelColor: accent,
                unselectedLabelColor: AppPageColors.subtitleOf(context),
                indicator: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.symmetric(vertical: 7),
                splashBorderRadius: BorderRadius.circular(999),
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
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
