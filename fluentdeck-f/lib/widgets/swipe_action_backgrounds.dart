import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';

/// Shared swipe backgrounds (conversation history / card browser style).
class SwipeActionBackgrounds {
  SwipeActionBackgrounds._();

  static Widget _base({
    required Alignment alignment,
    required Color backgroundColor,
    required Widget child,
    BorderRadius? borderRadius,
  }) {
    return Container(
      alignment: alignment,
      padding: EdgeInsets.only(
        left: alignment == Alignment.centerLeft ? 20 : 0,
        right: alignment == Alignment.centerRight ? 20 : 0,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      child: child,
    );
  }

  static Widget edit({
    Alignment alignment = Alignment.centerLeft,
    BorderRadius? borderRadius,
  }) {
    return _base(
      alignment: alignment,
      backgroundColor: AppColors.primaryPurple.withValues(alpha: 0.12),
      borderRadius: borderRadius,
      child: Icon(Icons.edit_outlined, color: AppColors.primaryPurple),
    );
  }

  static Widget study({
    Alignment alignment = Alignment.centerLeft,
    BorderRadius? borderRadius,
  }) {
    return _base(
      alignment: alignment,
      backgroundColor: AppColors.primaryPurple.withValues(alpha: 0.12),
      borderRadius: borderRadius,
      child: Icon(Icons.play_arrow_rounded, color: AppColors.primaryPurple),
    );
  }

  static Widget delete({
    Alignment alignment = Alignment.centerRight,
    BorderRadius? borderRadius,
  }) {
    return _base(
      alignment: alignment,
      backgroundColor: Colors.red.shade50,
      borderRadius: borderRadius,
      child: Icon(Icons.delete_outline, color: Colors.red.shade400),
    );
  }
}
