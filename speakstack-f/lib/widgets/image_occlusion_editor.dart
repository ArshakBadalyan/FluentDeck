import 'package:flutter/material.dart';
import 'package:untitled2/app_colors.dart';
import 'package:untitled2/models/occlusion_model.dart';

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

  void _deleteSelected() {
    if (_selectedId == null) return;
    _updateRegions(widget.regions.where((r) => r.id != _selectedId).toList());
    setState(() => _selectedId = null);
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

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl.trim().isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Enter an image URL above, then draw rectangles to hide regions.',
          style: TextStyle(color: Colors.grey.shade700),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              '${widget.regions.length} mask${widget.regions.length == 1 ? '' : 's'}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const Spacer(),
            if (_selectedId != null)
              TextButton.icon(
                onPressed: _deleteSelected,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete mask'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 4 / 3,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
                onPanStart: (d) => setState(() {
                  _dragStart = d.localPosition;
                  _dragCurrent = d.localPosition;
                }),
                onPanUpdate: (d) => setState(() => _dragCurrent = d.localPosition),
                onPanEnd: (_) {
                  if (_dragStart != null && _dragCurrent != null) {
                    final rect = _normalizeRect(_dragStart!, _dragCurrent!, size);
                    _addRegion(rect, size);
                  }
                  setState(() {
                    _dragStart = null;
                    _dragCurrent = null;
                  });
                },
                onTapUp: (d) {
                  for (final region in widget.regions.reversed) {
                    final r = Rect.fromLTWH(
                      region.x * size.width,
                      region.y * size.height,
                      region.w * size.width,
                      region.h * size.height,
                    );
                    if (r.contains(d.localPosition)) {
                      setState(() => _selectedId = region.id);
                      return;
                    }
                  }
                  setState(() => _selectedId = null);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        widget.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder:
                            (_, __, ___) => Container(
                              color: const Color(0xFFF2F2F5),
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
                              color: AppColors.primaryPurple.withValues(
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
                                '${region.id}',
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
                              color: AppColors.primaryPurple.withValues(alpha: 0.25),
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
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
