import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:fluentdeck/clarity_user_sync.dart'
    if (dart.library.html) 'package:fluentdeck/clarity_user_sync_stub.dart';
import 'package:fluentdeck/services/analytics_service.dart';
import 'package:fluentdeck/services/campaign_analytics.dart';
import 'package:fluentdeck/services/english_level_service.dart';
import 'package:fluentdeck/services/flashcard_sync_service.dart';
import 'package:fluentdeck/services/push_notification_service.dart';
import 'package:fluentdeck/services/token_storage.dart';

import 'package:fluentdeck/utils/user_facing_api_error.dart';

import 'package:fluentdeck/utils/strapi_response.dart';

import 'api_service.dart';

class AuthService {
  /// Syncs [app_opened_datetime] and [user_timezone] on the Strapi user (same as f7-math `sendAppInfo`).
  /// On logout, pass [clear] so both fields are set to null before the session is cleared.
  static Future<void> sendAppInfo({bool clear = false}) async {
    final userId = await TokenStorage.getUserId();
    if (userId == null) return;

    final Map<String, dynamic> body;
    if (clear) {
      body = {
        'app_opened_datetime': null,
        'user_timezone': null,
      };
    } else {
      String? tzId;
      try {
        final tz = await FlutterTimezone.getLocalTimezone();
        tzId = tz.identifier;
      } catch (e, st) {
        debugPrint('sendAppInfo: timezone unavailable: $e\n$st');
      }
      body = {
        'app_opened_datetime': DateTime.now().toUtc().toIso8601String(),
        if (tzId != null && tzId.isNotEmpty) 'user_timezone': tzId,
      };
    }

    try {
      await ApiService.put('users/$userId', body);
    } catch (e, st) {
      debugPrint('sendAppInfo: PUT failed: $e\n$st');
    }
  }

  static Future<Map<String, dynamic>> login(
    Map<String, dynamic> userData,
  ) async {
    final data = await ApiService.post('auth/local', userData);

    if (data['error'] == null) {
      await _storeJwtAndUser(data);
      unawaited(sendAppInfo());
      unawaited(EnglishLevelService.instance.syncOnAppStart());
      unawaited(FlashcardSyncService.instance.syncOnAppStart());
      await PushNotificationService.login(data['user']['id'].toString());
      await _logAuthAnalyticsLogin(method: 'email', userId: data['user']['id']);
      return {'status': 'success'};
    }
    return {'status': 'error', 'error': data['error']};
  }


  static Future<Map<String, dynamic>> loginViaProvider(
    String provider,
    String accessToken,
  ) async {
    final data = await ApiService.get('auth/$provider/callback$accessToken');

    if (data['error'] == null) {
      await completeProviderSession(
        Map<String, dynamic>.from(data as Map),
        analyticsMethod: provider,
        isNewUser: false,
      );
      return {'status': 'success'};
    }
    return {'status': 'error', 'message': data['error']?['message']};
  }

  /// Persists JWT/user after a successful OAuth or Apple mobile auth response.
  static Future<void> completeProviderSession(
    Map<String, dynamic> data, {
    required String analyticsMethod,
    required bool isNewUser,
  }) async {
    await _storeJwtAndUser(data);
    unawaited(sendAppInfo());
    unawaited(EnglishLevelService.instance.syncOnAppStart());
    unawaited(FlashcardSyncService.instance.syncOnAppStart());
    await PushNotificationService.login(data['user']['id'].toString());
    if (isNewUser) {
      await _logAuthAnalyticsSignUp(
        method: analyticsMethod,
        userId: data['user']['id'],
      );
    } else {
      await _logAuthAnalyticsLogin(
        method: analyticsMethod,
        userId: data['user']['id'],
      );
    }
  }


  static Future<Map<String, dynamic>> register(
    Map<String, dynamic> userData,
  ) async {
    final data = await ApiService.post('auth/local/register', userData);

    if (data['error'] == null) {
      await _storeJwtAndUser(data);
      unawaited(sendAppInfo());
      unawaited(EnglishLevelService.instance.syncOnAppStart());
      unawaited(FlashcardSyncService.instance.syncOnAppStart());
      await PushNotificationService.login(data['user']['id'].toString());
      await _logAuthAnalyticsSignUp(method: 'password', userId: data['user']['id']);
      return {'status': 'success'};
    }
    return {'status': 'error', 'error': data['error']};
  }


  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final data = await ApiService.post('auth/forgot-password', {
      'email': email,
    });

    return data['error'] == null
        ? {'status': 'success'}
        : {'status': 'error', 'message': data['error']?['message']};
  }


  static Future<Map<String, dynamic>> resetPassword(
    Map<String, dynamic> body,
  ) async {
    final data = await ApiService.post('auth/reset-password', body);

    if (data['error'] == null) {
      await _storeJwtAndUser(data);
      unawaited(sendAppInfo());
      return {'status': 'success'};
    }
    return {'status': 'error', 'message': data['error']?['message']};
  }

  static Future<Map<String, dynamic>> getUser() async {
    final userId = await TokenStorage.getUserId();
    if (userId == null) {
      return {'status': 'error', 'message': 'User not authenticated'};
    }

    try {
      final data = await ApiService.get('users/$userId');

      if (data is! Map) {
        return {'status': 'error', 'message': 'Unexpected response'};
      }

      final map = StrapiResponse.row(data);
      if (map == null) {
        return {'status': 'error', 'message': 'Unexpected response'};
      }
      if (map['error'] != null) {
        return {'status': 'error', 'message': map['error']?['message']};
      }

      // needs_logout_credentials is set by Strapi on GET /users/:id when fetching self
      return {'status': 'success', 'user': map};
    } catch (e, st) {
      debugPrint('AuthService.getUser failed: $e\n$st');
      return {
        'status': 'error',
        'messageKey': userFacingErrorLocalizationKey(e),
      };
    }
  }


  static Future<Map<String, dynamic>> updateUser(
    Map<String, dynamic> body,
  ) async {
    final userId = await TokenStorage.getUserId();

    if (userId == null) {
      return {'status': 'error', 'message': 'User not authenticated'};
    }

    final data = await ApiService.put('users/$userId', body);

    if (data['error'] == null) {
      return {'status': 'success'};
    }
    return {
      'status': 'error',
      'message': data['error']?['message']?.toString(),
      'fieldErrors': _parseStrapiFieldErrors(data['error']),
    };
  }


  static Future<Map<String, dynamic>> deleteNicknamedUser() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return updateUser({
      'username': 'Del$timestamp',
      'email': 'Del$timestamp@example.com',
    });
  }

  /// Same as f7-math `deleteNicknamedUser` on the auth store — hard-deletes the user via Strapi.
  static Future<Map<String, dynamic>> deleteNicknamedUserRecord() async {
    final userId = await TokenStorage.getUserId();
    if (userId == null) {
      return {'status': 'error', 'message': 'User not authenticated'};
    }
    try {
      final data = await ApiService.delete('users/$userId/delete-nicknamed-user');
      if (data is Map && data['error'] != null) {
        return {
          'status': 'error',
          'message': data['error']?['message']?.toString(),
        };
      }
      return {'status': 'success'};
    } catch (e, st) {
      debugPrint('deleteNicknamedUserRecord: $e\n$st');
      return {
        'status': 'error',
        'messageKey': userFacingErrorLocalizationKey(e),
      };
    }
  }

  static Map<String, String> _parseStrapiFieldErrors(dynamic error) {
    final out = <String, String>{};
    if (error is! Map) return out;
    final details = error['details'];
    if (details is! Map) return out;
    final errors = details['errors'];
    if (errors is! List) return out;
    for (final e in errors) {
      if (e is! Map) continue;
      final path = e['path'];
      final msg = e['message']?.toString();
      if (msg == null || msg.isEmpty) continue;
      if (path is List && path.isNotEmpty) {
        out[path[0].toString()] = msg;
      }
    }
    return out;
  }

  /// f7 `nicknamedUserLogout`: clear app info, delete user on server, clear local session (no full [logout]).
  static Future<Map<String, dynamic>> deleteNicknamedUserAndClearSession() async {
    await sendAppInfo(clear: true);
    final res = await deleteNicknamedUserRecord();
    if (res['status'] == 'success') {
      await PushNotificationService.logout();
      await TokenStorage.clearAll();
      await AnalyticsService.instance.setUserId(null);
      clarityOnLogout();
    }
    return res;
  }

  static Future<void> logout() async {
    await sendAppInfo(clear: true);
    await PushNotificationService.logout();
    await TokenStorage.clearAll();
    await AnalyticsService.instance.setUserId(null);
    clarityOnLogout();
  }

  static Future<void> _logAuthAnalyticsLogin({
    required String method,
    required dynamic userId,
  }) async {
    await AnalyticsService.instance.setUserId(userId.toString());
    await CampaignAnalytics.logLogin(method: method);
  }

  static Future<void> _logAuthAnalyticsSignUp({
    required String method,
    required dynamic userId,
  }) async {
    await AnalyticsService.instance.setUserId(userId.toString());
    await CampaignAnalytics.logSignUp(method: method);
  }

  static Future<void> _storeJwtAndUser(Map<String, dynamic> data) async {
    final user = data['user'] as Map<String, dynamic>;
    await TokenStorage.saveToken(data['jwt']);
    await TokenStorage.saveUserId(user['id']);
    await TokenStorage.saveIsAdmin(user['is_admin'] == true);
    final accountType = user['account_type']?.toString();
    if (accountType == 'teacher') {
      await TokenStorage.saveAccountType('teacher');
      await TokenStorage.saveTeacherApproved(user['teacher_approved'] == true);
    } else {
      await TokenStorage.saveAccountType('student');
      await TokenStorage.saveTeacherApproved(false);
    }
    await TokenStorage.saveHideScreenExplanation(
      user['hide_screen_explanation'] == true,
    );
    syncClarityCustomUserId(user['id'].toString());
  }
}
