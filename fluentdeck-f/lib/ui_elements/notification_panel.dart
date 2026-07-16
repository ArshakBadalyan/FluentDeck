import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/localization/app_localizations.dart';
import 'package:fluentdeck/services/audio_service.dart';
import 'package:fluentdeck/services/notifications_service.dart';
import 'package:fluentdeck/utils/strapi_response.dart';

class NotificationPanel extends StatefulWidget {
  final VoidCallback? onChanged;

  const NotificationPanel({super.key, this.onChanged});

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    AudioService().play('notificationOpen');
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await NotificationsService.getNotifications();
    final raw = res['data'] as List? ?? [];
    final parsed = raw
        .whereType<Map>()
        .map((n) => StrapiResponse.unwrap(Map<String, dynamic>.from(n)))
        .toList();
    if (!mounted) return;
    setState(() {
      _items = parsed;
      _loading = false;
    });
  }

  Future<void> _markRead(Map<String, dynamic> item) async {
    final id = item['id'];
    if (id is int) {
      await NotificationsService.readNotification(id);
    }
    await _load();
    widget.onChanged?.call();
  }

  Future<void> _markAllRead() async {
    await NotificationsService.readAllNotifications();
    await _load();
    widget.onChanged?.call();
  }

  Future<void> _onTap(Map<String, dynamic> item) async {
    await _markRead(item);
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = NotificationsService.hasUnread(_items);

    return SafeArea(
      child: Material(
        color: Colors.white,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.80,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryPurple,
                    Color(0xFF5B12C9),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.notifications_none_outlined,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        context.tr('top-bar.notifications'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasUnread)
                        TextButton(
                          onPressed: _markAllRead,
                          child: Text(
                            context.tr('notification.mark-all-read'),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        tooltip: 'Close',
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onChanged?.call();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.tr('notification.there-arnt-notification')),
                          const SizedBox(height: 24),
                          Text(
                            context.tr('notification.welcome-app'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final read = item['read'] == true;
                        return ListTile(
                          dense: true,
                          tileColor: read
                              ? null
                              : AppColors.primaryPurple.withValues(alpha: 0.06),
                          title: Text(
                            (item['title'] ?? '').toString(),
                            style: TextStyle(
                              fontWeight:
                                  read ? FontWeight.normal : FontWeight.w600,
                            ),
                          ),
                          subtitle: Text((item['text'] ?? '').toString()),
                          onTap: () => _onTap(item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
