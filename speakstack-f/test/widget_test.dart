import 'package:flutter_test/flutter_test.dart';
import 'package:speakstack/routing/app_route_names.dart';

void main() {
  test('AppRouteNames defines Speakstack routes', () {
    expect(AppRouteNames.main, '/main');
    expect(AppRouteNames.speakingSessionDetail, '/activity/speaking_session');
  });
}
