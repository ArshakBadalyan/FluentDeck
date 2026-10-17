import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluentdeck/localization/app_localizations.dart';

import '../app_colors.dart';
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
        backgroundColor: AppColors.brandPrimaryDeep,
        toolbarHeight: _toolbarHeight,
      );
    }

    return AppBar(
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      elevation: suppressShadow ? 0 : 4,
      shadowColor: suppressShadow ? null : Colors.black.withValues(alpha: 0.35),
      scrolledUnderElevation: suppressShadow ? 0 : 8,
      // Material3 tints an elevated AppBar's surface with colorScheme.surfaceTint
      // by default — in dark mode that's the bright cyan brandPrimaryOnDark, so
      // the toolbar (elevated) ends up a visibly different, lighter teal than the
      // flat tab-bar Material directly below it even though both use the same
      // backgroundColor. Disabling the tint keeps elevation as a pure shadow.
      surfaceTintColor: Colors.transparent,
      backgroundColor: AppColors.brandPrimaryDeep,
      titleSpacing: 24,
      centerTitle: false,
      toolbarHeight: _toolbarHeight,
      actions: [
        if (onNewConversationTap != null)
          IconButton(
            tooltip: 'New conversation',
            icon: const Icon(Icons.add_comment_outlined, size: 26),
            color: Colors.white,
            onPressed: onNewConversationTap,
          ),
        if (onConversationHistoryTap != null)
          IconButton(
            tooltip: 'Conversation history',
            icon: const Icon(Icons.history, size: 26),
            color: Colors.white,
            onPressed: onConversationHistoryTap,
          ),
        if (onExplainOnePartTap != null)
          IconButton(
            tooltip: AppLocalizations.instance.t(
              'top-bar.explain-one-part-hint',
            ),
            icon: const Icon(Icons.help_outline_rounded, size: 26),
            color: Colors.white,
            onPressed: onExplainOnePartTap,
          ),
        if (onSearchTap != null)
          IconButton(
            key: ScreenTutorialKeys.mainAppBarSearch,
            icon: const Icon(Icons.search, size: 26),
            color: Colors.white,
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
              color: Colors.white,
              onPressed: onAssignmentsTap,
            ),
          ),
        if (onDecksSettingsTap != null)
          IconButton(
            tooltip: 'Decks settings',
            icon: const Icon(Icons.settings_outlined, size: 26),
            color: Colors.white,
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
              color: Colors.white,
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
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),

      bottom: tabs == null ? null : _buildTabBar(),
    );
  }

  PreferredSizeWidget _buildTabBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kTextTabBarHeight),
      child: Material(
        color: AppColors.brandPrimaryDeep,
        child: Row(
          children: [
            Expanded(
              child: TabBar(
                key: ScreenTutorialKeys.mainAppBarTabs,
                controller: controller,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: const EdgeInsets.only(left: 12),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.65),
                indicatorColor: Colors.white,
                indicatorSize: TabBarIndicatorSize.label,
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
