import 'package:riovox/ui_elements/app_toast.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:riovox/utils/api_exception.dart';
import 'package:riovox/app_colors.dart';
import 'package:riovox/models/flashcard_model.dart';
import 'package:riovox/models/flashcard_note_model.dart';
import 'package:riovox/models/speaking_preferences.dart';
import 'package:riovox/services/flashcard_service.dart';
import 'package:riovox/services/note_service.dart';
import 'package:riovox/services/speaking_preferences_service.dart';
import 'package:riovox/services/subscription_service.dart';
import 'package:riovox/ui_elements/modern_page_widgets.dart';
import 'package:riovox/utils/html_text_utils.dart';
import 'package:riovox/utils/speaking_premium_gate.dart';
import 'package:riovox/widgets/cefr_level_chips.dart';
import 'package:riovox/widgets/cloze_field_editor.dart';
import 'package:riovox/widgets/html_field_editor.dart';
import 'package:riovox/widgets/record_audio_button.dart';
import 'package:riovox/ui_elements/app_skeletons.dart';
import 'package:riovox/widgets/synced_learning_language_hint.dart';
import 'package:riovox/models/occlusion_model.dart';
import 'package:riovox/widgets/image_occlusion_editor.dart';
import 'package:riovox/widgets/note_preview_sheet.dart';
import 'package:riovox/ui_elements/app_motion.dart';

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
      backgroundColor: AppPageColors.fieldBgOf(context),
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
  final _tagInputCtrl = TextEditingController();
  final _mediaPlayer = AudioPlayer();
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
  String _translationLanguage = 'none';
  bool _generatingMeaning = false;
  bool _translating = false;
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
    // Needed when editing too: Generate with AI / Detect CEFR are Premium.
    _loadPremium();
  }

  @override
  void dispose() {
    _mediaCtrl.dispose();
    _tagsCtrl.dispose();
    _tagInputCtrl.dispose();
    _mediaPlayer.dispose();
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
      AppToast.showSnackBar(context, 
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
        AppToast.showSnackBar(context, 
          SnackBar(content: Text('Suggested level: ${result.cefrLevel}')),
        );
      } else {
        AppToast.showSnackBar(context, 
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
      } on ApiException {
        // The server answered (e.g. 404) — show its message, not "offline".
        rethrow;
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
        _translationLanguage = prefs.translationLanguage;
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
        _error = e is ApiException ? e.message : e.toString();
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

    // Older speaking-note cards kept the example inside Back as
    // "…\n\nExample: …"; move it into the Example field when one exists.
    final hasExampleField = type.fields.any((f) => f.name == 'Example');
    final legacyBack = values['Back'] ?? '';
    final legacy = RegExp(
      r'(?:^|\n\s*\n|<br\s*/?>\s*<br\s*/?>)Example:\s*(.+)$',
      dotAll: true,
    ).firstMatch(legacyBack);
    if (hasExampleField && (values['Example'] ?? '').trim().isEmpty && legacy != null) {
      values = {
        ...values,
        'Back': legacyBack.substring(0, legacy.start).trim(),
        'Example': legacy.group(1)!.trim(),
      };
    }

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
    _commitTagInput();
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

  /// Toolbar image button: a picture for the card (shown above it in review).
  Future<void> _pickImage() => _pickMedia(imagesOnly: true);

  Future<void> _pickMedia({bool imagesOnly = false}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        if (!imagesOnly) ...['mp3', 'wav', 'm4a', 'ogg'],
        'png', 'jpg', 'jpeg', 'gif', 'webp',
      ],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      if (!mounted) return;
      AppToast.showSnackBar(context, 
        const SnackBar(content: Text('Could not read file')),
      );
      return;
    }

    try {
      final url = await FlashcardService.instance.uploadMedia(bytes, file.name);
      if (!mounted) return;
      if (url == null || url.isEmpty) {
        AppToast.showSnackBar(context, 
          const SnackBar(content: Text('Upload failed')),
        );
        return;
      }
      setState(() => _mediaCtrl.text = url);
    } catch (e) {
      if (!mounted) return;
      AppToast.showSnackBar(context,
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  /// Image Occlusion's "Image URL" field had no upload path — pasting a
  /// link from Google Photos/Drive "share" looked like it should work but
  /// doesn't: those URLs open an HTML viewer page, not raw image bytes, so
  /// the editor's image never loads and there's nothing to draw a mask on.
  /// Uploading the file directly (same path `_pickMedia` already uses)
  /// always produces a URL this editor can actually load.
  Future<void> _pickOcclusionImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'gif', 'webp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      if (!mounted) return;
      AppToast.showSnackBar(context,
        const SnackBar(content: Text('Could not read file')),
      );
      return;
    }

    try {
      final url = await FlashcardService.instance.uploadMedia(bytes, file.name);
      if (!mounted) return;
      if (url == null || url.isEmpty) {
        AppToast.showSnackBar(context,
          const SnackBar(content: Text('Upload failed')),
        );
        return;
      }
      setState(() => _fieldCtrl('Image').text = url);
    } catch (e) {
      if (!mounted) return;
      AppToast.showSnackBar(context,
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _preview() async {
    final fields = _buildFields();
    final err = _validateFields(fields);
    if (err != null) {
      AppToast.showSnackBar(context, SnackBar(content: Text(err)));
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
      AppToast.showSnackBar(context, 
        const SnackBar(content: Text('Select a deck')),
      );
      return;
    }

    final fields = _buildFields();
    final validationError = _validateFields(fields);
    if (validationError != null) {
      AppToast.showSnackBar(context, 
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
        AppToast.showSnackBar(context, 
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
        AppToast.showSnackBar(context, 
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
      AppToast.showSnackBar(context, 
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
        // Light header; Save is the one teal action (Lagoon Daylight).
        backgroundColor: AppPageColors.pageBgOf(context),
        foregroundColor: AppPageColors.textPrimaryOf(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 4,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          widget.isEditing ? 'Edit card' : 'Add card',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility_outlined),
            tooltip: 'Preview',
            onPressed: _loading || _saving ? null : _preview,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: FilledButton(
                onPressed: _saving || _loading ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppPageColors.accentOf(context),
                  foregroundColor: AppPageColors.onAccentOf(context),
                  elevation: 0,
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
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
                color: AppPageColors.subtitleOf(context).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 8, 0),
          child: Row(
            children: [
              const SizedBox(width: 12),
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
                      style: TextStyle(fontSize: 12, color: AppPageColors.subtitleOf(context)),
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
            color: AppPageColors.cardBgOf(context),
            border: Border(top: BorderSide(color: AppPageColors.subtleBorderOf(context))),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.transparent
                    : Colors.black.withValues(alpha: 0.04),
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
                backgroundColor: AppColors.brandPrimary,
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
      return AppLoadingSwitcher(
      loading: true,
      child: const ProfileSettingsCardSkeleton(rows: 4),
    );
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

    return AppLoadingSwitcher(
      loading: false,
      child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      child: form,
    ),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _typeDropdown()),
              const SizedBox(width: 10),
              Expanded(child: _deckDropdown()),
            ],
          ),
          if (_activeType != null) ...[
            const SizedBox(height: 6),
            Text(
              '${_activeType!.cardTemplateNames.join(', ')} card(s) will be created',
              style: TextStyle(fontSize: 13, color: AppPageColors.subtitleOf(context)),
            ),
          ],
          if (!widget.isEditing) ...[
            const SizedBox(height: 12),
            AppSelectField<String>(
              label: 'Language',
              value: _languageCode,
              enabled: !_syncLearningLanguage,
              fieldColor: AppPageColors.cardBgOf(context),
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
          if (_needsFullEditor) ...[
            const SizedBox(height: 16),
            Material(
              color: AppColors.brandPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
                leading: const Icon(Icons.image_outlined, color: AppColors.brandPrimary),
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
            _tagsField(),
          ],
          // Save lives in the header; a live preview closes the form.
          if (!widget.sheetMode && !_needsFullEditor && !_isImageOcclusion) ...[
            const SizedBox(height: 16),
            Text('Preview', style: _fieldLabelStyle),
            const SizedBox(height: 8),
            _livePreview(),
          ],
        ];
  }

  /// The card's front as it will read, blanks shown as […].
  Widget _livePreview() {
    final ctrl = _fieldCtrls['Text'] ?? _fieldCtrls['Front'];
    if (ctrl == null) return const SizedBox.shrink();
    final accent = AppPageColors.accentOf(context);
    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) {
        final raw = stripHtml(ctrl.text).trim();
        final cloze = RegExp(r'\{\{c\d+::(.*?)(?:::.*?)?\}\}');
        final spans = <TextSpan>[];
        var last = 0;
        for (final m in cloze.allMatches(raw)) {
          spans.add(TextSpan(text: raw.substring(last, m.start)));
          spans.add(TextSpan(text: '[…]', style: TextStyle(color: accent)));
          last = m.end;
        }
        spans.add(TextSpan(text: raw.substring(last)));
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppPageColors.cardBgOf(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppPageColors.subtleBorderOf(context)),
          ),
          child: raw.isEmpty
              ? Text(
                  'Your card will show here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: AppPageColors.mutedOf(context)),
                )
              : !cloze.hasMatch(raw)
              // Bold, italic, underline and red as the card will show them.
              ? BasicHtmlText(
                  html: ctrl.text.trim(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                    color: AppPageColors.textPrimaryOf(context),
                  ),
                )
              : Text.rich(
                  TextSpan(children: spans),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppPageColors.textPrimaryOf(context),
                  ),
                ),
        );
      },
    );
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
                  foregroundColor: AppColors.brandPrimary,
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
      fieldColor: AppPageColors.cardBgOf(context),
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
      fieldColor: AppPageColors.cardBgOf(context),
    );
  }

  List<Widget> _buildFieldEditors() {
    if (_isImageOcclusion) {
      final imageUrl = _fieldCtrl('Image').text.trim();
      return [
        _imageUrlField(),
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
              // Delete lives on the mask chips above (in the editor itself)
              // — this row is just the label text, no second delete control
              // needed next to it.
              child: TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  labelText: 'Mask ${region.id}',
                  filled: true,
                  fillColor: AppPageColors.cardBgOf(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppPageColors.subtleBorderOf(context), width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppPageColors.subtleBorderOf(context), width: 1),
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
        HtmlFieldEditor(
          label: 'Front',
          controller: _fieldCtrl('Front'),
          required: true,
          toolbarActions: _mediaToolbarActions(),
        ),
        const SizedBox(height: 16),
        HtmlFieldEditor(label: 'Back', controller: _fieldCtrl('Back'), maxLines: 5, required: true),
      ];
    }

    final widgets = <Widget>[];
    for (final field in type.fields) {
      final isClozeText = _isCloze && field.name == 'Text';
      // One recording per card, so the mic sits on the first field only.
      final actions = field == type.fields.first ? _mediaToolbarActions() : const <Widget>[];
      widgets.add(
        isClozeText
            ? ClozeFieldEditor(
                controller: _fieldCtrl(field.name),
                maxLines: 5,
                required: field.required,
                toolbarActions: actions,
              )
            : HtmlFieldEditor(
                label: field.name,
                controller: _fieldCtrl(field.name),
                maxLines: field.name == 'Back' ? 5 : 3,
                required: field.required,
                trailing: _fieldAiAction(field.name),
                toolbarActions: actions,
              ),
      );
      widgets.add(const SizedBox(height: 16));
    }
    if (widgets.isNotEmpty) widgets.removeLast();
    return widgets;
  }

  /// Image and mic for the first field's toolbar (one picture or clip per card).
  List<Widget> _mediaToolbarActions() => [
    IconButton(
      icon: const Icon(Icons.image_outlined, size: 20),
      color: AppPageColors.accentOf(context),
      tooltip: 'Add a picture',
      onPressed: _pickImage,
      visualDensity: VisualDensity.compact,
    ),
    _recordButton(),
  ];

  /// Records the card's audio and puts the uploaded clip in Media URL, which
  /// review plays from the card's listen button.
  Widget _recordButton() {
    return RecordAudioButton(
      onError: _snack,
      onRecorded: (bytes, filename) async {
        final url = await FlashcardService.instance.uploadMedia(bytes, filename);
        if (!mounted) return;
        if (url == null || url.isEmpty) {
          _snack('Upload failed');
          return;
        }
        setState(() => _mediaCtrl.text = url);
        _snack('Audio added to this card');
      },
    );
  }

  String _plainFront() =>
      (_fieldCtrls['Front']?.text ?? '').replaceAll(RegExp(r'<[^>]+>'), '').trim();

  void _snack(String message) {
    AppToast.showSnackBar(context, SnackBar(content: Text(message)));
  }

  /// Fills Back (definition) and Example from the Front word with AI. Premium.
  Future<void> _generateMeaningWithAi() async {
    if (!_isPremium) {
      showSpeakingPremiumSnackBar(context);
      return;
    }
    final word = _plainFront();
    if (word.isEmpty) {
      _snack('Enter the Front (word or phrase) first');
      return;
    }
    setState(() => _generatingMeaning = true);
    final result = await NoteService.instance.generateWordMeaning(
      word: word,
      languageCode: _languageCode,
      translationLanguage: 'none',
    );
    if (!mounted) return;
    setState(() => _generatingMeaning = false);
    if (result.premiumRequired) {
      showSpeakingPremiumSnackBar(context);
      return;
    }
    if (!result.ok) {
      _snack(result.message ?? 'Could not generate a meaning');
      return;
    }
    _fieldCtrl('Back').text = result.definition;
    if (result.example.isNotEmpty && _fieldCtrls.containsKey('Example')) {
      _fieldCtrl('Example').text = result.example;
    }
  }

  /// Translates the Front word into the user's translation language.
  Future<void> _translateWithAi() async {
    if (!_isPremium) {
      showSpeakingPremiumSnackBar(context);
      return;
    }
    final word = _plainFront();
    if (word.isEmpty) {
      _snack('Enter the Front (word or phrase) first');
      return;
    }
    if (_translationLanguage == 'none' || _translationLanguage == _languageCode) {
      _snack(
        'Choose a translation language (different from the word\'s) '
        'in Settings → AI Speaking to translate with AI',
      );
      return;
    }
    setState(() => _translating = true);
    final translated = await NoteService.instance.translateText(
      text: word,
      targetLanguage: _translationLanguage,
    );
    if (!mounted) return;
    setState(() => _translating = false);
    if (translated == null) {
      _snack('Could not translate. Try again.');
      return;
    }
    _fieldCtrl('Translation').text = translated;
  }

  Widget? _fieldAiAction(String fieldName) {
    final hasFront = _fieldCtrls.containsKey('Front');
    if (!hasFront) return null;
    if (fieldName == 'Back' && !_checkingPremium) {
      return _aiButton(
        label: _isPremium ? 'Generate with AI' : 'Generate · Premium',
        busyLabel: 'Generating…',
        icon: Icons.auto_awesome_rounded,
        busy: _generatingMeaning,
        onPressed: _generateMeaningWithAi,
      );
    }
    if (fieldName == 'Translation' && !_checkingPremium) {
      return _aiButton(
        label: _isPremium ? 'Translate with AI' : 'Translate · Premium',
        busyLabel: 'Translating…',
        icon: Icons.translate_rounded,
        busy: _translating,
        onPressed: _translateWithAi,
      );
    }
    return null;
  }

  Widget _aiButton({
    required String label,
    required String busyLabel,
    required IconData icon,
    required bool busy,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: busy ? null : onPressed,
      icon:
          busy
              ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : Icon(icon, size: 16),
      label: Text(busy ? busyLabel : label),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.brandPrimary,
        visualDensity: VisualDensity.compact,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  TextEditingController _fieldCtrl(String name) {
    return _fieldCtrls.putIfAbsent(name, () => TextEditingController());
  }

  InputDecoration _filledDecoration({Widget? prefixIcon}) {
    return InputDecoration(
      prefixIcon: prefixIcon,
      filled: true,
      // White (cardBgOf), not the page's pale field tint — fields on this
      // sheet were barely distinguishable from the sheet's own background.
      fillColor: AppPageColors.cardBgOf(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppPageColors.subtleBorderOf(context), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppPageColors.subtleBorderOf(context), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppPageColors.accentOf(context), width: 1.5),
      ),
    );
  }

  /// Same border as the field next to it (theme default is near-white in dark mode).
  ButtonStyle _pickButtonStyle() {
    return OutlinedButton.styleFrom(
      side: BorderSide(color: AppPageColors.subtleBorderOf(context), width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  InputDecoration _inputDecoration([String? label]) {
    return _filledDecoration().copyWith(labelText: label);
  }

  TextStyle get _fieldLabelStyle => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppPageColors.subtitleOf(context),
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

  static const _imageExtensions = ['.png', '.jpg', '.jpeg', '.gif', '.webp'];

  bool get _mediaIsImage {
    final url = _mediaCtrl.text.trim().toLowerCase().split('?').first;
    return _imageExtensions.any(url.endsWith);
  }

  /// Audio or picture for the card: add a file or paste a link (record from
  /// the toolbar mic).
  /// Shows what is attached instead of the raw URL.
  Widget _mediaField() {
    final url = _mediaCtrl.text.trim();
    final accent = AppPageColors.accentOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Audio or picture', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (url.isEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _pickMedia,
                icon: const Icon(Icons.attach_file_rounded, size: 18),
                label: const Text('Add file'),
                style: _pickButtonStyle(),
              ),
              TextButton(onPressed: _pasteMediaLink, child: const Text('Paste a link')),
              // One recorder per screen: the mic lives in the first field's toolbar.
              Text(
                'or use 🎤 / 🖼 above',
                style: TextStyle(fontSize: 12, color: AppPageColors.subtitleOf(context)),
              ),
            ],
          )
        else
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
            decoration: BoxDecoration(
              color: AppPageColors.cardBgOf(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppPageColors.subtleBorderOf(context)),
            ),
            child: Row(
              children: [
                if (_mediaIsImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      url,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(Icons.image_outlined, color: accent),
                    ),
                  )
                else
                  IconButton(
                    tooltip: 'Play',
                    icon: Icon(Icons.play_circle_fill_rounded, color: accent, size: 32),
                    onPressed: () async {
                      await _mediaPlayer.stop();
                      await _mediaPlayer.play(UrlSource(url));
                    },
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _mediaIsImage ? 'Picture attached' : 'Audio attached',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove',
                  icon: Icon(Icons.close_rounded, color: AppPageColors.subtitleOf(context)),
                  onPressed: () {
                    _mediaPlayer.stop();
                    setState(() => _mediaCtrl.clear());
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _pasteMediaLink() async {
    final ctrl = TextEditingController();
    final link = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Paste a link'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(hintText: 'https://… (.mp3 or .jpg)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Add')),
        ],
      ),
    );
    ctrl.dispose();
    if (link == null || link.isEmpty || !mounted) return;
    setState(() => _mediaCtrl.text = link);
  }

  List<String> get _tagList => _tagsCtrl.text
      .split(',')
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toList();

  /// Adds whatever is typed in the tag box (split on commas) to the tags.
  void _commitTagInput() {
    final typed = _tagInputCtrl.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty);
    if (typed.isEmpty) return;
    final tags = _tagList;
    for (final t in typed) {
      if (!tags.contains(t)) tags.add(t);
    }
    _tagInputCtrl.clear();
    setState(() => _tagsCtrl.text = tags.join(', '));
  }

  /// Tags as removable chips, with a box to add more (Enter or comma adds).
  Widget _tagsField() {
    final tags = _tagList;
    final accent = AppPageColors.accentOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tags', style: widget.sheetMode ? _fieldLabelStyle : const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (tags.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in tags)
                InputChip(
                  label: Text(tag),
                  onDeleted: () => setState(
                    () => _tagsCtrl.text = (tags..remove(tag)).join(', '),
                  ),
                  backgroundColor: accent.withValues(alpha: 0.1),
                  labelStyle: TextStyle(color: accent, fontWeight: FontWeight.w600, fontSize: 13),
                  deleteIconColor: accent,
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: _tagInputCtrl,
          decoration: _filledDecoration().copyWith(hintText: 'Add a tag, e.g. travel'),
          textInputAction: TextInputAction.done,
          onChanged: (v) {
            if (v.contains(',')) _commitTagInput();
          },
          onSubmitted: (_) => _commitTagInput(),
        ),
      ],
    );
  }

  Widget _imageUrlField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Image URL', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _fieldCtrl('Image'),
                decoration: _filledDecoration(),
                // The occlusion canvas below only re-reads this field when
                // this widget rebuilds — without this it'd stay blank until
                // some unrelated setState happened to fire.
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _pickOcclusionImage,
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text('Pick'),
              style: _pickButtonStyle(),
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
