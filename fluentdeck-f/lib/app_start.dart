import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluentdeck/clarity_user_sync.dart'
    if (dart.library.html) 'package:fluentdeck/clarity_user_sync_stub.dart';
import 'package:fluentdeck/english_main_screen.dart';
import 'package:fluentdeck/screens/onboarding/english_onboarding_screen.dart';
import 'package:fluentdeck/services/analytics_service.dart';
import 'package:fluentdeck/services/auth_service.dart';
import 'package:fluentdeck/services/english_level_service.dart';
import 'package:fluentdeck/services/deck_backup_service.dart';
import 'package:fluentdeck/services/deck_notification_service.dart';
import 'package:fluentdeck/services/flashcard_sync_service.dart';
import 'package:fluentdeck/services/push_notification_service.dart';
import 'package:fluentdeck/services/token_storage.dart';
import 'package:fluentdeck/services/mobile_app_update_gate.dart';
import 'package:fluentdeck/ui_elements/loading_overlay.dart';
import 'package:fluentdeck/widgets/mobile_force_update_screen.dart';
import 'package:fluentdeck/widgets/mobile_soft_update_host.dart';

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
        final prefs = await SharedPreferences.getInstance();
        final seen = prefs.getBool(kEnglishOnboardingSeenPrefsKey) ?? false;
        next = seen ? const EnglishOnboardingScreen(startAtAuth: true) : const EnglishOnboardingScreen();
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
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool(kEnglishOnboardingSeenPrefsKey) ?? false;
      next = seen ? const EnglishOnboardingScreen(startAtAuth: true) : const EnglishOnboardingScreen();
    }

    Widget wrapOffer(Widget w) {
      if (softOffer == null) return w;
      return MobileSoftUpdateHost(offer: softOffer, child: w);
    }

    _go(wrapOffer(next));
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
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: LaunchLoadingIndicator()),
    );
  }
}
