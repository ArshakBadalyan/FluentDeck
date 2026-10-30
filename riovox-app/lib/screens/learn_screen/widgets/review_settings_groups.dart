import 'dart:async';

import 'package:flutter/material.dart';
import 'package:riovox/models/flashcard_model.dart';
import 'package:riovox/services/deck_scheduling_defaults.dart';
import 'package:riovox/services/flashcard_service.dart';
import 'package:riovox/services/review_settings_store.dart';
import 'package:riovox/ui_elements/app_dialog.dart';
import 'package:riovox/ui_elements/app_toast.dart';
import 'package:riovox/ui_elements/modern_page_widgets.dart';
import 'package:riovox/utils/sm2_preview.dart';

/// The top of Review settings (Decks · Review settings): Daily limits and
/// Learning steps for [deck], then the While reviewing switches. The deck
/// groups only show for a deck whose options can be edited.
class ReviewSettingsGroups extends StatefulWidget {
  const ReviewSettingsGroups({
    super.key,
    required this.deck,
    required this.settings,
    required this.onSettingsChanged,
  });

  final FlashcardDeckModel? deck;
  final ReviewSettings settings;
  final ValueChanged<ReviewSettings> onSettingsChanged;

  @override
  State<ReviewSettingsGroups> createState() => _ReviewSettingsGroupsState();
}

class _ReviewSettingsGroupsState extends State<ReviewSettingsGroups> {
  late DeckOptionsModel _options =
      widget.deck?.deckOptions ?? DeckSchedulingDefaults.deckOptions;
  Timer? _saveTimer;

  bool get _canEditDeck {
    final deck = widget.deck;
    return deck != null && !deck.isFiltered;
  }

  @override
  void didUpdateWidget(ReviewSettingsGroups oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deck?.id != widget.deck?.id) {
      _options = widget.deck?.deckOptions ?? DeckSchedulingDefaults.deckOptions;
    }
  }

  @override
  void dispose() {
    // Leaving mid-debounce still saves the last change.
    if (_saveTimer?.isActive ?? false) {
      _saveTimer!.cancel();
      unawaited(_saveOptions(showError: false));
    }
    super.dispose();
  }

  /// Steppers save once the taps settle, not on every tap.
  void _changeOptions(DeckOptionsModel options, {bool debounce = false}) {
    setState(() => _options = options);
    _saveTimer?.cancel();
    if (debounce) {
      _saveTimer = Timer(const Duration(milliseconds: 600), _saveOptions);
    } else {
      _saveOptions();
    }
  }

  Future<void> _saveOptions({bool showError = true}) async {
    final deck = widget.deck;
    if (deck == null) return;
    try {
      await FlashcardService.instance.updateDeck(deck.id, deckOptions: _options.toJson());
    } catch (_) {
      if (showError && mounted) {
        AppToast.showSnackBar(context, const SnackBar(content: Text('Could not save deck options')));
      }
    }
  }

  DeckOptionsModel _copy({
    int? newCardsPerDay,
    int? maxReviewsPerDay,
    List<int>? learningStepsMinutes,
    double? graduatingIntervalDays,
    double? easyIntervalDays,
  }) {
    final o = _options;
    return DeckOptionsModel(
      newCardsPerDay: newCardsPerDay ?? o.newCardsPerDay,
      maxReviewsPerDay: maxReviewsPerDay ?? o.maxReviewsPerDay,
      leechThreshold: o.leechThreshold,
      learningStepsMinutes: learningStepsMinutes ?? o.learningStepsMinutes,
      graduatingIntervalDays: graduatingIntervalDays ?? o.graduatingIntervalDays,
      easyIntervalDays: easyIntervalDays ?? o.easyIntervalDays,
      easyBonus: o.easyBonus,
      lapseStepsMinutes: o.lapseStepsMinutes,
      minimumIntervalDays: o.minimumIntervalDays,
    );
  }

  static String _stepLabel(int minutes) {
    if (minutes % 1440 == 0) return '${minutes ~/ 1440}d';
    if (minutes % 60 == 0) return '${minutes ~/ 60}h';
    return '${minutes}m';
  }

  static String _daysLabel(double days) {
    final text = days == days.roundToDouble() ? '${days.round()}' : '$days';
    return days == 1 ? '1 day' : '$text days';
  }

  Future<String?> _editText({
    required String title,
    required String initial,
    required String hint,
    TextInputType keyboardType = TextInputType.number,
  }) {
    final ctrl = TextEditingController(text: initial);
    return showAppDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: keyboardType,
          decoration: InputDecoration(helperText: hint),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('Save')),
        ],
      ),
    );
  }

  Future<void> _editSteps() async {
    final text = await _editText(
      title: 'Learning steps',
      initial: formatStepsField(_options.learningStepsMinutes),
      hint: 'Minutes, separated by commas (e.g. 1, 10)',
      keyboardType: TextInputType.text,
    );
    if (text == null) return;
    _changeOptions(_copy(learningStepsMinutes: parseStepsField(text, _options.learningStepsMinutes)));
  }

  Future<void> _editDays({required String title, required double current, required bool graduating}) async {
    final text = await _editText(title: title, initial: _daysLabel(current).split(' ').first, hint: 'Days');
    final days = double.tryParse(text?.trim() ?? '');
    if (days == null || days <= 0) return;
    _changeOptions(graduating ? _copy(graduatingIntervalDays: days) : _copy(easyIntervalDays: days));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_canEditDeck) ...[
          _ReviewGroup(
            title: 'Daily limits',
            rows: [
              _ReviewRow(
                title: 'New cards per day',
                trailing: _Stepper(
                  value: _options.newCardsPerDay,
                  onChanged: (v) => _changeOptions(_copy(newCardsPerDay: v), debounce: true),
                ),
              ),
              _ReviewRow(
                title: 'Maximum reviews',
                trailing: _Stepper(
                  value: _options.maxReviewsPerDay,
                  step: 10,
                  onChanged: (v) => _changeOptions(_copy(maxReviewsPerDay: v), debounce: true),
                ),
              ),
            ],
          ),
          _ReviewGroup(
            title: 'Learning steps',
            rows: [
              _ReviewRow(
                title: 'Steps',
                value: _options.learningStepsMinutes.map(_stepLabel).join(' '),
                onTap: _editSteps,
              ),
              _ReviewRow(
                title: 'Graduating interval',
                value: _daysLabel(_options.graduatingIntervalDays),
                onTap: () => _editDays(
                  title: 'Graduating interval',
                  current: _options.graduatingIntervalDays,
                  graduating: true,
                ),
              ),
              _ReviewRow(
                title: 'Easy interval',
                value: _daysLabel(_options.easyIntervalDays),
                onTap: () => _editDays(
                  title: 'Easy interval',
                  current: _options.easyIntervalDays,
                  graduating: false,
                ),
              ),
            ],
          ),
        ],
        _ReviewGroup(
          title: 'While reviewing',
          rows: [
            _ReviewRow(
              title: 'Show next-review times',
              trailing: AppSwitch(
                value: s.showIntervalPreviews,
                onChanged: (v) => widget.onSettingsChanged(s.copyWith(showIntervalPreviews: v)),
              ),
            ),
            _ReviewRow(
              title: 'Show the Hard button',
              trailing: AppSwitch(
                value: s.showHardButton,
                onChanged: (v) => widget.onSettingsChanged(s.copyWith(showHardButton: v)),
              ),
            ),
            _ReviewRow(
              title: 'Keep screen on',
              trailing: AppSwitch(
                value: s.keepScreenOn,
                onChanged: (v) => widget.onSettingsChanged(s.copyWith(keepScreenOn: v)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Uppercase grey label over a white card of rows split by hairlines.
class _ReviewGroup extends StatelessWidget {
  const _ReviewGroup({required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: AppPageColors.subtitleOf(context),
              ),
            ),
          ),
          Material(
            color: AppPageColors.cardBgOf(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppPageColors.subtleBorderOf(context)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) Divider(height: 1, thickness: 1, color: AppPageColors.rowDividerOf(context)),
                  rows[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One row: title on the left, then a grey [value] or a [trailing] control.
class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.title, this.value, this.trailing, this.onTap});

  final String title;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppPageColors.textPrimaryOf(context),
                ),
              ),
            ),
            if (value != null)
              Text(value!, style: TextStyle(fontSize: 15, color: AppPageColors.subtitleOf(context))),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

/// − value + with 36 dp square buttons.
class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.onChanged, this.step = 1});

  final int value;
  final int step;
  final ValueChanged<int> onChanged;

  static const _max = 9999;

  @override
  Widget build(BuildContext context) {
    Widget button(String label, String tooltip, int? next) {
      return Tooltip(
        message: tooltip,
        child: Material(
          color: AppPageColors.pageBgOf(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: AppPageColors.subtleBorderOf(context)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: next == null ? null : () => onChanged(next),
            child: SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: next == null ? AppPageColors.mutedOf(context) : AppPageColors.textPrimaryOf(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button('−', 'Fewer', value > 0 ? (value - step).clamp(0, _max) : null),
        SizedBox(
          width: 44,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppPageColors.textPrimaryOf(context)),
          ),
        ),
        button('+', 'More', value < _max ? (value + step).clamp(0, _max) : null),
      ],
    );
  }
}
