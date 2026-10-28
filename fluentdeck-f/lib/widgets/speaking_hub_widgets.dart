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
    this.tint,
  });

  final IconData icon;
  final String title;
  final double size;
  final double iconSize;

  /// Overrides the title-picked tint.
  final AppTint? tint;

  @override
  Widget build(BuildContext context) {
    final tint = this.tint ?? speakingIconTint(title);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppPageColors.tintOf(context, tint).bg,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: AppPageColors.tintIconOf(context, tint), size: iconSize),
    );
  }
}

/// White row card: icon tile, title, detail; selected = 2 dp teal border.
/// With [showChevron] it is a tap-to-start row (Role-play list).
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
    this.showChevron = false,
    this.iconTint,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final AppTint? iconTint;
  final String? subtitle;
  final int? score;
  final bool selected;
  final bool isPremiumLocked;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Dark mode dials the selected outline back to a translucent version
    // (a saturated ring on near-black reads like neon).
    final selectedBorderColor = isDark
        ? AppColors.brandPrimaryOnDark.withValues(alpha: 0.6)
        : AppColors.brandPrimary;
    return Opacity(
      opacity: isPremiumLocked ? 0.55 : 1,
      child: AppPressScale(
        child: Material(
          color: AppPageColors.cardBgOf(context),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: AppMotion.duration(context, AppMotion.fast),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? selectedBorderColor : AppPageColors.subtleBorderOf(context),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  SpeakingListIconBadge(icon: icon, title: title, size: 48, tint: iconTint),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppPageColors.textPrimaryOf(context),
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
                    )
                  else if (score != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        '$score / 10',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppPageColors.accentOf(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  if (showChevron && !isPremiumLocked)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(Icons.chevron_right_rounded, size: 22, color: AppPageColors.mutedOf(context)),
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

/// Topics grid card: icon tile on top, bold title, one-line description.
class SpeakingTopicGridCard extends StatelessWidget {
  const SpeakingTopicGridCard({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.selected = false,
    this.isPremiumLocked = false,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
  final bool selected;
  final bool isPremiumLocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Opacity(
      opacity: isPremiumLocked ? 0.55 : 1,
      child: AppPressScale(
        child: Material(
          color: AppPageColors.cardBgOf(context),
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
                      ? (isDark ? AppColors.brandPrimaryOnDark.withValues(alpha: 0.6) : AppColors.brandPrimary)
                      : AppPageColors.subtleBorderOf(context),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SpeakingListIconBadge(icon: icon, title: title),
                      const Spacer(),
                      if (isPremiumLocked)
                        Icon(Icons.lock_outline, color: AppPageColors.subtitleOf(context), size: 18),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppPageColors.textPrimaryOf(context),
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, height: 1.4, color: AppPageColors.subtitleOf(context)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 150 dp game tile: colored icon, then the name and a one-line description
/// at the bottom. The featured game is the one dark-teal tile.
class SpeakingGameGridCard extends StatelessWidget {
  const SpeakingGameGridCard({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.score,
    this.featured = false,
    this.selected = false,
    this.isPremiumLocked = false,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
  final int? score;
  final bool featured;
  final bool selected;
  final bool isPremiumLocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppPageColors.accentOf(context);
    final hero = featured && !isPremiumLocked;
    final bg = hero ? AppColors.brandPrimaryDeep : AppPageColors.cardBgOf(context);
    final fg = hero ? Colors.white : AppPageColors.textPrimaryOf(context);
    final iconColor = hero
        ? const Color(0xFF9FF0F5)
        : AppPageColors.tintIconOf(context, speakingIconTint(title));
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
              height: 150,
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
                      Icon(icon, color: iconColor, size: 28),
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
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, height: 1.2, color: fg),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: hero ? const Color(0xFFBFE4E7) : AppPageColors.subtitleOf(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The page's main action, floating above the bottom nav with a teal glow.
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
    final accent = AppPageColors.accentOf(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: AppPressScale(
          enabled: enabled,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: enabled
                  ? [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))]
                  : null,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: enabled ? onPressed : null,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: AppPageColors.onAccentOf(context),
                  disabledBackgroundColor: AppColors.greySkipped.withValues(alpha: 0.4),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
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
  static const double _edgeInset = 20;

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
      padding: const EdgeInsets.fromLTRB(_edgeInset, 4, _edgeInset, 12),
      child: Row(
        children: List.generate(widget.labels.length, (index) {
          final selected = index == widget.selectedIndex;
          return Padding(
            key: _keyFor(index),
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: selected ? AppPageColors.accentOf(context) : AppPageColors.cardBgOf(context),
              shape: StadiumBorder(
                side: selected
                    ? BorderSide.none
                    : BorderSide(color: AppPageColors.subtleBorderOf(context)),
              ),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => widget.onSelected(index),
                child: Semantics(
                  button: true,
                  selected: selected,
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    child: Text(
                      widget.labels[index],
                      style: TextStyle(
                        fontSize: 14,
                        color: selected
                            ? AppPageColors.onAccentOf(context)
                            : AppPageColors.textPrimaryOf(context),
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
