import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'api_service.dart';
import 'auth_service.dart';
import '../utils/api_exception.dart';

/// Native Google Sign-In flow, mirroring [AppleAuthService].
class GoogleAuthService {
  GoogleAuthService._();

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  static Future<Map<String, dynamic>> signIn() async {
    if (kIsWeb) {
      return {
        'status': 'error',
        'messageKey': 'login-register.google-web-unavailable',
      };
    }

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return {
          'status': 'cancelled',
          'messageKey': 'login-register.user-cancelled-login',
        };
      }

      final authentication = await account.authentication;
      final idToken = authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        return {
          'status': 'error',
          'messageKey': 'login-register.google-auth-failed',
        };
      }

      final nameParts = account.displayName?.trim().split(RegExp(r'\s+'));
      final firstName =
          (nameParts != null && nameParts.isNotEmpty) ? nameParts.first : null;
      final lastName = (nameParts != null && nameParts.length > 1)
          ? nameParts.sublist(1).join(' ')
          : null;

      final dynamic data = await ApiService.post('auth/google/mobile', {
        'idToken': idToken,
        if (account.email.isNotEmpty) 'email': account.email,
        if (firstName != null && firstName.isNotEmpty) 'firstName': firstName,
        if (lastName != null && lastName.isNotEmpty) 'lastName': lastName,
      });

      if (data is! Map) {
        return {
          'status': 'error',
          'messageKey': 'login-register.google-auth-failed',
        };
      }

      final map = Map<String, dynamic>.from(data);
      final error = map['error'];
      if (error != null) {
        final message = error is Map ? error['message']?.toString() : null;
        return {
          'status': 'error',
          'message': message,
        };
      }

      final isNewUser = map['isNewUser'] == true;
      await AuthService.completeProviderSession(
        map,
        analyticsMethod: 'google',
        isNewUser: isNewUser,
      );
      return {'status': 'success', 'isNewUser': isNewUser};
    } on ApiException catch (e) {
      return {
        'status': 'error',
        'message': e.message,
      };
    } catch (e, st) {
      debugPrint('GoogleAuthService.signIn failed: $e\n$st');
      return {
        'status': 'error',
        'messageKey': 'errors.network',
      };
    }
  }
}
