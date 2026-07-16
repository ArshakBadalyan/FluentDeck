import 'dart:async';

import 'package:flutter/material.dart';

/// Wraps a [TabBarView] so horizontal swipes at the first/last sub-tab
/// navigate to the adjacent main bottom-nav tab.
class HandoffTabBarView extends StatefulWidget {
  const HandoffTabBarView({
    super.key,
    required this.controller,
    required this.children,
    this.onHandoffPrevious,
    this.onHandoffNext,
    this.physics,
  });

  final TabController controller;
  final List<Widget> children;
  final Future<void> Function()? onHandoffPrevious;
  final Future<void> Function()? onHandoffNext;
  final ScrollPhysics? physics;

  @override
  State<HandoffTabBarView> createState() => _HandoffTabBarViewState();
}

class _HandoffTabBarViewState extends State<HandoffTabBarView> {
  static const _minDragDistance = 56.0;

  int? _dragStartTabIndex;
  double _dragTotal = 0;
  bool _handoffInProgress = false;
  Timer? _handoffResetTimer;

  @override
  void dispose() {
    _handoffResetTimer?.cancel();
    super.dispose();
  }

  bool get _atFirstTab => widget.controller.index == 0;

  bool get _atLastTab =>
      widget.controller.index >= widget.controller.length - 1;

  Future<void> _triggerHandoff(Future<void> Function()? callback) async {
    if (_handoffInProgress || callback == null) return;
    _handoffInProgress = true;
    _handoffResetTimer?.cancel();
    _handoffResetTimer = Timer(const Duration(milliseconds: 500), () {
      _handoffInProgress = false;
    });
    await callback();
  }

  void _resetDrag() {
    _dragStartTabIndex = null;
    _dragTotal = 0;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<OverscrollNotification>(
      onNotification: (notification) {
        if (_handoffInProgress) return false;
        if (notification.overscroll < 0 && _atFirstTab) {
          unawaited(_triggerHandoff(widget.onHandoffPrevious));
          return true;
        }
        if (notification.overscroll > 0 && _atLastTab) {
          unawaited(_triggerHandoff(widget.onHandoffNext));
          return true;
        }
        return false;
      },
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          _dragStartTabIndex = widget.controller.index;
          _dragTotal = 0;
        },
        onPointerMove: (event) {
          if (_dragStartTabIndex == null) return;
          _dragTotal += event.delta.dx;
        },
        onPointerUp: (_) async {
          if (_dragStartTabIndex == null) return;
          if (widget.controller.index != _dragStartTabIndex) {
            _resetDrag();
            return;
          }

          final total = _dragTotal;
          _resetDrag();

          if (_atFirstTab && total > _minDragDistance) {
            await _triggerHandoff(widget.onHandoffPrevious);
          } else if (_atLastTab && total < -_minDragDistance) {
            await _triggerHandoff(widget.onHandoffNext);
          }
        },
        onPointerCancel: (_) => _resetDrag(),
        child: TabBarView(
          controller: widget.controller,
          physics: widget.physics ?? const BouncingScrollPhysics(),
          children: widget.children,
        ),
      ),
    );
  }
}

/// Callbacks for handing off horizontal swipes to the main tab [PageView].
class MainTabHandoff {
  const MainTabHandoff({this.onPrevious, this.onNext});

  final Future<void> Function()? onPrevious;
  final Future<void> Function()? onNext;
}
