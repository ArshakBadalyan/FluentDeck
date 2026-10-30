import 'package:flutter/material.dart';

import 'config/brand_config.dart';

/// App-wide color tokens. Values live in [BrandConfig] — edit them there.
class AppColors {
  AppColors._();

  static const Color brandPrimary = BrandConfig.primary;

  /// Header / app-bar accent and gradient end.
  static const Color brandPrimaryDeep = BrandConfig.primaryDeep;
  static const Color brandPrimaryOnDark = BrandConfig.primaryOnDark;
  static const Color voice = BrandConfig.voice;
  static const Color voiceDeep = BrandConfig.voiceDeep;
  static const Color primaryYellow = BrandConfig.reward;
  static const Color navInactive = BrandConfig.navInactive;
  static const Color pageBg = BrandConfig.pageBg;
  static const List<Color> heroGradient = BrandConfig.heroGradient;

  static const Color greenCorrect = BrandConfig.correct;
  static const Color redWrong = BrandConfig.wrong;
  static const Color orangeHard = BrandConfig.hard;
  static const Color greySkipped = BrandConfig.skipped;

  static const Color axisBlack = Colors.black;
}
