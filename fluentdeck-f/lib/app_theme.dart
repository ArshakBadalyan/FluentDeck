import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_theme.dart';
import 'ui_elements/app_motion.dart';
import 'ui_elements/modern_page_widgets.dart';

/// Central light/dark themes seeded from the FluentDeck purple brand.
abstract final class AppTheme {
  static const _seed = AppColors.primaryPurple;

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
      surface: AppPageColors.pageBg,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Rubik',
      textTheme: AppTextTheme.textTheme,
      scaffoldBackgroundColor: Colors.white,
      cardColor: AppPageColors.cardBg,
      dividerColor: Colors.black.withValues(alpha: 0.06),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryPurple,
          foregroundColor: Colors.white,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryPurple,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPageColors.fieldBg,
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
      primary: AppColors.primaryPurple,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Rubik',
      textTheme: AppTextTheme.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      scaffoldBackgroundColor: scaffold,
      cardColor: card,
      dividerColor: Colors.white.withValues(alpha: 0.08),
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
          backgroundColor: AppColors.primaryPurple,
          foregroundColor: Colors.white,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryPurple,
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

class _AppSharedAxisTransitionsBuilder extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    final offsetAnimation = Tween<Offset>(
      begin: const Offset(0.06, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: AppMotion.curve));

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: offsetAnimation, child: child),
    );
  }
}
