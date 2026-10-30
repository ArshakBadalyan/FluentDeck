import 'package:flutter/material.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';
import 'package:fluentdeck/widgets/rich_text_controller.dart';

/// Card field with a formatting toolbar. Bold, italic, underline and red show
/// as formatting while typing; [controller] keeps the stored HTML.
///
/// Fields holding HTML the editor can't show (images, tables from imports)
/// fall back to editing the raw text so nothing is lost.
class HtmlFieldEditor extends StatefulWidget {
  const HtmlFieldEditor({
    super.key,
    required this.label,
    required this.controller,
    this.maxLines = 4,
    this.hint,
    this.required = false,
    this.trailing,
    this.toolbarActions = const [],
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final String? hint;
  final bool required;
  /// Optional action shown at the end of the label row (e.g. an AI button).
  final Widget? trailing;
  /// Extra buttons at the end of the formatting toolbar (e.g. record audio).
  final List<Widget> toolbarActions;

  @override
  State<HtmlFieldEditor> createState() => _HtmlFieldEditorState();
}

class _HtmlFieldEditorState extends State<HtmlFieldEditor> {
  RichTextController? _rich;

  @override
  void initState() {
    super.initState();
    _attach();
  }

  @override
  void didUpdateWidget(HtmlFieldEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onOuterChanged);
      _rich?.removeListener(_onRichChanged);
      _rich?.dispose();
      _attach();
    }
  }

  void _attach() {
    final html = widget.controller.text;
    _rich = RichTextController.canEdit(html) ? (RichTextController(html: html)..addListener(_onRichChanged)) : null;
    widget.controller.addListener(_onOuterChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onOuterChanged);
    _rich?.removeListener(_onRichChanged);
    _rich?.dispose();
    super.dispose();
  }

  void _onRichChanged() {
    final html = _rich!.html;
    if (widget.controller.text != html) widget.controller.text = html;
    setState(() {}); // toolbar active states follow the selection
  }

  /// Text set from outside (AI fill, reset after save) reloads the editor.
  void _onOuterChanged() {
    final rich = _rich;
    final html = widget.controller.text;
    if (rich == null || rich.html == html) return;
    if (RichTextController.canEdit(html)) {
      rich.setHtml(html);
    } else {
      rich.removeListener(_onRichChanged);
      rich.dispose();
      setState(() => _rich = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rich = _rich;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.required ? '${widget.label} *' : widget.label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (widget.trailing != null) widget.trailing!,
          ],
        ),
        SizedBox(height: widget.trailing != null ? 2 : 8),
        Container(
          decoration: BoxDecoration(
            color: AppPageColors.cardBgOf(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppPageColors.subtleBorderOf(context), width: 1),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                child: Row(
                  children: [
                    if (rich != null) ...[
                      _FormatButton(rich: rich, flag: RichFormat.bold, icon: Icons.format_bold, tooltip: 'Bold'),
                      _FormatButton(rich: rich, flag: RichFormat.italic, icon: Icons.format_italic, tooltip: 'Italic'),
                      _FormatButton(
                        rich: rich,
                        flag: RichFormat.underline,
                        icon: Icons.format_underlined,
                        tooltip: 'Underline',
                      ),
                      _FormatButton(rich: rich, flag: RichFormat.red, icon: Icons.format_color_text, tooltip: 'Red text'),
                    ],
                    ...widget.toolbarActions,
                  ],
                ),
              ),
              TextField(
                controller: rich ?? widget.controller,
                maxLines: widget.maxLines,
                style: TextStyle(fontSize: 16, color: AppPageColors.textPrimaryOf(context)),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  filled: true,
                  fillColor: AppPageColors.cardBgOf(context),
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

/// A toolbar toggle; filled while its format is on for the selection.
class _FormatButton extends StatelessWidget {
  const _FormatButton({required this.rich, required this.flag, required this.icon, required this.tooltip});

  final RichTextController rich;
  final int flag;
  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final accent = AppPageColors.accentOf(context);
    final active = rich.isActive(flag);
    // Material 2 ignores IconButton.style/isSelected, so the "on" tint is a box.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: active ? accent.withValues(alpha: 0.14) : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: flag == RichFormat.red ? Colors.red : accent),
        tooltip: tooltip,
        onPressed: () => rich.toggle(flag),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
