import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

bool _clarityMobileEnabled() {
  final id = dotenv.env['CLARITY_PROJECT_ID']?.trim();
  if (id == null || id.isEmpty) {
    return false;
  }
  if (defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS) {
    return false;
  }
  return true;
}

void syncClarityScreenName(String name) {
  if (!_clarityMobileEnabled()) {
    return;
  }
  Clarity.setCurrentScreenName(name);
}
