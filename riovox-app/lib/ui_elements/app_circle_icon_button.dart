import 'package:flutter/material.dart';
import 'package:riovox/ui_elements/modern_page_widgets.dart';

/// A top-bar action as a small round card: white (dark card in dark mode)
/// with a hairline border and a 20px icon, like the bell on Today.
class AppCircleIconButton extends StatelessWidget {
  const AppCircleIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final Widget icon;
  final String tooltip;
  final VoidCallback? onPressed;

  static const double size = 44;
  static const double iconSize = 20;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: AppPageColors.cardBgOf(context),
        shape: CircleBorder(side: BorderSide(color: AppPageColors.subtleBorderOf(context))),
        child: IconButton(
          tooltip: tooltip,
          constraints: const BoxConstraints.tightFor(width: size, height: size),
          padding: EdgeInsets.zero,
          iconSize: iconSize,
          color: AppPageColors.textPrimaryOf(context),
          onPressed: onPressed,
          icon: icon,
        ),
      ),
    );
  }
}
