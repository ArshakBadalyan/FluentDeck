import 'package:flutter/material.dart';
import 'package:speakstack/app_colors.dart';

/// Shows up to [previewCount] items in a fixed-height scroll area when there
/// are more entries, plus an optional "View all" link.
class ActivityPreviewList extends StatelessWidget {
  const ActivityPreviewList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.onViewAll,
    this.previewCount = 3,
    this.itemHeight = 72,
    this.itemSpacing = 10,
    this.viewAllLabel,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final VoidCallback onViewAll;
  final int previewCount;
  final double itemHeight;
  final double itemSpacing;
  final String? viewAllLabel;

  double get _listHeight {
    final visible = itemCount > previewCount ? previewCount : itemCount;
    if (visible <= 0) return 0;
    return visible * itemHeight + (visible - 1) * itemSpacing;
  }

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) return const SizedBox.shrink();

    final scrollable = itemCount > previewCount;
    final list = ListView.separated(
      shrinkWrap: !scrollable,
      physics:
          scrollable
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: itemCount,
      separatorBuilder: (_, __) => SizedBox(height: itemSpacing),
      itemBuilder: itemBuilder,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (scrollable)
          SizedBox(height: _listHeight, child: list)
        else
          list,
        if (scrollable) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: onViewAll,
              child: Text(
                viewAllLabel ?? 'View all ($itemCount)',
                style: const TextStyle(
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
