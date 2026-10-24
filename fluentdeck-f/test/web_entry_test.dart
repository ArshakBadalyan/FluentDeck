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

  test('the intro is only skipped on web (tests run as mobile)', () {
    expect(WebEntry.skipsIntro, isFalse);
    expect(WebEntry.authModeFromUrl(), isNull);
  });
}
