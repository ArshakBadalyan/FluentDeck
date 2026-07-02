/// Design System - Generated from task-management template SVGs
/// Colors, typography, and component specs extracted from actual design files

import 'package:flutter/material.dart';

// ============================================================================
// COLOR PALETTE (From SVG analysis)
// ============================================================================

class AppDesignColors {
  static const Color primary = Color(0xFF5F33E1);        // Purple
  static const Color primaryLight = Color(0xFF9260F4);   // Light Purple
  static const Color primaryDark = Color(0xFF8764FF);    // Dark Purple

  static const Color textPrimary = Color(0xFF24252C);    // Dark Gray
  static const Color textSecondary = Color(0xFF6E6A7C);  // Medium Gray

  static const Color bgLight = Color(0xFFF4F0FF);        // Light Purple BG
  static const Color bgLightPurple = Color(0xFFEEE9FF);  // Divider
  static const Color bgWhite = Color(0xFFFFFFFF);        // White

  // Additional colors from template
  static const Color blue = Color(0xFF0087FF);           // Blue accent
  static const Color blueLight = Color(0xFFE7F4FF);      // Light blue
}

// ============================================================================
// TYPOGRAPHY
// ============================================================================

class AppDesignTypography {
  static const TextStyle headingLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppDesignColors.textPrimary,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppDesignColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppDesignColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppDesignColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppDesignColors.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppDesignColors.textPrimary,
  );
}

// ============================================================================
// COMPONENT: Purple Gradient Button
// ============================================================================

class DesignButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  const DesignButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<DesignButton> createState() => _DesignButtonState();
}

class _DesignButtonState extends State<DesignButton> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppDesignColors.primary, AppDesignColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppDesignColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isLoading ? null : widget.onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: widget.isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    widget.label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// COMPONENT: Card with Header
// ============================================================================

class DesignCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final VoidCallback? onTap;
  final Color? headerColor;

  const DesignCard({
    Key? key,
    required this.title,
    required this.child,
    this.subtitle,
    this.onTap,
    this.headerColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AppDesignColors.bgLightPurple,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header bar
            Container(
              width: double.infinity,
              height: 4,
              decoration: BoxDecoration(
                color: headerColor ?? AppDesignColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
            ),
            // Content
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppDesignTypography.label),
                  if (subtitle != null) ...[
                    SizedBox(height: 4),
                    Text(subtitle!, style: AppDesignTypography.bodySmall),
                  ],
                  if (subtitle != null) SizedBox(height: 12),
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
// COMPONENT: Filter Tab Bar
// ============================================================================

class DesignFilterTabs extends StatefulWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  const DesignFilterTabs({
    Key? key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
  }) : super(key: key);

  @override
  State<DesignFilterTabs> createState() => _DesignFilterTabsState();
}

class _DesignFilterTabsState extends State<DesignFilterTabs> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(
          widget.tabs.length,
          (index) {
            final isSelected = index == widget.selectedIndex;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: GestureDetector(
                onTap: () => widget.onTabChanged(index),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppDesignColors.primary
                        : AppDesignColors.bgWhite,
                    border: isSelected
                        ? null
                        : Border.all(
                            color: AppDesignColors.bgLightPurple,
                            width: 1,
                          ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.tabs[index],
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppDesignColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// COMPONENT: Header Section
// ============================================================================

class DesignHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const DesignHeader({
    Key? key,
    required this.title,
    this.subtitle,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppDesignColors.primary, AppDesignColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// COMPONENT: List Item
// ============================================================================

class DesignListItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const DesignListItem({
    Key? key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppDesignColors.bgWhite,
          border: Border.all(
            color: AppDesignColors.bgLightPurple,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppDesignTypography.label),
                  if (subtitle != null) ...[
                    SizedBox(height: 4),
                    Text(subtitle!, style: AppDesignTypography.bodySmall),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              SizedBox(width: 12),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// COMPONENT: Circular Badge
// ============================================================================

class DesignBadge extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color? textColor;
  final double size;

  const DesignBadge({
    Key? key,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.size = 32,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? AppDesignColors.primary,
        boxShadow: [
          BoxShadow(
            color: (backgroundColor ?? AppDesignColors.primary).withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
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
// COMPONENT: Progress Bar
// ============================================================================

class DesignProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final Color? color;
  final double height;

  const DesignProgressBar({
    Key? key,
    required this.value,
    this.color,
    this.height = 6,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: value,
        minHeight: height,
        backgroundColor: AppDesignColors.bgLightPurple,
        valueColor: AlwaysStoppedAnimation(color ?? AppDesignColors.primary),
      ),
    );
  }
}

// ============================================================================
// THEME APPLICATION
// ============================================================================

ThemeData designSystemTheme() {
  return ThemeData(
    useMaterial3: true,
    primaryColor: AppDesignColors.primary,
    scaffoldBackgroundColor: AppDesignColors.bgLight,
    cardColor: AppDesignColors.bgWhite,
    fontFamily: 'Rubik',
    textTheme: TextTheme(
      displayLarge: AppDesignTypography.headingLarge,
      displayMedium: AppDesignTypography.headingMedium,
      bodyLarge: AppDesignTypography.bodyLarge,
      bodySmall: AppDesignTypography.bodySmall,
      labelSmall: AppDesignTypography.caption,
    ),
    appBarTheme: AppBarThemeData(
      backgroundColor: AppDesignColors.bgLight,
      foregroundColor: AppDesignColors.textPrimary,
      elevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppDesignColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}
