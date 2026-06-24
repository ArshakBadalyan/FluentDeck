import 'package:flutter/material.dart';
import 'package:speakstack/app_colors.dart';
import 'package:speakstack/models/placement_test_model.dart';
import 'package:speakstack/services/english_level_service.dart';

/// Verified placement styling (green check + light green background).
class CefrLevelColors {
  CefrLevelColors._();

  static const verifiedGreen = Color(0xFF2E7D32);
  static const verifiedGreenLight = Color(0xFFE8F5E9);
}

class CefrLevelChips extends StatelessWidget {
  const CefrLevelChips({
    super.key,
    this.levels = EnglishLevelService.levels,
    this.selectedLevel,
    this.verifiedLevel,
    this.onLevelSelected,
    this.allowDeselect = false,
    this.enabled = true,
  });

  final List<String> levels;
  final String? selectedLevel;
  final String? verifiedLevel;
  final ValueChanged<String?>? onLevelSelected;
  final bool allowDeselect;
  final bool enabled;

  bool get _locked => verifiedLevel != null;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          levels.map((level) => _LevelChip(
                level: level,
                isVerified: verifiedLevel == level,
                isSelected: selectedLevel == level,
                interactive: enabled && onLevelSelected != null && !_locked,
                allowDeselect: allowDeselect,
                onTap: onLevelSelected,
              )).toList(),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({
    required this.level,
    required this.isVerified,
    required this.isSelected,
    required this.interactive,
    required this.allowDeselect,
    this.onTap,
  });

  final String level;
  final bool isVerified;
  final bool isSelected;
  final bool interactive;
  final bool allowDeselect;
  final ValueChanged<String?>? onTap;

  @override
  Widget build(BuildContext context) {
    late final Color background;
    late final Color border;
    late final Color labelColor;

    if (isVerified) {
      background = CefrLevelColors.verifiedGreenLight;
      border = CefrLevelColors.verifiedGreen.withValues(alpha: 0.45);
      labelColor = CefrLevelColors.verifiedGreen;
    } else if (isSelected) {
      background = AppColors.primaryPurple.withValues(alpha: 0.12);
      border = AppColors.primaryPurple.withValues(alpha: 0.35);
      labelColor = AppColors.primaryPurple;
    } else {
      background = Colors.white;
      border = const Color(0xFFE0E0E5);
      labelColor = const Color(0xFF5C5C66);
    }

    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap:
            interactive
                ? () {
                  if (allowDeselect && isSelected) {
                    onTap?.call(null);
                  } else if (!isSelected) {
                    onTap?.call(level);
                  }
                }
                : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isVerified) ...[
                const Icon(
                  Icons.check_circle,
                  size: 18,
                  color: CefrLevelColors.verifiedGreen,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                level,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: labelColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VerifiedPlacementCard extends StatelessWidget {
  const VerifiedPlacementCard({super.key, required this.result});

  final PlacementTestResultModel result;

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final takenAt = result.takenAt;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CefrLevelColors.verifiedGreenLight,
            Colors.white,
          ],
        ),
        border: Border.all(
          color: CefrLevelColors.verifiedGreen.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CefrLevelColors.verifiedGreen.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_outlined,
              color: CefrLevelColors.verifiedGreen,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verified by placement test',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CefrLevelColors.verifiedGreen,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${result.suggestedLevel} · ${result.bucketLabel}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    'Score ${result.score.round()}%',
                    if (takenAt != null) 'Taken ${_formatDate(takenAt)}',
                  ].join(' · '),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
