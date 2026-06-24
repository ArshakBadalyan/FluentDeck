import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../app_colors.dart';
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
    final Color baseColor = color ?? AppColors.primaryPurple;

    final tallLabel = (maxLines ?? 1) > 1;

    return SizedBox(
      width: double.infinity,
      height: tallLabel ? 68 : 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? baseColor : baseColor.withOpacity(0.5),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        onPressed: () {
          if (!enabled) return;
          final id = analyticsId;
          if (id != null && id.isNotEmpty) {
            ClickTracker.recordNamedTap();
            unawaited(
              AnalyticsService.instance.logTap(targetId: id),
            );
          }
          onPressed?.call();
        },
        child: Stack(
          children: [
            Center(
              child: isLoading
                  ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
                  : Padding(
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
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: SvgPicture.asset(
                  'assets/buttons/buttons_pic.svg',
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
    );
  }
}