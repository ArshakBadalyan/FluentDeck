import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Debug-mode NDJSON logger (session ccf596).
void debugLog(
  String location,
  String message, {
  String? hypothesisId,
  Map<String, dynamic>? data,
}) {
  if (!kDebugMode) return;
  final payload = <String, dynamic>{
    'sessionId': 'ccf596',
    'timestamp': DateTime.now().millisecondsSinceEpoch,
    'location': location,
    'message': message,
    if (hypothesisId != null) 'hypothesisId': hypothesisId,
    if (data != null) 'data': data,
  };
  try {
    File('/Users/arshak/Workspace/FluentDeck/.cursor/debug-ccf596.log')
        .writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append);
  } catch (_) {}
}
