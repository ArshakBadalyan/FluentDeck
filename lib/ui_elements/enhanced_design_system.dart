/// Enhanced Design System v2.0
/// Beautiful, production-ready components for FluentDeck
/// Based on task-management template design with English learning focus

import 'package:flutter/material.dart';

// ============================================================================
// COLOR PALETTE & CONSTANTS
// ============================================================================

class DesignPalette {
  // Primary Colors
  static const Color primary = Color(0xFF5F33E1);        // Purple
  static const Color primaryLight = Color(0xFF9260F4);   // Light Purple
  static const Color primaryDark = Color(0xFF4A1FBE);    // Dark Purple

  // Accent Colors
  static const Color blue = Color(0xFF0087FF);           // Blue
  static const Color blueLight = Color(0xFFE7F4FF);      // Light Blue

  // Status Colors
  static const Color success = Color(0xFF46F080);        // Green
  static const Color warning = Color(0xFFFF9142);        // Orange
  static const Color error = Color(0xFFE53935);          // Red
  static const Color info = Color(0xFF06B6D4);           // Cyan

  // Neutrals
  static const Color textPrimary = Color(0xFF24252C);    // Dark
  static const Color textSecondary = Color(0xFF6E6A7C);  // Gray
  static const Color textTertiary = Color(0xFFB8B5C1);   // Light Gray

  static const Color bgPrimary = Color(0xFFF4F0FF);      // Light Purple
  static const Color bgSecondary = Color(0xFFEEE9FF);    // Divider
  static const Color bgTertiary = Color(0xFFFFFFFF);     // White
}

// ============================================================================
// SPACING & SIZING
// ============================================================================

class DesignSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  // Touch targets (minimum 48dp)
  static const double touchTarget = 48;
}

// ============================================================================
// SHADOWS & ELEVATION
// ============================================================================

class DesignShadows {
  static const BoxShadow subtle = BoxShadow(
    color: Color(0x0F000000),
    blurRadius: 4,
    offset: Offset(0, 1),
  );

  static const BoxShadow small = BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  static const BoxShadow medium = BoxShadow(
    color: Color(0x24000000),
    blurRadius: 12,
    offset: Offset(0, 4),
  );

  static const BoxShadow large = BoxShadow(
    color: Color(0x33000000),
    blurRadius: 16,
    offset: Offset(0, 8),
  );

  static List<BoxShadow> get elevation0 => [];
  static List<BoxShadow> get elevation1 => [subtle];
  static List<BoxShadow> get elevation2 => [small];
  static List<BoxShadow> get elevation3 => [medium];
  static List<BoxShadow> get elevation4 => [large];
}

// ============================================================================
// GRADIENTS
// ============================================================================

class DesignGradients {
  static final LinearGradient primaryGradient = LinearGradient(
    colors: [DesignPalette.primary, DesignPalette.primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final LinearGradient blueGradient = LinearGradient(
    colors: [DesignPalette.blue, Color(0xFF0066CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final LinearGradient successGradient = LinearGradient(
    colors: [DesignPalette.success, Color(0xFF22C55E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final LinearGradient warningGradient = LinearGradient(
    colors: [DesignPalette.warning, Color(0xFFFF7D53)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ============================================================================
// BORDER RADIUS
// ============================================================================

class DesignRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double full = 9999;
}

// ============================================================================
// TYPOGRAPHY
// ============================================================================

class DesignTypography {
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: DesignPalette.textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: DesignPalette.textPrimary,
  );

  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: DesignPalette.textPrimary,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: DesignPalette.textPrimary,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: DesignPalette.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: DesignPalette.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: DesignPalette.textSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: DesignPalette.textSecondary,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: DesignPalette.textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: DesignPalette.textPrimary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: DesignPalette.textTertiary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: DesignPalette.textTertiary,
  );
}

// ============================================================================
// THEME BUILDER
// ============================================================================

ThemeData buildDesignTheme({bool isDark = false}) {
  if (isDark) {
    return ThemeData.dark(useMaterial3: true).copyWith(
      primaryColor: DesignPalette.primary,
      scaffoldBackgroundColor: Color(0xFF121212),
      cardColor: Color(0xFF1E1E1E),
      textTheme: TextTheme(
        displayLarge: DesignTypography.displayLarge.copyWith(color: Colors.white),
        displayMedium: DesignTypography.displayMedium.copyWith(color: Colors.white),
        headingLarge: DesignTypography.headingLarge.copyWith(color: Colors.white),
        headingMedium: DesignTypography.headingMedium.copyWith(color: Colors.white),
        bodyLarge: DesignTypography.bodyLarge.copyWith(color: Colors.white70),
      ),
    );
  }

  return ThemeData(
    useMaterial3: true,
    primaryColor: DesignPalette.primary,
    scaffoldBackgroundColor: DesignPalette.bgPrimary,
    cardColor: DesignPalette.bgTertiary,
    fontFamily: 'Rubik',
    textTheme: TextTheme(
      displayLarge: DesignTypography.displayLarge,
      displayMedium: DesignTypography.displayMedium,
      headingLarge: DesignTypography.headingLarge,
      headingMedium: DesignTypography.headingMedium,
      headingSmall: DesignTypography.headingSmall,
      bodyLarge: DesignTypography.bodyLarge,
      bodyMedium: DesignTypography.bodyMedium,
      bodySmall: DesignTypography.bodySmall,
      labelLarge: DesignTypography.labelLarge,
      labelMedium: DesignTypography.labelMedium,
      labelSmall: DesignTypography.labelSmall,
    ),
    appBarTheme: AppBarThemeData(
      backgroundColor: DesignPalette.bgPrimary,
      foregroundColor: DesignPalette.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: DesignPalette.primary,
      foregroundColor: Colors.white,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: DesignPalette.primary,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: DesignSpacing.lg,
          vertical: DesignSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignRadius.md),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: DesignPalette.primary,
        side: BorderSide(color: DesignPalette.bgSecondary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignRadius.md),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: DesignPalette.primary,
      ),
    ),
    cardTheme: CardThemeData(
      color: DesignPalette.bgTertiary,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignRadius.md),
        side: BorderSide(color: DesignPalette.bgSecondary, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: DesignPalette.bgSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignRadius.md),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignRadius.md),
        borderSide: BorderSide(color: DesignPalette.primary, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: DesignSpacing.lg,
        vertical: DesignSpacing.md,
      ),
      hintStyle: DesignTypography.bodySmall,
    ),
    dividerTheme: DividerThemeData(
      color: DesignPalette.bgSecondary,
      thickness: 1,
      space: DesignSpacing.lg,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: DesignPalette.bgSecondary,
      selectedColor: DesignPalette.primary,
      disabledColor: DesignPalette.bgSecondary,
      padding: EdgeInsets.symmetric(
        horizontal: DesignSpacing.md,
        vertical: DesignSpacing.xs,
      ),
      labelStyle: DesignTypography.labelMedium,
      brightness: Brightness.light,
    ),
  );
}

// ============================================================================
// ANIMATION DURATIONS
// ============================================================================

class DesignAnimations {
  static const Duration quick = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);

  // Curves
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve spring = Curves.elasticOut;
  static const Curve bounce = Curves.elasticIn;
}
