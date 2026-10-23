import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../models/flashcard_model.dart';
import '../ui_elements/modern_page_widgets.dart';
import '../widgets/cached_strapi_image.dart';
import 'html_text_utils.dart';

/// Sort + filter helpers for the card browser (Phase 4D).
enum CardBrowserSortField { front, due, deck, type, state }

enum CardBrowserSortDir { asc, desc }

List<FlashcardModel> sortBrowserCards(
  List<FlashcardModel> cards,
  CardBrowserSortField? field,
  CardBrowserSortDir? dir,
) {
  if (field == null || dir == null) return List<FlashcardModel>.from(cards);

  final sorted = List<FlashcardModel>.from(cards);
  int compare(FlashcardModel a, FlashcardModel b) {
    switch (field) {
      case CardBrowserSortField.front:
        return stripHtml(a.displayFront).toLowerCase().compareTo(
          stripHtml(b.displayFront).toLowerCase(),
        );
      case CardBrowserSortField.due:
        final ad = a.reviewState?.dueAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.reviewState?.dueAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return ad.compareTo(bd);
      case CardBrowserSortField.deck:
        return (a.deckName ?? '').toLowerCase().compareTo((b.deckName ?? '').toLowerCase());
      case CardBrowserSortField.type:
        return a.cardType.compareTo(b.cardType);
      case CardBrowserSortField.state:
        return cardStateLabel(a).compareTo(cardStateLabel(b));
    }
  }

  sorted.sort((a, b) {
    final c = compare(a, b);
    return dir == CardBrowserSortDir.asc ? c : -c;
  });
  return sorted;
}

String formatDueLabel(FlashcardModel card) {
  final rs = card.reviewState;
  if (rs == null) return 'new';
  if (rs.suspended) return 'suspended';
  if (rs.buriedUntil != null && rs.buriedUntil!.isAfter(DateTime.now())) {
    return 'buried';
  }
  if (rs.dueAt != null) {
    final now = DateTime.now();
    final diff = rs.dueAt!.difference(now);
    if (diff.isNegative) return 'due';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return _shortDueDate(rs.dueAt!.toLocal());
  }
  if (rs.state == 'new') return 'new';
  return rs.state;
}

/// SM-2 state only — unlike [formatDueLabel] this never returns a due
/// countdown, so "Learning"/"Review" stay visible even once a card has a
/// scheduled due time.
String cardStateLabel(FlashcardModel card) {
  final rs = card.reviewState;
  if (rs == null) return 'New';
  if (rs.suspended) return 'Suspended';
  if (rs.buriedUntil != null && rs.buriedUntil!.isAfter(DateTime.now())) {
    return 'Buried';
  }
  switch (rs.state) {
    case 'learning':
      return 'Learning';
    case 'relearning':
      return 'Relearning';
    case 'review':
      return 'Review';
    default:
      return 'New';
  }
}

bool cardHasScheduledDue(FlashcardModel card) {
  final dueAt = card.reviewState?.dueAt;
  if (dueAt == null) return false;
  if (card.reviewState?.suspended == true) return false;
  if (card.reviewState?.buriedUntil != null &&
      card.reviewState!.buriedUntil!.isAfter(DateTime.now())) {
    return false;
  }
  return true;
}

String _shortDueDate(DateTime local) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return '${months[local.month - 1]} ${local.day}, $h:$m';
}

String formatDueDateTime(DateTime dueAt) {
  final local = dueAt.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} $h:$m';
}

/// Due column cell with optional schedule icon when a custom due date is set.
class CardDueLabel extends StatelessWidget {
  const CardDueLabel({super.key, required this.card, this.width = 40});

  final FlashcardModel card;
  final double width;

  @override
  Widget build(BuildContext context) {
    final scheduled = cardHasScheduledDue(card);
    final label = formatDueLabel(card);
    final textStyle = TextStyle(
      fontSize: 11,
      color: scheduled ? AppPageColors.accentOf(context) : AppPageColors.subtitleOf(context),
      fontWeight: scheduled ? FontWeight.w600 : FontWeight.w400,
    );

    return SizedBox(
      width: width,
      child: scheduled
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                  message: 'Due ${formatDueDateTime(card.reviewState!.dueAt!)}',
                  child: Icon(
                    Icons.event_available_rounded,
                    size: 13,
                    color: AppColors.brandPrimary.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle,
                  ),
                ),
              ],
            )
          : Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
    );
  }
}

String cardTypeLabel(String cardType) {
  switch (cardType) {
    case 'cloze':
      return 'Cloze';
    // "reversed" is the second (back → front) card generated by either
    // "Basic (and reversed card)" or "Basic (optional reversed card)" —
    // spelling it out here makes that relationship clear in the list
    // instead of a bare "Reversed" that reads as an unrelated type.
    case 'reversed':
      return 'Basic (reversed)';
    case 'type_answer':
      return 'Basic (type answer)';
    case 'image_occlusion':
      return 'Image Occlusion';
    default:
      return 'Basic';
  }
}

/// Readable text for the Question column — for every other card type this
/// is just the front text, but an Image Occlusion card's `front` is the
/// raw image URL (that's what the review screen loads to render the
/// photo), which is meaningless as a list label. Falls back through the
/// mask's own label, then a generic "Mask N", rather than ever showing
/// the URL.
String cardQuestionLabel(FlashcardModel card) {
  if (card.isImageOcclusion) {
    final region = card.occlusionData?.activeRegion;
    if (region != null && region.label.isNotEmpty) return region.label;
    if (region != null) return 'Mask ${region.id}';
    return 'Image Occlusion';
  }
  return stripHtml(card.displayFront);
}

/// Question column content — a small image thumbnail plus
/// [cardQuestionLabel] for Image Occlusion cards (so the raw URL is never
/// shown and the row is recognizable at a glance), plain text otherwise.
class QuestionCell extends StatelessWidget {
  const QuestionCell({
    super.key,
    required this.card,
    this.fontSize = 13,
    this.fontWeight,
    this.maxLines = 1,
  });

  final FlashcardModel card;
  final double fontSize;
  final FontWeight? fontWeight;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final label = cardQuestionLabel(card);
    final style = TextStyle(fontSize: fontSize, fontWeight: fontWeight);

    if (!card.isImageOcclusion) {
      return Text(label, maxLines: maxLines, overflow: TextOverflow.ellipsis, style: style);
    }

    final thumbSize = fontSize + 18;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: CachedStrapiImage(
            url: card.front,
            width: thumbSize,
            height: thumbSize,
            fit: BoxFit.cover,
            placeholderColor: AppPageColors.fieldBgOf(context),
            errorBuilder: (context) => Container(
              width: thumbSize,
              height: thumbSize,
              color: AppPageColors.fieldBgOf(context),
              alignment: Alignment.center,
              child: Icon(
                Icons.image_outlined,
                size: thumbSize * 0.6,
                color: AppPageColors.subtitleOf(context),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, maxLines: maxLines, overflow: TextOverflow.ellipsis, style: style),
        ),
      ],
    );
  }
}

/// Flag colors (1–7). 0 = none.
const Map<int, Color> flagColors = {
  1: Color(0xFFE53935),
  2: Color(0xFFFB8C00),
  3: Color(0xFF43A047),
  4: Color(0xFF1E88E5),
  5: Color(0xFFD81B60),
  6: Color(0xFF00ACC1),
  7: Color(0xFF8E24AA),
};

Color? flagColorFor(int flag) => flagColors[flag];
