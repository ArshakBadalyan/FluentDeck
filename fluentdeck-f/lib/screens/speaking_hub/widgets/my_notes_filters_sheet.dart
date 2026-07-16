import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/ui_elements/frosted_bottom_sheet.dart';
import 'package:fluentdeck/widgets/speaking_hub_widgets.dart';

class MyNotesFiltersSheet extends StatefulWidget {
  const MyNotesFiltersSheet({
    super.key,
    required this.levelLabels,
    required this.levelIndex,
    required this.languageLabels,
    required this.languageIndex,
    required this.topicOptions,
    required this.topicFilter,
    required this.enabled,
  });

  final List<String> levelLabels;
  final int levelIndex;
  final List<String> languageLabels;
  final int languageIndex;
  final List<String> topicOptions;
  final String topicFilter;
  final bool enabled;

  @override
  State<MyNotesFiltersSheet> createState() => _MyNotesFiltersSheetState();
}

class _MyNotesFiltersSheetState extends State<MyNotesFiltersSheet> {
  late int _levelIndex;
  late int _languageIndex;
  late String _topicFilter;

  @override
  void initState() {
    super.initState();
    _levelIndex = widget.levelIndex;
    _languageIndex = widget.languageIndex;
    _topicFilter = widget.topicFilter;
  }

  void _apply() {
    Navigator.pop(context, (
      levelIndex: _levelIndex,
      languageIndex: _languageIndex,
      topicFilter: _topicFilter,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: AppColors.primaryPurple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Refine list',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Rubik',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          if (!widget.enabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Level, language, and topic filters apply when viewing All or From speaking.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.35),
              ),
            ),
          Opacity(
            opacity: widget.enabled ? 1 : 0.45,
            child: IgnorePointer(
              ignoring: !widget.enabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: Text(
                      'Level',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  SpeakingFilterChips(
                    labels: widget.levelLabels,
                    selectedIndex: _levelIndex,
                    onSelected: (i) => setState(() => _levelIndex = i),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Text(
                      'Language',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  SpeakingFilterChips(
                    labels: widget.languageLabels,
                    selectedIndex: _languageIndex,
                    onSelected: (i) => setState(() => _languageIndex = i),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                    child: Text(
                      'Topic',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _topicChip('All topics', 'all'),
                        for (final topic in widget.topicOptions)
                          _topicChip(topic, topic),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: FilledButton(
              onPressed: _apply,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Apply filters'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topicChip(String label, String value) {
    final selected = _topicFilter == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _topicFilter = value),
      selectedColor: AppColors.primaryPurple.withValues(alpha: 0.12),
      checkmarkColor: AppColors.primaryPurple,
      labelStyle: TextStyle(
        fontSize: 12,
        color: selected ? AppColors.primaryPurple : const Color(0xFF777481),
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        fontFamily: 'Rubik',
      ),
      side: BorderSide(
        color: selected ? AppColors.primaryPurple : Colors.grey.shade300,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}

Future<({int levelIndex, int languageIndex, String topicFilter})?>
showMyNotesFiltersSheet(
  BuildContext context, {
  required List<String> levelLabels,
  required int levelIndex,
  required List<String> languageLabels,
  required int languageIndex,
  required List<String> topicOptions,
  required String topicFilter,
  required bool enabled,
}) {
  return showFrostedBottomSheet<({int levelIndex, int languageIndex, String topicFilter})>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder:
        (ctx) => MyNotesFiltersSheet(
          levelLabels: levelLabels,
          levelIndex: levelIndex,
          languageLabels: languageLabels,
          languageIndex: languageIndex,
          topicOptions: topicOptions,
          topicFilter: topicFilter,
          enabled: enabled,
        ),
  );
}
