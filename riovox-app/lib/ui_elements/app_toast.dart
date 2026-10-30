import 'dart:async';

import 'package:flutter/material.dart';

import '../config/toast_config.dart';

class _ToastEntry {
  _ToastEntry({
    required this.id,
    required this.type,
    required this.content,
    this.actionLabel,
    this.onAction,
    this.showClose = false,
  });

  final int id;
  final ToastType type;
  final Widget content;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showClose;
  bool leaving = false;
  Timer? timer;
}

/// App-wide toast notifications, drawn by [AppToastHost] above every page,
/// bottom sheet and dialog (unlike SnackBars, which render under modals).
/// Timing, colours and placement come from [ToastConfig].
class AppToast extends ChangeNotifier {
  AppToast._();
  static final AppToast instance = AppToast._();

  final List<_ToastEntry> _entries = [];
  int _nextId = 0;

  static void info(String message) =>
      instance._show(ToastType.info, Text(message), message);
  static void success(String message) =>
      instance._show(ToastType.success, Text(message), message);
  static void warning(String message) =>
      instance._show(ToastType.warning, Text(message), message);
  static void error(String message) =>
      instance._show(ToastType.error, Text(message), message);

  /// Drop-in for `ScaffoldMessenger.of(context).showSnackBar(snackBar)`: keeps
  /// the SnackBar's content, action and close icon, infers the type from its
  /// text. [context] is accepted for call-site compatibility only.
  static void showSnackBar(BuildContext? context, SnackBar snackBar) {
    final text = _plainText(snackBar.content);
    instance._show(
      _inferType(text),
      snackBar.content,
      text,
      actionLabel: snackBar.action?.label,
      onAction: snackBar.action?.onPressed,
      showClose: snackBar.showCloseIcon ?? false,
    );
  }

  /// Removes every visible toast.
  static void dismissAll() {
    for (final entry in List.of(instance._entries)) {
      instance._dismiss(entry.id);
    }
  }

  List<_ToastEntry> get _visible => List.unmodifiable(_entries);

  static String _plainText(Widget content) {
    if (content is Text) {
      return content.data ?? content.textSpan?.toPlainText() ?? '';
    }
    return '';
  }

  static ToastType _inferType(String text) {
    if (ToastConfig.errorPattern.hasMatch(text)) return ToastType.error;
    if (ToastConfig.warningPattern.hasMatch(text)) return ToastType.warning;
    if (ToastConfig.successPattern.hasMatch(text)) return ToastType.success;
    return ToastType.info;
  }

  static Duration _durationFor(
    ToastType type,
    String text, {
    required bool hasAction,
  }) {
    final base = ToastConfig.styles[type]!.duration;
    final extraChars = (text.length - ToastConfig.readingFreeChars).clamp(
      0,
      10000,
    );
    var ms = base.inMilliseconds + extraChars * ToastConfig.extraMsPerChar;
    if (hasAction) {
      ms = ms < ToastConfig.minDurationWithAction.inMilliseconds
          ? ToastConfig.minDurationWithAction.inMilliseconds
          : ms;
    }
    return Duration(
      milliseconds: ms.clamp(0, ToastConfig.maxDuration.inMilliseconds),
    );
  }

  void _show(
    ToastType type,
    Widget content,
    String text, {
    String? actionLabel,
    VoidCallback? onAction,
    bool showClose = false,
  }) {
    // The same message again (e.g. a double tap) restarts its timer instead.
    for (final e in _entries) {
      if (!e.leaving && text.isNotEmpty && _plainText(e.content) == text) {
        e.timer?.cancel();
        e.timer = Timer(
          _durationFor(type, text, hasAction: actionLabel != null),
          () => _dismiss(e.id),
        );
        return;
      }
    }

    final entry = _ToastEntry(
      id: _nextId++,
      type: type,
      content: content,
      actionLabel: actionLabel,
      onAction: onAction,
      showClose: showClose || type == ToastType.error,
    );
    _entries.add(entry);
    while (_entries.where((e) => !e.leaving).length > ToastConfig.maxVisible) {
      _dismiss(_entries.firstWhere((e) => !e.leaving).id);
    }
    entry.timer = Timer(
      _durationFor(type, text, hasAction: actionLabel != null),
      () => _dismiss(entry.id),
    );
    notifyListeners();
  }

  void _dismiss(int id) {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index < 0 || _entries[index].leaving) return;
    final entry = _entries[index];
    entry.timer?.cancel();
    entry.leaving = true;
    notifyListeners();
    Timer(ToastConfig.animationDuration, () {
      _entries.removeWhere((e) => e.id == id);
      notifyListeners();
    });
  }
}

/// Paints [AppToast]s over [child]. Mounted once in `MaterialApp.builder`,
/// above the Navigator, so it carries its own [Overlay] for tooltips.
class AppToastHost extends StatefulWidget {
  const AppToastHost({super.key, required this.child});

  final Widget child;

  @override
  State<AppToastHost> createState() => _AppToastHostState();
}

class _AppToastHostState extends State<AppToastHost> {
  late final OverlayEntry _layer = OverlayEntry(
    builder: (context) => ListenableBuilder(
      listenable: AppToast.instance,
      builder: (context, _) {
        final entries = AppToast.instance._visible;
        if (entries.isEmpty) return const SizedBox.shrink();
        return _ToastLayer(entries: entries);
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(child: Overlay(initialEntries: [_layer])),
      ],
    );
  }
}

class _ToastLayer extends StatelessWidget {
  const _ToastLayer({required this.entries});

  final List<_ToastEntry> entries;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final wide = media.size.width >= ToastConfig.wideBreakpoint;
    final placement = wide
        ? ToastConfig.widePlacement
        : ToastConfig.mobilePlacement;
    final atTop =
        placement == ToastPlacement.top || placement == ToastPlacement.topRight;
    final atRight =
        placement == ToastPlacement.topRight ||
        placement == ToastPlacement.bottomRight;
    final m = ToastConfig.margin;
    final padding = media.padding;

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: atRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.center,
      children: [
        for (final entry in atTop ? entries : entries.reversed)
          Padding(
            padding: EdgeInsets.only(bottom: ToastConfig.spacing),
            child: _ToastCard(
              key: ValueKey(entry.id),
              entry: entry,
              fromTop: atTop,
              maxWidth: wide ? ToastConfig.maxWidth : double.infinity,
            ),
          ),
      ],
    );

    return Align(
      alignment: atTop
          ? (atRight ? Alignment.topRight : Alignment.topCenter)
          : (atRight ? Alignment.bottomRight : Alignment.bottomCenter),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          m.left + padding.left,
          m.top + padding.top,
          m.right + padding.right,
          m.bottom + padding.bottom + media.viewInsets.bottom,
        ),
        child: column,
      ),
    );
  }
}

class _ToastCard extends StatelessWidget {
  const _ToastCard({
    super.key,
    required this.entry,
    required this.fromTop,
    required this.maxWidth,
  });

  final _ToastEntry entry;
  final bool fromTop;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final style = ToastConfig.styles[entry.type]!;
    final visible = !entry.leaving;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: visible ? 1 : 0),
      duration: ToastConfig.animationDuration,
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * (fromTop ? -16 : 16)),
          child: child,
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Semantics(
          liveRegion: true,
          child: Material(
            color: style.background,
            elevation: ToastConfig.elevation,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ToastConfig.borderRadius),
              // A plain shadow doesn't separate the toast from an app bar of a
              // similar colour (e.g. the deep-teal success toast over the deep-teal
              // header), so give every toast a thin white edge to stay legible.
              side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: Padding(
              padding: ToastConfig.padding,
              child: Row(
                mainAxisSize: maxWidth == double.infinity
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                children: [
                  Icon(style.icon, color: style.foreground, size: 20),
                  const SizedBox(width: 10),
                  Flexible(
                    child: DefaultTextStyle.merge(
                      style: TextStyle(
                        color: style.foreground,
                        fontSize: ToastConfig.fontSize,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                      child: entry.content,
                    ),
                  ),
                  if (entry.actionLabel != null)
                    TextButton(
                      onPressed: () {
                        entry.onAction?.call();
                        AppToast.instance._dismiss(entry.id);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: style.foreground,
                        visualDensity: VisualDensity.compact,
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      child: Text(entry.actionLabel!),
                    ),
                  if (entry.showClose)
                    IconButton(
                      tooltip: 'Dismiss',
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: style.foreground,
                      ),
                      onPressed: () => AppToast.instance._dismiss(entry.id),
                    )
                  else
                    const SizedBox(width: 6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
