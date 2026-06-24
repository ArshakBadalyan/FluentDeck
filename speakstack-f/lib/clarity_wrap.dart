import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Microsoft Clarity project ID from `CLARITY_PROJECT_ID` in [assets/english_config.txt].
String? _clarityProjectId() {
  final id = dotenv.env['CLARITY_PROJECT_ID']?.trim();
  if (id == null || id.isEmpty) {
    return null;
  }
  return id;
}

/// Clarity Flutter SDK supports iOS and Android only.
Widget wrapWithClarity(Widget app) {
  final projectId = _clarityProjectId();
  if (projectId == null) {
    return app;
  }
  if (defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS) {
    return app;
  }
  return ClarityWidget(
    app: app,
    clarityConfig: ClarityConfig(
      projectId: projectId,
      logLevel: kDebugMode ? LogLevel.Verbose : LogLevel.Info,
    ),
  );
}
