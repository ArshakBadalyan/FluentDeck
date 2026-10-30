import 'package:riovox/models/speaking_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Beta languages are hidden from new choices', () {
    final options = SpeakingPreferences.selectablePracticeLanguages();
    for (final code in SpeakingPreferences.betaLanguageCodes) {
      expect(options.containsKey(code), isFalse, reason: code);
    }
    expect(options.containsKey('en'), isTrue);
    expect(options.containsKey('hi'), isTrue); // Hindi is not in beta
  });

  test('An existing beta choice still shows, so the picker keeps working', () {
    final options = SpeakingPreferences.selectablePracticeLanguages(current: 'tr');
    expect(options['tr'], 'Turkish');
    expect(options.containsKey('vi'), isFalse);
    expect(SpeakingPreferences.selectableResponseLanguages(current: 'hy')['hy'], 'Armenian');
  });

  test('The full lists keep every language (labels and server sync)', () {
    for (final code in SpeakingPreferences.betaLanguageCodes) {
      expect(SpeakingPreferences.practiceLanguageOptions.containsKey(code), isTrue, reason: code);
    }
  });

  test('Indonesian and Armenian are text only; every other language has a voice', () {
    expect(SpeakingPreferences.hasTutorVoice('id'), isFalse);
    expect(SpeakingPreferences.hasTutorVoice('hy'), isFalse);
    for (final code in SpeakingPreferences.practiceLanguageOptions.keys) {
      if (code == 'id' || code == 'hy') continue;
      expect(SpeakingPreferences.hasTutorVoice(code), isTrue, reason: code);
    }
  });
}
