import 'package:riovox/services/clarity_screen_sync_mobile.dart'
    if (dart.library.html) 'package:riovox/services/clarity_screen_sync_stub.dart'
    as impl;

/// Microsoft Clarity "screen name" on iOS/Android; no-op on web / without project ID.
void syncClarityScreenName(String name) => impl.syncClarityScreenName(name);
