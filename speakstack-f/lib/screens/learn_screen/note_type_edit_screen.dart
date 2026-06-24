import 'package:flutter/material.dart';
import 'package:speakstack/app_colors.dart';
import 'package:speakstack/models/flashcard_note_model.dart';
import 'package:speakstack/services/flashcard_service.dart';

/// Create or edit a user-defined note type (Phase 5C).
class NoteTypeEditScreen extends StatefulWidget {
  const NoteTypeEditScreen({super.key, this.existing});

  final NoteTypeModel? existing;

  bool get isEditing => existing != null;

  @override
  State<NoteTypeEditScreen> createState() => _NoteTypeEditScreenState();
}

class _NoteTypeEditScreenState extends State<NoteTypeEditScreen> {
  final _nameCtrl = TextEditingController();
  final _cssCtrl = TextEditingController();
  late List<_FieldRow> _fields;
  late List<_TemplateRow> _templates;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameCtrl.text = existing?.name ?? '';
    _cssCtrl.text = existing?.css ?? '';
    _fields =
        existing != null && existing.fields.isNotEmpty
            ? existing.fields
                .map((f) => _FieldRow(name: f.name, required: f.required))
                .toList()
            : [
              _FieldRow(name: 'Front', required: true),
              _FieldRow(name: 'Back', required: true),
            ];
    _templates =
        existing != null && existing.cardTemplates.isNotEmpty
            ? existing.cardTemplates
                .map(
                  (t) => _TemplateRow(
                    name: t.name,
                    qfmt: t.qfmt,
                    afmt: t.afmt,
                  ),
                )
                .toList()
            : [
              _TemplateRow(
                name: 'Card 1',
                qfmt: '{{Front}}',
                afmt: '{{FrontSide}}<hr id="answer">{{Back}}',
              ),
            ];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cssCtrl.dispose();
    for (final f in _fields) {
      f.dispose();
    }
    for (final t in _templates) {
      t.dispose();
    }
    super.dispose();
  }

  NoteTypeModel _buildDraft() {
    return NoteTypeModel(
      id: widget.existing?.id ?? '',
      name: _nameCtrl.text.trim(),
      fields:
          _fields
              .map(
                (f) => NoteTypeFieldModel(
                  name: f.nameCtrl.text.trim(),
                  required: f.required,
                ),
              )
              .where((f) => f.name.isNotEmpty)
              .toList(),
      cardTemplates:
          _templates
              .asMap()
              .entries
              .map(
                (e) => NoteTypeCardTemplateModel(
                  name: e.value.nameCtrl.text.trim().isEmpty
                      ? 'Card ${e.key + 1}'
                      : e.value.nameCtrl.text.trim(),
                  ordinal: e.key,
                  qfmt: e.value.qfmtCtrl.text,
                  afmt: e.value.afmtCtrl.text,
                ),
              )
              .toList(),
      css: _cssCtrl.text.trim(),
      isCustom: true,
    );
  }

  String? _validate() {
    if (_nameCtrl.text.trim().isEmpty) return 'Name is required';
    final fieldNames = _fields.map((f) => f.nameCtrl.text.trim()).where((n) => n.isNotEmpty);
    if (fieldNames.isEmpty) return 'Add at least one field';
    if (fieldNames.length != fieldNames.toSet().length) return 'Field names must be unique';
    if (_templates.isEmpty) return 'Add at least one card template';
    for (final t in _templates) {
      if (t.qfmtCtrl.text.trim().isEmpty || t.afmtCtrl.text.trim().isEmpty) {
        return 'Each template needs front and back formats';
      }
    }
    return null;
  }

  Future<void> _save() async {
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

  void _addTemplate() {
    setState(
      () => _templates.add(
        _TemplateRow(
          name: 'Card ${_templates.length + 1}',
          qfmt: '{{Front}}',
          afmt: '{{FrontSide}}<hr id="answer">{{Back}}',
        ),
      ),
    );
  }

  void _removeTemplate(int index) {
    if (_templates.length <= 1) return;
    setState(() {
      _templates[index].dispose();
      _templates.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(widget.isEditing ? 'Edit note type' : 'New note type'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child:
                _saving
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_error!, style: TextStyle(color: Colors.red.shade800)),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          _sectionHeader('Fields', onAdd: _addField),
          const SizedBox(height: 8),
          ..._fields.asMap().entries.map((e) => _fieldTile(e.key, e.value)),
          const SizedBox(height: 20),
          _sectionHeader('Card templates', onAdd: _addTemplate),
          const SizedBox(height: 4),
          Text(
            'Use {{FieldName}} placeholders. {{FrontSide}} shows the question on the back.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          ..._templates.asMap().entries.map((e) => _templateTile(e.key, e.value)),
          const SizedBox(height: 20),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('CSS (optional)', style: TextStyle(fontWeight: FontWeight.w600)),
            children: [
              TextField(
                controller: _cssCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: '.card { font-size: 18px; }',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, {required VoidCallback onAdd}) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add'),
          style: TextButton.styleFrom(foregroundColor: AppColors.primaryPurple),
        ),
      ],
    );
  }

  Widget _fieldTile(int index, _FieldRow row) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: row.nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Field name',
                  border: InputBorder.none,
                ),
              ),
            ),
            Checkbox(
              value: row.required,
              activeColor: AppColors.primaryPurple,
              onChanged: (v) => setState(() => row.required = v == true),
            ),
            const Text('Req', style: TextStyle(fontSize: 12)),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _removeField(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _templateTile(int index, _TemplateRow row) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: row.nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Template name',
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _removeTemplate(index),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: row.qfmtCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Front (qfmt)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: row.afmtCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Back (afmt)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldRow {
  _FieldRow({String name = '', this.required = false}) : nameCtrl = TextEditingController(text: name);

  final TextEditingController nameCtrl;
  bool required;

  void dispose() => nameCtrl.dispose();
}

class _TemplateRow {
  _TemplateRow({String name = '', String qfmt = '', String afmt = ''})
    : nameCtrl = TextEditingController(text: name),
      qfmtCtrl = TextEditingController(text: qfmt),
      afmtCtrl = TextEditingController(text: afmt);

  final TextEditingController nameCtrl;
  final TextEditingController qfmtCtrl;
  final TextEditingController afmtCtrl;

  void dispose() {
    nameCtrl.dispose();
    qfmtCtrl.dispose();
    afmtCtrl.dispose();
  }
}
