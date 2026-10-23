import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../app_colors.dart';
import 'app_motion.dart';
import '../services/analytics_service.dart';
import '../services/click_tracking.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool enabled;
  final Color? color;
  final double? fontSize;
  final bool isLoading;

  /// Optional stable id used to emit a named `ui_tap` analytics event
  /// when the button is pressed (e.g. `onboarding.next`,
  /// `auth.register.submit`). When set, suppresses the generic
  /// `ui_tap` from [ClickTracker] for this gesture.
  final String? analyticsId;

  /// When > 1, allows wrapping long labels (e.g. CTAs).
  final int? maxLines;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.enabled,
    this.color,
    this.fontSize,
    this.isLoading = false,
    this.analyticsId,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final Color baseColor = color ?? AppColors.brandPrimary;

    final tallLabel = (maxLines ?? 1) > 1;

    return AppPressScale(
      enabled: enabled && !isLoading,
      child: SizedBox(
      width: double.infinity,
      height: tallLabel ? 68 : 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? baseColor : baseColor.withOpacity(0.5),
          foregroundColor: Colors.white,
          // Without these, ElevatedButton swaps in its own grey
          // disabled-state colors once onPressed is null below, instead of
          // keeping this dimmed brand color.
          disabledBackgroundColor: baseColor.withOpacity(0.5),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        // `enabled: false` must make this a truly disabled button (no tap
        // target, no ripple) — not just a dimmed one a tap still reaches.
        onPressed: enabled
            ? () {
                final id = analyticsId;
                if (id != null && id.isNotEmpty) {
                  ClickTracker.recordNamedTap();
                  unawaited(
                    AnalyticsService.instance.logTap(targetId: id),
                  );
                }
                onPressed?.call();
              }
            : null,
        child: Stack(
          children: [
            Center(
              child: AnimatedSwitcher(
                duration: AppMotion.duration(context, AppMotion.fast),
                switchInCurve: AppMotion.decelerateCurve,
                switchOutCurve: AppMotion.accelerateCurve,
                child: isLoading
                  ? const SizedBox(
                key: ValueKey('loading'),
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
                  : Padding(
                key: const ValueKey('label'),
                padding: const EdgeInsets.symmetric(horizontal: 44),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  maxLines: maxLines ?? 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: SvgPicture.asset(
                  'assets/buttons/button_wave.svg',
                  fit: BoxFit.fitHeight,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
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