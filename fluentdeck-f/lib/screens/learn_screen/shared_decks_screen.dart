import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/models/flashcard_model.dart';
import 'package:fluentdeck/services/flashcard_import_service.dart';
import 'package:fluentdeck/services/flashcard_service.dart';

/// Browse AnkiWeb and import shared decks (Phase 5I).
class SharedDecksScreen extends StatefulWidget {
  const SharedDecksScreen({
    super.key,
    this.decks = const [],
  });

  final List<FlashcardDeckModel> decks;

  @override
  State<SharedDecksScreen> createState() => _SharedDecksScreenState();
}

class _SharedDecksScreenState extends State<SharedDecksScreen> {
  final _searchCtrl = TextEditingController();
  final _importCtrl = TextEditingController();
  final _tkCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;
  bool _showLogin = false;
  bool _createDecks = true;
  bool _importScheduling = false;
  int? _targetDeckId;
  String? _browseUrl;
  String? _hintMessage;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _importCtrl.dispose();
    _tkCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _openBrowse([String? url]) async {
    final target = url ?? _browseUrl ?? 'https://ankiweb.net/shared/decks/';
    final uri = Uri.parse(target);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open AnkiWeb')),
      );
    }
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _hintMessage = null;
    });
    try {
      final result = await FlashcardService.instance.searchAnkiWeb(_searchCtrl.text);
      if (!mounted) return;
      setState(() {
        _browseUrl = result.browseUrl;
        _hintMessage = result.message;
        if (result.suggestedDeckId != null) {
          _importCtrl.text = result.suggestedDeckId!;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _import() async {
    final raw = _importCtrl.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a deck ID or download URL')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final isUrl = raw.startsWith('http://') || raw.startsWith('https://');
      final result = await FlashcardService.instance.importFromAnkiWeb(
        deckId: isUrl ? null : raw,
        downloadUrl: isUrl ? raw : null,
        tk: _tkCtrl.text.trim().isEmpty ? null : _tkCtrl.text.trim(),
        username: _showLogin ? _usernameCtrl.text.trim() : null,
        password: _showLogin ? _passwordCtrl.text : null,
        createDecks: _createDecks,
        defaultDeckId: _targetDeckId,
        importScheduling: _importScheduling,
      );
      if (!mounted) return;
      await showImportResultSnackBar(context, result);
      if (result.imported > 0) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Get shared decks'),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'AnkiWeb has no public search API. Browse decks on AnkiWeb, then import by deck ID or paste the download link (with ?tk= token).',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      labelText: 'Search on AnkiWeb',
                      hintText: 'e.g. japanese, deck ID',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _search,
                      ),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => _openBrowse(),
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('Browse AnkiWeb'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                    ),
                  ),
                  if (_hintMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(_hintMessage!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'Import deck',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _importCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Deck ID or download URL',
                      hintText: '123456789 or https://ankiweb.net/shared/download/…?tk=…',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 1,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _tkCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Download token (optional)',
                      hintText: 'tk= value from browser if import fails',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Create decks from package'),
                    value: _createDecks,
                    activeThumbColor: AppColors.primaryPurple,
                    onChanged: (v) => setState(() => _createDecks = v),
                  ),
                  if (!_createDecks && widget.decks.isNotEmpty)
                    DropdownButtonFormField<int?>(
                      initialValue: _targetDeckId,
                      decoration: const InputDecoration(
                        labelText: 'Import into deck',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('Default deck')),
                        ...widget.decks.map(
                          (d) => DropdownMenuItem<int?>(value: d.id, child: Text(d.name)),
                        ),
                      ],
                      onChanged: (v) => setState(() => _targetDeckId = v),
                    ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Import scheduling'),
                    subtitle: const Text('Keep due dates and intervals from the shared deck'),
                    value: _importScheduling,
                    activeThumbColor: AppColors.primaryPurple,
                    onChanged: (v) => setState(() => _importScheduling = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('AnkiWeb login (optional)'),
                    subtitle: const Text('Only if the deck requires an account'),
                    value: _showLogin,
                    activeThumbColor: AppColors.primaryPurple,
                    onChanged: (v) => setState(() => _showLogin = v),
                  ),
                  if (_showLogin) ...[
                    TextField(
                      controller: _usernameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'AnkiWeb username',
                        border: OutlineInputBorder(),
                      ),
                      autocorrect: false,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordCtrl,
                      decoration: const InputDecoration(
                        labelText: 'AnkiWeb password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _import,
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Download and import'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ],
              ),
    );
  }
}
