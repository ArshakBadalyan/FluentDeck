import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/models/flashcard_model.dart';
import 'package:fluentdeck/models/flashcard_note_model.dart';
import 'package:fluentdeck/models/speaking_preferences.dart';
import 'package:fluentdeck/services/flashcard_service.dart';
import 'package:fluentdeck/services/note_service.dart';
import 'package:fluentdeck/services/speaking_preferences_service.dart';
import 'package:fluentdeck/services/subscription_service.dart';
import 'package:fluentdeck/ui_elements/primary_button.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';
import 'package:fluentdeck/utils/html_text_utils.dart';
import 'package:fluentdeck/utils/speaking_premium_gate.dart';
import 'package:fluentdeck/widgets/cefr_level_chips.dart';
import 'package:fluentdeck/widgets/html_field_editor.dart';
import 'package:fluentdeck/widgets/synced_learning_language_hint.dart';
import 'package:fluentdeck/models/occlusion_model.dart';
import 'package:fluentdeck/widgets/image_occlusion_editor.dart';
import 'package:fluentdeck/widgets/note_preview_sheet.dart';

/// Add / edit note screen.
class CardEditScreen extends StatefulWidget {
  const CardEditScreen({
    super.key,
    this.deckId,
    this.noteId,
    this.sheetMode = false,
    this.scrollController,
  });

  /// Initial deck when creating; optional when editing (loaded from note).
  final int? deckId;

  /// When set, loads and updates an existing note.
  final int? noteId;

  /// Bottom-sheet presentation (add note from card browser).
  final bool sheetMode;

  final ScrollController? scrollController;

  bool get isEditing => noteId != null;

  /// Mobile-friendly add-note sheet (matches browser filter sheet UX).
  static Future<bool?> showAddSheet(
    BuildContext context, {
    int? deckId,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.88,
            minChildSize: 0.45,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return CardEditScreen(
                deckId: deckId,
                sheetMode: true,
                scrollController: scrollController,
              );
            },
          ),
        );
      },
    );
  }

  @override
  State<CardEditScreen> createState() => _CardEditScreenState();
}

class _CardEditScreenState extends State<CardEditScreen> {
  final _mediaCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _topicCtrl = TextEditingController();
  final Map<String, TextEditingController> _fieldCtrls = {};
  final Map<int, TextEditingController> _maskLabelCtrls = {};

  bool _loading = true;
  bool _saving = false;
  bool _offlineMode = false;
  String? _error;
  String _noteType = 'basic';
  bool _createReverse = false;
  bool _pinFront = false;
  int? _selectedDeckId;
  List<NoteTypeModel> _noteTypes = const [];
  List<FlashcardDeckModel> _decks = const [];
  String _languageCode = 'en';
  bool _syncLearningLanguage = true;
  String? _cefrLevel;
  bool _isPremium = false;
  bool _checkingPremium = true;
  bool _detectingLevel = false;

  List<OcclusionRegion> _occlusionRegions = const [];

  bool get _isCloze => _noteType == 'cloze';
  bool get _isImageOcclusion => _noteType == 'image_occlusion';
  bool get _showReverseOption => _noteType == 'basic_optional_reversed';

  NoteTypeModel? get _activeType {
    for (final t in _noteTypes) {
      if (t.id == _noteType) return t;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _selectedDeckId = widget.deckId;
    _load();
    if (!widget.isEditing) {
      _loadPremium();
    }
  }

  @override
  void dispose() {
    _mediaCtrl.dispose();
    _tagsCtrl.dispose();
    _topicCtrl.dispose();
    for (final c in _fieldCtrls.values) {
      c.dispose();
    }
    for (final c in _maskLabelCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncMaskLabelControllers() {
    final ids = _occlusionRegions.map((r) => r.id).toSet();
    for (final id in _maskLabelCtrls.keys.toList()) {
      if (!ids.contains(id)) {
        _maskLabelCtrls.remove(id)!.dispose();
      }
    }
    for (final region in _occlusionRegions) {
      _maskLabelCtrls.putIfAbsent(
        region.id,
        () => TextEditingController(text: region.label),
      );
    }
  }

  List<OcclusionRegion> _regionsWithLabels() {
    return _occlusionRegions
        .map(
          (r) => OcclusionRegion(
            id: r.id,
            x: r.x,
            y: r.y,
            w: r.w,
            h: r.h,
            label: _maskLabelCtrls[r.id]?.text.trim() ?? r.label,
          ),
        )
        .toList();
  }

  Future<void> _loadPremium() async {
    final status = await SubscriptionService.instance.fetchStatus();
    if (!mounted) return;
    setState(() {
      _isPremium = status.isPremium;
      _checkingPremium = false;
    });
  }

  String? _wordForCefrDetect() {
    final front = _fieldCtrls['Front']?.text.trim() ?? '';
    if (front.isNotEmpty) return stripHtml(front);
    final text = _fieldCtrls['Text']?.text.trim() ?? '';
    if (text.isNotEmpty) return stripHtml(text);
    return null;
  }

  Future<void> _detectCefrWithAi() async {
    if (!_isPremium) {
      showSpeakingPremiumSnackBar(context);
      return;
    }

    final word = _wordForCefrDetect();
    if (word == null || word.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the front field first')),
      );
      return;
    }

    setState(() => _detectingLevel = true);
    try {
      final result = await NoteService.instance.detectCefrLevel(
        word: word,
        languageCode: _languageCode,
        definition: _fieldCtrls['Back']?.text.trim(),
        exampleSentence: null,
      );
      if (!mounted) return;
      if (result.premiumRequired) {
        showSpeakingPremiumSnackBar(context);
        return;
      }
      if (result.ok && result.cefrLevel != null) {
        setState(() => _cefrLevel = result.cefrLevel);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Suggested level: ${result.cefrLevel}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Could not detect level')),
        );
      }
    } finally {
      if (mounted) setState(() => _detectingLevel = false);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      List<NoteTypeModel> types;
      List<FlashcardDeckModel> decks;
      FlashcardNoteModel? existing;
      var offline = false;

      try {
        types = await FlashcardService.instance.fetchNoteTypes();
        decks = await FlashcardService.instance.fetchDecks();
        if (widget.noteId != null) {
          existing = await FlashcardService.instance.fetchNote(widget.noteId!);
        }
      } catch (_) {
        offline = true;
        types = await FlashcardService.instance.fetchNoteTypesWithCache();
        decks = await FlashcardService.instance.fetchDecksWithCache();
        if (widget.isEditing) {
          throw Exception('Editing notes requires an internet connection');
        }
      }

      final prefs = await SpeakingPreferencesService.instance.load();

      if (existing != null) {
        _noteType = existing.noteType;
        _createReverse = existing.createReverse;
        _selectedDeckId = existing.deckId ?? widget.deckId;
        _mediaCtrl.text = existing.mediaUrl ?? '';
        _tagsCtrl.text = existing.tags.join(', ');
        _applyFieldControllers(existing.fields, types);
        _occlusionRegions = parseOcclusionField(existing.fields['Occlusion']?.toString() ?? '');
        _syncMaskLabelControllers();
      } else {
        _applyFieldControllers({}, types);
        _occlusionRegions = const [];
        _syncMaskLabelControllers();
      }

      if (!mounted) return;
      setState(() {
        _noteTypes = types;
        _decks = decks;
        _offlineMode = offline;
        _syncLearningLanguage = prefs.syncLearningLanguage;
        if (!widget.isEditing) {
          _languageCode = prefs.practiceLanguage;
        }
        if (_selectedDeckId == null && decks.isNotEmpty) {
          _selectedDeckId = decks.first.id;
        }
        if (types.isNotEmpty && !types.any((t) => t.id == _noteType)) {
          _noteType = types.first.id;
          _rebuildFieldsForType();
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _applyFieldControllers(
    Map<String, String> values,
    List<NoteTypeModel> types,
  ) {
    for (final c in _fieldCtrls.values) {
      c.dispose();
    }
    _fieldCtrls.clear();

    final type = types.firstWhere(
      (t) => t.id == _noteType,
      orElse: () => types.isNotEmpty ? types.first : const NoteTypeModel(id: 'basic', name: 'Basic'),
    );

    for (final field in type.fields) {
      final ctrl = TextEditingController(text: values[field.name] ?? '');
      _fieldCtrls[field.name] = ctrl;
    }
  }

  void _rebuildFieldsForType() {
    final preserved = <String, String>{};
    for (final e in _fieldCtrls.entries) {
      preserved[e.key] = e.value.text;
    }
    _applyFieldControllers(preserved, _noteTypes);
  }

  void _onNoteTypeChanged(String? value) {
    if (value == null) return;
    setState(() {
      _noteType = value;
      if (value != 'image_occlusion') _occlusionRegions = const [];
      _rebuildFieldsForType();
    });
  }

  List<String> _parseTags() {
    final tags =
        _tagsCtrl.text
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList();
    if (!widget.isEditing && _cefrLevel != null && _cefrLevel!.isNotEmpty) {
      tags.removeWhere((t) => t.toLowerCase().startsWith('cefr:'));
      tags.add('cefr:${_cefrLevel!}');
    }
    final topic = _topicCtrl.text.trim();
    if (!widget.isEditing && topic.isNotEmpty) {
      tags.removeWhere((t) => t.toLowerCase().startsWith('topic:'));
      tags.add('topic:$topic');
    }
    return tags;
  }

  Map<String, String> _buildFields() {
    final fields = <String, String>{};
    for (final e in _fieldCtrls.entries) {
      fields[e.key] = e.value.text.trim();
    }
    if (_isImageOcclusion) {
      fields['Occlusion'] = occlusionFieldJson(_regionsWithLabels());
    }
    return fields;
  }

  String? _validateFields(Map<String, String> fields) {
    final type = _activeType;
    if (type == null) return 'Unknown note type';

    for (final field in type.fields) {
      if (!field.required) continue;
      final v = fields[field.name] ?? '';
      if (v.isEmpty) return '${field.name} is required';
    }

    if (_isCloze) {
      final text = fields['Text'] ?? '';
      if (!hasClozeDeletions(text)) {
        return 'Cloze notes need at least one {{c1::answer}} deletion';
      }
    }

    if (_isImageOcclusion) {
      final image = fields['Image'] ?? '';
      if (image.isEmpty) return 'Image URL is required';
      if (_occlusionRegions.isEmpty) {
        return 'Draw at least one occlusion mask on the image';
      }
    }

    return null;
  }

  Future<void> _pickMedia() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'mp3', 'wav', 'm4a', 'ogg',
        'png', 'jpg', 'jpeg', 'gif', 'webp',
      ],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read file')),
      );
      return;
    }

    try {
      final url = await FlashcardService.instance.uploadMedia(bytes, file.name);
      if (!mounted) return;
      if (url == null || url.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed')),
        );
        return;
      }
      setState(() => _mediaCtrl.text = url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _preview() async {
    final fields = _buildFields();
    final err = _validateFields(fields);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    await NotePreviewSheet.show(
      context,
      noteType: _noteType,
      fields: fields,
      mediaUrl: _mediaCtrl.text.trim().isEmpty ? null : _mediaCtrl.text.trim(),
    );
  }

  Future<void> _save() async {
    if (_selectedDeckId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a deck')),
      );
      return;
    }

    final fields = _buildFields();
    final validationError = _validateFields(fields);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    final pinnedFront = _pinFront ? (_fieldCtrls['Front']?.text ?? '') : null;

    setState(() => _saving = true);
    try {
      if (widget.isEditing) {
        await FlashcardService.instance.updateNote(
          noteId: widget.noteId!,
          noteType: _noteType,
          fields: fields,
          tags: _parseTags(),
          createReverse: _createReverse,
          mediaUrl: _mediaCtrl.text.trim().isEmpty ? '' : _mediaCtrl.text.trim(),
          deckId: _selectedDeckId,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note updated')),
        );
        Navigator.pop(context, true);
      } else {
        final result = await FlashcardService.instance.createNote(
          deckId: _selectedDeckId!,
          noteType: _noteType,
          fields: fields,
          tags: _parseTags(),
          createReverse: _createReverse,
          mediaUrl: _mediaCtrl.text.trim().isEmpty ? null : _mediaCtrl.text.trim(),
          languageCode: _languageCode,
        );

        if (!mounted) return;
        final count = result.cards.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              count > 1 ? 'Note saved — $count cards created' : 'Note saved',
            ),
          ),
        );

        if (_pinFront && pinnedFront != null && pinnedFront.isNotEmpty) {
          _fieldCtrls['Front']?.text = pinnedFront;
          _fieldCtrls['Back']?.clear();
          if (_fieldCtrls.containsKey('Text')) _fieldCtrls['Text']?.clear();
          setState(() => _saving = false);
          return;
        }

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openFullEditor() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CardEditScreen(deckId: _selectedDeckId ?? widget.deckId),
      ),
    );
    if (!mounted) return;
    if (saved == true) Navigator.pop(context, true);
  }

  bool get _needsFullEditor => widget.sheetMode && _isImageOcclusion;

  @override
  Widget build(BuildContext context) {
    if (widget.sheetMode) {
      return _buildSheetPresentation();
    }

    return Scaffold(
      backgroundColor: AppPageColors.pageBgOf(context),
      appBar: AppBar(
        backgroundColor: AppPageColors.pageBgOf(context),
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(widget.isEditing ? 'Edit note' : 'Add note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility_outlined),
            tooltip: 'Preview',
            onPressed: _loading || _saving ? null : _preview,
          ),
          IconButton(
            icon: const Icon(Icons.check_rounded, color: AppColors.primaryPurple),
            tooltip: 'Save',
            onPressed: _saving || _loading ? null : _save,
          ),
        ],
      ),
      body: AppPageBackground(child: _buildBody()),
    );
  }

  Widget _buildSheetPresentation() {
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
                      'Add note',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Create a new flashcard',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.visibility_outlined),
                tooltip: 'Preview',
                onPressed: _loading || _saving || _needsFullEditor ? null : _preview,
              ),
            ],
          ),
        ),
        Expanded(child: _buildBody()),
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
              onPressed: _saving || _loading || _needsFullEditor ? null : _save,
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
                  : const Text('Save note'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _buildFormFields(),
    );

    if (widget.sheetMode) {
      return ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        children: [form],
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: form,
    );
  }

  List<Widget> _buildFormFields() {
    return [
          if (_offlineMode) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.cloud_off_rounded, size: 18, color: Colors.orange.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Offline mode — using cached decks and note types. Saving requires a connection.',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          _deckDropdown(),
          if (!widget.isEditing) ...[
            const SizedBox(height: 12),
            AppSelectField<String>(
              label: 'Language',
              value: _languageCode,
              enabled: !_syncLearningLanguage,
              options:
                  SpeakingPreferences.practiceLanguageOptions.entries
                      .map((e) => AppSelectOption(value: e.key, label: e.value))
                      .toList(),
              onChanged:
                  _syncLearningLanguage
                      ? null
                      : (value) => setState(() => _languageCode = value),
            ),
            if (_syncLearningLanguage)
              const SyncedLearningLanguageHint(),
            const SizedBox(height: 12),
            _buildCefrSection(),
            const SizedBox(height: 12),
            _labeledField(
              'Topic (optional)',
              TextField(
                controller: _topicCtrl,
                decoration: _filledDecoration(),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _typeDropdown(),
          if (_activeType != null) ...[
            const SizedBox(height: 6),
            Text(
              '${_activeType!.cardTemplateNames.join(', ')} card(s) will be created',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
          if (_needsFullEditor) ...[
            const SizedBox(height: 16),
            Material(
              color: AppColors.primaryPurple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
                leading: const Icon(Icons.image_outlined, color: AppColors.primaryPurple),
                title: const Text('Image occlusion editor'),
                subtitle: const Text('Open the full editor to draw masks on an image'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: _openFullEditor,
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            ..._buildFieldEditors(),
            if (_showReverseOption) ...[
              const SizedBox(height: 12),
              AppToggleRow(
                title: 'Create reverse card',
                subtitle: 'Also add Back → Front card',
                value: _createReverse,
                onChanged: (v) => setState(() => _createReverse = v),
              ),
            ],
            if (!widget.isEditing) ...[
              const SizedBox(height: 8),
              AppToggleRow(
                title: 'Pin front field',
                subtitle: 'Keep front text after saving for the next note',
                value: _pinFront,
                onChanged: (v) => setState(() => _pinFront = v),
              ),
            ],
            const SizedBox(height: 12),
            _mediaField(),
            const SizedBox(height: 12),
            if (widget.sheetMode)
              _labeledField(
                'Tags (comma-separated)',
                TextField(
                  controller: _tagsCtrl,
                  decoration: _filledDecoration(),
                ),
              )
            else
              _plainField('Tags (comma-separated)', _tagsCtrl),
          ],
          if (!widget.sheetMode) ...[
            const SizedBox(height: 24),
            PrimaryButton(
              text: _saving ? 'SAVING…' : (widget.isEditing ? 'UPDATE NOTE' : 'SAVE NOTE'),
              enabled: !_saving,
              onPressed: _save,
            ),
          ],
        ];
  }

  Widget _buildCefrSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(
              child: Text(
                'CEFR level (optional)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (!_checkingPremium)
              TextButton.icon(
                onPressed:
                    _detectingLevel
                        ? null
                        : (_isPremium
                            ? _detectCefrWithAi
                            : () => showSpeakingPremiumSnackBar(context)),
                icon:
                    _detectingLevel
                        ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Icon(
                          _isPremium
                              ? Icons.auto_awesome_rounded
                              : Icons.lock_outline_rounded,
                          size: 16,
                        ),
                label: Text(
                  _detectingLevel
                      ? 'Analyzing…'
                      : (_isPremium ? 'Detect with AI' : 'Premium'),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryPurple,
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        CefrLevelChips(
          selectedLevel: _cefrLevel,
          allowDeselect: true,
          onLevelSelected: (level) => setState(() => _cefrLevel = level),
        ),
      ],
    );
  }

  Widget _deckDropdown() {
    final deckId =
        _decks.any((d) => d.id == _selectedDeckId)
            ? _selectedDeckId
            : (_decks.isNotEmpty ? _decks.first.id : null);
    return AppSelectField<int>(
      label: 'Deck',
      value: deckId,
      options:
          _decks
              .map((d) => AppSelectOption(value: d.id, label: d.name))
              .toList(),
      onChanged: (v) => setState(() => _selectedDeckId = v),
    );
  }

  Widget _typeDropdown() {
    final typeId =
        _noteTypes.any((t) => t.id == _noteType)
            ? _noteType
            : (_noteTypes.isNotEmpty ? _noteTypes.first.id : 'basic');
    return AppSelectField<String>(
      label: 'Type',
      value: typeId,
      options:
          _noteTypes
              .map((t) => AppSelectOption(value: t.id, label: t.name))
              .toList(),
      onChanged: _onNoteTypeChanged,
    );
  }

  List<Widget> _buildFieldEditors() {
    if (_isImageOcclusion) {
      final imageUrl = _fieldCtrl('Image').text.trim();
      return [
        _plainField('Image URL', _fieldCtrl('Image')),
        const SizedBox(height: 16),
        ImageOcclusionEditor(
          imageUrl: imageUrl,
          regions: _occlusionRegions,
          onChanged: (regions) {
            setState(() {
              _occlusionRegions = regions;
              _syncMaskLabelControllers();
            });
          },
        ),
        if (_occlusionRegions.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Mask labels', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._occlusionRegions.map((region) {
            final ctrl = _maskLabelCtrls[region.id]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  labelText: 'Mask ${region.id}',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
              ),
            );
          }),
        ],
        const SizedBox(height: 16),
        _plainField('Header (optional caption)', _fieldCtrl('Header')),
      ];
    }

    final type = _activeType;
    if (type == null || type.fields.isEmpty) {
      return [
        HtmlFieldEditor(label: 'Front', controller: _fieldCtrl('Front'), required: true),
        const SizedBox(height: 16),
        HtmlFieldEditor(label: 'Back', controller: _fieldCtrl('Back'), maxLines: 5, required: true),
      ];
    }

    final widgets = <Widget>[];
    for (final field in type.fields) {
      final isClozeText = _isCloze && field.name == 'Text';
      widgets.add(
        HtmlFieldEditor(
          label: field.name,
          controller: _fieldCtrl(field.name),
          maxLines: isClozeText ? 5 : (field.name == 'Back' ? 5 : 3),
          required: field.required,
          hint: isClozeText ? 'Use {{c1::answer}} for cloze deletions' : null,
        ),
      );
      widgets.add(const SizedBox(height: 16));
    }
    if (widgets.isNotEmpty) widgets.removeLast();
    return widgets;
  }

  TextEditingController _fieldCtrl(String name) {
    return _fieldCtrls.putIfAbsent(name, () => TextEditingController());
  }

  InputDecoration _filledDecoration({Widget? prefixIcon}) {
    return InputDecoration(
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryPurple, width: 1.5),
      ),
    );
  }

  InputDecoration _inputDecoration([String? label]) {
    return _filledDecoration().copyWith(labelText: label);
  }

  TextStyle get _fieldLabelStyle => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Colors.grey.shade700,
  );

  Widget _labeledField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _fieldLabelStyle),
        const SizedBox(height: 8),
        field,
      ],
    );
  }

  Widget _mediaField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Media URL (audio/image)', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _mediaCtrl,
                decoration: _filledDecoration(),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _pickMedia,
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text('Pick'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _plainField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: _inputDecoration(),
        ),
      ],
    );
  }
}
