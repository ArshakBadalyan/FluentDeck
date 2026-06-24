import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled2/localization/app_localizations.dart';
import 'package:untitled2/screens/activity_screen/activity_shell_screen.dart';
import 'package:untitled2/screens/speaking_hub/speaking_hub_screen.dart';
import 'package:untitled2/screens/conversation_screen/conversation_history_screen.dart';
import 'package:untitled2/screens/conversation_screen/conversation_screen.dart';
import 'package:untitled2/screens/learn_screen/decks_shell_screen.dart';
import 'package:untitled2/screens/learn_screen/placement_test_screen.dart';
import 'package:untitled2/screens/library_screen/library_screen.dart';
import 'package:untitled2/screens/profile_screen/about_us/profile_about_tab.dart';
import 'package:untitled2/screens/profile_screen/profile_account_tab.dart';
import 'package:untitled2/screens/profile_screen/profile_notifications_tab.dart';
import 'package:untitled2/screens/profile_screen/profile_security_tab.dart';
import 'package:untitled2/screens/profile_screen/profile_sound_tab.dart';
import 'package:untitled2/screens/profile_screen/profile_settings_tab.dart';
import 'package:untitled2/services/app_feature_config_service.dart';
import 'package:untitled2/services/audio_service.dart';
import 'package:untitled2/services/conversation_service.dart';
import 'package:untitled2/services/auth_service.dart';
import 'package:untitled2/services/main_navigation_coordinator.dart';
import 'package:untitled2/services/notifications_service.dart';
import 'package:untitled2/services/unsaved_changes_service.dart';
import 'package:untitled2/services/vocabulary_service.dart';
import 'package:untitled2/ui_elements/english_bottom_nav.dart';
import 'package:untitled2/ui_elements/main_app_bar.dart';
import 'package:untitled2/ui_elements/notification_panel.dart';

const String kPlacementPromptSeenPrefsKey = 'placement_test_prompt_seen';

class EnglishMainScreen extends StatefulWidget {
  const EnglishMainScreen({super.key, this.initialMainIndex = 0});

  final int initialMainIndex;

  static const mainTabCount = 5;

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
  TabController? _profileTabController;
  TabController? _decksTabController;
  TabController? _libraryTabController;
  TabController? _speakTabController;
  TabController? _activityTabController;
  bool _speakInSession = false;
  int _notificationUnreadCount = 0;
  final GlobalKey<DecksShellScreenState> _decksShellKey = GlobalKey();
  final GlobalKey<SpeakingHubScreenState> _speakingHubKey = GlobalKey();

  static const _titles = ['Speak', 'Decks', 'Library', 'Activity', 'Profile'];

  static const _decksSubTabs = ['Decks', 'Browser'];

  static const _activitySubTabs = ['Speaking', 'Decks'];

  static const _speakSubTabs = ['Chat', 'Deck Words', 'Games', 'Role-Play', 'Topics'];

  static const _librarySubTabs = ['Words', 'My Notes', 'Study Hall', 'Lessons'];

  final _profileSubTabs = const [
    'Account',
    'Settings',
    'Notifications',
    'Sound',
    'Security',
    'About',
  ];

  @override
  void initState() {
    super.initState();
    MainNavigationCoordinator.navigateToMainTab = setMainIndex;
    _initProfileTabs();
    UnsavedChangesService().addListener(_onUnsavedChangesChanged);
    unawaited(_initSoundSettings());
    unawaited(_refreshNotificationUnread());
    unawaited(_initLearnFeatures());
  }

  Future<void> _initLearnFeatures() async {
    await AppFeatureConfigService.instance.fetch();
    if (!mounted) return;
    await _maybePromptPlacementTest();
  }

  Future<void> _maybePromptPlacementTest() async {
    final latest = await VocabularyService.instance.fetchLatestPlacement();
    if (!mounted) return;
    if (latest != null) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(kPlacementPromptSeenPrefsKey) == true) return;
    await prefs.setBool(kPlacementPromptSeenPrefsKey, true);
    if (!mounted) return;

    final takeTest = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Find your level'),
            content: const Text(
              'Take a quick vocabulary test (~2 min) to get your CEFR level and a suggested study setup.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Later'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Start test'),
              ),
            ],
          ),
    );

    if (takeTest == true && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const PlacementTestScreen()),
      );
    }
  }

  @override
  void dispose() {
    if (MainNavigationCoordinator.navigateToMainTab == setMainIndex) {
      MainNavigationCoordinator.navigateToMainTab = null;
    }
    UnsavedChangesService().removeListener(_onUnsavedChangesChanged);
    _profileTabController?.dispose();
    _decksTabController?.dispose();
    _libraryTabController?.dispose();
    _speakTabController?.dispose();
    _activityTabController?.dispose();
    super.dispose();
  }

  void _onUnsavedChangesChanged() {
    if (mounted) setState(() {});
  }

  void _initProfileTabs() {
    _profileTabController?.dispose();
    _decksTabController?.dispose();
    _libraryTabController?.dispose();
    _activityTabController?.dispose();
    _speakTabController?.dispose();
    if (_currentIndex == 4) {
      _profileTabController = TabController(length: _profileSubTabs.length, vsync: this);
      _decksTabController = null;
      _libraryTabController = null;
      _speakTabController = null;
      _activityTabController = null;
    } else if (_currentIndex == 1) {
      _decksTabController = TabController(length: _decksSubTabs.length, vsync: this);
      _profileTabController = null;
      _libraryTabController = null;
      _speakTabController = null;
      _activityTabController = null;
    } else if (_currentIndex == 2) {
      _libraryTabController = TabController(length: _librarySubTabs.length, vsync: this);
      _profileTabController = null;
      _decksTabController = null;
      _speakTabController = null;
      _activityTabController = null;
    } else if (_currentIndex == 0) {
      _speakTabController = TabController(length: _speakSubTabs.length, vsync: this);
      _profileTabController = null;
      _decksTabController = null;
      _libraryTabController = null;
      _activityTabController = null;
    } else if (_currentIndex == 3) {
      _activityTabController = TabController(length: _activitySubTabs.length, vsync: this);
      _profileTabController = null;
      _decksTabController = null;
      _libraryTabController = null;
      _speakTabController = null;
    } else {
      _profileTabController = null;
      _decksTabController = null;
      _libraryTabController = null;
      _speakTabController = null;
      _activityTabController = null;
    }
  }

  void _onSpeakSessionActiveChanged(bool inSession) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _speakInSession == inSession) return;
      setState(() => _speakInSession = inSession);
    });
  }

  void setMainIndex(int index, {int? subIndex}) {
    if (!mounted) return;
    if (_currentIndex == 0 && index != 0) {
      unawaited(ConversationService.instance.leaveChat());
    }
    setState(() {
      if (_currentIndex == 0 && index != 0) {
        _speakInSession = false;
      }
      _currentIndex = index.clamp(0, EnglishMainScreen.mainTabCount - 1);
      _initProfileTabs();
      if (subIndex != null && _profileTabController != null) {
        _profileTabController!.index = subIndex.clamp(0, _profileSubTabs.length - 1);
      }
      if (subIndex != null && _speakTabController != null) {
        _speakTabController!.index = subIndex.clamp(0, _speakSubTabs.length - 1);
      }
      if (subIndex != null && _libraryTabController != null) {
        _libraryTabController!.index = subIndex.clamp(0, _librarySubTabs.length - 1);
      }
    });
    AudioService().play('tabChange');
  }

  Future<void> _refreshNotificationUnread() async {
    try {
      final res = await NotificationsService.getNotifications();
      final list = res['data'] as List? ?? [];
      if (!mounted) return;
      var count = 0;
      for (final n in list) {
        if (n is! Map) continue;
        final read =
            n['read'] ??
            (n['attributes'] is Map ? (n['attributes'] as Map)['read'] : null);
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

  Widget _bodyForIndex(int index) {
    switch (index) {
      case 0:
        return SpeakingHubScreen(
          key: _speakingHubKey,
          tabController: _speakTabController!,
          onSessionActiveChanged: _onSpeakSessionActiveChanged,
        );
      case 1:
        return DecksShellScreen(
          key: _decksShellKey,
          tabController: _decksTabController!,
        );
      case 2:
        return LibraryScreen(tabController: _libraryTabController!);
      case 3:
        return ActivityShellScreen(tabController: _activityTabController!);
      case 4:
        return TabBarView(
          controller: _profileTabController,
          physics:
              UnsavedChangesService().hasUnsavedChanges
                  ? const NeverScrollableScrollPhysics()
                  : null,
          children: const [
            ProfileAccountTab(),
            ProfileSettingsTab(),
            ProfileNotificationsTab(),
            ProfileSoundTab(),
            ProfileSecurityTab(),
            ProfileAboutTab(showResetAllScreenTips: false),
          ],
        );
      default:
        return const ConversationScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProfile = _currentIndex == 4;
    final isDecks = _currentIndex == 1;
    final isLibrary = _currentIndex == 2;
    final isSpeak = _currentIndex == 0;
    final isActivity = _currentIndex == 3;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: MainAppBar(
        title:
            isProfile
                ? AppLocalizations.instance.t('profile.profile')
                : _titles[_currentIndex],
        tabs:
            isProfile
                ? _profileSubTabs.map((label) => Tab(text: label)).toList()
                : isDecks
                ? _decksSubTabs.map((label) => Tab(text: label)).toList()
                : isLibrary
                ? _librarySubTabs.map((label) => Tab(text: label)).toList()
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
                : isLibrary
                ? _libraryTabController
                : isActivity
                ? _activityTabController
                : isSpeak && !_speakInSession
                ? _speakTabController
                : null,
        notificationUnreadCount: _notificationUnreadCount,
        onConversationHistoryTap:
            _currentIndex == 0
                ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ConversationHistoryScreen(),
                    ),
                  );
                }
                : null,
        onNewConversationTap:
            _currentIndex == 0
                ? () async {
                  await _speakingHubKey.currentState?.startNewFreeChat();
                }
                : null,
      ),
      endDrawer: NotificationPanel(
        onChanged: () {
          unawaited(_refreshNotificationUnread());
        },
      ),
      body: _bodyForIndex(_currentIndex),
      bottomNavigationBar: EnglishBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) async {
          if (index == _currentIndex) return;
          if (UnsavedChangesService().hasUnsavedChanges) {
            final confirmed = await UnsavedChangesService().showConfirmDialog(
              context,
            );
            if (!confirmed) return;
          }
          setState(() {
            if (_currentIndex == 0 && index != 0) {
              _speakInSession = false;
              unawaited(ConversationService.instance.leaveChat());
            }
            _currentIndex = index;
            _initProfileTabs();
          });
          AudioService().play('tabChange');
        },
      ),
    );
  }
}
