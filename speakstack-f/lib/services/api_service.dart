import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakstack/utils/api_exception.dart';

class ApiService {
  static String get baseUrl {
    return dotenv.env['API_URL']!;
  }

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final format = dotenv.env['STRAPI_RESPONSE_FORMAT']?.trim().toLowerCase();
    final useV4Header = format != 'v5' && format != '5';

    return {
      'Content-Type': 'application/json',
      if (useV4Header) 'Strapi-Response-Format': 'v4',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Bearer + JSON headers (same token as other API calls).
  static Future<Map<String, String>> requestHeaders() async => _headers();

  static dynamic _decodeResponse(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String message = 'Request failed (${res.statusCode})';
      dynamic body;
      if (res.body.isNotEmpty) {
        try {
          body = jsonDecode(res.body);
          if (body is Map) {
            final err = body['error'];
            if (err is Map && err['message'] != null) {
              message = err['message'].toString();
            }
          }
        } catch (_) {
          message = res.body.length > 200
              ? '${res.body.substring(0, 200)}…'
              : res.body;
        }
      }
      throw ApiException(res.statusCode, message, body: body);
    }

    if (res.body.isEmpty) return <String, dynamic>{};
    return jsonDecode(res.body);
  }

  static Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$baseUrl/$path').replace(
      queryParameters: query?.isNotEmpty == true ? query : null,
    );
    final res = await http.get(uri, headers: await _headers());
    return _decodeResponse(res);
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl/$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decodeResponse(res);
  }

  static Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$baseUrl/$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decodeResponse(res);
  }

  static Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decodeResponse(res);
  }

  static Future<dynamic> delete(String path) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/$path'),
      headers: await _headers(),
    );
    return _decodeResponse(res);
  }

  static Future<http.Response> getRaw(String path) async {
    return http.get(
      Uri.parse('$baseUrl/$path'),
      headers: await _headers(),
    );
  }

  static Future<dynamic> postMultipart(
    String path, {
    required String field,
    required List<int> bytes,
    required String filename,
    Map<String, String>? fields,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/$path'));
    final headers = await _headers();
    headers.remove('Content-Type');
    request.headers.addAll(headers);
    if (fields != null) request.fields.addAll(fields);
    request.files.add(
      http.MultipartFile.fromBytes(field, bytes, filename: filename),
    );
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _decodeResponse(res);
  }
}
