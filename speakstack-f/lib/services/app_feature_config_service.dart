import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/app_feature_config_model.dart';
import 'api_service.dart';

class AppFeatureConfigService {
  AppFeatureConfigService._();
  static final AppFeatureConfigService instance = AppFeatureConfigService._();

  AppFeatureConfigModel _cached = const AppFeatureConfigModel();
  AppFeatureConfigModel get config => _cached;

  Future<AppFeatureConfigModel> fetch() async {
    try {
      final base = ApiService.baseUrl.replaceAll(RegExp(r'/api/?$'), '');
      final res = await http.get(
        Uri.parse('$base/api/app-feature-config-public'),
      );
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json is Map<String, dynamic>) {
          _cached = AppFeatureConfigModel.fromJson(json);
        }
      }
    } catch (_) {
      // Keep defaults on failure.
    }
    return _cached;
  }
}
