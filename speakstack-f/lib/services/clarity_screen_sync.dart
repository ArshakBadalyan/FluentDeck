import 'package:untitled2/services/clarity_screen_sync_mobile.dart'
    if (dart.library.html) 'package:untitled2/services/clarity_screen_sync_stub.dart'
    as _impl;

/// Microsoft Clarity "screen name" on iOS/Android; no-op on web / without project ID.
void syncClarityScreenName(String name) => _impl.syncClarityScreenName(name);
