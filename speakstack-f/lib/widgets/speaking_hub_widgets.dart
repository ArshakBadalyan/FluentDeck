import 'package:flutter/material.dart';
import 'package:untitled2/app_colors.dart';

/// Matches [MainAppBar] sub-tab styling (Decks, Library, Speak).
TabBar buildAppStyleTabBar({
  required TabController controller,
  required List<Widget> tabs,
}) {
  return TabBar(
    controller: controller,
    isScrollable: true,
    tabAlignment: TabAlignment.start,
    padding: const EdgeInsets.only(left: 12),
    labelColor: AppColors.primaryPurple,
    unselectedLabelColor: const Color(0xFF777481),
    indicatorColor: Colors.transparent,
    dividerColor: Colors.transparent,
    labelStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      fontFamily: 'Rubik',
    ),
    unselectedLabelStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      fontFamily: 'Rubik',
    ),
    tabs: tabs,
  );
}

IconData speakingIconForKey(String key) {
  switch (key) {
    case 'restaurant':
      return Icons.restaurant;
    case 'work':
      return Icons.work_outline;
    case 'school':
      return Icons.school_outlined;
    case 'favorite':
      return Icons.favorite_border;
    case 'travel':
      return Icons.flight;
    case 'hotel':
      return Icons.hotel;
    case 'health':
      return Icons.medical_services_outlined;
    case 'shopping':
      return Icons.shopping_bag_outlined;
    case 'transport':
      return Icons.local_taxi;
    case 'social':
      return Icons.people_outline;
    case 'bank':
      return Icons.account_balance;
    case 'movie':
      return Icons.movie_outlined;
    case 'library':
      return Icons.local_library_outlined;
    case 'delivery':
      return Icons.delivery_dining;
    case 'customs':
      return Icons.luggage;
    case 'haircut':
      return Icons.content_cut;
    case 'return':
      return Icons.assignment_return;
    case 'birthday':
      return Icons.cake_outlined;
    case 'family':
      return Icons.home_outlined;
    case 'routine':
      return Icons.alarm;
    case 'food':
      return Icons.fastfood_outlined;
    case 'holiday':
      return Icons.celebration;
    case 'dragon':
      return Icons.auto_stories;
    case 'question':
      return Icons.help_outline;
    case 'emoji':
      return Icons.emoji_emotions_outlined;
    case 'detective':
      return Icons.search;
    case 'quill':
      return Icons.edit_outlined;
    case 'would_you_rather':
      return Icons.compare_arrows;
    case 'home':
      return Icons.home_outlined;
    case 'pets':
      return Icons.pets;
    case 'hobbies':
      return Icons.interests_outlined;
    case 'music':
      return Icons.music_note_outlined;
    case 'books':
      return Icons.menu_book_outlined;
    case 'sports':
      return Icons.sports_soccer_outlined;
    case 'weather':
      return Icons.wb_sunny_outlined;
    case 'fashion':
      return Icons.checkroom_outlined;
    case 'garden':
      return Icons.yard_outlined;
    case 'camping':
      return Icons.park_outlined;
    case 'crafts':
      return Icons.brush_outlined;
    case 'gaming':
      return Icons.sports_esports_outlined;
    case 'furniture':
      return Icons.chair_outlined;
    case 'amusement':
      return Icons.attractions_outlined;
    case 'art':
      return Icons.palette_outlined;
    case 'memory':
      return Icons.history_edu_outlined;
    default:
      return Icons.chat_bubble_outline;
  }
}

class SpeakingSelectionCard extends StatelessWidget {
  const SpeakingSelectionCard({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.score,
    this.selected = false,
    this.trailing,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
  final int? score;
  final bool selected;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: selected ? 2 : 0,
      shadowColor: AppColors.primaryPurple.withValues(alpha: 0.2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primaryPurple : Colors.grey.shade200,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primaryPurple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Rubik',
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.3,
                          fontFamily: 'Rubik',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (score != null)
                Text(
                  '$score / 10',
                  style: const TextStyle(
                    color: AppColors.primaryPurple,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Rubik',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SpeakingGameGridCard extends StatelessWidget {
  const SpeakingGameGridCard({
    super.key,
    required this.title,
    required this.icon,
    this.score,
    this.featured = false,
    this.selected = false,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final int? score;
  final bool featured;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: selected ? 2 : 0,
      shadowColor: AppColors.primaryPurple.withValues(alpha: 0.15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primaryPurple : Colors.grey.shade200,
              width: selected ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              if (featured)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Popular',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryPurple,
                        fontFamily: 'Rubik',
                      ),
                    ),
                  ),
                ),
              if (score != null)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Text(
                    '$score / 10',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryPurple,
                      fontFamily: 'Rubik',
                    ),
                  ),
                ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 36, color: AppColors.primaryPurple),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        fontFamily: 'Rubik',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SpeakingStartButton extends StatelessWidget {
  const SpeakingStartButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: enabled ? onPressed : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              disabledBackgroundColor: AppColors.greySkipped.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                fontFamily: 'Rubik',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SpeakingFilterChips extends StatelessWidget {
  const SpeakingFilterChips({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = index == selectedIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(labels[index]),
              selected: selected,
              onSelected: (_) => onSelected(index),
              selectedColor: AppColors.primaryPurple.withValues(alpha: 0.12),
              checkmarkColor: AppColors.primaryPurple,
              labelStyle: TextStyle(
                color: selected ? AppColors.primaryPurple : const Color(0xFF777481),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                fontFamily: 'Rubik',
              ),
              side: BorderSide(
                color: selected ? AppColors.primaryPurple : Colors.grey.shade300,
              ),
            ),
          );
        }),
      ),
    );
  }
}
