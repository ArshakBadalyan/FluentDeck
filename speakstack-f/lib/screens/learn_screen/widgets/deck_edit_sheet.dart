import 'package:flutter/material.dart';
import 'package:speakstack/app_colors.dart';
import 'package:speakstack/ui_elements/frosted_bottom_sheet.dart';
import 'package:speakstack/models/flashcard_model.dart';
import 'package:speakstack/services/flashcard_service.dart';
import 'package:speakstack/services/deck_scheduling_defaults.dart';
import 'package:speakstack/utils/sm2_preview.dart';

/// Rename deck, edit description, set parent deck (Phase 4F / 5A).
Future<bool?> showDeckEditSheet(
  BuildContext context, {
  required FlashcardDeckModel deck,
  required List<FlashcardDeckModel> allDecks,
}) {
  return showFrostedBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    useSafeArea: true,
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.82,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return _DeckEditSheet(
            deck: deck,
            allDecks: allDecks,
            scrollController: scrollController,
          );
        },
      );
    },
  );
}

class _DeckEditSheet extends StatefulWidget {
  const _DeckEditSheet({
    required this.deck,
    required this.allDecks,
    required this.scrollController,
  });

  final FlashcardDeckModel deck;
  final List<FlashcardDeckModel> allDecks;
  final ScrollController scrollController;

  @override
  State<_DeckEditSheet> createState() => _DeckEditSheetState();
}

class _DeckEditSheetState extends State<_DeckEditSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _newCardsCtrl;
  late final TextEditingController _maxReviewsCtrl;
  late final TextEditingController _leechThresholdCtrl;
  late final TextEditingController _learningStepsCtrl;
  late final TextEditingController _lapseStepsCtrl;
  late final TextEditingController _graduatingCtrl;
  late final TextEditingController _easyIntervalCtrl;
  late final TextEditingController _easyBonusCtrl;
  late final TextEditingController _minIntervalCtrl;
  int? _parentDeckId;
  bool _saving = false;
  bool _showAdvanced = false;

  bool get _canRename => !widget.deck.isDefault;
  bool get _canNest => !widget.deck.isDefault && !widget.deck.isFiltered;
  bool get _canEditOptions => !widget.deck.isDefault && !widget.deck.isFiltered;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.deck.name);
    _descCtrl = TextEditingController(text: widget.deck.description);
    _parentDeckId = widget.deck.parentDeckId;
    final opts = widget.deck.deckOptions ?? DeckSchedulingDefaults.deckOptions;
    _newCardsCtrl = TextEditingController(text: '${opts.newCardsPerDay}');
    _maxReviewsCtrl = TextEditingController(text: '${opts.maxReviewsPerDay}');
    _leechThresholdCtrl = TextEditingController(text: '${opts.leechThreshold}');
    _learningStepsCtrl = TextEditingController(
      text: formatStepsField(opts.learningStepsMinutes),
    );
    _lapseStepsCtrl = TextEditingController(
      text: formatStepsField(opts.lapseStepsMinutes),
    );
    _graduatingCtrl = TextEditingController(text: '${opts.graduatingIntervalDays}');
    _easyIntervalCtrl = TextEditingController(text: '${opts.easyIntervalDays}');
    _easyBonusCtrl = TextEditingController(text: '${opts.easyBonus}');
    _minIntervalCtrl = TextEditingController(text: '${opts.minimumIntervalDays}');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _newCardsCtrl.dispose();
    _maxReviewsCtrl.dispose();
    _leechThresholdCtrl.dispose();
    _learningStepsCtrl.dispose();
    _lapseStepsCtrl.dispose();
    _graduatingCtrl.dispose();
    _easyIntervalCtrl.dispose();
    _easyBonusCtrl.dispose();
    _minIntervalCtrl.dispose();
    super.dispose();
  }

  List<FlashcardDeckModel> get _parentOptions {
    return widget.allDecks
        .where(
          (d) =>
              d.id != widget.deck.id &&
              !d.isFiltered &&
              d.parentDeckId != widget.deck.id,
        )
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  int? get _safeParentDeckId {
    if (_parentDeckId == null) return null;
    return _parentOptions.any((d) => d.id == _parentDeckId) ? _parentDeckId : null;
  }

  InputDecoration _fieldDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF2F2F5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  TextStyle get _labelStyle => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Colors.grey.shade700,
  );

  Widget _labeledField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: 8),
        field,
      ],
    );
  }

  Widget _numberField(String label, TextEditingController controller, {String? hint}) {
    return _labeledField(
      label,
      TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: _fieldDecoration().copyWith(hintText: hint),
      ),
    );
  }

  Future<void> _save() async {
    if (_canRename && _nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deck name cannot be empty')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      Map<String, dynamic>? deckOptions;
      if (_canEditOptions) {
        deckOptions = {
          'newCardsPerDay': int.tryParse(_newCardsCtrl.text.trim()) ?? 20,
          'maxReviewsPerDay': int.tryParse(_maxReviewsCtrl.text.trim()) ?? 200,
          'leechThreshold': int.tryParse(_leechThresholdCtrl.text.trim()) ?? 8,
          'learningStepsMinutes': parseStepsField(
            _learningStepsCtrl.text,
            DeckSchedulingDefaults.learningStepsMinutes,
          ),
          'lapseStepsMinutes': parseStepsField(_lapseStepsCtrl.text, const [10]),
          'graduatingIntervalDays':
              double.tryParse(_graduatingCtrl.text.trim()) ?? 1,
          'easyIntervalDays': double.tryParse(_easyIntervalCtrl.text.trim()) ?? 4,
          'easyBonus': double.tryParse(_easyBonusCtrl.text.trim()) ?? 1.3,
          'minimumIntervalDays': double.tryParse(_minIntervalCtrl.text.trim()) ?? 1,
        };
      }
      await FlashcardService.instance.updateDeck(
        widget.deck.id,
        name: _canRename ? _nameCtrl.text.trim() : null,
        description: _descCtrl.text.trim(),
        parentDeckId: _canNest ? _parentDeckId : null,
        clearParent: _canNest && _parentDeckId == null,
        deckOptions: deckOptions,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 6),
          child: Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 8, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Close',
                onPressed: _saving ? null : () => Navigator.pop(context, false),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit deck',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      widget.deck.name,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            children: [
              if (_canRename)
                _labeledField(
                  'Name',
                  TextField(
                    controller: _nameCtrl,
                    decoration: _fieldDecoration(),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    widget.deck.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              const SizedBox(height: 12),
              _labeledField(
                'Description',
                TextField(
                  controller: _descCtrl,
                  maxLines: 2,
                  decoration: _fieldDecoration(),
                ),
              ),
              if (_canNest) ...[
                const SizedBox(height: 12),
                _labeledField(
                  'Parent deck',
                  DropdownButtonFormField<int?>(
                    value: _safeParentDeckId,
                    isExpanded: true,
                    decoration: _fieldDecoration(),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('None (top level)'),
                      ),
                      ..._parentOptions.map(
                        (d) => DropdownMenuItem<int?>(
                          value: d.id,
                          child: Text(d.name),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _parentDeckId = v),
                  ),
                ),
              ],
              if (_canEditOptions) ...[
                const SizedBox(height: 16),
                Material(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Scheduling options',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'Daily limits, steps, intervals',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            _showAdvanced ? Icons.expand_less : Icons.expand_more,
                            color: Colors.grey.shade700,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_showAdvanced) ...[
                  const SizedBox(height: 12),
                  _numberField('New cards per day', _newCardsCtrl),
                  const SizedBox(height: 12),
                  _numberField('Max reviews per day', _maxReviewsCtrl),
                  const SizedBox(height: 12),
                  _labeledField(
                    'Learning steps (minutes)',
                    TextField(
                      controller: _learningStepsCtrl,
                      decoration: _fieldDecoration().copyWith(hintText: '1, 10'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _labeledField(
                    'Lapse steps (minutes)',
                    TextField(
                      controller: _lapseStepsCtrl,
                      decoration: _fieldDecoration().copyWith(hintText: '10'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _numberField('Graduating interval (days)', _graduatingCtrl),
                  const SizedBox(height: 12),
                  _numberField('Easy interval (days)', _easyIntervalCtrl),
                  const SizedBox(height: 12),
                  _numberField('Easy bonus multiplier', _easyBonusCtrl),
                  const SizedBox(height: 12),
                  _numberField('Minimum interval (days)', _minIntervalCtrl),
                  const SizedBox(height: 12),
                  _numberField('Leech threshold (lapses)', _leechThresholdCtrl),
                ],
              ],
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            12 + MediaQuery.paddingOf(context).bottom,
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save changes'),
            ),
          ),
        ),
      ],
    );
  }
}
