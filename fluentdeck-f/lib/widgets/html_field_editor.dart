import 'package:flutter/material.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';
import 'package:fluentdeck/utils/html_text_utils.dart';

/// Text field with a minimal HTML formatting toolbar.
class HtmlFieldEditor extends StatelessWidget {
  const HtmlFieldEditor({
    super.key,
    required this.label,
    required this.controller,
    this.maxLines = 4,
    this.hint,
    this.required = false,
    this.trailing,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final String? hint;
  final bool required;
  /// Optional action shown at the end of the label row (e.g. an AI button).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                required ? '$label *' : label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        SizedBox(height: trailing != null ? 2 : 8),
        Container(
          decoration: BoxDecoration(
            color: AppPageColors.fieldBgOf(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppPageColors.subtleBorderOf(context), width: 1),
          ),
          child: Column(
            children: [
              _Toolbar(controller: controller),
              TextField(
                controller: controller,
                maxLines: maxLines,
                decoration: InputDecoration(
                  hintText: hint,
                  filled: true,
                  fillColor: AppPageColors.fieldBgOf(context),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Row(
        children: [
          _btn(context, Icons.format_bold, () => wrapHtmlSelection(controller, '<b>', '</b>')),
          _btn(context, Icons.format_italic, () => wrapHtmlSelection(controller, '<i>', '</i>')),
          _btn(
            context,
            Icons.format_underlined,
            () => wrapHtmlSelection(controller, '<u>', '</u>'),
          ),
          _btn(
            context,
            Icons.format_color_text,
            () => wrapHtmlSelection(
              controller,
              '<span style="color:red">',
              '</span>',
            ),
          ),
          _btn(
            context,
            Icons.functions,
            () => wrapLatexInline(controller),
            tooltip: 'Insert LaTeX \\( \\)',
          ),
        ],
      ),
    );
  }

  Widget _btn(
    BuildContext context,
    IconData icon,
    VoidCallback onPressed, {
    String? tooltip,
  }) {
    return IconButton(
      icon: Icon(icon, size: 20),
      color: AppPageColors.accentOf(context),
      tooltip: tooltip ?? 'Format selection',
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
    );
  }
}
