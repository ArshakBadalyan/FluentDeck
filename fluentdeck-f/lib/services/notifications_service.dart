import 'package:fluentdeck/utils/strapi_response.dart';

import 'api_service.dart';
import 'token_storage.dart';

class NotificationsService {

  static Future<Map<String, dynamic>> getNotifications({
    int page = 1,
  }) async {
    final userId = await TokenStorage.getUserId();

    final res = await ApiService.get(
      'notifications'
          '?filters[users_permissions_user][id][\$eq]=$userId'
          '&pagination[page]=$page'
          '&sort[0]=read'
          '&sort[1]=createdAt:desc',
    );

    return {
      'data': StrapiResponse.list(res),
      'pageCount': res['meta']?['pagination']?['pageCount'] ?? 0,
    };
  }


  static Future<bool> readNotification(int id) async {
    final res = await ApiService.put(
      'notifications/$id',
      {
        'data': {'read': true},
      },
    );

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


  static bool hasUnread(List<dynamic> notifications) {
    return notifications.any((n) {
      if (n is! Map) return false;
      final map = Map<String, dynamic>.from(n);
      return StrapiResponse.field<bool>(map, 'read') == false;
    });
  }
}
