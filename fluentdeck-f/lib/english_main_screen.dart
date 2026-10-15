import 'package:fluentdeck/services/logout_flow.dart';
import 'package:fluentdeck/services/screen_tutorial_service.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluentdeck/screens/learn_screen/widgets/decks_contextual_help.dart';
import 'package:fluentdeck/localization/app_localizations.dart';
import 'package:fluentdeck/screens/activity_screen/activity_shell_screen.dart';
import 'package:fluentdeck/screens/speaking_hub/speaking_hub_screen.dart';
import 'package:fluentdeck/screens/conversation_screen/conversation_history_screen.dart';
import 'package:fluentdeck/screens/learn_screen/decks_shell_screen.dart';
import 'package:fluentdeck/screens/profile_screen/about_us/profile_about_tab.dart';
import 'package:fluentdeck/screens/profile_screen/profile_account_tab.dart';
import 'package:fluentdeck/screens/profile_screen/profile_security_tab.dart';
import 'package:fluentdeck/screens/profile_screen/profile_settings_tab.dart';
import 'package:fluentdeck/screens/profile_screen/profile_subscription_tab.dart';
import 'package:fluentdeck/services/app_feature_config_service.dart';
import 'package:fluentdeck/services/audio_service.dart';
import 'package:fluentdeck/services/conversation_service.dart';
import 'package:fluentdeck/services/auth_service.dart';
import 'package:fluentdeck/services/flashcard_sync_service.dart';
import 'package:fluentdeck/services/main_navigation_coordinator.dart';
import 'package:fluentdeck/services/main_tab_config.dart';
import 'package:fluentdeck/services/notifications_service.dart';
import 'package:fluentdeck/utils/strapi_response.dart';
import 'package:fluentdeck/services/unsaved_changes_service.dart';
import 'package:fluentdeck/ui_elements/english_bottom_nav.dart';
import 'package:fluentdeck/ui_elements/handoff_tab_bar_view.dart';
import 'package:fluentdeck/ui_elements/main_app_bar.dart';
import 'package:fluentdeck/ui_elements/notification_panel.dart';


class EnglishMainScreen extends StatefulWidget {
  const EnglishMainScreen({super.key, this.initialMainIndex = 0});

  final int initialMainIndex;

  static int get mainTabCount => MainTabConfig.tabCount;

  @override
  State<EnglishMainScreen> createState() => EnglishMainScreenState();

  static EnglishMainScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<EnglishMainScreenState>();
  }
}

class EnglishMainScreenState extends State<EnglishMainScreen>
    with TickerProviderStateMixin {
  late int _currentIndex =
      widget.initialMainIndex.clamp(0, EnglishMainScreen.mainTabCount - 1);
  late final PageController _pageController =
      PageController(initialPage: _currentIndex);
  late final TabController _profileTabController =
      TabController(length: _profileSubTabs.length, vsync: this);
  late final TabController _decksTabController =
      TabController(length: _decksSubTabs.length, vsync: this);
  late TabController _speakTabController =
      TabController(length: _speakSubTabs.length, vsync: this);
  late final TabController _activityTabController =
      TabController(length: _activitySubTabs.length, vsync: this);
  bool _speakInSession = false;
  int _notificationUnreadCount = 0;
  /// When set before [PageController] navigation, overrides default sub-tab 0.
  int? _pendingSubIndex;
  final GlobalKey<DecksShellScreenState> _decksShellKey = GlobalKey();
  final GlobalKey<SpeakingHubScreenState> _speakingHubKey = GlobalKey();

  static const _decksSubTabs = ['Decks', 'Browser'];

  static const _activitySubTabs = ['Progress', 'Speaking', 'Decks'];

  static const _speakSubTabDefs = [
    ('chat', 'Chat'),
    ('notes', 'My Notes'),
    ('practice', 'Deck Words'),
    ('games', 'Games'),
    ('roleplay', 'Role-Play'),
    ('topics', 'Topics'),
  ];

  /// Falls back to showing every tab if config hides all of them (misconfiguration guard).
  List<(String, String)> get _visibleSpeakSubTabDefs {
    final hidden = AppFeatureConfigService.instance.config.hiddenSpeakingTabs;
    final visible =
        _speakSubTabDefs.where((tab) => !hidden.contains(tab.$1)).toList();
    return visible.isEmpty ? _speakSubTabDefs : visible;
  }

  List<String> get _speakSubTabIds =>
      _visibleSpeakSubTabDefs.map((tab) => tab.$1).toList();

  List<String> get _speakSubTabs =>
      _visibleSpeakSubTabDefs.map((tab) => tab.$2).toList();

  final _profileSubTabs = const [
    'Account',
    'Settings',
    'Subscription',
    'Security',
    'About',
  ];

  MainTabId get _currentTab => MainTabConfig.tabAt(_currentIndex);

  String get _currentTitle {
    final tab = _currentTab;
    if (tab == MainTabId.profile) {
      return AppLocalizations.instance.t('profile.profile');
    }
    return MainTabConfig.definition(tab).title;
  }

  @override
  void initState() {
    super.initState();
    MainNavigationCoordinator.navigateToMainTab = setMainIndex;
    // Profile → About → Show tips reads where the user is.
    ScreenTutorialReplayCoordinator.currentMainTabIndex = _tutorialMainIndex;
    ScreenTutorialReplayCoordinator.currentSubTabIndex = _tutorialSubIndex;
    MainNavigationCoordinator.enterSpeakChatSession = () {
      _speakingHubKey.currentState?.enterLoadedSession();
    };
    UnsavedChangesService().addListener(_onUnsavedChangesChanged);
    unawaited(_initSoundSettings());
    unawaited(_refreshNotificationUnread());
    unawaited(_initLearnFeatures());
  }

  Future<void> _initLearnFeatures() async {
    await AppFeatureConfigService.instance.fetch();
    if (!mounted) return;
    _syncSpeakTabController();
  }

  /// Recreates the Speak sub-tab controller if config hid/unhid tabs after cold start.
  void _syncSpeakTabController() {
    final newLength = _speakSubTabs.length;
    if (_speakTabController.length == newLength) return;
    final oldController = _speakTabController;
    final clampedIndex = oldController.index.clamp(0, newLength - 1);
    setState(() {
      _speakTabController = TabController(
        length: newLength,
        vsync: this,
        initialIndex: clampedIndex,
      );
    });
    oldController.dispose();
  }

  int _tutorialMainIndex() => _currentIndex;

  int _tutorialSubIndex() {
    switch (_currentTab) {
      case MainTabId.profile:
        return _profileTabController.index;
      case MainTabId.decks:
        return _decksTabController.index;
      case MainTabId.speak:
        return _speakTabController.index;
      case MainTabId.activity:
        return _activityTabController.index;
    }
  }

  @override
  void dispose() {
    if (ScreenTutorialReplayCoordinator.currentMainTabIndex == _tutorialMainIndex) {
      ScreenTutorialReplayCoordinator.currentMainTabIndex = null;
      ScreenTutorialReplayCoordinator.currentSubTabIndex = null;
    }
    if (MainNavigationCoordinator.navigateToMainTab == setMainIndex) {
      MainNavigationCoordinator.navigateToMainTab = null;
    }
    if (MainNavigationCoordinator.enterSpeakChatSession != null) {
      MainNavigationCoordinator.enterSpeakChatSession = null;
    }
    UnsavedChangesService().removeListener(_onUnsavedChangesChanged);
    _pageController.dispose();
    _profileTabController.dispose();
    _decksTabController.dispose();
    _speakTabController.dispose();
    _activityTabController.dispose();
    super.dispose();
  }

  ScrollPhysics get _mainPagePhysics {
    if (_speakInSession || UnsavedChangesService().hasUnsavedChanges) {
      return const NeverScrollableScrollPhysics();
    }
    return const PageScrollPhysics();
  }

  void _leaveSpeakTabIfNeeded(int nextIndex) {
    if (MainTabConfig.isTab(_currentIndex, MainTabId.speak) &&
        !MainTabConfig.isTab(nextIndex, MainTabId.speak)) {
      _speakInSession = false;
      unawaited(ConversationService.instance.leaveChat());
    }
  }

  void _onMainPageChanged(int index) {
    if (!mounted || index == _currentIndex) return;
    _leaveSpeakTabIfNeeded(index);
    final tab = MainTabConfig.tabAt(index);
    final subIndex = _pendingSubIndex ?? 0;
    _pendingSubIndex = null;
    _applySubIndex(tab, subIndex);
    setState(() => _currentIndex = index);
    AudioService().play('tabChange');
  }

  Future<bool> _confirmLeaveIfUnsaved() async {
    if (!UnsavedChangesService().hasUnsavedChanges) return true;
    return UnsavedChangesService().showConfirmDialog(context);
  }

  void _onUnsavedChangesChanged() {
    if (mounted) setState(() {});
  }

  void _onSpeakSessionActiveChanged(bool inSession) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _speakInSession == inSession) return;
      setState(() => _speakInSession = inSession);
    });
  }

  void _applySubIndex(MainTabId tab, int subIndex) {
    switch (tab) {
      case MainTabId.speak:
        _speakTabController.index =
            subIndex.clamp(0, _speakSubTabs.length - 1);
      case MainTabId.decks:
        _decksTabController.index =
            subIndex.clamp(0, _decksSubTabs.length - 1);
      case MainTabId.activity:
        _activityTabController.index =
            subIndex.clamp(0, _activitySubTabs.length - 1);
      case MainTabId.profile:
        _profileTabController.index =
            subIndex.clamp(0, _profileSubTabs.length - 1);
    }
  }

  void setMainIndex(int index, {int? subIndex}) {
    if (!mounted) return;
    final next = index.clamp(0, EnglishMainScreen.mainTabCount - 1);
    _leaveSpeakTabIfNeeded(next);
    _pendingSubIndex = subIndex;
    if (next != _currentIndex) {
      _pageController.jumpToPage(next);
      return;
    }
    _pendingSubIndex = null;
    _applySubIndex(MainTabConfig.tabAt(next), subIndex ?? 0);
    setState(() => _currentIndex = next);
    AudioService().play('tabChange');
  }

  MainTabHandoff get _mainTabHandoff => MainTabHandoff(
    onPrevious:
        _currentIndex > 0 ? () => _goToAdjacentMainTab(-1) : null,
    onNext:
        _currentIndex < MainTabConfig.tabCount - 1
            ? () => _goToAdjacentMainTab(1)
            : null,
  );

  /// Neighbouring tabs slide; farther tabs jump straight there. Animating
  /// across several pages fired onPageChanged for every tab in between
  /// (building them, hitting their APIs and replaying the tab sound).
  Future<void> _showMainPage(int index) async {
    if ((index - _currentIndex).abs() > 1) {
      _pageController.jumpToPage(index);
      return;
    }
    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _goToAdjacentMainTab(int direction) async {
    final next = _currentIndex + direction;
    if (next < 0 || next >= MainTabConfig.tabCount) return;
    if (!await _confirmLeaveIfUnsaved()) return;
    _leaveSpeakTabIfNeeded(next);
    _pendingSubIndex = null;
    await _showMainPage(next);
  }

  Future<void> _refreshNotificationUnread() async {
    try {
      final res = await NotificationsService.getNotifications();
      final list = res['data'] as List? ?? [];
      if (!mounted) return;
      var count = 0;
      for (final n in list) {
        if (n is! Map) continue;
        final read = StrapiResponse.field<bool>(Map<String, dynamic>.from(n), 'read');
        if (read != true) count += 1;
      }
      setState(() => _notificationUnreadCount = count);
    } catch (_) {}
  }

  Future<void> _initSoundSettings() async {
    final res = await AuthService.getUser();
    if (res['status'] == 'success') {
      final user = res['user'];
      AudioService().updateSettings(
        enabled: user['sound'] ?? false,
        volumePercent: (user['volume_sound'] ?? 50).toDouble(),
      );
    }
  }

  Widget _profileBody() {
    return HandoffTabBarView(
      controller: _profileTabController,
      onHandoffPrevious: _mainTabHandoff.onPrevious,
      onHandoffNext: _mainTabHandoff.onNext,
      physics:
          UnsavedChangesService().hasUnsavedChanges
              ? const NeverScrollableScrollPhysics()
              : const BouncingScrollPhysics(),
      children: const [
        ProfileAccountTab(),
        ProfileSettingsTab(),
        ProfileSubscriptionTab(),
        ProfileSecurityTab(),
        ProfileAboutTab(showResetAllScreenTips: false),
      ],
    );
  }

  Widget _pageForTab(MainTabId tab) {
    final handoff = _mainTabHandoff;
    switch (tab) {
      case MainTabId.speak:
        return SpeakingHubScreen(
          key: _speakingHubKey,
          tabController: _speakTabController,
          visibleTabIds: _speakSubTabIds,
          mainTabHandoff: handoff,
          onSessionActiveChanged: _onSpeakSessionActiveChanged,
        );
      case MainTabId.decks:
        return DecksShellScreen(
          key: _decksShellKey,
          tabController: _decksTabController,
          mainTabHandoff: handoff,
        );
      case MainTabId.activity:
        return ActivityShellScreen(
          tabController: _activityTabController,
          mainTabHandoff: handoff,
        );
      case MainTabId.profile:
        return _profileBody();
    }
  }

  List<Widget> get _orderedPages =>
      MainTabConfig.order.map(_pageForTab).toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final tab = _currentTab;
    final isProfile = tab == MainTabId.profile;
    final isDecks = tab == MainTabId.decks;
    final isSpeak = tab == MainTabId.speak;
    final isActivity = tab == MainTabId.activity;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: MainAppBar(
        title: _currentTitle,
        // Profile: log out sits to the right of the bell.
        trailingAction:
            isProfile
                ? Builder(
                  builder: (context) => IconButton(
                    tooltip: 'Log out',
                    icon: const Icon(Icons.logout_rounded, size: 24),
                    color: Colors.white,
                    onPressed: () => runLogoutFlow(context),
                  ),
                )
                : null,
        helpAction:
            isDecks
                ? AnimatedBuilder(
                    animation: _decksTabController,
                    builder: (context, _) => DecksContextualHelpButton(
                      helpSectionId:
                          _decksTabController.index == 1 ? 'card-browser' : null,
                      iconSize: 26,
                      color: Colors.white,
                    ),
                  )
                : isActivity
                ? AnimatedBuilder(
                    animation: _activityTabController,
                    // Deck statistics help on Activity → Decks.
                    builder: (context, _) =>
                        _activityTabController.index == 2
                            ? const DecksContextualHelpButton(
                              helpSectionId: 'statistics',
                              iconSize: 26,
                              color: Colors.white,
                            )
                            : const SizedBox.shrink(),
                  )
                : null,
        tabs:
            isProfile
                ? _profileSubTabs.map((label) => Tab(text: label)).toList()
                : isDecks
                ? _decksSubTabs.map((label) => Tab(text: label)).toList()
                : isActivity
                ? _activitySubTabs.map((label) => Tab(text: label)).toList()
                : isSpeak && !_speakInSession
                ? _speakSubTabs.map((label) => Tab(text: label)).toList()
                : null,
        controller:
            isProfile
                ? _profileTabController
                : isDecks
                ? _decksTabController
                : isActivity
                ? _activityTabController
                : isSpeak && !_speakInSession
                ? _speakTabController
                : null,
        notificationUnreadCount: _notificationUnreadCount,
        onConversationHistoryTap:
            isSpeak
                ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ConversationHistoryScreen(),
                    ),
                  );
                }
                : null,
        onNewConversationTap:
            isSpeak
                ? () async {
                  await _speakingHubKey.currentState?.startNewFreeChat();
                }
                : null,
      ),
      // Unread badge refreshes when the drawer closes (swipe / tap outside).
      onEndDrawerChanged: (isOpen) {
        if (!isOpen) unawaited(_refreshNotificationUnread());
      },
      endDrawer: NotificationPanel(
        onChanged: () {
          unawaited(_refreshNotificationUnread());
        },
      ),
      body: Column(
        children: [
          const _OfflineSyncBanner(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: _mainPagePhysics,
              onPageChanged: _onMainPageChanged,
              children: _orderedPages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: EnglishBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) async {
          if (index == _currentIndex) return;
          _pendingSubIndex = null;
          if (!await _confirmLeaveIfUnsaved()) return;
          _leaveSpeakTabIfNeeded(index);
          await _showMainPage(index);
        },
      ),
    );
  }
}

/// App-wide banner shown whenever [FlashcardSyncService] can't reach the API.
class _OfflineSyncBanner extends StatelessWidget {
  const _OfflineSyncBanner();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FlashcardSyncService.instance,
      builder: (context, _) {
        final offline =
            FlashcardSyncService.instance.status == FlashcardSyncStatus.offline;
        return AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: offline
              ? Container(
                  width: double.infinity,
                  color: Colors.grey.shade700,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: SafeArea(
                    bottom: false,
                    top: false,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cloud_off_outlined,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "You're offline — some features may be limited",
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }
}
