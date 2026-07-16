import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/ui_elements/frosted_bottom_sheet.dart';
import 'package:fluentdeck/models/flashcard_model.dart';
import 'package:fluentdeck/utils/html_text_utils.dart';
import 'package:fluentdeck/utils/type_answer_utils.dart';

/// Preview a study card from the browser (Phase 4D).
class CardPreviewSheet extends StatefulWidget {
  const CardPreviewSheet({super.key, required this.card});

  final FlashcardModel card;

  static Future<void> show(BuildContext context, FlashcardModel card) {
    return showFrostedBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CardPreviewSheet(card: card),
    );
  }

  @override
  State<CardPreviewSheet> createState() => _CardPreviewSheetState();
}

class _CardPreviewSheetState extends State<CardPreviewSheet> {
  bool _revealed = false;

  String get _frontHtml {
    if (widget.card.cardType == 'type_answer') {
      return typeAnswerQuestionHtml(widget.card.front);
    }
    if (widget.card.cardType == 'cloze' && widget.card.clozeText?.isNotEmpty == true) {
      return widget.card.clozeText!;
    }
    return widget.card.front;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.card.deckName ?? 'Card preview',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Text(
              [
                widget.card.templateName,
                widget.card.cardType,
                widget.card.reviewState?.state ?? 'new',
              ].join(' · '),
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
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
                  html: _revealed ? widget.card.back : _frontHtml,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.35),
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
          ],
        ),
      ),
    );
  }
}
