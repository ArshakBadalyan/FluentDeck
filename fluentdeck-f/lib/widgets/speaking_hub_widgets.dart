import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/ui_elements/app_motion.dart';
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
      // Flat soft tint of the item's accent (Lagoon Daylight).
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.32),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // A solid 2px brandPrimary border reads as a normal selection outline on
    // white, but the same color looks like a glowing neon ring against the
    // near-black dark surfaces (irradiation — a saturated color against a
    // dark background looks far more vivid than its actual RGB value) — so
    // dark mode dials the border back to a translucent, thinner version of
    // the same selected-state indicator instead of a different color.
    final selectedBorderColor = isDark
        ? AppColors.brandPrimaryOnDark.withValues(alpha: 0.6)
        : AppColors.brandPrimary;
    return Opacity(
      opacity: isPremiumLocked ? 0.55 : 1,
      child: AppPressScale(
      child: Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: AppMotion.duration(context, AppMotion.fast),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? selectedBorderColor
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
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
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
                          fontSize: 13,
                          color: AppPageColors.subtitleOf(context),
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
                  child: Icon(Icons.lock_outline, color: AppPageColors.subtitleOf(context), size: 20),
                ),
              if (score != null)
                Text(
                  '$score / 10',
                  style: TextStyle(
                    color: AppPageColors.accentOf(context),
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Rubik',
                  ),
                ),
            ],
          ),
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
    final accent = AppPageColors.accentOf(context);
    // The featured game is the one dark-teal card in the grid.
    final hero = featured && !isPremiumLocked;
    final bg = hero ? AppColors.brandPrimaryDeep : cardBg;
    final fg = hero ? Colors.white : AppPageColors.textPrimaryOf(context);
    return Opacity(
      opacity: isPremiumLocked ? 0.55 : 1,
      child: AppPressScale(
      child: Material(
      color: bg,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: AppMotion.duration(context, AppMotion.fast),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: hero
                ? null
                : Border.all(
                    color: selected ? accent : AppPageColors.subtleBorderOf(context),
                    width: selected ? 2 : 1,
                  ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  hero
                      ? Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(icon, color: const Color(0xFF9FF0F5), size: 22),
                        )
                      : SpeakingListIconBadge(icon: icon, title: title),
                  const Spacer(),
                  if (isPremiumLocked)
                    Icon(Icons.lock_outline, color: AppPageColors.subtitleOf(context), size: 18)
                  else if (score != null)
                    Text(
                      '$score / 10',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: hero ? Colors.white : accent,
                      ),
                    )
                  else if (hero)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.voice,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Popular',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, height: 1.2, color: fg),
              ),
            ],
          ),
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
          height: 56,
          child: AppPressScale(
            enabled: enabled,
            child: FilledButton(
              onPressed: enabled ? onPressed : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppPageColors.accentOf(context),
                foregroundColor: AppPageColors.onAccentOf(context),
                disabledBackgroundColor: AppColors.greySkipped.withValues(alpha: 0.4),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Rubik',
                ),
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
              showCheckmark: false,
              onSelected: (_) => widget.onSelected(index),
              backgroundColor: AppPageColors.cardBgOf(context),
              selectedColor: AppPageColors.accentOf(context),
              labelStyle: TextStyle(
                color: selected ? AppPageColors.onAccentOf(context) : AppPageColors.textPrimaryOf(context),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                fontFamily: 'Rubik',
              ),
              side: BorderSide(
                color: selected ? AppPageColors.accentOf(context) : AppPageColors.subtleBorderOf(context),
              ),
            ),
          );
        }),
      ),
    );
  }
}
