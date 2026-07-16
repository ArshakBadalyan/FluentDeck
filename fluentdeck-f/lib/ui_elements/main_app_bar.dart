import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluentdeck/localization/app_localizations.dart';

import '../app_colors.dart';
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
  });

  static const double _toolbarHeight = 56.0;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      elevation: 0,
      backgroundColor: AppColors.headerPurple,
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
        Builder(
          builder:
              (context) => Padding(
                padding: EdgeInsets.only(right: onAssignmentsTap != null ? 12 : 24),
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
      preferredSize: const Size.fromHeight(kTextTabBarHeight + 1),
      child: Builder(
        builder: (context) {
          final tabBg = AppPageColors.cardBgOf(context);
          final divider = AppPageColors.subtleBorderOf(context);
          final unselected = AppPageColors.subtitleOf(context);
          return Material(
            color: tabBg,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TabBar(
                  key: ScreenTutorialKeys.mainAppBarTabs,
                  controller: controller,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  padding: const EdgeInsets.only(left: 12),
                  labelColor: AppColors.primaryPurple,
                  unselectedLabelColor: unselected,
                  indicatorColor: Colors.transparent,
                  dividerColor: Colors.transparent,
                  labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  tabs: tabs!,
                ),
                Divider(height: 1, thickness: 1, color: divider),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Size get preferredSize {
    final tabsHeight = tabs == null ? 0.0 : kTextTabBarHeight + 1;
    return Size.fromHeight(_toolbarHeight + tabsHeight);
  }
}
