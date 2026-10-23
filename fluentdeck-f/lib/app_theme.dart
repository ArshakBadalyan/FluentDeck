import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_theme.dart';
import 'config/brand_config.dart';
import 'ui_elements/modern_page_widgets.dart';

/// Central light/dark themes seeded from the brand color in [BrandConfig].
///
/// Material 2 (m2.material.io/components): `useMaterial3: false`, so buttons,
/// cards, dialogs, chips and snackbars use M2 shapes, elevation and ripples.
/// In M2, toggles (switch, checkbox, radio, slider) and the FAB take
/// `colorScheme.secondary`, so primary *and* secondary are the brand teal —
/// the seed alone would make them a muted tone. Plan and phases:
/// docs/motion-and-material-plan.md.
abstract final class AppTheme {
  static const _seed = AppColors.brandPrimary;

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
      surface: AppPageColors.pageBg,
    ).copyWith(
      primary: AppColors.brandPrimary,
      onPrimary: Colors.white,
      secondary: AppColors.brandPrimary,
      onSecondary: Colors.white,
    );

    return ThemeData(
      useMaterial3: false,
      splashFactory: InkRipple.splashFactory,
      colorScheme: scheme,
      fontFamily: BrandConfig.fontFamily,
      textTheme: AppTextTheme.textTheme,
      scaffoldBackgroundColor: Colors.white,
      cardColor: AppPageColors.cardBg,
      dividerColor: Colors.black.withValues(alpha: 0.06),
      // Flutter's mouse tracker doesn't re-evaluate hover regions on scroll
      // without pointer movement, so the default gray hover overlay sticks to
      // a screen position and appears to "jump" onto whatever card/tile
      // scrolls under the (unmoved) cursor. Mobile has no hover anyway.
      hoverColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: BrandConfig.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: Colors.white,
        ).merge(_m2ButtonShapeAndElevation),
      ),
      // Material3's seed-generated default (colorScheme.primaryContainer) is a
      // pale, washed-out tint of the brand teal — fine for chips, wrong for an
      // FAB. Any FloatingActionButton that doesn't set its own colors falls
      // back to this instead of that pastel.
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.brandPrimaryDeep,
        foregroundColor: Colors.white,
      ),
      // M2 chips default to grey; keep filter/choice chips on brand.
      chipTheme: _m2ChipTheme(
        accent: AppColors.brandPrimary,
        background: AppPageColors.fieldBg,
        label: BrandConfig.textPrimary,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brandPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(Colors.white),
          elevation: WidgetStateProperty.all(8),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 6)),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(Colors.white),
          elevation: WidgetStateProperty.all(8),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: Colors.white,
        dayPeriodColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.brandPrimary
              : AppPageColors.fieldBg,
        ),
        dayPeriodTextColor: WidgetStateColor.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? Colors.white : BrandConfig.textPrimary,
        ),
        hourMinuteColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.brandPrimary.withValues(alpha: 0.12)
              : AppPageColors.fieldBg,
        ),
        hourMinuteTextColor: BrandConfig.textPrimary,
        dialHandColor: AppColors.brandPrimary,
        dialBackgroundColor: AppPageColors.fieldBg,
        entryModeIconColor: AppColors.brandPrimary,
      ),
      pageTransitionsTheme: _pageTransitionsTheme,
    );
  }

  static ThemeData get dark {
    const scaffold = AppPageColors.darkPageBg;
    const card = AppPageColors.darkCardBg;
    const raised = AppPageColors.darkRaisedBg;

    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
      surface: scaffold,
    ).copyWith(
      surfaceContainerHighest: raised,
      surfaceContainerHigh: raised,
      surfaceContainer: card,
      primary: AppColors.brandPrimaryOnDark,
      onPrimary: BrandConfig.onPrimaryDark,
      secondary: AppColors.brandPrimaryOnDark,
      onSecondary: BrandConfig.onPrimaryDark,
    );

    return ThemeData(
      useMaterial3: false,
      splashFactory: InkRipple.splashFactory,
      colorScheme: scheme,
      fontFamily: BrandConfig.fontFamily,
      textTheme: AppTextTheme.textTheme.apply(
        bodyColor: BrandConfig.darkTextPrimary,
        displayColor: BrandConfig.darkTextPrimary,
      ),
      scaffoldBackgroundColor: scaffold,
      cardColor: card,
      dividerColor: Colors.white.withValues(alpha: 0.08),
      hoverColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: card,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: raised,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: raised,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: raised,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: raised,
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandPrimaryOnDark,
          foregroundColor: BrandConfig.onPrimaryDark,
        ).merge(_m2ButtonShapeAndElevation),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.brandPrimaryOnDark,
        foregroundColor: BrandConfig.onPrimaryDark,
      ),
      chipTheme: _m2ChipTheme(
        accent: AppColors.brandPrimaryOnDark,
        background: raised,
        label: BrandConfig.darkTextPrimary,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brandPrimaryOnDark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: raised,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(raised),
          elevation: WidgetStateProperty.all(8),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 6)),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(raised),
          elevation: WidgetStateProperty.all(8),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: raised,
        dayPeriodColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.brandPrimaryOnDark
              : scaffold,
        ),
        dayPeriodTextColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? BrandConfig.onPrimaryDark
              : BrandConfig.darkTextPrimary,
        ),
        hourMinuteColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.brandPrimaryOnDark.withValues(alpha: 0.16)
              : scaffold,
        ),
        hourMinuteTextColor: BrandConfig.darkTextPrimary,
        dialHandColor: AppColors.brandPrimaryOnDark,
        dialBackgroundColor: scaffold,
        dialTextColor: BrandConfig.darkTextPrimary,
        entryModeIconColor: AppColors.brandPrimaryOnDark,
      ),
      pageTransitionsTheme: _pageTransitionsTheme,
    );
  }

  static ChipThemeData _m2ChipTheme({
    required Color accent,
    required Color background,
    required Color label,
  }) {
    return ChipThemeData(
      backgroundColor: background,
      selectedColor: accent.withValues(alpha: 0.18),
      checkmarkColor: accent,
      // Chips replace (not merge) the default text style, so the font
      // family must be named here or labels fall back to the system font.
      labelStyle: TextStyle(
        fontFamily: BrandConfig.fontFamily,
        color: label,
        fontWeight: FontWeight.w500,
      ),
      secondaryLabelStyle: TextStyle(
        fontFamily: BrandConfig.fontFamily,
        color: accent,
        fontWeight: FontWeight.w600,
      ),
      secondarySelectedColor: accent.withValues(alpha: 0.18),
      shape: const StadiumBorder(),
    );
  }

  /// FilledButton is a Material 3 widget; give it the M2 button look used by
  /// ElevatedButton under `useMaterial3: false` — 4dp corners, resting
  /// elevation 2 that rises to 8 while pressed (animated by the button).
  static final ButtonStyle _m2ButtonShapeAndElevation = ButtonStyle(
    shape: WidgetStateProperty.all(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    elevation: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return 0;
      if (states.contains(WidgetState.pressed)) return 8;
      if (states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused)) {
        return 4;
      }
      return 2;
    }),
  );

  static PageTransitionsTheme get _pageTransitionsTheme {
    return PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _AppSharedAxisTransitionsBuilder(),
        TargetPlatform.iOS: _AppSharedAxisTransitionsBuilder(),
        TargetPlatform.macOS: _AppSharedAxisTransitionsBuilder(),
        TargetPlatform.linux: _AppSharedAxisTransitionsBuilder(),
        TargetPlatform.windows: _AppSharedAxisTransitionsBuilder(),
        TargetPlatform.fuchsia: _AppSharedAxisTransitionsBuilder(),
      },
    );
  }
}

/// Shared-axis page transitions (from the `animations` package) for every
/// pushed [MaterialPageRoute] app-wide, with reduced-motion support.
class _AppSharedAxisTransitionsBuilder extends PageTransitionsBuilder {
  static const _delegate = SharedAxisPageTransitionsBuilder(
    transitionType: SharedAxisTransitionType.horizontal,
    fillColor: Colors.transparent,
  );

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    return _delegate.buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
