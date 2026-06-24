import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speakstack/app_colors.dart';
import 'package:speakstack/screens/learn_screen/decks_settings_section.dart';
import 'package:speakstack/screens/learn_screen/decks_settings_section_screen.dart';
import 'package:speakstack/services/deck_backup_service.dart';
import 'package:speakstack/services/deck_notification_service.dart';
import 'package:speakstack/services/flashcard_sync_service.dart';
import 'package:speakstack/services/flashcard_sync_store.dart';
import 'package:speakstack/services/review_settings_store.dart';

/// Anki-style Decks settings hub (Step 6).
class DecksSettingsScreen extends StatefulWidget {
  const DecksSettingsScreen({
    super.key,
    this.embedInShell = false,
    this.inlineInScroll = false,
    this.sections = decksProfileHubSections,
  });

  /// When true, renders without [Scaffold] for Profile → Settings.
  final bool embedInShell;

  /// When true, renders a [Column] instead of [ListView] for nested scroll views.
  final bool inlineInScroll;

  /// Which hub sections to list (excludes About, Notifications, etc.).
  final List<DecksSettingsSection> sections;

  @override
  State<DecksSettingsScreen> createState() => _DecksSettingsScreenState();
}

class _DecksSettingsScreenState extends State<DecksSettingsScreen> {
  ReviewSettings _settings = const ReviewSettings();
  bool _loading = true;
  String _lastBackupLabel = 'Never';
  FlashcardSyncLog _syncLog = const FlashcardSyncLog();
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _load();
    FlashcardSyncService.instance.addListener(_onSyncChanged);
  }

  @override
  void dispose() {
    FlashcardSyncService.instance.removeListener(_onSyncChanged);
    super.dispose();
  }

  void _onSyncChanged() {
    if (!mounted) return;
    setState(() {
      _syncLog = FlashcardSyncService.instance.log;
      _syncing = FlashcardSyncService.instance.syncing;
    });
  }

  Future<void> _load() async {
    final settings = await ReviewSettingsStore.instance.load();
    final lastMs = await DeckBackupService.instance.getLastBackupMs();
    await FlashcardSyncService.instance.loadLog();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _lastBackupLabel = DeckBackupService.instance.formatLastBackup(lastMs);
      _syncLog = FlashcardSyncService.instance.log;
      _loading = false;
    });
  }

  Future<void> _save(ReviewSettings settings) async {
    setState(() => _settings = settings);
    await ReviewSettingsStore.instance.save(settings);
    await DeckNotificationService.instance.syncFromSettings();
  }

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    final result = await FlashcardSyncService.instance.syncNow();
    if (!mounted) return;
    setState(() {
      _syncing = false;
      _syncLog = FlashcardSyncService.instance.log;
    });
    if (result.success) {
      await FlashcardSyncService.showConflictDialogIfNeeded(context, skipped: result.skipped);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.applied > 0
                ? 'Synced ${result.applied} review${result.applied == 1 ? '' : 's'}'
                : 'Cloud sync complete',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync failed — check connection')),
      );
    }
  }

  Future<void> _backupNow() async {
    try {
      await DeckBackupService.instance.performBackup();
      final lastMs = await DeckBackupService.instance.getLastBackupMs();
      if (!mounted) return;
      setState(() {
        _lastBackupLabel = DeckBackupService.instance.formatLastBackup(lastMs);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            kIsWeb
                ? 'Backup downloaded (web stores latest in browser storage when auto-backup runs)'
                : 'Backup saved to device',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _openSection(DecksSettingsSection section) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder:
            (_) => DecksSettingsSectionScreen(
              section: section,
              settings: _settings,
              onSave: _save,
              lastBackupLabel: _lastBackupLabel,
              syncLog: _syncLog,
              syncing: _syncing,
              onSyncNow: _syncNow,
              onBackupNow: _backupNow,
              onReload: _load,
            ),
      ),
    );
    await _load();
  }

  Widget _buildSectionTiles() {
    final tiles = <Widget>[
      for (final section in widget.sections)
        ListTile(
          leading: Icon(section.icon, color: AppColors.primaryPurple),
          title: Text(section.title),
          subtitle: Text(section.subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openSection(section),
        ),
    ];

    if (widget.inlineInScroll) {
      return Column(mainAxisSize: MainAxisSize.min, children: tiles);
    }

    return ListView(
      padding: EdgeInsets.symmetric(vertical: widget.embedInShell ? 0 : 8),
      children: [
        if (widget.embedInShell && !widget.inlineInScroll)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Review, sync, backup, and study options for your decks.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
        ...tiles,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final body =
        _loading
            ? const Center(child: CircularProgressIndicator())
            : _buildSectionTiles();

    if (widget.embedInShell || widget.inlineInScroll) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Decks settings'),
      ),
      body: body,
    );
  }
}
