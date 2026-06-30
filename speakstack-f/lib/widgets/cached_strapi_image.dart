import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'package:speakstack/ui_elements/modern_page_widgets.dart';

/// Disk-cached network image for Strapi media and flashcard attachments.
class CachedStrapiImage extends StatelessWidget {
  const CachedStrapiImage({
    super.key,
    required this.url,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderColor,
    this.errorBuilder,
  });

  final String url;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Color? placeholderColor;
  final Widget Function(BuildContext context)? errorBuilder;

  static final CacheManager cacheManager = CacheManager(
    Config(
      'speakstack_media_cache',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 400,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final placeholder = placeholderColor ?? AppPageColors.fieldBg;

    Widget image = CachedNetworkImage(
      imageUrl: url,
      cacheManager: cacheManager,
      height: height,
      width: width,
      fit: fit,
      placeholder: (context, _) => ColoredBox(
        color: placeholder,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
      errorWidget: (context, _, __) {
        if (errorBuilder != null) return errorBuilder!(context);
        return ColoredBox(
          color: placeholder,
          child: const Center(child: Text('Could not load image')),
        );
      },
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }
}
