import 'dart:convert';

import 'package:fluentdeck/models/app_feature_config_model.dart';
import 'package:fluentdeck/screens/profile_screen/profile_subscription_tab.dart';
import 'package:fluentdeck/services/conversation_limit_service.dart';
import 'package:fluentdeck/services/subscription_service.dart';
import 'package:fluentdeck/ui_elements/app_toast.dart';
import 'package:fluentdeck/utils/practice_time_format.dart';
import 'package:fluentdeck/widgets/ai_daily_usage_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Store with no products (as before they're live) and no platform calls.
class FakeStore extends InAppPurchasePlatform {
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => const Stream.empty();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) async =>
      ProductDetailsResponse(productDetails: const [], notFoundIDs: identifiers.toList());
}

http.Response _json(Object body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json'},
);

void main() {
  group('practice time labels', () {
    test('seconds, minutes, hours', () {
      expect(formatPracticeTime(0), '0 min');
      expect(formatPracticeTime(45), '45 sec');
      expect(formatPracticeTime(60), '1 min');
      expect(formatPracticeTime(119), '1 min'); // rounds down
      expect(formatPracticeTime(12 * 60), '12 min');
      expect(formatPracticeTime(4 * 3600), '4 h');
      expect(formatPracticeTime(90 * 60), '1 h 30 min');
      expect(formatPracticeMinutes(240), '4 h');
      expect(formatPracticeMinutes(5), '5 min');
    });
  });

  group('plans', () {
    test('only Monthly and Yearly are sold; Yearly has a 7-day trial', () {
      expect(kDefaultFluentDeckPlans.map((p) => p.productId), [
        kMonthlyProductId,
        kYearlyProductId,
      ]);
      expect(kDefaultSubscriptionProductIds, isNot(contains(kLegacyQuarterlyProductId)));
      final yearly = kDefaultFluentDeckPlans.last;
      expect(yearly.fallbackPrice, '\$79.99');
      expect(yearly.trialDays, 7);
      expect(yearly.badge, 'Save 33%');
      expect(kDefaultFluentDeckPlans.first.fallbackPrice, '\$9.99');
      expect(kDefaultFluentDeckPlans.every((p) => p.dailyMinutes == 240), isTrue);
    });

    test('existing quarterly subscribers still see their plan name', () {
      expect(planTitleFor(kLegacyQuarterlyProductId), 'Quarterly');
      expect(planTitleFor(kYearlyProductId), 'Yearly');
      expect(planTitleFor(null), 'Premium');
    });

    test('server config carries daily minutes and trial days', () {
      final config = AppFeatureConfigModel.fromJson({
        'freeDailyMinutes': 10,
        'premiumDailyMinutes': 300,
        'subscriptionPlans': [
          {
            'productId': kYearlyProductId,
            'title': 'Yearly',
            'durationMonths': 12,
            'fallbackPrice': '\$79.99',
            'dailyMinutes': 360,
            'trialDays': 7,
          },
        ],
      });
      expect(config.freeDailyMinutes, 10);
      expect(config.premiumDailyMinutes, 300);
      expect(config.subscriptionPlans.single.dailyMinutes, 360);
      expect(config.subscriptionPlans.single.trialDays, 7);
      expect(const AppFeatureConfigModel().freeDailyMinutes, 5);
    });

    test('subscription status reads dailyMinutes', () {
      final status = SubscriptionStatus.fromJson({
        'isPremium': true,
        'subscription': {'productId': kMonthlyProductId, 'dailyMinutes': 240},
      });
      expect(status.dailyMinutes, 240);
    });
  });

  group('usage (seconds)', () {
    test('remaining and progress are in seconds', () {
      final usage = ConversationUsageStatus.fromJson({
        'allowed': true,
        'unit': 'seconds',
        'usedToday': 3600,
        'dailyLimit': 14400,
        'isPremium': true,
        'freeDailyLimit': 300,
        'premiumDailyLimit': 14100,
      });
      expect(usage.remaining, 10800);
      expect(usage.progress, 0.25);
      expect(usage.hasMeter, isTrue);
    });

    testWidgets('usage bar shows time used and left', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiDailyUsageBar(
              usage: ConversationUsageStatus.fromJson({
                'allowed': true,
                'usedToday': 150,
                'dailyLimit': 300,
                'isPremium': false,
                'freeDailyLimit': 300,
              }),
            ),
          ),
        ),
      );
      expect(find.text('2 min'), findsOneWidget);
      expect(find.text('2 min left of 5 min'), findsOneWidget);
    });

    testWidgets('usage bar when time is used up', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiDailyUsageBar(
              usage: ConversationUsageStatus.fromJson({
                'allowed': false,
                'usedToday': 300,
                'dailyLimit': 300,
                'isPremium': false,
              }),
            ),
          ),
        ),
      );
      expect(
        find.text('Daily practice time used · resets at midnight'),
        findsOneWidget,
      );
    });
  });

  group('Profile → Subscription screen', () {
    setUp(() {
      InAppPurchasePlatform.instance = FakeStore();
      dotenv.testLoad(fileInput: 'API_URL=https://api.test/api');
      SharedPreferences.setMockInitialValues({'user_id': '7'});
      FlutterSecureStorage.setMockInitialValues({'token': 'jwt-123'});
    });

    tearDown(AppToast.dismissAll);

    Future<void> pumpTab(WidgetTester tester, Map<String, dynamic> status) async {
      tester.view.physicalSize = const Size(1080, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final client = MockClient((req) async {
        if (req.url.path == '/api/subscriptions/status') return _json(status);
        if (req.url.path == '/api/ai/usage') {
          return _json({
            'allowed': true,
            'unit': 'seconds',
            'usedToday': 1800,
            'dailyLimit': status['isPremium'] == true ? 14400 : 300,
            'isPremium': status['isPremium'] == true,
          });
        }
        return _json({});
      });
      await tester.runAsync(
        () => http.runWithClient(() async {
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, child) => AppToastHost(child: child!),
              home: const Scaffold(body: ProfileSubscriptionTab()),
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }, () => client),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows Monthly + Yearly with daily time, no slider', (
      tester,
    ) async {
      await pumpTab(tester, {'isPremium': false, 'subscription': null});

      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Yearly'), findsOneWidget);
      expect(find.text('Quarterly'), findsNothing);
      expect(find.byType(Slider), findsNothing);
      expect(find.text('Daily conversations'), findsNothing);
      expect(find.text('\$9.99 / month'), findsOneWidget);
      // Design: "price · ≈ per month" on one line, trial on the button.
      expect(find.text('\$79.99 / year · ≈ \$6.67 a month'), findsOneWidget);
      expect(find.text('Start 7-day free trial'), findsOneWidget);
      // Free plan: the Premium pitch instead of the full feature list.
      expect(find.text('Speak as much as you want'), findsOneWidget);
      expect(find.text('Up to 4 h with Rio every day'), findsOneWidget);
      expect(find.text('Restore purchases'), findsOneWidget);
    });

    testWidgets('a legacy quarterly subscriber sees their plan name', (
      tester,
    ) async {
      await pumpTab(tester, {
        'isPremium': true,
        'subscription': {
          'productId': kLegacyQuarterlyProductId,
          'status': 'active',
          'currentPeriodEnd':
              DateTime.now().add(const Duration(days: 30)).toIso8601String(),
          'dailyMinutes': 240,
        },
      });
      expect(find.text('Premium · Quarterly'), findsOneWidget);
      // Not a sold plan, so nothing is marked "Current"; Yearly is preselected.
      expect(find.text('Current'), findsNothing);
      expect(find.text('Subscribe'), findsOneWidget);
    });
  });
}
