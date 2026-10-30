import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../config/brand_config.dart';

/// The "riovox" wordmark: rounded lowercase letters with the coral "v" and
/// eyes in the o's — the same drawing as the landing page's
/// `riovox-wordmark.svg`. Letters follow the theme (dark ink on light pages,
/// light on dark ones); the "v" is always the voice coral.
class RiovoxWordmark extends StatelessWidget {
  const RiovoxWordmark({super.key, this.height = 28, this.color});

  /// Height of the wordmark; the width follows its 588:184 shape.
  final double height;

  /// Letter colour; defaults to the theme's primary text colour.
  final Color? color;

  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  static String _svg(String ink, String voice) => '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="14 32 588 184">
<path d="M30 200V96M30 138c0-30 18-44 46-42" stroke="$ink" fill="none" stroke-width="28" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M110 96V200" stroke="$ink" fill="none" stroke-width="28" stroke-linecap="round" stroke-linejoin="round"/>
<circle cx="110" cy="50" r="17" fill="$ink"/>
<circle cx="190" cy="145" r="51" stroke="$ink" fill="none" stroke-width="28"/>
<path d="M268 96l37 104 37-104" stroke="$voice" fill="none" stroke-width="28" stroke-linecap="round" stroke-linejoin="round"/>
<circle cx="420" cy="145" r="51" stroke="$ink" fill="none" stroke-width="28"/>
<circle cx="200" cy="137" r="14" fill="$ink"/>
<circle cx="430" cy="137" r="14" fill="$ink"/>
<path d="M500 96l86 104M586 96l-86 104" stroke="$ink" fill="none" stroke-width="28" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = color ??
        (isDark ? BrandConfig.darkTextPrimary : BrandConfig.textPrimary);
    return Semantics(
      label: BrandConfig.appName,
      image: true,
      child: ExcludeSemantics(
        child: SvgPicture.string(
          _svg(_hex(ink), _hex(BrandConfig.voice)),
          height: height,
          width: height * 588 / 184,
        ),
      ),
    );
  }
}
