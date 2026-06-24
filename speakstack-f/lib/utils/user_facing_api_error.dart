import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:speakstack/utils/api_exception.dart';

/// Returns a key for [AppLocalizations] / [context.tr] — never expose [error.toString()] to users.
String userFacingErrorLocalizationKey(Object error) {
  if (error is ApiException) {
    if (error.statusCode == 401 || error.statusCode == 403) {
      return 'errors.unauthorized';
    }
    if (error.statusCode >= 500) {
      return 'errors.server';
    }
    return 'errors.request-failed';
  }
  if (_isLikelyNetworkError(error)) {
    return 'errors.network';
  }
  return 'errors.unexpected';
}

bool _isLikelyNetworkError(Object error) {
  if (error is TimeoutException) return true;
  if (error is http.ClientException) return true;

  final lower = error.toString().toLowerCase();
  if (lower.contains('socketexception')) return true;
  if (lower.contains('clientexception')) return true;
  if (lower.contains('operation timed out')) return true;
  if (lower.contains('connection timed out')) return true;
  if (lower.contains('connection refused')) return true;
  if (lower.contains('network is unreachable')) return true;
  if (lower.contains('failed host lookup')) return true;
  if (lower.contains('no address associated')) return true;
  if (lower.contains('handshakeexception')) return true;
  if (lower.contains('tlsexception')) return true;
  if (lower.contains('httpexception')) return true;
  return false;
}
