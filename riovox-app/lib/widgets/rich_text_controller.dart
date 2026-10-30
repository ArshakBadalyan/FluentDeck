import 'package:flutter/material.dart';

/// Formatting flags a character can carry in [RichTextController].
abstract final class RichFormat {
  static const bold = 1;
  static const italic = 2;
  static const underline = 4;
  static const red = 8;
}

/// Edits text with bold / italic / underline / red shown as formatting, not
/// tags. [text] is plain; [html] is what the card stores (the same tags
/// [BasicHtmlText] renders).
class RichTextController extends TextEditingController {
  RichTextController({String html = ''}) {
    setHtml(html);
  }

  static final _tagRe = RegExp(r'<(/?)([a-zA-Z]+)([^>]*)>');
  static const _knownTags = {'b', 'strong', 'i', 'em', 'u', 'span'};

  /// True when [html] only uses tags this editor can show without losing any.
  static bool canEdit(String html) => _tagRe
      .allMatches(html)
      .every((m) => _knownTags.contains(m.group(2)!.toLowerCase()));

  List<int> _styles = [];
  String _lastText = '';

  /// Style for the next typed characters after a toolbar tap with no selection.
  int? _typingStyle;

  void setHtml(String html) {
    final chars = StringBuffer();
    final styles = <int>[];
    final stack = <int>[];
    var current = 0;
    var index = 0;
    void addText(String s) {
      chars.write(s);
      styles.addAll(List.filled(s.length, current));
    }

    for (final m in _tagRe.allMatches(html)) {
      addText(html.substring(index, m.start));
      index = m.end;
      final closing = m.group(1) == '/';
      final flag = switch (m.group(2)!.toLowerCase()) {
        'b' || 'strong' => RichFormat.bold,
        'i' || 'em' => RichFormat.italic,
        'u' => RichFormat.underline,
        'span' => (m.group(3) ?? '').contains('color') ? RichFormat.red : 0,
        _ => 0,
      };
      if (closing) {
        if (stack.isNotEmpty) stack.removeLast();
      } else {
        stack.add(flag);
      }
      current = stack.fold(0, (a, f) => a | f);
    }
    addText(html.substring(index));
    _styles = styles;
    _lastText = chars.toString();
    _typingStyle = null;
    super.value = TextEditingValue(
      text: _lastText,
      selection: TextSelection.collapsed(offset: _lastText.length),
    );
  }

  String get html {
    final out = StringBuffer();
    var i = 0;
    while (i < _lastText.length) {
      final style = _styles[i];
      var j = i;
      while (j < _lastText.length && _styles[j] == style) {
        j++;
      }
      var run = _lastText.substring(i, j);
      if (style & RichFormat.bold != 0) run = '<b>$run</b>';
      if (style & RichFormat.italic != 0) run = '<i>$run</i>';
      if (style & RichFormat.underline != 0) run = '<u>$run</u>';
      if (style & RichFormat.red != 0) run = '<span style="color:red">$run</span>';
      out.write(run);
      i = j;
    }
    return out.toString();
  }

  @override
  set value(TextEditingValue newValue) {
    if (newValue.text != _lastText) {
      _reconcile(_lastText, newValue.text);
      _lastText = newValue.text;
    } else if (newValue.selection != value.selection) {
      _typingStyle = null;
    }
    super.value = newValue;
  }

  /// Keeps one style per character across an edit: removed text drops its
  /// styles, inserted text takes the style of the character before it.
  void _reconcile(String oldText, String newText) {
    var prefix = 0;
    final maxPrefix = oldText.length < newText.length ? oldText.length : newText.length;
    while (prefix < maxPrefix && oldText.codeUnitAt(prefix) == newText.codeUnitAt(prefix)) {
      prefix++;
    }
    var suffix = 0;
    while (suffix < oldText.length - prefix &&
        suffix < newText.length - prefix &&
        oldText.codeUnitAt(oldText.length - 1 - suffix) ==
            newText.codeUnitAt(newText.length - 1 - suffix)) {
      suffix++;
    }
    final inserted = newText.length - prefix - suffix;
    final after = oldText.length - suffix;
    final inherit = _typingStyle ??
        (prefix > 0
            ? _styles[prefix - 1]
            : (after < _styles.length ? _styles[after] : 0));
    _styles = [
      ..._styles.sublist(0, prefix),
      ...List.filled(inserted, inherit),
      ..._styles.sublist(oldText.length - suffix),
    ];
  }

  int _styleAtCursor() {
    final offset = selection.isValid ? selection.start : _lastText.length;
    return _typingStyle ?? (offset > 0 && offset <= _styles.length ? _styles[offset - 1] : 0);
  }

  /// Whether [flag] is on for the selection (or for typing at the cursor).
  bool isActive(int flag) {
    final sel = selection;
    if (!sel.isValid || sel.isCollapsed) return _styleAtCursor() & flag != 0;
    for (var i = sel.start; i < sel.end; i++) {
      if (_styles[i] & flag == 0) return false;
    }
    return true;
  }

  /// Turns [flag] on for the selection, or off if it is already on everywhere.
  /// With no selection, it applies to what is typed next.
  void toggle(int flag) {
    final sel = selection;
    if (!sel.isValid || sel.isCollapsed) {
      _typingStyle = _styleAtCursor() ^ flag;
      notifyListeners();
      return;
    }
    final on = !isActive(flag);
    for (var i = sel.start; i < sel.end; i++) {
      _styles[i] = on ? _styles[i] | flag : _styles[i] & ~flag;
    }
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final base = style ?? const TextStyle();
    final composing = withComposing && value.isComposingRangeValid ? value.composing : null;
    final children = <TextSpan>[];
    var i = 0;
    while (i < _lastText.length) {
      final s = _styles[i];
      final inComposing = composing != null && i >= composing.start && i < composing.end;
      var j = i + 1;
      while (j < _lastText.length &&
          _styles[j] == s &&
          (composing != null && j >= composing.start && j < composing.end) == inComposing) {
        j++;
      }
      final underline = s & RichFormat.underline != 0 || inComposing;
      children.add(TextSpan(
        text: _lastText.substring(i, j),
        style: base.copyWith(
          fontWeight: s & RichFormat.bold != 0 ? FontWeight.w800 : FontWeight.w400,
          fontStyle: s & RichFormat.italic != 0 ? FontStyle.italic : FontStyle.normal,
          decoration: underline ? TextDecoration.underline : TextDecoration.none,
          color: s & RichFormat.red != 0 ? Colors.red : null,
        ),
      ));
      i = j;
    }
    return TextSpan(style: base, children: children);
  }
}
