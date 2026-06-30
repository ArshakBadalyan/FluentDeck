import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluentdeck/localization/app_localizations.dart';
import 'package:fluentdeck/services/analytics_service.dart';
import 'package:fluentdeck/services/click_tracking.dart';
import 'package:fluentdeck/services/interaction_haptics.dart';

class EnglishBottomNav extends StatelessWidget {
  const EnglishBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  Color _iconColor(bool active) =>
      active ? const Color(0xFF8419FF) : const Color(0xFF777481);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.black.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: (index) {
          InteractionHaptics.pulse();
          ClickTracker.recordNamedTap();
          AnalyticsService.instance.logTap(
            targetId: 'bottom_nav.english.$index',
            extra: {'main_index': index},
          );
          onTap(index);
        },
        showUnselectedLabels: true,
        selectedItemColor: const Color(0xFF8419FF),
        unselectedItemColor: const Color(0xFF777481),
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.mic, color: _iconColor(currentIndex == 0)),
            label: 'Speak',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.style_outlined,
              color: _iconColor(currentIndex == 1),
            ),
            label: 'Decks',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.menu_book_outlined,
              color: _iconColor(currentIndex == 2),
            ),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/buttons/activity.svg',
              width: 26,
              colorFilter: ColorFilter.mode(
                _iconColor(currentIndex == 3),
                BlendMode.srcIn,
              ),
            ),
            label: AppLocalizations.instance.t('activity.Activity'),
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/buttons/profile.svg',
              width: 26,
              colorFilter: ColorFilter.mode(
                _iconColor(currentIndex == 4),
                BlendMode.srcIn,
              ),
            ),
            label: AppLocalizations.instance.t('profile.profile'),
          ),
        ],
      ),
    );
  }
}
