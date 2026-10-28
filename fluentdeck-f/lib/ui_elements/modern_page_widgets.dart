import 'package:fluentdeck/ui_elements/app_dialog.dart';
import 'dart:math';

import 'package:flutter/cupertino.dart' show CupertinoSwitch;
import 'package:flutter/material.dart';
import 'package:fluentdeck/config/brand_config.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/ui_elements/frosted_bottom_sheet.dart';
import 'app_motion.dart';
import 'package:fluentdeck/widgets/tutor_scene.dart';

/// Soft tints from the redesign; see [AppPageColors.tintOf].
enum AppTint { teal, voice, reward, success, warning, danger, info, pink, neutral }

/// Shared visual language for Activity, Decks, and Profile screens.
class AppPageColors {
  AppPageColors._();

  static const pageBg = BrandConfig.pageBg;
  static const cardBg = BrandConfig.cardBg;
  static const fieldBg = BrandConfig.fieldBg;

  /// Dark scaffold / page background.
  static const darkPageBg = BrandConfig.darkPageBg;
  /// Dark cards & app bar surface.
  static const darkCardBg = BrandConfig.darkCardBg;
  /// Dark raised surface (dialogs, sheets, menus, inputs).
  static const darkRaisedBg = BrandConfig.darkRaisedBg;

  static Color pageBgOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkPageBg : pageBg;

  static Color cardBgOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkCardBg : cardBg;

  static Color fieldBgOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkRaisedBg : fieldBg;

  static Color subtleBorderOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.08)
          : BrandConfig.border;

  /// Hairline between rows inside a card.
  static Color rowDividerOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.06)
          : BrandConfig.rowDivider;

  /// Muted labels and inactive icons (nav, "or continue with").
  static Color mutedOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? BrandConfig.darkTextSecondary
          : BrandConfig.navInactive;

  /// Icon color on a [tintOf] tile: teal and coral icons use the stronger
  /// brand hue (#0D7C86, #E2553A); the rest use the tint's text color.
  static Color tintIconOf(BuildContext context, AppTint tint) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (!dark && tint == AppTint.teal) return BrandConfig.primary;
    if (!dark && tint == AppTint.voice) return BrandConfig.voiceDeep;
    return tintOf(context, tint).fg;
  }

  /// Soft fill and the readable text on it, for chips, icon tiles, count
  /// badges and notices. Dark mode uses the hue at low alpha with a lighter
  /// foreground.
  static ({Color bg, Color fg}) tintOf(BuildContext context, AppTint tint) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    switch (tint) {
      case AppTint.teal:
        return dark
            ? (bg: BrandConfig.primaryOnDark.withValues(alpha: 0.16), fg: BrandConfig.primaryOnDark)
            : (bg: BrandConfig.tealTint, fg: BrandConfig.primaryDeep);
      case AppTint.voice:
        return dark
            ? (bg: BrandConfig.voice.withValues(alpha: 0.16), fg: const Color(0xFFFF9B80))
            : (bg: BrandConfig.voiceTint, fg: BrandConfig.voiceTintText);
      case AppTint.reward:
        return dark
            ? (bg: BrandConfig.reward.withValues(alpha: 0.16), fg: const Color(0xFFFFD54F))
            : (bg: BrandConfig.rewardTint, fg: BrandConfig.rewardText);
      case AppTint.success:
        return dark
            ? (bg: BrandConfig.correct.withValues(alpha: 0.14), fg: const Color(0xFF6EF09A))
            : (bg: BrandConfig.successTint, fg: BrandConfig.successText);
      case AppTint.warning:
        return dark
            ? (bg: BrandConfig.hard.withValues(alpha: 0.18), fg: const Color(0xFFFFB27A))
            : (bg: BrandConfig.warningTint, fg: BrandConfig.warningText);
      case AppTint.danger:
        return dark
            ? (bg: BrandConfig.wrong.withValues(alpha: 0.18), fg: const Color(0xFFFF8A80))
            : (bg: BrandConfig.dangerTint, fg: BrandConfig.dangerText);
      case AppTint.info:
        return dark
            ? (bg: BrandConfig.newCards.withValues(alpha: 0.18), fg: const Color(0xFF82B1FF))
            : (bg: BrandConfig.infoTint, fg: BrandConfig.infoText);
      case AppTint.pink:
        return dark
            ? (bg: const Color(0xFFE9407A).withValues(alpha: 0.16), fg: const Color(0xFFFF8FB3))
            : (bg: BrandConfig.pinkTint, fg: BrandConfig.pinkText);
      case AppTint.neutral:
        return dark
            ? (bg: Colors.white.withValues(alpha: 0.06), fg: BrandConfig.darkTextSecondary)
            : (bg: BrandConfig.pageBg, fg: BrandConfig.navInactive);
    }
  }

  static Color subtitleOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? BrandConfig.darkTextSecondary
          : BrandConfig.textSecondary;

  /// Primary (highest-emphasis) body text — for the common bug pattern of a
  /// widget hardcoding `Colors.black` / `Colors.black87` instead of inheriting
  /// the theme's text color, which reads as near-invisible dark text on a
  /// dark surface.
  static Color textPrimaryOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? BrandConfig.darkTextPrimary
          : BrandConfig.textPrimary;

  /// Brand teal for text/icons/selected-state accents — [AppColors.brandPrimary]
  /// (#0D7C86) is tuned for contrast on light surfaces and reads muddy on the
  /// dark surfaces above, so dark mode swaps to the brighter
  /// [AppColors.brandPrimaryOnDark] (#2EC4CF; see the WCAG note in
  /// `brand_config.dart`). Use this anywhere brandPrimary was being used as a
  /// foreground color that also needs to work in dark mode.
  static Color accentOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.brandPrimaryOnDark
          : AppColors.brandPrimary;

  /// Readable text/icon color for a surface painted [accentOf] — e.g. a
  /// selected chip or a filled CTA. Dark mode's `brandPrimaryOnDark` is a
  /// *brighter* teal than light mode's `brandPrimary`, so white text that
  /// works on the light-mode accent fails contrast on the dark-mode one;
  /// this mirrors the pairing `AppTheme.dark`'s `filledButtonTheme` already
  /// uses (`BrandConfig.onPrimaryDark`, a near-black).
  static Color onAccentOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? BrandConfig.onPrimaryDark
          : Colors.white;
}

class AppPageBackground extends StatelessWidget {
  const AppPageBackground({super.key, required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color ?? AppPageColors.pageBgOf(context),
      child: child,
    );
  }
}

class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.subtitle,
    this.subtitleWidget,
    this.trailing,
    this.padding = const EdgeInsets.all(18),
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final String? subtitle;
  final Widget? subtitleWidget;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final cardBg = AppPageColors.cardBgOf(context);
    final borderColor = AppPageColors.subtleBorderOf(context);

    // Flat card with a hairline border (Lagoon Daylight); the section icon
    // sits in a soft tinted badge.
    return AppFadeIn(
      child: Material(
      color: cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppPageColors.accentOf(context).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, size: 18, color: AppPageColors.accentOf(context)),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            if (subtitleWidget != null || subtitle != null) ...[
              const SizedBox(height: 4),
              subtitleWidget ??
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppPageColors.subtitleOf(context),
                    ),
                  ),
            ],
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    ),
    );
  }
}

/// Large tappable row for Settings hub categories (Profile → Settings home).
class AppSettingsCategoryTile extends StatelessWidget {
  const AppSettingsCategoryTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppPressScale(
      child: Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppPageColors.cardBgOf(context),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppPageColors.subtleBorderOf(context)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppPageColors.accentOf(context).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 22, color: AppPageColors.accentOf(context)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppPageColors.subtitleOf(context),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppPageColors.subtitleOf(context)),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}

/// Nested group inside a settings page — title bar + child controls.
class AppSettingsGroup extends StatelessWidget {
  const AppSettingsGroup({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.borderRadius = 16,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    // Small grey label above a flat grouped card (Lagoon Daylight).
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: AppPageColors.subtitleOf(context),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppPageColors.subtitleOf(context),
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Material(
            color: AppPageColors.cardBgOf(context),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius < 20 ? 20 : borderRadius),
              side: BorderSide(color: AppPageColors.subtleBorderOf(context)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// A circular ring showing two solid-color arcs on the same 0..1 scale: a
/// "target" arc marking where a goal is set, and a "progress" arc showing
/// how far actual progress has reached — drawn on top so it covers the
/// target arc where the two overlap, and extends past it once progress
/// exceeds the target.
class DualArcProgressRing extends StatelessWidget {
  const DualArcProgressRing({
    super.key,
    required this.targetFraction,
    required this.progressFraction,
    required this.targetColor,
    required this.progressColor,
    this.size = 76,
    this.strokeWidth = 5,
    this.trackColor,
    this.center,
    this.animationDuration = AppMotion.slow,
    this.animationCurve = AppMotion.standardCurve,
  });

  /// 0..1 — where the target/goal marker sits on the ring.
  final double targetFraction;

  /// 0..1 — how far actual progress has filled the ring.
  final double progressFraction;
  final Color targetColor;
  final Color progressColor;
  final double size;
  final double strokeWidth;
  final Color? trackColor;
  final Widget? center;

  /// How the arcs (and their colors) sweep to new values. The ring fills in
  /// from empty when it first appears; later changes sweep from where the
  /// arcs currently are, so rapid updates (dragging) stay continuous.
  final Duration animationDuration;
  final Curve animationCurve;

  @override
  Widget build(BuildContext context) {
    final end = _RingValues(
      target: targetFraction,
      progress: progressFraction,
      targetColor: targetColor,
      progressColor: progressColor,
    );
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<_RingValues>(
            tween: _RingTween(
              begin: _RingValues(
                target: 0,
                progress: 0,
                targetColor: targetColor,
                progressColor: progressColor,
              ),
              end: end,
            ),
            duration: AppMotion.duration(context, animationDuration),
            curve: animationCurve,
            builder: (context, v, _) => CustomPaint(
              size: Size.square(size),
              painter: _DualArcPainter(
                targetFraction: v.target,
                progressFraction: v.progress,
                targetColor: v.targetColor,
                progressColor: v.progressColor,
                strokeWidth: strokeWidth,
                trackColor: trackColor ?? AppPageColors.subtleBorderOf(context),
              ),
            ),
          ),
          if (center != null) center!,
        ],
      ),
    );
  }
}

class _RingValues {
  const _RingValues({
    required this.target,
    required this.progress,
    required this.targetColor,
    required this.progressColor,
  });

  final double target;
  final double progress;
  final Color targetColor;
  final Color progressColor;
}

class _RingTween extends Tween<_RingValues> {
  _RingTween({super.begin, super.end});

  @override
  _RingValues lerp(double t) {
    final a = begin!;
    final b = end!;
    return _RingValues(
      target: a.target + (b.target - a.target) * t,
      progress: a.progress + (b.progress - a.progress) * t,
      targetColor: Color.lerp(a.targetColor, b.targetColor, t)!,
      progressColor: Color.lerp(a.progressColor, b.progressColor, t)!,
    );
  }
}

class _DualArcPainter extends CustomPainter {
  _DualArcPainter({
    required this.targetFraction,
    required this.progressFraction,
    required this.targetColor,
    required this.progressColor,
    required this.strokeWidth,
    required this.trackColor,
  });

  final double targetFraction;
  final double progressFraction;
  final Color targetColor;
  final Color progressColor;
  final double strokeWidth;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    final target = targetFraction.clamp(0.0, 1.0);
    if (target > 0) {
      canvas.drawArc(
        rect,
        -pi / 2,
        target * 2 * pi,
        false,
        Paint()
          ..color = targetColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }

    final progress = progressFraction.clamp(0.0, 1.0);
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -pi / 2,
        progress * 2 * pi,
        false,
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DualArcPainter old) =>
      old.targetFraction != targetFraction ||
      old.progressFraction != progressFraction ||
      old.targetColor != targetColor ||
      old.progressColor != progressColor ||
      old.trackColor != trackColor;
}

class AppHeroCard extends StatelessWidget {
  const AppHeroCard({
    super.key,
    required this.value,
    required this.label,
    required this.subtitle,
    required this.icon,
    this.badge,
    this.action,
    this.onIconTap,
    this.scene,
    this.sceneOnLeft = false,
  });

  final String value;
  final String label;
  final String subtitle;
  final IconData icon;
  final Widget? badge;
  final Widget? action;
  final VoidCallback? onIconTap;

  /// Optional tutor scene on one side of the card (the card colour fades over it).
  final TutorScene? scene;
  final bool sceneOnLeft;

  Widget _withScene(Widget content, {required double clearFactor}) {
    final s = scene;
    if (s == null) return content;
    // The picture takes the outer ~40% and the text keeps clear of it.
    return SceneBackdrop(
      scene: s,
      onLeft: sceneOnLeft,
      widthFactor: 0.4,
      color: sceneOnLeft ? AppColors.heroGradient.first : AppColors.heroGradient.last,
      child: LayoutBuilder(
        builder: (context, c) {
          final clear = (c.maxWidth * clearFactor).clamp(0.0, 200.0);
          return Padding(
            padding: sceneOnLeft
                ? EdgeInsets.only(left: clear)
                : EdgeInsets.only(right: clear),
            child: content,
          );
        },
      ),
    );
  }

  /// Solid white action disc: the one obvious thing to tap.
  Widget _disc({required bool compact}) {
    return AppPressScale(
      enabled: onIconTap != null,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        child: InkWell(
          onTap: onIconTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: EdgeInsets.all(compact ? 13 : 18),
            child: Icon(icon, size: compact ? 26 : 32, color: AppColors.brandPrimaryDeep),
          ),
        ),
      ),
    );
  }

  Widget _text() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCountUpText(
          value,
          style: const TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.92),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.78),
          ),
        ),
        if (badge != null) ...[const SizedBox(height: 12), badge!],
        if (action != null) ...[const SizedBox(height: 14), action!],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppFadeIn(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Phones: the disc moves into the picture's bottom corner (clear of
          // Rio's face) so the text side keeps room for its pills and buttons.
          final compact = scene != null && constraints.maxWidth < 480;
          Widget body = _withScene(
            Padding(
              padding: const EdgeInsets.all(24),
              child: compact
                  ? _text()
                  : Row(
                      children: [
                        Expanded(child: _text()),
                        _disc(compact: false),
                      ],
                    ),
            ),
            clearFactor: 0.3,
          );
          if (compact) {
            body = Stack(
              // Passthrough keeps the card's full width (a loose Stack would
              // shrink the picture to the text's width).
              fit: StackFit.passthrough,
              children: [
                body,
                Positioned(
                  bottom: 16,
                  right: sceneOnLeft ? null : 16,
                  left: sceneOnLeft ? 16 : null,
                  child: _disc(compact: true),
                ),
              ],
            );
          }
          return Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.heroGradient,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandPrimary.withValues(alpha: 0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: body,
          );
        },
      ),
    );
  }
}

class AppMetricTile extends StatelessWidget {
  const AppMetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppFadeIn(
      child: Container(
      padding: const EdgeInsets.all(16),
      // Flat card with a hairline border; the number leads, the label follows.
      decoration: BoxDecoration(
        color: AppPageColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPageColors.subtleBorderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          AppCountUpText(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppPageColors.subtitleOf(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.onChanged,
    this.suffixIcon,
    this.keyboardType,
    this.minLines,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.errorText,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final bool obscureText;
  final bool enabled;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final int? minLines;
  final int? maxLines;
  final TextCapitalization textCapitalization;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppPageColors.subtitleOf(context),
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          obscureText: obscureText,
          enabled: enabled,
          autofocus: autofocus,
          onChanged: onChanged,
          keyboardType: keyboardType,
          minLines: minLines,
          maxLines: maxLines,
          textCapitalization: textCapitalization,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            filled: true,
            fillColor:
                Theme.of(context).brightness == Brightness.dark
                    ? AppPageColors.fieldBgOf(context)
                    : Colors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppPageColors.subtleBorderOf(context), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppPageColors.subtleBorderOf(context), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppPageColors.accentOf(context), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.redWrong.withValues(alpha: 0.6)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.redWrong, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

InputDecoration appDropdownDecoration(BuildContext context, String label) {
  return appSheetFieldDecoration(context, label: label);
}

/// One choice in [AppSelectField] / [showAppSelectSheet].
class AppSelectOption<T> {
  const AppSelectOption({
    required this.value,
    required this.label,
    this.enabled = true,
    this.trailing,
  });

  final T value;
  final String label;
  final bool enabled;
  final Widget? trailing;
}

/// Frosted bottom sheet picker — consistent dropdown UX on mobile and web.
/// Wraps a picked option's value so `null` (e.g. an "All ..." option) can be
/// told apart from the sheet being dismissed without a choice.
class _PickedOption<T> {
  const _PickedOption(this.value);
  final T value;
}

// Returns the wrapped pick (not T? directly): T itself may be nullable (an
// "All ..." option), so only the wrapper can tell that apart from a dismiss.
Future<_PickedOption<T>?> showAppSelectSheet<T>({
  required BuildContext context,
  required String title,
  String? subtitle,
  required List<AppSelectOption<T>> options,
  T? selected,
  bool Function(AppSelectOption<T> option)? canSelect,
}) {
  return showFrostedBottomSheet<_PickedOption<T>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) {
      final maxHeight = MediaQuery.sizeOf(ctx).height * 0.72;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppSheetHandle(),
              AppSheetHeader(
                title: title,
                subtitle: subtitle,
                icon: Icons.tune_rounded,
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    for (final option in options)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: AppPageColors.cardBgOf(ctx),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color:
                                  selected == option.value
                                      ? AppColors.brandPrimary.withValues(alpha: 0.35)
                                      : AppPageColors.subtleBorderOf(ctx),
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              if (!(canSelect?.call(option) ?? true)) return;
                              if (!option.enabled) return;
                              Navigator.pop(ctx, _PickedOption<T>(option.value));
                            },
                            child: Opacity(
                              opacity: option.enabled ? 1 : 0.5,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        option.label,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight:
                                              selected == option.value
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                          color:
                                              selected == option.value
                                                  ? AppPageColors.accentOf(ctx)
                                                  : null,
                                        ),
                                      ),
                                    ),
                                    if (option.trailing != null)
                                      option.trailing!
                                    else if (selected == option.value)
                                      Icon(
                                        Icons.check_rounded,
                                        color: AppPageColors.accentOf(ctx),
                                        size: 22,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Tappable select field — opens [showAppSelectSheet] instead of native dropdown.
class AppSelectField<T> extends StatelessWidget {
  const AppSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.enabled = true,
    this.hint,
    this.sheetTitle,
    this.sheetSubtitle,
    this.canSelect,
    this.compact = false,
    this.showLabel = true,
    this.fieldColor,
  });

  final String label;
  final T? value;
  final List<AppSelectOption<T>> options;
  final ValueChanged<T>? onChanged;
  final bool enabled;
  final String? hint;
  final String? sheetTitle;
  final String? sheetSubtitle;
  final bool Function(AppSelectOption<T> option)? canSelect;
  final bool compact;
  final bool showLabel;
  /// Overrides the field's background; defaults to [AppPageColors.fieldBgOf].
  final Color? fieldColor;

  String? get _selectedLabel {
    for (final option in options) {
      if (option.value == value) return option.label;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final active = enabled && onChanged != null;
    final display = _selectedLabel ?? hint ?? 'Choose…';
    final hasSelection = _selectedLabel != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: AppPageColors.subtitleOf(context),
            ),
          ),
          SizedBox(height: compact ? 6 : 8),
        ],
        Material(
          color: fieldColor ?? AppPageColors.fieldBgOf(context),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compact ? 12 : 14),
            // Same border whether active or not — a field being disabled
            // (e.g. "synced to your learning language") is shown by the
            // dimmed content below, not by changing the box outline.
            side: BorderSide(color: AppPageColors.subtleBorderOf(context)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            // Web/desktop builds otherwise show Material's default focus
            // ring around this box once it has been tapped or tabbed to,
            // which reads as an unrelated accent-colored border.
            focusColor: Colors.transparent,
            onTap:
                active
                    ? () async {
                      final picked = await showAppSelectSheet<T>(
                        context: context,
                        title: sheetTitle ?? label,
                        subtitle: sheetSubtitle,
                        options: options,
                        selected: value,
                        canSelect: canSelect,
                      );
                      if (picked != null) onChanged!(picked.value);
                    }
                    : null,
            child: Opacity(
              opacity: active ? 1 : 0.55,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 12 : 14,
                  vertical: compact ? 10 : 14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        display,
                        style: TextStyle(
                          fontSize: compact ? 13 : 15,
                          fontWeight: hasSelection ? FontWeight.w600 : FontWeight.w500,
                          color: hasSelection
                              ? AppPageColors.accentOf(context)
                              : AppPageColors.subtitleOf(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.expand_more_rounded,
                      size: compact ? 20 : 24,
                      color: active
                          ? AppPageColors.accentOf(context)
                          : AppPageColors.subtitleOf(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Icon-only "Filters" button used on every list with filters.
/// Inactive: transparent with a dark icon. Active: brand tint, border and
/// icon (same look as [AppClearFiltersButton]) plus a count badge.
class AppFilterButton extends StatelessWidget {
  const AppFilterButton({
    super.key,
    required this.active,
    required this.onPressed,
    this.count = 0,
    this.size = 38,
    this.tooltip = 'Filters',
  });

  final bool active;
  final int count;

  /// Null disables the button (e.g. filters locked for this source).
  final VoidCallback? onPressed;
  final double size;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final iconColor =
        !enabled
            ? onSurface.withValues(alpha: 0.3)
            : active
            ? AppColors.brandPrimary
            : onSurface.withValues(alpha: 0.87);
    return AppPressScale(
      enabled: onPressed != null,
      child: Tooltip(
      message: tooltip,
      child: Material(
        color: active ? AppColors.brandPrimary.withValues(alpha: 0.1) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: active
                ? AppColors.brandPrimary.withValues(alpha: 0.35)
                : Colors.transparent,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: Badge(
                isLabelVisible: active && count > 0,
                label: Text('$count'),
                backgroundColor: AppColors.brandPrimary,
                // Badge defaults to colorScheme.onError, which is red in dark mode.
                textColor: Colors.white,
                child: Icon(Icons.tune_rounded, size: 20, color: iconColor),
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}

/// Clears every active filter; shown next to [AppFilterButton] while any
/// filter is on.
class AppClearFiltersButton extends StatelessWidget {
  const AppClearFiltersButton({super.key, required this.onPressed, this.size = 38});

  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AppPressScale(
      child: Tooltip(
      message: 'Clear all filters',
      child: Material(
        color: AppColors.brandPrimary.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.brandPrimary.withValues(alpha: 0.35)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: const Icon(
              Icons.filter_alt_off_outlined,
              size: 18,
              color: AppColors.brandPrimary,
            ),
          ),
        ),
      ),
    ),
    );
  }
}

/// App-wide on/off switch: iOS-style white knob with a soft shadow, light
/// grey track when off, brand track when on — the same on every platform.
class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged});

  final bool value;

  /// Null disables the switch.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return CupertinoSwitch(
      value: value,
      onChanged: onChanged,
      activeTrackColor: dark ? BrandConfig.primaryOnDark : BrandConfig.primary,
      // `fieldBgOf` (darkRaisedBg, #152A2E) was too close in luminance to the
      // card/sheet surfaces the switch usually sits on to read as a track at
      // all — this needs to stay visibly lighter than any dark surface in
      // the app, not just differ from the page background.
      inactiveTrackColor: dark ? const Color(0xFF2A4A50) : const Color(0xFFE5E5EA),
      thumbColor: Colors.white,
    );
  }
}

class AppToggleRow extends StatelessWidget {
  const AppToggleRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppPageColors.subtitleOf(context),
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          AppSwitch(value: value, onChanged: enabled ? onChanged : null),
        ],
      ),
    );
  }
}

class AppNavRow extends StatelessWidget {
  const AppNavRow({
    super.key,
    required this.title,
    required this.onTap,
    this.icon,
  });

  final String title;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return AppPressScale(
      child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.brandPrimary),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppPageColors.subtitleOf(context)),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class AppEmptyHint extends StatelessWidget {
  const AppEmptyHint({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return AppFadeIn(
      child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          color: AppPageColors.subtitleOf(context),
          fontSize: 14,
          height: 1.45,
        ),
      ),
      ),
    );
  }
}

class AppSliderRow extends StatelessWidget {
  const AppSliderRow({
    super.key,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.label,
    required this.onChanged,
    this.onChangeEnd,
    this.enabled = true,
  });

  final String title;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String label;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.brandPrimary,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: label,
          activeColor: AppColors.brandPrimary,
          onChanged: enabled ? onChanged : null,
          onChangeEnd: enabled ? onChangeEnd : null,
        ),
      ],
    );
  }
}

/// Drag handle shown at the top of frosted bottom sheets.
class AppSheetHandle extends StatelessWidget {
  const AppSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppPageColors.subtitleOf(context).withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

/// Header row for frosted bottom sheets (icon, title, optional subtitle, close).
class AppSheetHeader extends StatelessWidget {
  const AppSheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.tune_rounded,
    this.onClose,
    this.actions,
    this.showClose = false,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onClose;
  final List<Widget>? actions;

  /// Sheets close by tapping outside or dragging down, so no × by default.
  final bool showClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 8, 12),
      child: Row(
        children: [
          if (showClose)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Close',
              onPressed: onClose ?? () => Navigator.pop(context),
            )
          else
            const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppPageColors.accentOf(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppPageColors.accentOf(context), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 12, color: AppPageColors.subtitleOf(context)),
                  ),
                ],
              ],
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

InputDecoration appSheetFieldDecoration(
  BuildContext context, {
  String? label,
  String? hint,
  Widget? prefixIcon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: prefixIcon,
    filled: true,
    fillColor: AppPageColors.fieldBgOf(context),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppPageColors.subtleBorderOf(context), width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppPageColors.subtleBorderOf(context), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppPageColors.accentOf(context), width: 1.5),
    ),
  );
}

/// Tappable action row inside sheets (import/export format pickers).
class AppSheetActionTile extends StatelessWidget {
  const AppSheetActionTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.trailing,
    this.iconColor,
    this.enabled = true,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? iconColor;
  final bool enabled;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final accent = iconColor ?? AppColors.brandPrimary;
    return AppPressScale(
      enabled: enabled,
      child: Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppPageColors.cardBgOf(context),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppPageColors.subtleBorderOf(context)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          // Light brand tint instead of the default grey, so a hovered tile
          // (the sheet often opens under the cursor) doesn't look like a
          // different, greyed-out card.
          hoverColor: accent.withValues(alpha: 0.05),
          highlightColor: accent.withValues(alpha: 0.08),
          splashColor: accent.withValues(alpha: 0.10),
          child: Opacity(
            opacity: enabled ? 1 : 0.55,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 20, color: accent),
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
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppPageColors.subtitleOf(context),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null)
                    trailing!
                  else if (showChevron)
                    Icon(Icons.chevron_right_rounded, color: AppPageColors.subtitleOf(context)),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}

/// Centered form dialog matching Riovox sheet styling.
Future<String?> showAppPromptDialog(
  BuildContext context, {
  required String title,
  String? subtitle,
  IconData icon = Icons.edit_outlined,
  String fieldLabel = 'Name',
  String hintText = '',
  String confirmLabel = 'Create',
}) async {
  final controller = TextEditingController();
  String? result;

  try {
    result = await showAppDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) {
        return Dialog(
          backgroundColor: AppPageColors.cardBgOf(ctx),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppPageColors.accentOf(ctx).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: AppPageColors.accentOf(ctx), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppPageColors.subtitleOf(ctx),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: controller,
                  label: fieldLabel,
                  hint: hintText,
                  autofocus: true,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.brandPrimary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(confirmLabel),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  } finally {
    controller.dispose();
  }

  if (result == null || result.isEmpty) return null;
  return result;
}
