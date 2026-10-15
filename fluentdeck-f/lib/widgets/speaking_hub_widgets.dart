import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';
import 'package:fluentdeck/utils/speaking_item_icons.dart';

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
    labelColor: AppColors.brandPrimary,
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

IconData speakingIconForKey(String key) =>
    resolveSpeakingListIcon(title: '', iconKey: key);

class SpeakingListIconBadge extends StatelessWidget {
  const SpeakingListIconBadge({
    super.key,
    required this.icon,
    required this.title,
    this.size = 44,
    this.iconSize = 22,
  });

  final IconData icon;
  final String title;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final accent = speakingIconAccent(title);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.18),
            accent.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Icon(icon, color: accent, size: iconSize),
    );
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
    this.isPremiumLocked = false,
    this.trailing,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
  final int? score;
  final bool selected;
  final bool isPremiumLocked;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cardBg = AppPageColors.cardBgOf(context);
    return Opacity(
      opacity: isPremiumLocked ? 0.55 : 1,
      child: Material(
      color: selected
          ? Color.alphaBlend(
              AppColors.brandPrimary.withValues(alpha: 0.06),
              cardBg,
            )
          : cardBg,
      borderRadius: BorderRadius.circular(16),
      elevation: selected ? 2 : 0,
      shadowColor: AppColors.brandPrimary.withValues(alpha: 0.2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppColors.brandPrimary
                  : AppPageColors.subtleBorderOf(context),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              SpeakingListIconBadge(icon: icon, title: title),
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
              if (isPremiumLocked)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(Icons.lock_outline, color: Colors.grey.shade600, size: 20),
                ),
              if (score != null)
                Text(
                  '$score / 10',
                  style: const TextStyle(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Rubik',
                  ),
                ),
            ],
          ),
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
    this.isPremiumLocked = false,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final int? score;
  final bool featured;
  final bool selected;
  final bool isPremiumLocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cardBg = AppPageColors.cardBgOf(context);
    return Opacity(
      opacity: isPremiumLocked ? 0.55 : 1,
      child: Material(
      color: selected
          ? Color.alphaBlend(
              AppColors.brandPrimary.withValues(alpha: 0.06),
              cardBg,
            )
          : cardBg,
      borderRadius: BorderRadius.circular(16),
      elevation: selected ? 2 : 0,
      shadowColor: AppColors.brandPrimary.withValues(alpha: 0.15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppColors.brandPrimary
                  : AppPageColors.subtleBorderOf(context),
              width: selected ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              if (featured && !isPremiumLocked)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Popular',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandPrimary,
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
                      color: AppColors.brandPrimary,
                      fontFamily: 'Rubik',
                    ),
                  ),
                ),
              if (isPremiumLocked)
                const Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(Icons.lock_outline, color: Colors.black45, size: 18),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SpeakingListIconBadge(
                      icon: icon,
                      title: title,
                      size: 52,
                      iconSize: 26,
                    ),
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
              ),
            ],
          ),
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
              backgroundColor: AppColors.brandPrimary,
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

class SpeakingFilterChips extends StatefulWidget {
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
  State<SpeakingFilterChips> createState() => _SpeakingFilterChipsState();
}

class _SpeakingFilterChipsState extends State<SpeakingFilterChips> {
  static const double _edgeInset = 16;

  final Map<int, GlobalKey> _chipKeys = {};

  GlobalKey _keyFor(int index) => _chipKeys.putIfAbsent(index, GlobalKey.new);

  @override
  void initState() {
    super.initState();
    _revealSelected(animate: false);
  }

  @override
  void didUpdateWidget(SpeakingFilterChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) _revealSelected();
  }

  /// Scrolls the selected chip fully into view. Centering clamps at the ends,
  /// so the first/last chip settles against the side inset, clear of the fade.
  void _revealSelected({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _chipKeys[widget.selectedIndex]?.currentContext;
      if (!mounted || ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.5,
        duration: animate ? const Duration(milliseconds: 250) : Duration.zero,
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Fade chips out over the side insets so they never butt against the
    // container edge while scrolling. At rest the first/last chip sits past
    // the fade, so it stays fully opaque.
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        final fade = bounds.width > 0 ? _edgeInset / bounds.width : 0.0;
        return LinearGradient(
          colors: const [
            Colors.transparent,
            Colors.black,
            Colors.black,
            Colors.transparent,
          ],
          stops: [0, fade, 1 - fade, 1],
        ).createShader(bounds);
      },
      child: _buildStrip(),
    );
  }

  Widget _buildStrip() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: _edgeInset, vertical: 8),
      child: Row(
        children: List.generate(widget.labels.length, (index) {
          final selected = index == widget.selectedIndex;
          return Padding(
            key: _keyFor(index),
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(widget.labels[index]),
              selected: selected,
              onSelected: (_) => widget.onSelected(index),
              selectedColor: AppColors.brandPrimary.withValues(alpha: 0.12),
              checkmarkColor: AppColors.brandPrimary,
              labelStyle: TextStyle(
                color: selected ? AppColors.brandPrimary : const Color(0xFF777481),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                fontFamily: 'Rubik',
              ),
              side: BorderSide(
                color: selected ? AppColors.brandPrimary : Colors.grey.shade300,
              ),
            ),
          );
        }),
      ),
    );
  }
}
