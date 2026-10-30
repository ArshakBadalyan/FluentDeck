import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:riovox/services/main_tab_config.dart';
import 'package:riovox/ui_elements/modern_page_widgets.dart';

/// Cards saved since the user last opened Decks; the Decks tab shows "+N".
class NewCardsBadge {
  NewCardsBadge._();

  static final ValueNotifier<int> count = ValueNotifier(0);

  static void add([int n = 1]) => count.value += n;

  static void clear() {
    if (count.value != 0) count.value = 0;
  }
}

/// A small card arcs from [from] down to where the Decks tab sits, then the
/// Decks badge counts it. With reduced motion it only counts.
void flyCardToDecks(BuildContext from) {
  final box = from.findRenderObject() as RenderBox?;
  final overlay = Overlay.maybeOf(from, rootOverlay: true);
  if (box == null || !box.attached || overlay == null || MediaQuery.disableAnimationsOf(from)) {
    NewCardsBadge.add();
    return;
  }
  final size = MediaQuery.sizeOf(from);
  final start = box.localToGlobal(box.size.center(Offset.zero));
  // The bottom bar is a row of equal tabs inside 16px + 6px padding.
  final index = MainTabConfig.indexOf(MainTabId.decks);
  final tabWidth = (size.width - 44) / MainTabConfig.tabCount;
  final end = Offset(22 + tabWidth * (index + 0.5), size.height - 44);
  final accent = AppPageColors.accentOf(from);
  final cardBg = AppPageColors.cardBgOf(from);

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _FlyingCard(
      start: start,
      end: end,
      accent: accent,
      cardBg: cardBg,
      onDone: () {
        entry.remove();
        NewCardsBadge.add();
      },
    ),
  );
  overlay.insert(entry);
}

class _FlyingCard extends StatefulWidget {
  const _FlyingCard({
    required this.start,
    required this.end,
    required this.accent,
    required this.cardBg,
    required this.onDone,
  });

  final Offset start;
  final Offset end;
  final Color accent;
  final Color cardBg;
  final VoidCallback onDone;

  @override
  State<_FlyingCard> createState() => _FlyingCardState();
}

class _FlyingCardState extends State<_FlyingCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  )..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final t = Curves.easeInOutCubic.transform(_c.value);
          // Quadratic curve: up first, then down to the tab.
          final control = Offset(
            (widget.start.dx + widget.end.dx) / 2,
            math.min(widget.start.dy, widget.end.dy) - 120,
          );
          final p = Offset(
            _bezier(widget.start.dx, control.dx, widget.end.dx, t),
            _bezier(widget.start.dy, control.dy, widget.end.dy, t),
          );
          final scale = 1 - 0.55 * t;
          return Positioned(
            left: p.dx - 22,
            top: p.dy - 15,
            child: Opacity(
              opacity: _c.value < 0.85 ? 1 : (1 - _c.value) / 0.15,
              child: Transform.rotate(
                angle: -0.35 * t,
                child: Transform.scale(scale: scale, child: child),
              ),
            ),
          );
        },
        child: Container(
          width: 44,
          height: 30,
          decoration: BoxDecoration(
            color: widget.cardBg,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: widget.accent, width: 1.5),
            boxShadow: [
              BoxShadow(color: widget.accent.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Icon(Icons.style_rounded, size: 16, color: widget.accent),
        ),
      ),
    );
  }

  static double _bezier(double a, double b, double c, double t) =>
      (1 - t) * (1 - t) * a + 2 * (1 - t) * t * b + t * t * c;
}

/// "+N" bubble on the Decks tab icon; springs in each time a card lands.
class NewCardsBadgeBubble extends StatelessWidget {
  const NewCardsBadgeBubble({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NewCardsBadge.count,
      child: child,
      builder: (context, n, child) => Stack(
        clipBehavior: Clip.none,
        children: [
          child!,
          if (n > 0)
            Positioned(
              right: -12,
              top: -8,
              child: TweenAnimationBuilder<double>(
                key: ValueKey(n), // re-bounce on every new card
                tween: Tween(begin: 0.3, end: 1),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 450),
                curve: Curves.elasticOut,
                builder: (context, s, child) => Transform.scale(scale: s, child: child),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppPageColors.tintOf(context, AppTint.voice).fg,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: AppPageColors.cardBgOf(context), width: 1.5),
                  ),
                  child: Text(
                    '+$n',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
