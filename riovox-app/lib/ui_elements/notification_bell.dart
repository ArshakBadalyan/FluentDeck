import 'package:flutter/material.dart';
import 'package:riovox/app_colors.dart';
import 'package:riovox/services/notification_badge.dart';
import 'package:riovox/ui_elements/modern_page_widgets.dart';

/// The bell icon with its badge: a number for new notifications (top right),
/// a dot for ones you marked unread (top left), or both.
class NotificationBellIcon extends StatelessWidget {
  const NotificationBellIcon({super.key, this.size = 26, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<NotificationBadgeState>(
      valueListenable: NotificationBadge.state,
      builder: (context, s, _) {
        final label = s.newCount > 99 ? '99+' : '${s.newCount}';
        return Semantics(
          label: [
            'Notifications',
            if (s.newCount > 0) '${s.newCount} new',
            if (s.dot) 'some marked unread',
          ].join(', '),
          excludeSemantics: true,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.notifications_none_rounded, size: size, color: color),
              if (s.dot)
                Positioned(
                  left: -1,
                  top: -1,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: AppColors.voice,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppPageColors.cardBgOf(context), width: 1.5),
                    ),
                  ),
                ),
              if (s.newCount > 0)
                Positioned(
                  right: -8,
                  top: -6,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    height: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.redWrong,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: AppPageColors.cardBgOf(context), width: 1.5),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white, height: 1),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
