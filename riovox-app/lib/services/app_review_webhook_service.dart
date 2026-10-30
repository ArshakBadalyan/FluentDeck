import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'token_storage.dart';

/// Make.com webhook for in-app review / feedback payloads.
class AppReviewWebhookService {
  AppReviewWebhookService._();

  static const String webhookUrl =
      'https://hook.eu2.make.com/an75hafoapas8yvpn142fpnmghvf5h2y';

  static Future<void> submit({
    required int stars,
    required String message,
    required String testerPlatform,
  }) async {
    final userId = await TokenStorage.getUserId();
    final idForContact = userId?.toString() ?? '';

    final payload = <String, String>{
      'form-name': 'App review',
      'tester-name': '',
      'tester-email': '',
      'tester-platform': testerPlatform,
      'name': idForContact,
      'email': '',
      'phone': stars.toString(),
      'message': message,
      'subscription-email': '',
    };

    final response = await http.post(
      Uri.parse(webhookUrl),
      headers: const {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint(
        'AppReviewWebhookService: POST failed ${response.statusCode} ${response.body}',
      );
      throw AppReviewWebhookException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }
  }
}

class AppReviewWebhookException implements Exception {
  AppReviewWebhookException({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}
