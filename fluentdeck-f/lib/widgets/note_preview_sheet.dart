import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/ui_elements/frosted_bottom_sheet.dart';
import 'package:fluentdeck/utils/html_text_utils.dart';

/// Modal preview of note fields as they would appear in review.
class NotePreviewSheet extends StatefulWidget {
  const NotePreviewSheet({
    super.key,
    required this.noteType,
    required this.fields,
    this.mediaUrl,
  });

  final String noteType;
  final Map<String, String> fields;
  final String? mediaUrl;

  static Future<void> show(
    BuildContext context, {
    required String noteType,
    required Map<String, String> fields,
    String? mediaUrl,
  }) {
    return showFrostedBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => NotePreviewSheet(
            noteType: noteType,
            fields: fields,
            mediaUrl: mediaUrl,
          ),
    );
  }

  @override
  State<NotePreviewSheet> createState() => _NotePreviewSheetState();
}

class _NotePreviewSheetState extends State<NotePreviewSheet> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final isCloze = widget.noteType == 'cloze';
    final text = widget.fields['Text'] ?? widget.fields['text'] ?? '';
    final front = isCloze ? renderClozePreviewFront(text) : (widget.fields['Front'] ?? '');
    final back =
        isCloze
            ? renderClozePreviewBack(text)
            : (widget.fields['Back'] ?? '');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text(
                  'Preview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            if (widget.mediaUrl != null && widget.mediaUrl!.trim().isNotEmpty) ...[
              Text('Media: ${widget.mediaUrl}', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 8),
            ],
            GestureDetector(
              onTap: () => setState(() => _revealed = !_revealed),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.2)),
                ),
                child: BasicHtmlText(
                  html: _revealed ? back : front,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _revealed ? 'Tap to hide answer' : 'Tap to reveal answer',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            if (widget.noteType == 'basic_type_answer' && !_revealed) ...[
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Type your answer…',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
