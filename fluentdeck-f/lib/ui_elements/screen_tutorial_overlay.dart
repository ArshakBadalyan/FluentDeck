import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/localization/app_localizations.dart';
import 'package:fluentdeck/services/screen_tutorial_segments.dart';
import 'package:fluentdeck/services/screen_tutorial_service.dart';
import 'package:fluentdeck/services/user_session.dart';
import 'package:fluentdeck/ui_elements/screen_tutorial_targets.dart';

/// Air between spotlight edge and arrow tip ([_PointerGlyph]); all steps share this.
const double _kCoachArrowTipGap = 14;
const double _kCoachArrowIconSize = 22;

/// Full-screen coach-mark flow: spotlight, tool-card, link-style navigation.
abstract final class ScreenTutorialOverlay {
  static bool _showing = false;

  static bool get isShowing => _showing;

  static Future<void> show(
    BuildContext context, {
    required String tutorialId,
    bool force = false,
    List<ScreenTutorialStep>? stepsOverride,
  }) async {
    if (_showing) return;
    if (await UserSession.instance.hideScreenExplanation) return;
    if (!force && await ScreenTutorialService.instance.isComplete(tutorialId)) {
      return;
    }
    if (!context.mounted) return;

    final steps =
        stepsOverride ?? ScreenTutorialCatalog.stepsFor(tutorialId);
    if (steps.isEmpty) return;

    await _present(
      context,
      steps: steps,
      markTutorialIdOnFinish: tutorialId,
      markTutorialIdOnSkip: tutorialId,
      segmentId: null,
    );
  }

  /// Replay a single spotlight segment from the picker sheet; does not persist.
  static Future<void> showSegment(
    BuildContext context, {
    required String segmentId,
  }) async {
    final steps = ScreenTutorialSegmentCatalog.stepsFor(segmentId);
    if (steps.isEmpty || _showing) return;
    if (await UserSession.instance.hideScreenExplanation) return;
    if (!context.mounted) return;

    await _present(
      context,
      steps: steps,
      markTutorialIdOnFinish: null,
      markTutorialIdOnSkip: null,
      segmentId: segmentId,
    );
  }

  static Future<void> _present(
    BuildContext context, {
    required List<ScreenTutorialStep> steps,
    required String? markTutorialIdOnFinish,
    required String? markTutorialIdOnSkip,
    String? segmentId,
  }) async {
    final overlay = Overlay.of(context, rootOverlay: true);
    _showing = true;

    final done = Completer<void>();
    late OverlayEntry entry;

    void requestClose() {
      entry.remove();
      if (!done.isCompleted) done.complete();
      _showing = false;
    }

    entry = OverlayEntry(
      builder: (overlayContext) {
        return _CoachMarkHost(
          steps: steps,
          markTutorialIdOnFinish: markTutorialIdOnFinish,
          markTutorialIdOnSkip: markTutorialIdOnSkip,
          segmentId: segmentId,
          requestClose: requestClose,
        );
      },
    );

    overlay.insert(entry);
    await done.future;
  }
}

Rect _clampedInflatedHoleRect(Rect raw, Size viewport) {
  final r = raw.inflate(_CoachMarkDims.holeBleedPx);
  return Rect.fromLTRB(
    r.left.clamp(0.0, viewport.width),
    r.top.clamp(0.0, viewport.height),
    r.right.clamp(0.0, viewport.width),
    r.bottom.clamp(0.0, viewport.height),
  );
}

double _effectiveSpotlightCornerRadius(Rect hole) {
  if (hole.width <= 0 || hole.height <= 0) return 0;
  return math.min(
    _CoachMarkDims.holeCornerRadius,
    math.min(hole.width, hole.height) / 2,
  );
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({required this.holeRect, required this.scrimOpacity});

  final Rect? holeRect;
  final double scrimOpacity;

  /// Dim everything except a **rounded** spotlight cut-out (same geometry as
  /// the purple ring) so square scrim corners never leave white wedges.
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.black.withValues(alpha: scrimOpacity)
          ..isAntiAlias = true;

    if (holeRect == null) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      return;
    }

    final hole = _clampedInflatedHoleRect(holeRect!, size);
    if (hole.width <= 0 || hole.height <= 0) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      return;
    }

    final rr = RRect.fromRectAndRadius(
      hole,
      Radius.circular(_effectiveSpotlightCornerRadius(hole)),
    );

    // Offscreen layer + BlendMode.clear: true transparency in the cut-out so
    // the underlying widget stays at full luminance (Path.combine can leave a
    // smoky tint over the hole on Flutter web / HTML renderer).
    final bounds = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.saveLayer(bounds, Paint());
    canvas.drawRect(bounds, paint);
    final clearPaint = Paint()..blendMode = BlendMode.clear;
    canvas.drawRRect(rr, clearPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.holeRect != holeRect ||
      oldDelegate.scrimOpacity != scrimOpacity;
}

/// Crisp purple outline — fixed stroke (no pulse: pulsing thickness looked like an
/// “expanding” border and smeared on web/Skia).
class _SpotlightHoleFrame extends StatelessWidget {
  const _SpotlightHoleFrame({required this.rawHoleRect});

  final Rect rawHoleRect;

  @override
  Widget build(BuildContext context) {
    final vp = MediaQuery.sizeOf(context);
    final hole = _clampedInflatedHoleRect(rawHoleRect, vp);
    if (hole.width <= 0 || hole.height <= 0) {
      return const SizedBox.shrink();
    }
    final corner = _effectiveSpotlightCornerRadius(hole);
    return Positioned(
      left: hole.left,
      top: hole.top,
      width: hole.width,
      height: hole.height,
      child: IgnorePointer(
        child: CustomPaint(
          painter: _SpotlightRingPainter(
            rrect: RRect.fromRectAndRadius(
              Rect.fromLTWH(0, 0, hole.width, hole.height),
              Radius.circular(corner),
            ),
            color: AppColors.primaryPurple.withValues(alpha: 0.9),
            strokeWidth: _CoachMarkDims.ringStrokePx,
          ),
        ),
      ),
    );
  }
}

abstract final class _CoachMarkDims {
  static const double holeBleedPx = 4;
  static const double holeCornerRadius = 15;
  /// Hairline-ish ring; avoids [BoxDecoration.border] softness at corners on HTML.
  static const double ringStrokePx = 2;
}

class _SpotlightRingPainter extends CustomPainter {
  _SpotlightRingPainter({
    required this.rrect,
    required this.color,
    required this.strokeWidth,
  });

  final RRect rrect;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final ring =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..isAntiAlias = true;
    canvas.drawRRect(rrect, ring);
  }

  @override
  bool shouldRepaint(covariant _SpotlightRingPainter oldDelegate) =>
      oldDelegate.rrect != rrect ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}

class _CardPlacement {
  const _CardPlacement({required this.top, required this.bottom});

  final double? top;
  final double? bottom;
}

class _CoachMarkHost extends StatefulWidget {
  const _CoachMarkHost({
    required this.steps,
    required this.markTutorialIdOnFinish,
    required this.markTutorialIdOnSkip,
    required this.segmentId,
    required this.requestClose,
  });

  final List<ScreenTutorialStep> steps;
  final String? markTutorialIdOnFinish;
  final String? markTutorialIdOnSkip;
  final String? segmentId;
  final VoidCallback requestClose;

  @override
  State<_CoachMarkHost> createState() => _CoachMarkHostState();
}

class _CoachMarkHostState extends State<_CoachMarkHost> {
  int _stepIndex = 0;
  Rect? _hole;

  ScreenTutorialStep get _step => widget.steps[_stepIndex];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyRemixCoachUiIfNeeded();
      _scheduleMeasure();
    });
  }

  void _notifyRemixCoachUiIfNeeded() {}

  void _scheduleMeasure() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ScreenTutorialKeys.ensureTargetScrollVisible(_step.targetId);
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _resolveHole(retries: 0);
      });
    });
  }

  void _resolveHole({required int retries}) {
    final id = _step.targetId;
    Rect? hole;
    if (id != null && id.isNotEmpty) {
      hole = ScreenTutorialKeys.spotlightRectFromId(id);
    }
    if (hole == null &&
        retries < 32 &&
        id != null &&
        id.isNotEmpty &&
        mounted) {
      Future<void>.delayed(const Duration(milliseconds: 42), () {
        if (!mounted) return;
        _resolveHole(retries: retries + 1);
      });
    }
    final changed = !_rectSame(_hole, hole);
    if (changed && mounted) setState(() => _hole = hole);
  }

  bool _rectSame(Rect? a, Rect? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return (a.left - b.left).abs() < 0.5 &&
        (a.top - b.top).abs() < 0.5 &&
        (a.width - b.width).abs() < 0.5 &&
        (a.height - b.height).abs() < 0.5;
  }

  /// Keeps the tool card away from the spotlight so it doesn’t hide the target.
  _CardPlacement _pickCardPlacement(Rect? hole, MediaQueryData mq) {
    final double safeTop = mq.padding.top + 8;
    final double safeBottom = mq.padding.bottom + 12;
    final double h = mq.size.height;
    final double w = mq.size.width;

    if (hole == null) {
      return _CardPlacement(top: null, bottom: safeBottom + h * 0.12);
    }

    const double estCardHeight = 380;
    const double sideInset = 20;
    const double gap = 22;
    final double cardTop = safeTop + 8;
    final double bottomInset = safeBottom + 12;
    final double cardBottomAnchorTop = h - bottomInset - estCardHeight;

    final Rect expandedHole = hole.inflate(gap);
    bool overlapsBand(double bandTop, double bandBottom) {
      final Rect band = Rect.fromLTRB(
        sideInset,
        bandTop,
        w - sideInset,
        bandBottom,
      );
      return band.overlaps(expandedHole);
    }

    final bool topBad = overlapsBand(cardTop, cardTop + estCardHeight);
    final bool bottomBad = overlapsBand(cardBottomAnchorTop, h - bottomInset);

    if (!topBad && bottomBad) {
      return _CardPlacement(top: cardTop, bottom: null);
    }
    if (topBad && !bottomBad) {
      return _CardPlacement(top: null, bottom: bottomInset);
    }
    if (!topBad && !bottomBad) {
      final double midY = (mq.padding.top + (h - mq.padding.bottom)) / 2;
      if (hole.center.dy > midY) {
        return _CardPlacement(top: cardTop, bottom: null);
      }
      return _CardPlacement(top: null, bottom: bottomInset);
    }
    final double topMid = cardTop + estCardHeight / 2;
    final double botMid = cardBottomAnchorTop + estCardHeight / 2;
    final double dTop = (topMid - hole.center.dy).abs();
    final double dBot = (botMid - hole.center.dy).abs();
    return dTop >= dBot
        ? _CardPlacement(top: cardTop, bottom: null)
        : _CardPlacement(top: null, bottom: bottomInset);
  }

  Future<void> _finish() async {
    final id = widget.markTutorialIdOnFinish;
    if (id != null) {
      await ScreenTutorialService.instance.markComplete(id);
    }
    widget.requestClose();
  }

  Future<void> _skip() async {
    final id = widget.markTutorialIdOnSkip;
    if (id != null) {
      await ScreenTutorialService.instance.markComplete(id);
    }
    widget.requestClose();
  }

  void _next() {
    if (_stepIndex < widget.steps.length - 1) {
      setState(() => _stepIndex++);
      _scheduleMeasure();
    } else {
      unawaited(_finish());
    }
  }

  void _back() {
    if (_stepIndex > 0) {
      setState(() => _stepIndex--);
      _scheduleMeasure();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final total = widget.steps.length;
    final stepNo = _stepIndex + 1;
    final last = _stepIndex >= total - 1;

    final card = _toolCard(
      context: context,
      last: last,
      stepNo: stepNo,
      total: total,
    );

    return Semantics(
      container: true,
      liveRegion: true,
      label:
          '${context.tr(_step.titleKey, vars: _step.titleVars)} — ${context.tr('screen-tutorial.common.step_counter', vars: {'current': '$stepNo', 'total': '$total'})}',
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _SpotlightPainter(holeRect: _hole, scrimOpacity: 0.58),
              ),
            ),
            if (_hole != null) _SpotlightHoleFrame(rawHoleRect: _hole!),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {},
                child: const SizedBox.expand(),
              ),
            ),
            Builder(
              builder: (_) {
                final placement = _pickCardPlacement(_hole, mq);
                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  left: 20,
                  right: 20,
                  top: placement.top,
                  bottom: placement.bottom,
                  child: GestureDetector(
                    onHorizontalDragEnd: (d) {
                      final v = d.primaryVelocity ?? 0;
                      if (v < -180) _next();
                      if (v > 180) _back();
                    },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: KeyedSubtree(
                        key: ValueKey(_stepIndex),
                        child: card,
                      ),
                    ),
                  ),
                );
              },
            ),
            if (_hole != null)
              _PointerGlyph(hole: _hole!, mqPadding: mq.padding),
          ],
        ),
      ),
    );
  }

  Widget _toolCard({
    required BuildContext context,
    required bool last,
    required int stepNo,
    required int total,
  }) {
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: 18,
      height: 1.22,
    );
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      height: 1.38,
      color: Colors.black87,
      fontSize: 15,
    );

    final counter = context.tr(
      'screen-tutorial.common.step_counter',
      vars: {'current': '$stepNo', 'total': '$total'},
    );

    Widget tourLink({required String label, required VoidCallback? onPressed}) {
      if (onPressed == null) return const SizedBox.shrink();
      final textStyle = TextStyle(
        color: AppColors.primaryPurple,
        fontWeight: FontWeight.w600,
        fontSize: 15,
        decoration: TextDecoration.none,
      );
      return Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Text(label, style: textStyle),
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 380),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            counter,
            style: const TextStyle(fontSize: 12, color: Colors.black45),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(_step.titleKey, vars: _step.titleVars),
                    style: titleStyle,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    context.tr(_step.bodyKey, vars: _step.bodyVars),
                    style: bodyStyle,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(total, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _stepIndex == i ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color:
                      _stepIndex == i
                          ? AppColors.primaryPurple
                          : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child:
                      _stepIndex > 0
                          ? tourLink(
                            label: context.tr('screen-tutorial.common.back'),
                            onPressed: _back,
                          )
                          : const SizedBox.shrink(),
                ),
              ),
              Expanded(
                child: Center(
                  child: tourLink(
                    label: context.tr('screen-tutorial.common.skip'),
                    onPressed: () => unawaited(_skip()),
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: tourLink(
                    label:
                        last
                            ? context.tr('screen-tutorial.common.done')
                            : context.tr('screen-tutorial.common.next'),
                    onPressed: last ? () => unawaited(_finish()) : _next,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PointerGlyph extends StatelessWidget {
  const _PointerGlyph({required this.hole, required this.mqPadding});

  final Rect hole;
  final EdgeInsets mqPadding;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final centerX = hole.center.dx;
    final placeAbove = hole.center.dy > screen.height * 0.55;
    // Global [hole]; place icon so glyph tip stays off the cut-out edge.
    final rawTop =
        placeAbove
            ? hole.top - _kCoachArrowTipGap - _kCoachArrowIconSize
            : hole.bottom + _kCoachArrowTipGap;
    final top = rawTop.clamp(mqPadding.top + 6, screen.height - 120);
    return Positioned(
      left:
          (centerX - _kCoachArrowIconSize / 2).clamp(
            12.0,
            screen.width - _kCoachArrowIconSize - 12,
          ),
      top: top,
      child: Icon(
        placeAbove ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
        color: Colors.white,
        size: _kCoachArrowIconSize,
      ),
    );
  }
}
