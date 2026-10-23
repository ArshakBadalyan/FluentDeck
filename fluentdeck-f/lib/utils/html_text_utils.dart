import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// Wrap the current selection in [open]/[close] tags.
void wrapHtmlSelection(
  TextEditingController controller,
  String open,
  String close,
) {
  final selection = controller.selection;
  if (!selection.isValid) return;

  final text = controller.text;
  final selected = selection.textInside(text);
  final start = selection.start;
  final end = selection.end;
  final updated = text.replaceRange(start, end, '$open$selected$close');

  controller.value = TextEditingValue(
    text: updated,
    selection: TextSelection.collapsed(
      offset: start + open.length + selected.length + close.length,
    ),
  );
}

/// Insert inline LaTeX delimiters around the selection.
void wrapLatexInline(TextEditingController controller) {
  wrapHtmlSelection(controller, r'\(', r'\)');
}

/// Strip HTML tags for plain-text previews.
String stripHtml(String input) {
  return input.replaceAll(RegExp(r'<[^>]+>'), '').trim();
}

final _inlineLatexRe = RegExp(r'\\\((.+?)\\\)', dotAll: true);
final _displayLatexRe = RegExp(r'\\\[(.+?)\\\]', dotAll: true);
final _htmlTagRe = RegExp(
  r'<(b|i|u|span)(?:\s+style="color:\s*([^"]+)")?\s*>(.*?)</\1>',
  caseSensitive: false,
  dotAll: true,
);

bool _containsLatex(String input) =>
    _inlineLatexRe.hasMatch(input) || _displayLatexRe.hasMatch(input);

Color? _parseHtmlColor(String value) {
  final v = value.trim().toLowerCase();
  const named = {
    'red': Colors.red,
    'blue': Colors.blue,
    'green': Colors.green,
    'orange': Colors.orange,
    'purple': Colors.purple,
    'black': Colors.black,
    'gray': Colors.grey,
    'grey': Colors.grey,
  };
  if (named.containsKey(v)) return named[v];
  if (v.startsWith('#') && (v.length == 7 || v.length == 4)) {
    final hex = v.substring(1);
    if (hex.length == 6) {
      final n = int.tryParse(hex, radix: 16);
      if (n != null) return Color(0xFF000000 | n);
    }
  }
  return null;
}

List<InlineSpan> _parseHtmlSpans(String input, TextStyle current) {
  final spans = <InlineSpan>[];
  var index = 0;
  for (final match in _htmlTagRe.allMatches(input)) {
    if (match.start > index) {
      spans.add(TextSpan(text: stripHtml(input.substring(index, match.start)), style: current));
    }

    final tag = match.group(1)!.toLowerCase();
    final color = match.group(2);
    final inner = match.group(3) ?? '';
    TextStyle next = current;
    if (tag == 'b') next = next.copyWith(fontWeight: FontWeight.bold);
    if (tag == 'i') next = next.copyWith(fontStyle: FontStyle.italic);
    if (tag == 'u') next = next.copyWith(decoration: TextDecoration.underline);
    if (tag == 'span' && color != null) {
      next = next.copyWith(color: _parseHtmlColor(color));
    }

    spans.addAll(_parseHtmlSpans(inner, next));
    index = match.end;
  }

  if (index < input.length) {
    spans.add(TextSpan(text: stripHtml(input.substring(index)), style: current));
  }

  if (spans.isEmpty) {
    spans.add(TextSpan(text: stripHtml(input), style: current));
  }

  return spans;
}

Widget _mathWidget(String latex, TextStyle base, {bool display = false}) {
  return Math.tex(
    latex,
    mathStyle: display ? MathStyle.display : MathStyle.text,
    textStyle: base,
    onErrorFallback: (err) => Text(
      latex,
      style: base.copyWith(
        fontStyle: FontStyle.italic,
        color: Colors.red.shade700,
      ),
    ),
  );
}

WidgetSpan _inlineLatexSpan(String latex, TextStyle base) {
  return WidgetSpan(
    alignment: PlaceholderAlignment.middle,
    child: _mathWidget(latex, base),
  );
}

List<InlineSpan> _parseInlineLatexSpans(String input, TextStyle base) {
  final spans = <InlineSpan>[];
  var index = 0;
  for (final match in _inlineLatexRe.allMatches(input)) {
    if (match.start > index) {
      spans.addAll(_parseHtmlSpans(input.substring(index, match.start), base));
    }
    spans.add(_inlineLatexSpan(match.group(1) ?? '', base));
    index = match.end;
  }
  if (index < input.length) {
    spans.addAll(_parseHtmlSpans(input.substring(index), base));
  }
  if (spans.isEmpty) {
    spans.addAll(_parseHtmlSpans(input, base));
  }
  return spans;
}

class _HtmlBlock {
  const _HtmlBlock({this.text = '', this.latex = '', this.isDisplay = false});

  final String text;
  final String latex;
  final bool isDisplay;
}

List<_HtmlBlock> _splitDisplayBlocks(String input) {
  final blocks = <_HtmlBlock>[];
  var index = 0;
  for (final match in _displayLatexRe.allMatches(input)) {
    if (match.start > index) {
      blocks.add(_HtmlBlock(text: input.substring(index, match.start)));
    }
    blocks.add(_HtmlBlock(latex: match.group(1) ?? '', isDisplay: true));
    index = match.end;
  }
  if (index < input.length) {
    blocks.add(_HtmlBlock(text: input.substring(index)));
  }
  if (blocks.isEmpty) {
    blocks.add(_HtmlBlock(text: input));
  }
  return blocks;
}

CrossAxisAlignment _crossAlign(TextAlign align) {
  switch (align) {
    case TextAlign.center:
      return CrossAxisAlignment.center;
    case TextAlign.end:
    case TextAlign.right:
      return CrossAxisAlignment.end;
    default:
      return CrossAxisAlignment.start;
  }
}

Alignment _blockAlign(TextAlign align) {
  switch (align) {
    case TextAlign.center:
      return Alignment.center;
    case TextAlign.end:
    case TextAlign.right:
      return Alignment.centerRight;
    default:
      return Alignment.centerLeft;
  }
}

/// Lightweight renderer for basic HTML (b, i, u, span color) and LaTeX.
class BasicHtmlText extends StatelessWidget {
  const BasicHtmlText({
    super.key,
    required this.html,
    this.style,
    this.textAlign = TextAlign.start,
  });

  final String html;
  final TextStyle? style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final base = style ?? const TextStyle(fontSize: 16, height: 1.4);
    if (!_containsLatex(html)) {
      return Text.rich(
        TextSpan(children: _parseHtmlSpans(html, base)),
        textAlign: textAlign,
      );
    }

    final blocks = _splitDisplayBlocks(html);
    return Column(
      crossAxisAlignment: _crossAlign(textAlign),
      children:
          blocks.map((block) {
            if (block.isDisplay) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Align(
                  alignment: _blockAlign(textAlign),
                  child: _mathWidget(block.latex, base, display: true),
                ),
              );
            }
            return Text.rich(
              TextSpan(children: _parseInlineLatexSpans(block.text, base)),
              textAlign: textAlign,
            );
          }).toList(),
    );
  }
}

/// Cloze helpers for Phase 4C editor validation.
bool hasClozeDeletions(String text) => RegExp(r'\{\{c\d+::').hasMatch(text);

final _clozeDeletionRe = RegExp(r'\{\{c(\d+)::([^}]+?)(?:::[^}]+)?\}\}');

/// One `{{cN::word}}` found in a Cloze note's text — number + hidden word.
class ClozeDeletion {
  const ClozeDeletion({required this.number, required this.word});
  final int number;
  final String word;
}

List<ClozeDeletion> extractClozeDeletions(String text) => _clozeDeletionRe
    .allMatches(text)
    .map((m) => ClozeDeletion(number: int.parse(m.group(1)!), word: m.group(2) ?? ''))
    .toList();

/// Wraps the controller's current text selection in `{{cN::selected}}`,
/// auto-picking the next deletion number — the "tap Hide" alternative to
/// typing the `{{c1::...}}` syntax by hand. No-op on an empty/invalid
/// selection or one that's only whitespace.
void wrapClozeSelection(TextEditingController controller) {
  final selection = controller.selection;
  if (!selection.isValid || selection.isCollapsed) return;

  final text = controller.text;
  final selected = selection.textInside(text);
  if (selected.trim().isEmpty) return;

  final existing = extractClozeDeletions(text);
  final nextNumber = existing.isEmpty
      ? 1
      : existing.map((d) => d.number).reduce((a, b) => a > b ? a : b) + 1;

  final start = selection.start;
  final end = selection.end;
  final wrapped = '{{c$nextNumber::$selected}}';
  final updated = text.replaceRange(start, end, wrapped);

  controller.value = TextEditingValue(
    text: updated,
    selection: TextSelection.collapsed(offset: start + wrapped.length),
  );
}

/// Removes one specific `{{cN::word}}` deletion, leaving the plain word in
/// its place — the "x" on a deletion chip, undoing a Hide without having to
/// hand-edit the braces back out.
void removeClozeDeletion(TextEditingController controller, int number) {
  final text = controller.text;
  final match = _clozeDeletionRe.allMatches(text).firstWhere(
        (m) => int.parse(m.group(1)!) == number,
        orElse: () => throw StateError('deletion c$number not found'),
      );
  final word = match.group(2) ?? '';
  final updated = text.replaceRange(match.start, match.end, word);
  controller.value = TextEditingValue(
    text: updated,
    selection: TextSelection.collapsed(offset: match.start + word.length),
  );
}

String renderClozePreviewFront(String text, {int activeIndex = 1}) {
  return text.replaceAllMapped(
    RegExp(r'\{\{c(\d+)::([^}]+?)(?:::[^}]+)?\}\}'),
    (m) => int.parse(m.group(1)!) == activeIndex ? '[...]' : (m.group(2) ?? ''),
  );
}

String renderClozePreviewBack(String text, {int activeIndex = 1}) {
  return text.replaceAllMapped(
    RegExp(r'\{\{c(\d+)::([^}]+?)(?:::[^}]+)?\}\}'),
    (m) =>
        int.parse(m.group(1)!) == activeIndex
            ? '<b>${m.group(2)}</b>'
            : (m.group(2) ?? ''),
  );
}
