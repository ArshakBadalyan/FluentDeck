import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/services/english_level_service.dart';

class CefrLevelChips extends StatelessWidget {
  const CefrLevelChips({
    super.key,
    this.levels = EnglishLevelService.levels,
    this.selectedLevel,
    this.onLevelSelected,
    this.allowDeselect = false,
    this.enabled = true,
    this.lockedLevels = const {},
    this.onLockedLevelTap,
  });

  final List<String> levels;
  final String? selectedLevel;
  final ValueChanged<String?>? onLevelSelected;
  final bool allowDeselect;
  final bool enabled;

  /// Levels shown with a lock icon (e.g. Premium-only). Tapping one calls
  /// [onLockedLevelTap] instead of [onLevelSelected].
  final Set<String> lockedLevels;
  final ValueChanged<String>? onLockedLevelTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          levels
              .map(
                (level) => _LevelChip(
                  level: level,
                  isSelected: selectedLevel == level,
                  interactive: enabled && onLevelSelected != null,
                  allowDeselect: allowDeselect,
                  locked: lockedLevels.contains(level),
                  onTap: onLevelSelected,
                  onLockedTap: onLockedLevelTap,
                ),
              )
              .toList(),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({
    required this.level,
    required this.isSelected,
    required this.interactive,
    required this.allowDeselect,
    this.locked = false,
    this.onTap,
    this.onLockedTap,
  });

  final String level;
  final bool isSelected;
  final bool interactive;
  final bool allowDeselect;
  final bool locked;
  final ValueChanged<String?>? onTap;
  final ValueChanged<String>? onLockedTap;

  @override
  Widget build(BuildContext context) {
    late final Color background;
    late final Color border;
    late final Color labelColor;

    if (isSelected) {
      background = AppColors.primaryPurple.withValues(alpha: 0.12);
      border = AppColors.primaryPurple.withValues(alpha: 0.35);
      labelColor = AppColors.primaryPurple;
    } else if (locked) {
      background = const Color(0xFFF2F2F5);
      border = const Color(0xFFE0E0E5);
      labelColor = Colors.grey.shade500;
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
            locked
                ? (onLockedTap != null ? () => onLockedTap!(level) : null)
                : interactive
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
              Text(
                level,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: labelColor,
                ),
              ),
              if (locked) ...[
                const SizedBox(width: 5),
                Icon(Icons.lock_outline_rounded, size: 13, color: labelColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
