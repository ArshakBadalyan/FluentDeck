import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/utils/html_text_utils.dart';

/// Text field with a minimal HTML formatting toolbar.
class HtmlFieldEditor extends StatefulWidget {
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
  State<HtmlFieldEditor> createState() => _HtmlFieldEditorState();
}

class _HtmlFieldEditorState extends State<HtmlFieldEditor> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.required ? '${widget.label} *' : widget.label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isHovered ? AppColors.primaryPurple : Colors.grey.shade200,
                width: _isHovered ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                _Toolbar(controller: widget.controller),
                TextField(
                  controller: widget.controller,
                  maxLines: widget.maxLines,
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  ),
                ),
              ],
            ),
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
