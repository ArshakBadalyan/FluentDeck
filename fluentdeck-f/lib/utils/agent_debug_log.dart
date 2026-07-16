import 'dart:convert';

import 'package:http/http.dart' as http;

void agentDebugLog({
  required String hypothesisId,
  required String location,
  required String message,
  required Map<String, dynamic> data,
}) {
  // #region agent log
  final payload = jsonEncode({
    'sessionId': '2e7cd5',
    'runId': 'dark-surfaces-pre-fix',
    'hypothesisId': hypothesisId,
    'location': location,
    'message': message,
    'data': data,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  });
  http
      .post(
        Uri.parse(
          'http://127.0.0.1:7337/ingest/ea2fc602-e0ad-43b0-b0a8-176383aba938',
        ),
        headers: {
          'Content-Type': 'application/json',
          'X-Debug-Session-Id': '2e7cd5',
        },
        body: payload,
      )
      .catchError((_) => http.Response('', 500));
  // #endregion
}
