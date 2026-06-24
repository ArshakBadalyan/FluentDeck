import 'package:flutter/material.dart';
import 'package:speakstack/app_colors.dart';
import 'package:speakstack/utils/html_text_utils.dart';

/// Text field with a minimal HTML formatting toolbar (Anki-style).
class HtmlFieldEditor extends StatelessWidget {
  const HtmlFieldEditor({
    super.key,
    required this.label,
    required this.controller,
    this.maxLines = 4,
    this.hint,
    this.required = false,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final String? hint;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required ? '$label *' : label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _Toolbar(controller: controller),
              TextField(
                controller: controller,
                maxLines: maxLines,
                decoration: InputDecoration(
                  hintText: hint,
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
          _btn(Icons.format_bold, () => wrapHtmlSelection(controller, '<b>', '</b>')),
          _btn(Icons.format_italic, () => wrapHtmlSelection(controller, '<i>', '</i>')),
          _btn(Icons.format_underlined, () => wrapHtmlSelection(controller, '<u>', '</u>')),
          _btn(
            Icons.format_color_text,
            () => wrapHtmlSelection(
              controller,
              '<span style="color:red">',
              '</span>',
            ),
          ),
          _btn(
            Icons.functions,
            () => wrapLatexInline(controller),
            tooltip: 'Insert LaTeX \\( \\)',
          ),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onPressed, {String? tooltip}) {
    return IconButton(
      icon: Icon(icon, size: 20),
      color: AppColors.primaryPurple,
      tooltip: tooltip ?? 'Format selection',
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
    );
  }
}
