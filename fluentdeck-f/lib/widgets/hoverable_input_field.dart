import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';

/// Wraps a TextField or similar input with hover detection that changes border color.
class HoverableInputField extends StatefulWidget {
  const HoverableInputField({
    super.key,
    required this.child,
    this.onHoverChanged,
  });

  final Widget child;
  final ValueChanged<bool>? onHoverChanged;

  @override
  State<HoverableInputField> createState() => _HoverableInputFieldState();
}

class _HoverableInputFieldState extends State<HoverableInputField> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        widget.onHoverChanged?.call(true);
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        widget.onHoverChanged?.call(false);
      },
      child: _HoverBorderOverlay(
        isHovered: _isHovered,
        child: widget.child,
      ),
    );
  }
}

/// Applies a purple border overlay when hovered.
class _HoverBorderOverlay extends StatelessWidget {
  const _HoverBorderOverlay({
    required this.isHovered,
    required this.child,
  });

  final bool isHovered;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: isHovered
          ? BoxDecoration(
              border: Border.all(color: AppColors.primaryPurple, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: child,
    );
  }
}

/// Helper to create input decoration with hover-aware borders.
InputDecoration createHoverableInputDecoration({
  String? labelText,
  String? hintText,
  Widget? prefixIcon,
  Widget? suffixIcon,
  bool filled = true,
  Color? fillColor,
}) {
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: filled,
    fillColor: fillColor ?? Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primaryPurple, width: 1.5),
    ),
  );
}
