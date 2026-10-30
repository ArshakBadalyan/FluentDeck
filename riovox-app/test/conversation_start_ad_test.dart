import 'package:riovox/models/app_feature_config_model.dart';
import 'package:riovox/services/conversation_start_ad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 23, 12);
  bool show(String? country, {bool premium = false, DateTime? last, AdConfig? config}) =>
      ConversationStartAd.shouldShow(
        config: config ?? const AdConfig(),
        isPremium: premium,
        country: country,
        now: now,
        lastShownAt: last,
      );

  group('who sees the conversation-start ad', () {
    test('free users in Brazil, Turkey, India and other low-value regions', () {
      for (final c in ['BR', 'TR', 'IN', 'AM', 'MX', 'VN', 'ID', 'EG']) {
        expect(show(c), isTrue, reason: c);
      }
    });

    test('unknown country is treated as low-value (ad shown)', () {
      expect(show(null), isTrue);
    });

    test('not in high-value countries (US, EU, Japan…)', () {
      for (final c in ['US', 'GB', 'DE', 'ES', 'FR', 'JP', 'us']) {
        expect(show(c), isFalse, reason: c);
      }
    });

    test('never for Premium', () {
      expect(show('TR', premium: true), isFalse);
    });

    test('at most one per cooldown (default 5 minutes)', () {
      expect(show('TR', last: now.subtract(const Duration(minutes: 2))), isFalse);
      expect(show('TR', last: now.subtract(const Duration(minutes: 5))), isTrue);
    });

    test('off when the server turns it off', () {
      expect(show('TR', config: const AdConfig(conversationStartAdEnabled: false)), isFalse);
    });
  });

  group('server config', () {
    test('reads countries, switch, cooldown and rewarded flag', () {
      final config = AdConfig.fromJson({
        'highValueCountries': ['us', 'GB'],
        'conversationStartAd': {'enabled': true, 'lowValueOnly': true, 'cooldownMinutes': 10},
        'rewardedMinutes': {'enabled': false, 'highValueOnly': true},
      });
      expect(config.highValueCountries, {'US', 'GB'});
      expect(config.conversationStartAdCooldownMinutes, 10);
      expect(config.rewardedMinutesEnabled, isFalse);
      expect(config.isHighValue('DE'), isFalse); // server list replaces defaults
    });

    test('missing config → same defaults as the server', () {
      final config = AppFeatureConfigModel.fromJson({}).ads;
      expect(config.isHighValue('US'), isTrue);
      expect(config.isHighValue('BR'), isFalse);
      expect(config.conversationStartAdEnabled, isTrue);
      expect(config.conversationStartAdCooldownMinutes, 5);
      expect(config.rewardedMinutesEnabled, isFalse);
    });
  });

  group('device country', () {
    testWidgets('from the phone region, e.g. English language in Turkey', (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('en', 'TR')];
      tester.platformDispatcher.localeTestValue = const Locale('en', 'TR');
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      expect(ConversationStartAd.deviceCountry(), 'TR');
    });

    testWidgets('null when the phone has no region', (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('en')];
      tester.platformDispatcher.localeTestValue = const Locale('en');
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      expect(ConversationStartAd.deviceCountry(), isNull);
    });
  });
}
