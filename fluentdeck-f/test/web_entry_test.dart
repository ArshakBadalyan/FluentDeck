import 'package:fluentdeck/screens/auth/auth_screen.dart';
import 'package:fluentdeck/utils/web_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AuthMode? mode(String url) => WebEntry.authModeFromUrl(Uri.parse(url));

  test('landing page links open the right auth form', () {
    expect(mode('https://fluentdeck.app/app/?auth=signup'), AuthMode.register);
    expect(mode('https://fluentdeck.app/app/?auth=signin'), AuthMode.login);
    expect(mode('https://fluentdeck.app/app/?auth=SIGNUP'), AuthMode.register);
    expect(mode('https://fluentdeck.app/app/?auth=register'), AuthMode.register);
    expect(mode('https://fluentdeck.app/app/?auth=login'), AuthMode.login);
  });

  test('no or unknown auth parameter → no preference (sign-in by default)', () {
    expect(mode('https://fluentdeck.app/app/'), isNull);
    expect(mode('https://fluentdeck.app/app/?auth=nope'), isNull);
  });

  test('web skips the intro only when opened from a landing page button', () {
    bool skips(String url) =>
        WebEntry.skipsIntroFor(Uri.parse(url), isWeb: true);
    expect(skips('https://fluentdeck.app/app/?auth=signup'), isTrue);
    expect(skips('https://fluentdeck.app/app/?auth=signin'), isTrue);
    expect(skips('https://fluentdeck.app/app/'), isFalse); // direct launch: intro first
    expect(skips('http://localhost:63162/'), isFalse); // flutter run -d chrome
    expect(
      WebEntry.skipsIntroFor(Uri.parse('https://x/app/?auth=signup'), isWeb: false),
      isFalse,
    );
  });

  test('the intro is only skipped on web (tests run as mobile)', () {
    expect(WebEntry.skipsIntro, isFalse);
    expect(WebEntry.authModeFromUrl(), isNull);
  });
}
