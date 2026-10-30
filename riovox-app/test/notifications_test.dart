import 'dart:convert';

import 'package:riovox/screens/profile_screen/profile_notifications_tab.dart';
import 'package:riovox/services/notifications_service.dart';
import 'package:riovox/ui_elements/app_toast.dart';
import 'package:riovox/ui_elements/modern_page_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records requests; [respond] decides the answer (default: `{}` 200).
class FakeServer {
  final requests = <http.Request>[];
  http.Response Function(http.Request)? respond;

  MockClient get client => MockClient((req) async {
    requests.add(req);
    return respond?.call(req) ?? http.Response('{}', 200);
  });

  List<http.Request> where(String method, String path) => requests
      .where((r) => r.method == method && r.url.path == path)
      .toList();
}

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  late FakeServer server;

  setUp(() {
    dotenv.testLoad(fileInput: 'API_URL=https://api.test/api');
    SharedPreferences.setMockInitialValues({'user_id': '7'});
    FlutterSecureStorage.setMockInitialValues({'token': 'jwt-123'});
    server = FakeServer();
  });

  Future<T> withServer<T>(Future<T> Function() body) =>
      http.runWithClient(body, () => server.client);

  group('NotificationsService (bell panel)', () {
    test('getNotifications reads the page and pageCount', () async {
      server.respond = (_) => _json({
        'data': [
          {'id': 1, 'title': 'Hi', 'read': false},
          {'id': 2, 'title': 'Old', 'read': true},
        ],
        'meta': {
          'pagination': {'page': 2, 'pageCount': 3},
        },
      });

      final res = await withServer(
        () => NotificationsService.getNotifications(page: 2),
      );

      final req = server.requests.single;
      expect(req.method, 'GET');
      expect(req.url.path, '/api/notifications/mine');
      expect(req.url.queryParameters, {'page': '2'});
      expect(req.headers['Authorization'], 'Bearer jwt-123');
      expect((res['data'] as List).length, 2);
      expect(res['pageCount'], 3);
    });

    test('getNotifications without pagination meta → pageCount 0', () async {
      server.respond = (_) => _json({'data': []});
      final res = await withServer(NotificationsService.getNotifications);
      expect(res['data'], isEmpty);
      expect(res['pageCount'], 0);
    });

    test('readNotification marks one as read', () async {
      server.respond = (_) => _json({
        'data': {'id': 5, 'read': true},
      });
      final ok = await withServer(() => NotificationsService.readNotification(5));
      expect(ok, isTrue);
      expect(server.where('PUT', '/api/notifications/5/read'), hasLength(1));
    });

    test('readNotification on someone else\'s / missing id throws', () async {
      server.respond = (_) => _json({
        'error': {'message': 'Notification not found'},
      }, 404);
      await expectLater(
        withServer(() => NotificationsService.readNotification(99)),
        throwsA(predicate((e) => '$e'.contains('Notification not found'))),
      );
    });

    test('readAllNotifications calls the mark-all endpoint', () async {
      server.respond = (_) => _json({'updatedCount': 3});
      final ok = await withServer(NotificationsService.readAllNotifications);
      expect(ok, isTrue);
      expect(server.where('PUT', '/api/readAllNotifications'), hasLength(1));
    });

    test('hasUnread is true only when some item has read == false', () {
      expect(NotificationsService.hasUnread([]), isFalse);
      expect(
        NotificationsService.hasUnread([
          {'id': 1, 'read': true},
        ]),
        isFalse,
      );
      expect(
        NotificationsService.hasUnread([
          {'id': 1, 'read': true},
          {'id': 2, 'read': false},
        ]),
        isTrue,
      );
      // Strapi v4 shape (attributes) works too.
      expect(
        NotificationsService.hasUnread([
          {
            'id': 3,
            'attributes': {'read': false},
          },
        ]),
        isTrue,
      );
      expect(NotificationsService.hasUnread(['junk', 42]), isFalse);
    });
  });

  group('Profile → Notifications → Daily practice reminder', () {
    var prefs = <String, dynamic>{};

    setUp(() {
      prefs = {'daily_reminder_enabled': false, 'daily_reminder_time': '09:00'};
      server.respond = (req) {
        if (req.url.path == '/api/users/me/speaking-preferences') {
          if (req.method == 'PUT') {
            prefs = {...prefs, ...jsonDecode(req.body) as Map<String, dynamic>};
          }
          return _json(prefs);
        }
        return http.Response('{}', 200);
      };
    });

    tearDown(AppToast.dismissAll);

    Future<void> pumpTab(WidgetTester tester) async {
      await tester.runAsync(
        () => withServer(() async {
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, child) => AppToastHost(child: child!),
              home: const Scaffold(body: ProfileNotificationsTab()),
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }),
      );
      await tester.pumpAndSettle();
    }

    /// Taps inside the mocked-server zone and lets the request finish.
    Future<void> tapAndWait(WidgetTester tester, Finder finder) async {
      await tester.runAsync(
        () => withServer(() async {
          await tester.tap(finder);
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }),
      );
      await tester.pumpAndSettle();
    }

    Finder reminderRow() => find.widgetWithText(AppToggleRow, 'Daily reminder');
    Finder reminderSwitch() =>
        find.descendant(of: reminderRow(), matching: find.byType(AppSwitch));
    bool reminderOn(WidgetTester tester) =>
        tester.widget<AppToggleRow>(reminderRow()).value;

    testWidgets('loads the saved setting; time row hidden while off', (
      tester,
    ) async {
      await pumpTab(tester);
      expect(find.text('Daily practice reminder'), findsOneWidget);
      expect(reminderOn(tester), isFalse);
      expect(find.text('Reminder time'), findsNothing);
    });

    testWidgets('loads an enabled reminder with its time', (tester) async {
      prefs = {'daily_reminder_enabled': true, 'daily_reminder_time': '07:30'};
      await pumpTab(tester);
      expect(reminderOn(tester), isTrue);
      expect(find.text('Reminder time'), findsOneWidget);
      expect(find.text('07:30'), findsOneWidget);
    });

    testWidgets('turning it on saves to the server and shows the time row', (
      tester,
    ) async {
      await pumpTab(tester);
      await tapAndWait(tester, reminderSwitch());

      final puts = server.where('PUT', '/api/users/me/speaking-preferences');
      expect(puts, hasLength(1));
      final body = jsonDecode(puts.single.body) as Map<String, dynamic>;
      expect(body['daily_reminder_enabled'], isTrue);
      expect(body['daily_reminder_time'], '09:00');
      expect(find.text('Reminder time'), findsOneWidget);
    });

    testWidgets('a rejected save reverts the switch and explains why', (
      tester,
    ) async {
      await pumpTab(tester);
      server.respond = (req) {
        if (req.method == 'PUT') {
          return _json({
            'error': {'message': 'daily_reminder_time must be HH:MM'},
          }, 400);
        }
        return _json(prefs);
      };

      await tapAndWait(tester, reminderSwitch());

      expect(tester.takeException(), isNull);
      expect(reminderOn(tester), isFalse);
      expect(find.text('Reminder time'), findsNothing);
      expect(find.text('daily_reminder_time must be HH:MM'), findsOneWidget);
      AppToast.dismissAll();
      await tester.pumpAndSettle();
    });
  });
}
