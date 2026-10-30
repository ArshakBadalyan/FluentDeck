import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riovox/clarity_user_sync.dart'
    if (dart.library.html) 'package:riovox/clarity_user_sync_stub.dart';
import 'package:riovox/english_main_screen.dart';
import 'package:riovox/screens/auth/auth_screen.dart';
import 'package:riovox/screens/onboarding/english_onboarding_screen.dart';
import 'package:riovox/services/analytics_service.dart';
import 'package:riovox/services/auth_service.dart';
import 'package:riovox/services/english_level_service.dart';
import 'package:riovox/services/deck_backup_service.dart';
import 'package:riovox/services/deck_notification_service.dart';
import 'package:riovox/services/flashcard_sync_service.dart';
import 'package:riovox/services/push_notification_service.dart';
import 'package:riovox/services/token_storage.dart';
import 'package:riovox/services/mobile_app_update_gate.dart';
import 'package:riovox/ui_elements/app_skeletons.dart';
import 'package:riovox/ui_elements/modern_page_widgets.dart';
import 'package:riovox/utils/web_entry.dart';
import 'package:riovox/widgets/mobile_force_update_screen.dart';
import 'package:riovox/widgets/mobile_soft_update_host.dart';

class AppStart extends StatefulWidget {
  const AppStart({super.key});

  @override
  State<AppStart> createState() => _AppStartState();
}

class _AppStartState extends State<AppStart> {
  MobileForcedUpdateDecision? _forcedUpdate;

  @override
  void initState() {
    super.initState();
    unawaited(_runStartupGateThenAuth());
  }

  Future<void> _runStartupGateThenAuth() async {
    if (mobileAppUpdateTargetNativeMobile) {
      try {
        final gate = await MobileAppUpdateBootstrap.evaluate();
        if (!mounted) return;
        _forcedUpdate = gate.forced;
        if (_forcedUpdate != null) {
          setState(() {});
          return;
        }

        await _routeInitialScreenAfterAuth(softOffer: gate.softOffer);
        return;
      } catch (e, st) {
        debugPrint('_runStartupGateThenAuth mobile policy error: $e\n$st');
      }
      if (!mounted) return;
    }

    await _routeInitialScreenAfterAuth(softOffer: null);
  }

  Future<void> _routeInitialScreenAfterAuth({
    MobileSoftUpdateOffer? softOffer,
  }) async {
    final token = await TokenStorage.getToken();
    final userId = await TokenStorage.getUserId();

    Widget next;
    if (token != null && token.isNotEmpty && userId != null) {
      final valid = await AuthService.validateStoredSession();
      if (!valid) {
        await AuthService.logout();
        next = await _signedOutScreen();
        _go(softOffer == null ? next : MobileSoftUpdateHost(offer: softOffer, child: next));
        return;
      }
      unawaited(AnalyticsService.instance.setUserId(userId.toString()));
      syncClarityCustomUserId(userId.toString());
      unawaited(AuthService.sendAppInfo());
      unawaited(EnglishLevelService.instance.syncOnAppStart());
      unawaited(FlashcardSyncService.instance.syncOnAppStart());
      unawaited(DeckBackupService.instance.runAutoBackupIfDue());
      unawaited(DeckNotificationService.instance.syncFromSettings());
      await _initPushNotifications();
      next = const EnglishMainScreen();
    } else {
      next = await _signedOutScreen();
    }

    Widget wrapOffer(Widget w) {
      if (softOffer == null) return w;
      return MobileSoftUpdateHost(offer: softOffer, child: w);
    }

    _go(wrapOffer(next));
  }

  /// Signed-out start: the intro the first time on mobile, else sign-in.
  /// On web the landing page already introduced the app, so it goes straight
  /// to sign-up / sign-in (`/app/?auth=signup|signin`, default sign-in).
  Future<Widget> _signedOutScreen() async {
    if (WebEntry.skipsIntro) {
      return EnglishOnboardingScreen(
        startAtAuth: true,
        authMode: WebEntry.authModeFromUrl() ?? AuthMode.login,
      );
    }
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(kEnglishOnboardingSeenPrefsKey) ?? false;
    return seen
        ? const EnglishOnboardingScreen(startAtAuth: true)
        : const EnglishOnboardingScreen();
  }

  Future<void> _initPushNotifications() async {
    final userId = await TokenStorage.getUserId();
    if (userId == null) return;
    try {
      await PushNotificationService.login(
        userId.toString(),
      ).timeout(const Duration(seconds: 12));
    } catch (e, st) {
      debugPrint('_initPushNotifications: $e\n$st');
    }
  }

  bool _navigated = false;

  void _go(Widget page) {
    if (_navigated) return;
    _navigated = true;

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    if (_forcedUpdate != null) {
      return MobileForceUpdateScreen(storeUrl: _forcedUpdate!.storeUrl);
    }
    return Scaffold(
      backgroundColor: AppPageColors.pageBgOf(context),
      body: const AppLaunchSkeleton(),
    );
  }
}
