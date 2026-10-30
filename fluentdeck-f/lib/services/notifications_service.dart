import 'package:riovox/utils/strapi_response.dart';

import 'api_service.dart';

class NotificationsService {

  static Future<Map<String, dynamic>> getNotifications({
    int page = 1,
  }) async {
    final res = await ApiService.get(
      'notifications/mine',
      query: {'page': '$page'},
    );

    return {
      'data': StrapiResponse.list(res),
      'pageCount': res['meta']?['pagination']?['pageCount'] ?? 0,
    };
  }


  static Future<bool> readNotification(int id) async {
    final res = await ApiService.put('notifications/$id/read', const {});

    return res['data'] != null;
  }


  static Future<bool> readAllNotifications() async {
    final res = await ApiService.put(
      'readAllNotifications',
      {
        'data': {'read': true},
      },
    );

    return res != null;
  }


  /// "Mark as unread": the bell shows a dot for it.
  static Future<bool> markUnread(int id) async {
    final res = await ApiService.put('notifications/$id/unread', const {});
    return res is Map && res['data'] != null;
  }

  /// Opening the panel: everything new counts as seen (the number clears).
  static Future<void> markAllSeen() async {
    await ApiService.put('notifications/seen-all', const {});
  }

  /// For the bell: how many are new, and whether any were marked unread.
  static Future<({int newCount, bool hasMarkedUnread})> unreadSummary() async {
    final res = await ApiService.get('notifications/unread-summary');
    final data = res is Map ? res['data'] : null;
    if (data is! Map) return (newCount: 0, hasMarkedUnread: false);
    return (
      newCount: (data['newCount'] as num?)?.toInt() ?? 0,
      hasMarkedUnread: data['hasMarkedUnread'] == true,
    );
  }

  /// Creates the "Achievement unlocked" notification (once per achievement).
  static Future<void> reportAchievement({
    required String achievementId,
    required String title,
    required String description,
  }) async {
    await ApiService.post('notifications/achievement', {
      'achievementId': achievementId,
      'title': title,
      'description': description,
    });
  }

  static bool hasUnread(List<dynamic> notifications) {
    return notifications.any((n) {
      if (n is! Map) return false;
      final map = Map<String, dynamic>.from(n);
      return StrapiResponse.field<bool>(map, 'read') == false;
    });
  }
}
