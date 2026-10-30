import 'package:fluentdeck/ui_elements/app_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluentdeck/screens/learn_screen/decks_settings_section.dart';
import 'package:fluentdeck/screens/learn_screen/decks_settings_section_screen.dart';
import 'package:fluentdeck/screens/learn_screen/widgets/decks_settings_widgets.dart';
import 'package:fluentdeck/screens/learn_screen/widgets/review_settings_groups.dart';
import 'package:fluentdeck/models/flashcard_model.dart';
import 'package:fluentdeck/services/flashcard_service.dart';
import 'package:fluentdeck/services/deck_backup_service.dart';
import 'package:fluentdeck/services/deck_notification_service.dart';
import 'package:fluentdeck/services/flashcard_sync_service.dart';
import 'package:fluentdeck/services/flashcard_sync_store.dart';
import 'package:fluentdeck/services/review_settings_store.dart';
import 'package:fluentdeck/ui_elements/app_skeletons.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';

/// Decks settings hub. Standalone it is "Review settings": Daily limits and
/// Learning steps for [deckId], the While reviewing switches, then the
/// sections under "More settings".
class DecksSettingsScreen extends StatefulWidget {
  const DecksSettingsScreen({
    super.key,
    this.embedInShell = false,
    this.inlineInScroll = false,
    this.sections = decksProfileHubSections,
    this.deckId,
  });

  /// The deck whose limits and steps show at the top; null hides them.
  final int? deckId;

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
  FlashcardDeckModel? _deck;

  bool get _standalone => !widget.embedInShell && !widget.inlineInScroll;

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
    final deck = _standalone ? await _loadDeck() : null;
    final lastMs = await DeckBackupService.instance.getLastBackupMs();
    await FlashcardSyncService.instance.loadLog();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _deck = deck;
      _lastBackupLabel = DeckBackupService.instance.formatLastBackup(lastMs);
      _syncLog = FlashcardSyncService.instance.log;
      _loading = false;
    });
  }

  Future<FlashcardDeckModel?> _loadDeck() async {
    final id = widget.deckId;
    if (id == null) return null;
    try {
      final decks = await FlashcardService.instance.fetchDecksWithCache();
      for (final d in decks) {
        if (d.id == id) return d;
      }
    } catch (_) {
      // Offline: the deck groups stay hidden; the rest still works.
    }
    return null;
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
      AppToast.showSnackBar(context, 
        SnackBar(
          content: Text(
            result.applied > 0
                ? 'Synced ${result.applied} review${result.applied == 1 ? '' : 's'}'
                : 'Cloud sync complete',
          ),
        ),
      );
    } else {
      AppToast.showSnackBar(context, 
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
      AppToast.showSnackBar(context, 
        const SnackBar(
          content: Text(
            kIsWeb
                ? 'Backup downloaded (web stores latest in browser storage when auto-backup runs)'
                : 'Backup saved to device',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.showSnackBar(context, 
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

  Widget _sectionTile(BuildContext context, DecksSettingsSection section) {
    return decksSettingsNavTile(
      context: context,
      icon: section.icon,
      title: section.title,
      subtitle: section.subtitle,
      onTap: () => _openSection(section),
    );
  }

  Widget _buildSectionTiles(BuildContext context) {
    final tiles = <Widget>[
      for (final section in widget.sections) _sectionTile(context, section),
    ];

    if (widget.inlineInScroll) {
      return Column(mainAxisSize: MainAxisSize.min, children: tiles);
    }

    if (_standalone) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          ReviewSettingsGroups(deck: _deck, settings: _settings, onSettingsChanged: _save),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'MORE SETTINGS',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: AppPageColors.subtitleOf(context),
              ),
            ),
          ),
          ...tiles,
        ],
      );
    }

    return ListView(
      padding: EdgeInsets.symmetric(vertical: widget.embedInShell ? 0 : 8),
      children: [
        if (widget.embedInShell && !widget.inlineInScroll)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Review, sync, backup, and study options for your decks.',
              style: TextStyle(fontSize: 13, color: AppPageColors.subtitleOf(context)),
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
            ? AppListSkeleton(
                count: 5,
                itemHeight: 56,
                scrollable: !widget.inlineInScroll,
              )
            : _buildSectionTiles(context);

    if (widget.embedInShell || widget.inlineInScroll) {
      return body;
    }

    return Scaffold(
      backgroundColor: AppPageColors.pageBgOf(context),
      appBar: AppBar(
        backgroundColor: AppPageColors.pageBgOf(context),
        foregroundColor: AppPageColors.textPrimaryOf(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Review settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
      ),
      body: body,
    );
  }
}
