import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_theme.dart';
import 'config/brand_config.dart';
import 'ui_elements/modern_page_widgets.dart';

/// Central light/dark themes seeded from the brand color in [BrandConfig].
abstract final class AppTheme {
  static const _seed = AppColors.brandPrimary;

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
      surface: AppPageColors.pageBg,
    );

    return ThemeData(
      useMaterial3: true,
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
        ),
      ),
      // Material3's seed-generated default (colorScheme.primaryContainer) is a
      // pale, washed-out tint of the brand teal — fine for chips, wrong for an
      // FAB. Any FloatingActionButton that doesn't set its own colors falls
      // back to this instead of that pastel.
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.brandPrimaryDeep,
        foregroundColor: Colors.white,
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
    );

    return ThemeData(
      useMaterial3: true,
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
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.brandPrimaryOnDark,
        foregroundColor: BrandConfig.onPrimaryDark,
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
      pageTransitionsTheme: _pageTransitionsTheme,
    );
  }

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
