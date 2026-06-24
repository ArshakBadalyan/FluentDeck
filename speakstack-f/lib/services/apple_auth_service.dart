import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'api_service.dart';
import 'auth_service.dart';
import '../utils/api_exception.dart';

/// Native Sign in with Apple flow for iOS (and Android when configured).
class AppleAuthService {
  AppleAuthService._();

  static Future<Map<String, dynamic>> signIn() async {
    if (kIsWeb) {
      return {
        'status': 'error',
        'messageKey': 'login-register.apple-unavailable',
      };
    }

    final isAvailable = await SignInWithApple.isAvailable();
    if (!isAvailable) {
      return {
        'status': 'error',
        'messageKey': 'login-register.apple-unavailable',
      };
    }

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: _sha256ofString(_generateNonce()),
      );

      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        return {
          'status': 'error',
          'messageKey': 'login-register.apple-auth-failed',
        };
      }

      final dynamic data = await ApiService.post('auth/apple/mobile', {
        'identityToken': identityToken,
        if (credential.email != null && credential.email!.isNotEmpty)
          'email': credential.email,
        if (credential.givenName != null && credential.givenName!.isNotEmpty)
          'firstName': credential.givenName,
        if (credential.familyName != null && credential.familyName!.isNotEmpty)
          'lastName': credential.familyName,
      });

      if (data is! Map) {
        return {
          'status': 'error',
          'messageKey': 'login-register.apple-auth-failed',
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
        analyticsMethod: 'apple',
        isNewUser: isNewUser,
      );
      return {'status': 'success', 'isNewUser': isNewUser};
    } on ApiException catch (e) {
      return {
        'status': 'error',
        'message': e.message,
      };
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return {
          'status': 'cancelled',
          'messageKey': 'login-register.user-cancelled-login',
        };
      }
      debugPrint('AppleAuthService: authorization error: $e');
      return {
        'status': 'error',
        'messageKey': 'login-register.apple-auth-failed',
      };
    } catch (e, st) {
      debugPrint('AppleAuthService.signIn failed: $e\n$st');
      return {
        'status': 'error',
        'messageKey': 'errors.network',
      };
    }
  }

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
