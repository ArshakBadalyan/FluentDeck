import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:riovox/app_colors.dart';
import 'package:riovox/widgets/cached_strapi_image.dart';
import 'package:riovox/models/occlusion_model.dart';
import 'package:riovox/ui_elements/modern_page_widgets.dart';

/// Draw occlusion masks on an image and edit regions (Phase 4I).
class ImageOcclusionEditor extends StatefulWidget {
  const ImageOcclusionEditor({
    super.key,
    required this.imageUrl,
    required this.regions,
    required this.onChanged,
  });

  final String imageUrl;
  final List<OcclusionRegion> regions;
  final ValueChanged<List<OcclusionRegion>> onChanged;

  @override
  State<ImageOcclusionEditor> createState() => _ImageOcclusionEditorState();
}

class _ImageOcclusionEditorState extends State<ImageOcclusionEditor> {
  Offset? _dragStart;
  Offset? _dragCurrent;
  int? _selectedId;
  Size _lastSize = Size.zero;

  void _updateRegions(List<OcclusionRegion> regions) {
    widget.onChanged(regions);
  }

  void _addRegion(Rect normRect, Size size) {
    if (normRect.width < 0.02 || normRect.height < 0.02) return;
    final nextId =
        widget.regions.isEmpty
            ? 1
            : widget.regions.map((r) => r.id).reduce((a, b) => a > b ? a : b) + 1;
    _updateRegions([
      ...widget.regions,
      OcclusionRegion(
        id: nextId,
        x: normRect.left,
        y: normRect.top,
        w: normRect.width,
        h: normRect.height,
      ),
    ]);
    setState(() => _selectedId = nextId);
  }

  void _deleteRegion(int id) {
    _updateRegions(widget.regions.where((r) => r.id != id).toList());
    if (_selectedId == id) setState(() => _selectedId = null);
  }

  Rect _normalizeRect(Offset a, Offset b, Size size) {
    final left = (a.dx < b.dx ? a.dx : b.dx) / size.width;
    final top = (a.dy < b.dy ? a.dy : b.dy) / size.height;
    final right = (a.dx > b.dx ? a.dx : b.dx) / size.width;
    final bottom = (a.dy > b.dy ? a.dy : b.dy) / size.height;
    return Rect.fromLTRB(
      left.clamp(0.0, 1.0),
      top.clamp(0.0, 1.0),
      right.clamp(0.0, 1.0),
      bottom.clamp(0.0, 1.0),
    );
  }

  Drag? _onDragStart(Offset position) {
    final box = context.findRenderObject() as RenderBox;
    final local = box.globalToLocal(position);
    setState(() {
      _dragStart = local;
      _dragCurrent = local;
    });
    return _MaskDrag(this);
  }

  void _handleDragUpdate(Offset globalPosition) {
    if (_dragStart == null) return;
    final box = context.findRenderObject() as RenderBox;
    setState(() => _dragCurrent = box.globalToLocal(globalPosition));
  }

  void _handleDragEnd() {
    if (_dragStart == null || _dragCurrent == null) return;
    final start = _dragStart!;
    final current = _dragCurrent!;
    final moved = (current - start).distance;
    if (moved < 6) {
      // Treated as a tap, not a drag — select a mask under it.
      for (final region in widget.regions.reversed) {
        final r = Rect.fromLTWH(
          region.x * _lastSize.width,
          region.y * _lastSize.height,
          region.w * _lastSize.width,
          region.h * _lastSize.height,
        );
        if (r.contains(current)) {
          setState(() {
            _selectedId = region.id;
            _dragStart = null;
            _dragCurrent = null;
          });
          return;
        }
      }
      setState(() => _selectedId = null);
    } else {
      final rect = _normalizeRect(start, current, _lastSize);
      _addRegion(rect, _lastSize);
    }
    setState(() {
      _dragStart = null;
      _dragCurrent = null;
    });
  }

  void _handleDragCancel() {
    setState(() {
      _dragStart = null;
      _dragCurrent = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl.trim().isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPageColors.fieldBgOf(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Enter an image URL above, then draw rectangles to hide regions.',
          style: TextStyle(color: AppPageColors.subtitleOf(context)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${widget.regions.length} mask${widget.regions.length == 1 ? '' : 's'}',
          style: TextStyle(fontSize: 13, color: AppPageColors.subtitleOf(context)),
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 4 / 3,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              _lastSize = size;
              // `Listener` (tried first) only *observes* pointer events —
              // it doesn't stop the ancestor SingleChildScrollView's own
              // drag recognizer from also claiming the gesture, so the page
              // kept scrolling instead of a mask being drawn.
              // ImmediateMultiDragGestureRecognizer actually competes in
              // the gesture arena and — true to its name — accepts
              // immediately on pointer-down rather than waiting to see if
              // the movement looks more horizontal/vertical, so it wins
              // against the scroll view's recognizer instead of losing the
              // tie-break to it.
              return RawGestureDetector(
                behavior: HitTestBehavior.opaque,
                gestures: {
                  ImmediateMultiDragGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                          ImmediateMultiDragGestureRecognizer>(
                    () => ImmediateMultiDragGestureRecognizer(),
                    (instance) => instance.onStart = _onDragStart,
                  ),
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedStrapiImage(
                        url: widget.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context) => Container(
                          color: AppPageColors.fieldBgOf(context),
                          alignment: Alignment.center,
                          child: const Text('Could not load image'),
                        ),
                      ),
                      ...widget.regions.map((region) {
                        final selected = region.id == _selectedId;
                        return Positioned(
                          left: region.x * size.width,
                          top: region.y * size.height,
                          width: region.w * size.width,
                          height: region.h * size.height,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.brandPrimary.withValues(
                                alpha: selected ? 0.55 : 0.35,
                              ),
                              border: Border.all(
                                color:
                                    selected
                                        ? AppColors.primaryYellow
                                        : Colors.white,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                region.label.isNotEmpty ? region.label : '${region.id}',
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      if (_dragStart != null && _dragCurrent != null)
                        Positioned.fromRect(
                          rect: Rect.fromPoints(_dragStart!, _dragCurrent!),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.primaryYellow, width: 2),
                              color: AppColors.brandPrimary.withValues(alpha: 0.25),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Drag on the image to add a mask. Tap a mask to select it.',
          style: TextStyle(fontSize: 12, color: AppPageColors.subtitleOf(context)),
        ),
        // Label + delete for each mask lives here, outside the canvas —
        // putting interactive buttons directly on the masks would compete
        // with ImmediateMultiDragGestureRecognizer above (it claims a
        // pointer-down immediately, before a nested button's own tap
        // recognizer gets a chance to decide anything), so taps there could
        // silently start a new mask-drag instead of registering as a tap.
        // This also means every mask always has a working delete button
        // regardless of canvas-selection state, instead of one shared
        // button that only appears for whichever mask happens to be
        // selected.
        // Labels for each mask are edited in the "Mask labels" section
        // below this widget (card_edit_screen.dart already has one editor
        // per region there) — duplicating that here would mean two
        // controllers independently fighting over the same `label` field.
        // This row is just a tappable badge (highlights the mask on the
        // canvas) plus its delete button.
        if (widget.regions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.regions.map((region) {
              final selected = region.id == _selectedId;
              return InputChip(
                avatar: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: Text(
                    '${region.id}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                label: Text(
                  region.label.isNotEmpty ? region.label : 'Mask ${region.id}',
                ),
                selected: selected,
                onPressed: () => setState(
                  () => _selectedId = selected ? null : region.id,
                ),
                onDeleted: () => _deleteRegion(region.id),
                deleteIconColor: AppColors.redWrong,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

/// Hands pointer-move/up/cancel for one in-progress drag back to the state
/// that started it — required by [ImmediateMultiDragGestureRecognizer],
/// which (unlike GestureDetector's onPan*) hands off an actual [Drag]
/// object per gesture instead of just invoking callbacks.
class _MaskDrag extends Drag {
  _MaskDrag(this._state);

  final _ImageOcclusionEditorState _state;

  @override
  void update(DragUpdateDetails details) {
    _state._handleDragUpdate(details.globalPosition);
  }

  @override
  void end(DragEndDetails details) {
    _state._handleDragEnd();
  }

  @override
  void cancel() {
    _state._handleDragCancel();
  }
}

