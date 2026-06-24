import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled2/clarity_user_sync.dart'
    if (dart.library.html) 'package:untitled2/clarity_user_sync_stub.dart';
import 'package:untitled2/english_main_screen.dart';
import 'package:untitled2/screens/onboarding/english_onboarding_screen.dart';
import 'package:untitled2/services/analytics_service.dart';
import 'package:untitled2/services/auth_service.dart';
import 'package:untitled2/services/english_level_service.dart';
import 'package:untitled2/services/deck_backup_service.dart';
import 'package:untitled2/services/deck_notification_service.dart';
import 'package:untitled2/services/flashcard_service.dart';
import 'package:untitled2/services/push_notification_service.dart';
import 'package:untitled2/services/token_storage.dart';
import 'package:untitled2/services/mobile_app_update_gate.dart';
import 'package:untitled2/ui_elements/loading_overlay.dart';
import 'package:untitled2/widgets/mobile_force_update_screen.dart';
import 'package:untitled2/widgets/mobile_soft_update_host.dart';

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
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');
    final userId = prefs.getInt('user_id');

    Widget next;
    if (token != null && token.isNotEmpty && userId != null) {
      unawaited(AnalyticsService.instance.setUserId(userId.toString()));
      syncClarityCustomUserId(userId.toString());
      unawaited(AuthService.sendAppInfo());
      unawaited(EnglishLevelService.instance.syncOnAppStart());
      unawaited(FlashcardService.instance.syncOnAppStart());
      unawaited(DeckBackupService.instance.runAutoBackupIfDue());
      unawaited(DeckNotificationService.instance.syncFromSettings());
      await _initPushNotifications();
      next = const EnglishMainScreen();
    } else {
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
