import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/models/card_style_preset.dart';
import 'package:fluentdeck/models/flashcard_note_model.dart';
import 'package:fluentdeck/services/flashcard_service.dart';
import 'package:fluentdeck/services/note_type_style_store.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';

/// Create or edit a user-defined note type. No HTML/CSS in sight — pick what
/// information each note stores (fields) and a ready-made visual look
/// (style). The front/back card layout is generated automatically: the first
/// field is the question, the rest appear on the answer side.
class NoteTypeEditScreen extends StatefulWidget {
  const NoteTypeEditScreen({super.key, this.existing});

  final NoteTypeModel? existing;

  bool get isEditing => existing != null;

  /// Built-in types: card style only. Custom types: full editor.
  bool get styleOnly => existing != null && !existing!.isCustom;

  @override
  State<NoteTypeEditScreen> createState() => _NoteTypeEditScreenState();
}

class _NoteTypeEditScreenState extends State<NoteTypeEditScreen> {
  final _nameCtrl = TextEditingController();
  late List<_FieldRow> _fields;
  late String _selectedThemeId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameCtrl.text = existing?.name ?? '';
    _selectedThemeId = existing?.themeId ?? CardStylePreset.all.first.id;
    _fields =
        existing != null && existing.fields.isNotEmpty
            ? existing.fields
                .map((f) => _FieldRow(name: f.name, required: f.required))
                .toList()
            : [
              _FieldRow(name: 'Front', required: true),
              _FieldRow(name: 'Back', required: true),
            ];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (final f in _fields) {
      f.dispose();
    }
    super.dispose();
  }

  /// The card layout is always front → answer: the first field is the
  /// question, every other field is revealed underneath on the back.
  NoteTypeCardTemplateModel _generateTemplate(List<NoteTypeFieldModel> fields) {
    final first = fields.first.name;
    final rest = fields.skip(1).map((f) => '{{${f.name}}}').join('<br>');
    return NoteTypeCardTemplateModel(
      name: 'Card 1',
      ordinal: 0,
      qfmt: '{{$first}}',
      afmt: rest.isEmpty ? '{{FrontSide}}' : '{{FrontSide}}<hr id="answer">$rest',
    );
  }

  NoteTypeModel _buildDraft() {
    final fields =
        _fields
            .map(
              (f) => NoteTypeFieldModel(
                name: f.nameCtrl.text.trim(),
                required: f.required,
              ),
            )
            .where((f) => f.name.isNotEmpty)
            .toList();
    final preset = CardStylePreset.byId(_selectedThemeId);

    return NoteTypeModel(
      id: widget.existing?.id ?? '',
      name: _nameCtrl.text.trim(),
      fields: fields,
      cardTemplates: fields.isEmpty ? const [] : [_generateTemplate(fields)],
      css: preset.toCss(),
      themeId: preset.id,
      isCustom: true,
    );
  }

  String? _validate() {
    if (_nameCtrl.text.trim().isEmpty) return 'Give this type a name';
    final fieldNames = _fields.map((f) => f.nameCtrl.text.trim()).where((n) => n.isNotEmpty);
    if (fieldNames.isEmpty) return 'Add at least one field';
    if (fieldNames.length != fieldNames.toSet().length) return 'Field names must be unique';
    return null;
  }

  Future<void> _save() async {
    if (widget.styleOnly) {
      setState(() {
        _saving = true;
        _error = null;
      });
      try {
        await NoteTypeStyleStore.instance.save(
          widget.existing!.id,
          _selectedThemeId,
        );
        if (!mounted) return;
        Navigator.pop(context, true);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _error = e.toString();
          _saving = false;
        });
      }
      return;
    }

    final validation = _validate();
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final draft = _buildDraft();
      if (widget.isEditing) {
        final id = widget.existing!.customDbId;
        if (id == null) throw Exception('Invalid custom note type id');
        await FlashcardService.instance.updateCustomNoteType(id: id, draft: draft);
      } else {
        await FlashcardService.instance.createCustomNoteType(draft);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  void _addField() {
    setState(() => _fields.add(_FieldRow()));
  }

  void _removeField(int index) {
    if (_fields.length <= 1) return;
    setState(() {
      _fields[index].dispose();
      _fields.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPageColors.pageBgOf(context),
      appBar: AppBar(
        backgroundColor: AppPageColors.pageBgOf(context),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        title: Text(
          widget.styleOnly
              ? 'Card style'
              : widget.isEditing
              ? 'Edit note type'
              : 'New note type',
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _saving ? null : _save,
              style: TextButton.styleFrom(foregroundColor: AppColors.primaryPurple),
              child:
                  _saving
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: AppPageBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.redWrong.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.redWrong.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, size: 18, color: AppColors.redWrong),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.redWrong, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (widget.styleOnly) ...[
              AppSectionCard(
                title: widget.existing!.name,
                icon: Icons.lock_outline_rounded,
                subtitle: 'Built-in type — you can change the card style only',
                child: Text(
                  'Fields and templates are fixed for this note type.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              AppSectionCard(
                title: 'Name',
                icon: Icons.label_outline_rounded,
                child: AppTextField(
                  controller: _nameCtrl,
                  hint: 'e.g. Vocabulary, Grammar point',
                ),
              ),
              const SizedBox(height: 16),
              AppSectionCard(
                title: 'What does each card show?',
                icon: Icons.view_column_outlined,
                subtitle: 'The first field is the question; the rest appear when you reveal the answer',
                trailing: _AddButton(onPressed: _addField),
                child: Column(
                  children: [
                    for (final entry in _fields.asMap().entries) ...[
                      if (entry.key > 0) const SizedBox(height: 8),
                      _fieldTile(entry.key, entry.value),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            AppSectionCard(
              title: 'Card style',
              icon: Icons.palette_outlined,
              subtitle: 'Pick a look — applied to every card of this type',
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final preset in CardStylePreset.all) _themeSwatch(preset),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldTile(int index, _FieldRow row) {
    return Builder(
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppPageColors.fieldBgOf(context),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: row.nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'Field name',
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Required',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Switch(
                  value: row.required,
                  activeThumbColor: AppColors.primaryPurple,
                  onChanged: (v) => setState(() => row.required = v),
                ),
              ],
            ),
            IconButton(
              icon: Icon(Icons.close_rounded, size: 18, color: Colors.grey.shade500),
              tooltip: 'Remove field',
              onPressed: () => _removeField(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _themeSwatch(CardStylePreset preset) {
    final selected = preset.id == _selectedThemeId;
    return GestureDetector(
      onTap: () => setState(() => _selectedThemeId = preset.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 96,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: preset.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primaryPurple : Colors.black.withValues(alpha: 0.08),
            width: selected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  selected
                      ? AppColors.primaryPurple.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.04),
              blurRadius: selected ? 10 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Aa',
              style: TextStyle(
                color: preset.textColor,
                fontSize: preset.fontSize * 0.8,
                fontWeight: preset.fontWeight,
                fontFamily: 'Rubik',
              ),
            ),
            const SizedBox(height: 8),
            Container(width: 28, height: 2.5, color: preset.accentColor),
            const SizedBox(height: 8),
            Text(
              preset.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.primaryPurple : preset.textColor,
              ),
            ),
            if (selected) ...[
              const SizedBox(height: 4),
              const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.primaryPurple),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text('Add'),
      style: TextButton.styleFrom(foregroundColor: AppColors.primaryPurple),
    );
  }
}

class _FieldRow {
  _FieldRow({String name = '', this.required = false}) : nameCtrl = TextEditingController(text: name);

  final TextEditingController nameCtrl;
  bool required;

  void dispose() => nameCtrl.dispose();
}
