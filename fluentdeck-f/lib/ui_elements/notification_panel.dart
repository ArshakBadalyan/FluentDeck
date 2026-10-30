import 'package:flutter/material.dart';
import 'package:riovox/app_colors.dart';
import 'package:riovox/localization/app_localizations.dart';
import 'package:riovox/services/audio_service.dart';
import 'package:riovox/services/notification_badge.dart';
import 'package:riovox/services/notifications_service.dart';
import 'package:riovox/ui_elements/modern_page_widgets.dart';
import 'package:riovox/utils/strapi_response.dart';
import 'package:riovox/ui_elements/app_motion.dart';

/// The notifications drawer. Opening it marks everything as seen (the bell's
/// number clears); read rows are plain, unread rows are tinted; each row can
/// be marked read or unread, and "mark all read" sits in the header.
class NotificationPanel extends StatefulWidget {
  final VoidCallback? onChanged;

  const NotificationPanel({super.key, this.onChanged});

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    AudioService().play('notificationOpen');
    // The number on the bell clears at once; the server follows.
    NotificationBadge.clearCount();
    _load();
    _markSeen();
  }

  Future<void> _markSeen() async {
    try {
      await NotificationsService.markAllSeen();
    } catch (e) {
      debugPrint('NotificationPanel markAllSeen failed: $e');
    }
    await NotificationBadge.refresh();
    widget.onChanged?.call();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
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
    } catch (e) {
      debugPrint('NotificationPanel load failed: $e');
      if (!mounted) return;
      setState(() {
        _error = "Couldn't load notifications. Check your connection and try again.";
        _loading = false;
      });
    }
  }

  /// Read or unread, shown right away, then saved.
  Future<void> _setRead(Map<String, dynamic> item, bool read) async {
    final id = item['id'];
    if (id is! int || (item['read'] == true) == read) return;
    setState(() {
      item['read'] = read;
      item['markedUnread'] = !read;
    });
    try {
      if (read) {
        await NotificationsService.readNotification(id);
      } else {
        await NotificationsService.markUnread(id);
      }
    } catch (e) {
      debugPrint('NotificationPanel setRead failed: $e');
      await _load();
    }
    await NotificationBadge.refresh();
    widget.onChanged?.call();
  }

  Future<void> _markAllRead() async {
    setState(() {
      for (final item in _items) {
        item['read'] = true;
        item['markedUnread'] = false;
      }
    });
    try {
      await NotificationsService.readAllNotifications();
    } catch (e) {
      debugPrint('NotificationPanel markAllRead failed: $e');
      await _load();
    }
    await NotificationBadge.refresh();
    widget.onChanged?.call();
  }

  static String _ago(Object? createdAt) {
    final when = DateTime.tryParse(createdAt?.toString() ?? '')?.toLocal();
    if (when == null) return '';
    final d = DateTime.now().difference(when);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return '${when.day}.${when.month.toString().padLeft(2, '0')}.${when.year}';
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = NotificationsService.hasUnread(_items);

    return SafeArea(
      child: Material(
        color: AppPageColors.cardBgOf(context),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: AppColors.heroGradient),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_none_outlined, color: Colors.white),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        context.tr('top-bar.notifications'),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.done_all_rounded),
                      color: Colors.white,
                      disabledColor: Colors.white.withValues(alpha: 0.4),
                      tooltip: context.tr('notification.mark-all-read'),
                      onPressed: hasUnread ? _markAllRead : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_error!),
                            const SizedBox(height: 12),
                            FilledButton(onPressed: _load, child: const Text('Try again')),
                          ],
                        ),
                      )
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
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _items.length,
                          separatorBuilder: (_, _) => Divider(height: 1, color: AppPageColors.subtleBorderOf(context)),
                          itemBuilder: (context, index) => AppStaggeredFadeIn(
                            index: index,
                            child: _NotificationRow(
                              item: _items[index],
                              ago: _ago(_items[index]['createdAt']),
                              onTap: () => _setRead(_items[index], true),
                              onToggle: () => _setRead(_items[index], _items[index]['read'] != true),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One notification: white when read, tinted (a darker tone in dark mode)
/// when unread, with a read/unread toggle on the right.
class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.item,
    required this.ago,
    required this.onTap,
    required this.onToggle,
  });

  final Map<String, dynamic> item;
  final String ago;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final read = item['read'] == true;
    final achievement = item['type'] == 'achievement';
    final teal = AppPageColors.tintOf(context, AppTint.teal);
    final reward = AppPageColors.tintOf(context, AppTint.reward);
    final text = (item['text'] ?? '').toString().trim();
    return Material(
      color: read ? AppPageColors.cardBgOf(context) : teal.bg,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: achievement ? reward.bg : (read ? AppPageColors.fieldBgOf(context) : AppPageColors.cardBgOf(context)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  achievement ? Icons.emoji_events_rounded : Icons.notifications_rounded,
                  size: 20,
                  color: achievement ? AppColors.primaryYellow : teal.fg,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (!read) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: teal.fg, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            (item['title'] ?? '').toString(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: read ? FontWeight.w500 : FontWeight.w700,
                              color: AppPageColors.textPrimaryOf(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (text.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(text, style: TextStyle(fontSize: 13, height: 1.35, color: AppPageColors.subtitleOf(context))),
                    ],
                    if (ago.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(ago, style: TextStyle(fontSize: 11.5, color: AppPageColors.mutedOf(context))),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: read ? 'Mark as unread' : 'Mark as read',
                icon: Icon(
                  read ? Icons.mark_email_unread_outlined : Icons.mark_email_read_outlined,
                  size: 20,
                  color: AppPageColors.subtitleOf(context),
                ),
                onPressed: onToggle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
