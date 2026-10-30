import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';
import 'package:fluentdeck/utils/html_text_utils.dart';

/// Cloze "Text" field — select a word, tap "Hide selected" to turn it into
/// a blank, instead of typing `{{c1::word}}` by hand. Existing blanks show
/// as removable chips below the field so undoing one doesn't mean hand-
/// editing braces back out either.
class ClozeFieldEditor extends StatefulWidget {
  const ClozeFieldEditor({
    super.key,
    required this.controller,
    this.maxLines = 5,
    this.required = false,
    this.toolbarActions = const [],
  });

  final TextEditingController controller;
  final int maxLines;
  final bool required;
  /// Extra buttons after "Hide selected" (e.g. record audio).
  final List<Widget> toolbarActions;

  @override
  State<ClozeFieldEditor> createState() => _ClozeFieldEditorState();
}

class _ClozeFieldEditorState extends State<ClozeFieldEditor> {
  @override
  void initState() {
    super.initState();
    // TextEditingController's notifications cover both text and selection
    // changes, so this alone keeps the "Hide selected" enabled-state and
    // the chip list in sync with what's actually selected/typed.
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  void _hideSelection() => wrapClozeSelection(widget.controller);

  void _removeDeletion(int number) => removeClozeDeletion(widget.controller, number);

  @override
  Widget build(BuildContext context) {
    final selection = widget.controller.selection;
    final hasSelection = selection.isValid &&
        !selection.isCollapsed &&
        selection.textInside(widget.controller.text).trim().isNotEmpty;
    final deletions = extractClozeDeletions(widget.controller.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.required ? 'Text *' : 'Text',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            // White with a teal outline, like the other card fields.
            color: AppPageColors.cardBgOf(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppPageColors.accentOf(context), width: 2),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: hasSelection ? _hideSelection : null,
                      icon: const Icon(Icons.visibility_off_outlined, size: 18),
                      label: const Text('Hide selected'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppPageColors.accentOf(context),
                        disabledForegroundColor: AppPageColors.subtitleOf(context),
                      ),
                    ),
                    ...widget.toolbarActions,
                  ],
                ),
              ),
              TextField(
                controller: widget.controller,
                maxLines: widget.maxLines,
                decoration: InputDecoration(
                  hintText: 'Type a sentence, select a word, then tap "Hide selected"',
                  filled: true,
                  fillColor: AppPageColors.cardBgOf(context),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (deletions.isEmpty)
          Text(
            'No blanks yet — select a word above, then tap "Hide selected".',
            style: TextStyle(fontSize: 12, color: AppPageColors.subtitleOf(context)),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: deletions.map((d) {
              return Chip(
                label: Text('c${d.number}: ${d.word}'),
                onDeleted: () => _removeDeletion(d.number),
                backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.12),
                labelStyle: TextStyle(
                  color: AppPageColors.accentOf(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                deleteIconColor: AppPageColors.accentOf(context),
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
      ],
    );
  }
}
