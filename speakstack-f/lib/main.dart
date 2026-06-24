import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:untitled2/localization/app_localizations.dart';
import 'package:untitled2/services/admob_service.dart';
import 'package:untitled2/services/analytics_service.dart';
import 'package:untitled2/services/click_tracking.dart';
import 'package:untitled2/services/consent_service.dart';
import 'package:untitled2/services/audio_service.dart';
import 'package:untitled2/services/interaction_haptics.dart';
import 'package:untitled2/services/deck_notification_service.dart';
import 'package:untitled2/services/push_notification_service.dart';

import 'app_start.dart';
import 'app_text_theme.dart';
import 'clarity_wrap.dart' if (dart.library.html) 'clarity_wrap_stub.dart';
import 'firebase_options.dart';
import 'services/clarity_route_observer.dart';

List<String> _adMobTestDeviceIds() {
  // Never tag devices as "test" in release: AdMob would return only test ads
  // (or "no fill") for real users. Only honor the env var in debug/profile.
  if (kReleaseMode) return const [];
  final raw = dotenv.env['ADMOB_TEST_DEVICE_IDS'];
  if (raw == null || raw.isEmpty) {
    return const [];
  }
  return raw
      .split(',')
      .map((id) => id.trim())
      .where((id) => id.isNotEmpty)
      .toList();
}

/// Loads [assets/english_config.txt] (KEY=value), falling back to legacy
/// [assets/mathe_config.txt]. On web, [rootBundle] resolves some paths to
/// `…/assets/<file>` while the file is served at `…/assets/assets/<file>`;
/// we fetch using [Uri.base] so `/web/` + `assets/assets/` matches deployment.
Future<void> _loadDotenv() async {
  const primary = 'assets/english_config.txt';
  const legacy = 'assets/mathe_config.txt';

  if (kIsWeb) {
    Future<http.Response> fetchConfig(String assetPath) {
      final uri = Uri.base.resolve('assets/$assetPath');
      return http.get(uri);
    }

    var res = await fetchConfig(primary);
    if (res.statusCode != 200) {
      res = await fetchConfig(legacy);
    }
    if (res.statusCode != 200) {
      throw Exception(
        'Could not load $primary or $legacy (HTTP ${res.statusCode}). '
        'Put KEY=value lines in assets/english_config.txt, then '
        'flutter build web --release --base-href /web/ --pwa-strategy none',
      );
    }
    dotenv.testLoad(fileInput: res.body);
    return;
  }

  try {
    await dotenv.load(fileName: primary);
  } catch (_) {
    await dotenv.load(fileName: legacy);
  }
}

final ClarityRouteObserver _clarityRouteObserver = ClarityRouteObserver();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _loadDotenv();
  await AppLocalizations.instance.load();
  if (AdIds.adsEnabled) {
    await AdConsentService.prepare();

    final testIds = _adMobTestDeviceIds();
    debugPrint('[AdMob] Test device IDs: $testIds');
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        maxAdContentRating: MaxAdContentRating.g,
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
        testDeviceIds: testIds,
      ),
    );
    await MobileAds.instance.initialize();
  }

  await PushNotificationService.initialize();
  await DeckNotificationService.instance.initialize();

  await AudioService().ensureInitialized();

  await _resetThemePrefsOnce();

  runApp(wrapWithClarity(const MyApp()));
}

/// Clears app-wide dark theme prefs left from Step 6 (one-time).
Future<void> _resetThemePrefsOnce() async {
  final prefs = await SharedPreferences.getInstance();
  const doneKey = 'theme_revert_v1_done';
  if (prefs.getBool(doneKey) == true) return;
  await prefs.setString('app_theme_mode_v1', 'light');
  await prefs.setBool('review_settings_v1_darkMode', false);
  await prefs.setBool(doneKey, true);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppLocalizations.instance,
      builder: (_, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: AppLocalizations.instance.locale,
        home: const AppStart(),
        theme: ThemeData(
          fontFamily: 'Rubik',
          textTheme: AppTextTheme.textTheme,
          scaffoldBackgroundColor: Colors.white,
        ),
        navigatorObservers: [
          AnalyticsService.instance.observer,
          AnalyticsService.instance.routeObserver,
          _clarityRouteObserver,
        ],
        builder: (context, child) {
          return InteractionSwipeHapticsScope(
            child: ClickTracker(child: child ?? const SizedBox.shrink()),
          );
        },
      ),
    );
  }
}
