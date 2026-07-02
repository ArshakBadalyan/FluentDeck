/// Beautiful, Production-Ready Components
/// Part of Enhanced Design System

import 'package:flutter/material.dart';
import 'enhanced_design_system.dart';

// ============================================================================
// COMPONENT 1: Premium Button
// ============================================================================

class PremiumButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final Color? backgroundColor;
  final bool isOutlined;

  const PremiumButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.backgroundColor,
    this.isOutlined = false,
  }) : super(key: key);

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DesignAnimations.quick,
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isOutlined) {
      return OutlinedButton(
        onPressed: widget.isDisabled || widget.isLoading ? null : widget.onPressed,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: DesignSpacing.lg,
            vertical: DesignSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18),
                SizedBox(width: DesignSpacing.sm),
              ],
              Text(widget.label),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTapDown: widget.isDisabled || widget.isLoading
          ? null
          : (_) => _controller.forward(),
      onTapUp: widget.isDisabled || widget.isLoading
          ? null
          : (_) {
            _controller.reverse();
            widget.onPressed();
          },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1, end: 0.95).animate(_controller),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: DesignSpacing.lg,
            vertical: DesignSpacing.sm,
          ),
          decoration: BoxDecoration(
            gradient: DesignGradients.primaryGradient,
            borderRadius: BorderRadius.circular(DesignRadius.md),
            boxShadow: widget.isDisabled ? [] : DesignShadows.elevation2,
            opacity: widget.isDisabled ? 0.5 : 1,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isLoading)
                SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                    strokeWidth: 2,
                  ),
                )
              else ...[
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: Colors.white, size: 18),
                  SizedBox(width: DesignSpacing.sm),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// ============================================================================
// COMPONENT 2: Gorgeous Card
// ============================================================================

class GorgeousCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final VoidCallback? onTap;
  final Color? headerColor;
  final bool showBorder;
  final EdgeInsets padding;

  const GorgeousCard({
    Key? key,
    required this.title,
    required this.child,
    this.subtitle,
    this.onTap,
    this.headerColor,
    this.showBorder = true,
    this.padding = const EdgeInsets.all(16),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignRadius.md),
          side: showBorder
              ? BorderSide(color: DesignPalette.bgSecondary, width: 1)
              : BorderSide.none,
        ),
        elevation: 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gradient header bar
            Container(
              width: double.infinity,
              height: 4,
              decoration: BoxDecoration(
                color: headerColor ?? DesignPalette.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(DesignRadius.md),
                  topRight: Radius.circular(DesignRadius.md),
                ),
              ),
            ),
            // Content
            Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: DesignTypography.labelLarge),
                  if (subtitle != null) ...[
                    SizedBox(height: DesignSpacing.xs),
                    Text(subtitle!, style: DesignTypography.bodySmall),
                  ],
                  if (subtitle != null)
                    SizedBox(height: DesignSpacing.md),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// COMPONENT 3: Animated Progress Ring
// ============================================================================

class AnimatedProgressRing extends StatefulWidget {
  final double value; // 0.0 to 1.0
  final double size;
  final Color? color;
  final String? label;
  final Duration duration;

  const AnimatedProgressRing({
    Key? key,
    required this.value,
    this.size = 100,
    this.color,
    this.label,
    this.duration = const Duration(milliseconds: 1500),
  }) : super(key: key);

  @override
  State<AnimatedProgressRing> createState() => _AnimatedProgressRingState();
}

class _AnimatedProgressRingState extends State<AnimatedProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(begin: _animation.value, end: widget.value)
          .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
          );
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: _animation.value,
                strokeWidth: 8,
                backgroundColor: DesignPalette.bgSecondary,
                valueColor: AlwaysStoppedAnimation(
                  widget.color ?? DesignPalette.primary,
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${(_animation.value * 100).toStringAsFixed(0)}%',
                      style: DesignTypography.headingSmall,
                    ),
                    if (widget.label != null) ...[
                      SizedBox(height: DesignSpacing.xs),
                      Text(
                        widget.label!,
                        style: DesignTypography.caption,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// ============================================================================
// COMPONENT 4: Streak Badge
// ============================================================================

class StreakBadge extends StatefulWidget {
  final int count;
  final VoidCallback? onTap;
  final bool isAnimating;

  const StreakBadge({
    Key? key,
    required this.count,
    this.onTap,
    this.isAnimating = false,
  }) : super(key: key);

  @override
  State<StreakBadge> createState() => _StreakBadgeState();
}

class _StreakBadgeState extends State<StreakBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DesignAnimations.slow,
      vsync: this,
    );
    if (widget.isAnimating) _controller.forward();
  }

  @override
  void didUpdateWidget(StreakBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count != oldWidget.count && widget.isAnimating) {
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: Tween<double>(begin: 1, end: 1.15).animate(
          CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
        ),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: DesignGradients.warningGradient,
            boxShadow: [
              BoxShadow(
                color: DesignPalette.warning.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🔥', style: TextStyle(fontSize: 28)),
              Text(
                '${widget.count}',
                style: DesignTypography.labelLarge.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// ============================================================================
// COMPONENT 5: XP Display (Animated)
// ============================================================================

class XPDisplay extends StatefulWidget {
  final int xpAmount;
  final VoidCallback? onComplete;

  const XPDisplay({
    Key? key,
    required this.xpAmount,
    this.onComplete,
  }) : super(key: key);

  @override
  State<XPDisplay> createState() => _XPDisplayState();
}

class _XPDisplayState extends State<XPDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DesignAnimations.slow,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(0, -2),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: DesignSpacing.md,
              vertical: DesignSpacing.sm,
            ),
            decoration: BoxDecoration(
              gradient: DesignGradients.successGradient,
              borderRadius: BorderRadius.circular(DesignRadius.full),
              boxShadow: DesignShadows.elevation3,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: Colors.white, size: 16),
                SizedBox(width: DesignSpacing.xs),
                Text(
                  '+${widget.xpAmount} XP',
                  style: DesignTypography.labelMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// ============================================================================
// COMPONENT 6: Premium List Item
// ============================================================================

class PremiumListItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final bool showDivider;

  const PremiumListItem({
    Key? key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.backgroundColor,
    this.showDivider = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: DesignSpacing.lg,
              vertical: DesignSpacing.md,
            ),
            decoration: BoxDecoration(
              color: backgroundColor ?? DesignPalette.bgTertiary,
              borderRadius: BorderRadius.circular(DesignRadius.md),
              border: Border.all(
                color: DesignPalette.bgSecondary,
                width: 1,
              ),
              boxShadow: DesignShadows.elevation1,
            ),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  SizedBox(width: DesignSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: DesignTypography.labelLarge),
                      if (subtitle != null) ...[
                        SizedBox(height: DesignSpacing.xs),
                        Text(subtitle!, style: DesignTypography.bodySmall),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  SizedBox(width: DesignSpacing.md),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
        if (showDivider) ...[
          SizedBox(height: DesignSpacing.md),
        ],
      ],
    );
  }
}

// ============================================================================
// COMPONENT 7: Filter Chips
// ============================================================================

class PremiumFilterChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;
  final IconData? icon;

  const PremiumFilterChip({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.icon,
  }) : super(key: key);

  @override
  State<PremiumFilterChip> createState() => _PremiumFilterChipState();
}

class _PremiumFilterChipState extends State<PremiumFilterChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DesignAnimations.quick,
      vsync: this,
    );
    if (widget.isSelected) _controller.forward();
  }

  @override
  void didUpdateWidget(PremiumFilterChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 1, end: 1.05).animate(_controller),
      child: GestureDetector(
        onTap: () => widget.onSelected(!widget.isSelected),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: DesignSpacing.md,
            vertical: DesignSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? DesignPalette.primary
                : DesignPalette.bgTertiary,
            border: Border.all(
              color: widget.isSelected
                  ? DesignPalette.primary
                  : DesignPalette.bgSecondary,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(DesignRadius.full),
            boxShadow: widget.isSelected ? DesignShadows.elevation2 : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 16,
                  color: widget.isSelected
                      ? Colors.white
                      : DesignPalette.textSecondary,
                ),
                SizedBox(width: DesignSpacing.xs),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isSelected
                      ? Colors.white
                      : DesignPalette.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// ============================================================================
// COMPONENT 8: Premium App Bar
// ============================================================================

class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final Color? backgroundColor;
  final bool showBack;

  const PremiumAppBar({
    Key? key,
    required this.title,
    this.subtitle,
    this.actions,
    this.onBack,
    this.backgroundColor,
    this.showBack = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? DesignPalette.bgPrimary,
        boxShadow: DesignShadows.elevation1,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: DesignSpacing.lg,
            vertical: DesignSpacing.md,
          ),
          child: Row(
            children: [
              if (showBack)
                GestureDetector(
                  onTap: onBack ?? () => Navigator.pop(context),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    size: 20,
                    color: DesignPalette.textPrimary,
                  ),
                ),
              if (showBack) SizedBox(width: DesignSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: DesignTypography.headingMedium),
                    if (subtitle != null) ...[
                      SizedBox(height: DesignSpacing.xs),
                      Text(subtitle!, style: DesignTypography.bodySmall),
                    ],
                  ],
                ),
              ),
              if (actions != null && actions!.isNotEmpty)
                Row(children: actions!),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(subtitle != null ? 80 : 60);
}

// ============================================================================
// COMPONENT 9: Loading Skeleton
// ============================================================================

class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    Key? key,
    required this.width,
    required this.height,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.6, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: DesignPalette.bgSecondary,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(DesignRadius.md),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// ============================================================================
// COMPONENT 10: Empty State
// ============================================================================

class EmptyState extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String? buttonLabel;
  final VoidCallback? onButtonTap;

  const EmptyState({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    this.buttonLabel,
    this.onButtonTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(DesignSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: DesignPalette.textSecondary.withOpacity(0.5),
            ),
            SizedBox(height: DesignSpacing.xl),
            Text(
              title,
              style: DesignTypography.headingMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: DesignSpacing.md),
            Text(
              description,
              style: DesignTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (buttonLabel != null) ...[
              SizedBox(height: DesignSpacing.xl),
              PremiumButton(
                label: buttonLabel!,
                onPressed: onButtonTap ?? () {},
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// COMPONENT 11: Badge
// ============================================================================

class PremiumBadge extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color? textColor;
  final double size;
  final IconData? icon;

  const PremiumBadge({
    Key? key,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.size = 32,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? DesignPalette.primary,
        boxShadow: DesignShadows.elevation2,
      ),
      child: icon != null
          ? Icon(icon, color: textColor ?? Colors.white, size: size * 0.6)
          : Center(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }
}

// ============================================================================
// COMPONENT 12: Premium Progress Bar
// ============================================================================

class PremiumProgressBar extends StatefulWidget {
  final double value; // 0.0 to 1.0
  final Color? color;
  final double height;
  final String? label;
  final Duration duration;

  const PremiumProgressBar({
    Key? key,
    required this.value,
    this.color,
    this.height = 8,
    this.label,
    this.duration = const Duration(milliseconds: 1500),
  }) : super(key: key);

  @override
  State<PremiumProgressBar> createState() => _PremiumProgressBarState();
}

class _PremiumProgressBarState extends State<PremiumProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(PremiumProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(begin: _animation.value, end: widget.value)
          .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
          );
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.label != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.label!, style: DesignTypography.labelMedium),
                  Text(
                    '${(_animation.value * 100).toStringAsFixed(0)}%',
                    style: DesignTypography.labelMedium,
                  ),
                ],
              ),
              SizedBox(height: DesignSpacing.sm),
            ],
            ClipRRect(
              borderRadius: BorderRadius.circular(widget.height / 2),
              child: LinearProgressIndicator(
                value: _animation.value,
                minHeight: widget.height,
                backgroundColor: DesignPalette.bgSecondary,
                valueColor: AlwaysStoppedAnimation(
                  widget.color ?? DesignPalette.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
