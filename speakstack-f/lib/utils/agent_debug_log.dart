import 'dart:convert';

import 'package:http/http.dart' as http;

/// Debug-mode NDJSON logger (session 2e7cd5).
void agentDebugLog(
  String hypothesisId,
  String location,
  String message,
  Map<String, dynamic> data, {
  String runId = 'pre-fix',
}) {
  // #region agent log
  final payload = jsonEncode({
    'sessionId': '2e7cd5',
    'runId': runId,
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
