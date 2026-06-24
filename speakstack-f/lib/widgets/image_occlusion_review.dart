import 'package:flutter/material.dart';
import 'package:speakstack/app_colors.dart';
import 'package:speakstack/models/occlusion_model.dart';

/// Image occlusion review — one hidden mask per card (Phase 4I).
class ImageOcclusionReview extends StatelessWidget {
  const ImageOcclusionReview({
    super.key,
    required this.data,
    required this.revealed,
    this.onTap,
    this.textScale = 1.0,
  });

  final OcclusionData data;
  final bool revealed;
  final VoidCallback? onTap;
  final double textScale;

  @override
  Widget build(BuildContext context) {
    final imageUrl = data.imageUrl.isNotEmpty ? data.imageUrl : '';
    if (imageUrl.isEmpty) {
      return const Text('Missing occlusion image');
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (data.header.isNotEmpty) ...[
            Text(
              data.header,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16 * textScale,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
          ],
          AspectRatio(
            aspectRatio: 4 / 3,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder:
                            (_, __, ___) => Container(
                              color: const Color(0xFFF2F2F5),
                              alignment: Alignment.center,
                              child: const Text('Could not load image'),
                            ),
                      ),
                      ...data.regions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final region = entry.value;
                        final isActive = index == data.activeIndex;
                        if (!isActive) {
                          return Positioned(
                            left: region.x * size.width,
                            top: region.y * size.height,
                            width: region.w * size.width,
                            height: region.h * size.height,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  width: 1,
                                ),
                              ),
                            ),
                          );
                        }

                        if (revealed) {
                          return Positioned(
                            left: region.x * size.width,
                            top: region.y * size.height,
                            width: region.w * size.width,
                            height: region.h * size.height,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.greenCorrect, width: 2),
                                color: AppColors.greenCorrect.withValues(alpha: 0.15),
                              ),
                            ),
                          );
                        }

                        return Positioned(
                          left: region.x * size.width,
                          top: region.y * size.height,
                          width: region.w * size.width,
                          height: region.h * size.height,
                          child: ColoredBox(
                            color: AppColors.primaryPurple.withValues(alpha: 0.88),
                            child: const Center(
                              child: Icon(Icons.visibility_off, color: Colors.white),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
          if (revealed && data.activeRegion?.label.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text(
              data.activeRegion!.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20 * textScale,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
