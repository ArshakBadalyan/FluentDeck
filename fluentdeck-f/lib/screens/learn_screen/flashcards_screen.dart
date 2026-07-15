import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/models/flashcard_model.dart';
import 'package:fluentdeck/screens/learn_screen/card_edit_screen.dart';
import 'package:fluentdeck/screens/learn_screen/deck_overview_screen.dart';
import 'package:fluentdeck/screens/learn_screen/review_session_screen.dart';
import 'package:fluentdeck/screens/learn_screen/widgets/deck_count_buttons.dart';
import 'package:fluentdeck/screens/learn_screen/widgets/deck_edit_sheet.dart';
import 'package:fluentdeck/screens/learn_screen/widgets/filtered_deck_dialog.dart';
import 'package:fluentdeck/screens/learn_screen/shared_decks_screen.dart';
import 'package:fluentdeck/screens/learn_screen/note_types_screen.dart';
import 'package:fluentdeck/screens/learn_screen/widgets/decks_overflow_menu.dart';
import 'package:fluentdeck/services/deck_order_store.dart';
import 'package:fluentdeck/services/deck_backup_service.dart';
import 'package:fluentdeck/services/flashcard_export_service.dart';
import 'package:fluentdeck/services/flashcard_import_service.dart';
import 'package:fluentdeck/services/flashcard_service.dart';
import 'package:fluentdeck/services/flashcard_sync_service.dart';
import 'package:fluentdeck/ui_elements/app_skeletons.dart';
import 'package:fluentdeck/ui_elements/frosted_bottom_sheet.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';
import 'package:fluentdeck/widgets/swipe_action_backgrounds.dart';

class _DeckRow {
  const _DeckRow({required this.deck, required this.depth});

  final FlashcardDeckModel deck;
  final int depth;
}

List<_DeckRow> _orderedDeckRows(List<FlashcardDeckModel> decks) {
  final children = <int?, List<FlashcardDeckModel>>{};
  for (final deck in decks) {
    children.putIfAbsent(deck.parentDeckId, () => []).add(deck);
  }
  for (final list in children.values) {
    list.sort((a, b) {
      if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
      if (a.isFiltered != b.isFiltered) return a.isFiltered ? 1 : -1;
      return a.name.compareTo(b.name);
    });
  }

  final rows = <_DeckRow>[];
  void walk(int? parentId, int depth) {
    for (final deck in children[parentId] ?? const <FlashcardDeckModel>[]) {
      rows.add(_DeckRow(deck: deck, depth: depth));
      if (!deck.isFiltered) walk(deck.id, depth + 1);
    }
  }

  walk(null, 0);
  return rows;
}

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key, this.enableDeckSwipeActions = false});

  /// When false, horizontal swipes change tabs instead of study/delete on decks.
  final bool enableDeckSwipeActions;

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  static const _dragColumnWidth = 32.0;

  bool _loading = true;
  String? _error;
  List<FlashcardDeckModel> _decks = const [];
  List<_DeckRow> _deckRows = const [];
  FlashcardStudyStats? _stats;
  final _sync = FlashcardSyncService.instance;

  @override
  void initState() {
    super.initState();
    _sync.addListener(_onSyncChanged);
    _load();
  }

  @override
  void dispose() {
    _sync.removeListener(_onSyncChanged);
    super.dispose();
  }

  void _onSyncChanged() {
    if (mounted) setState(() {});
  }

  Widget _deckReorderProxy(Widget child, int index, Animation<double> animation) {
    final width = MediaQuery.sizeOf(context).width - 32;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = Curves.easeOut.transform(animation.value);
        return Material(
          color: AppPageColors.cardBg,
          elevation: 4 * t,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: width,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Future<List<_DeckRow>> _deckRowsWithStoredOrder(
    List<FlashcardDeckModel> decks,
  ) async {
    final baseRows = _orderedDeckRows(decks);
    final stored = await DeckOrderStore.instance.load();
    return DeckOrderStore.applyOrder(
      items: baseRows,
      orderedIds: stored,
      idFor: (row) => row.deck.id,
    );
  }

  void _onDeckReorder(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    var target = newIndex;
    if (target > oldIndex) target -= 1;
    _scheduleDeckOrderMutation(oldIndex, target);
  }

  void _scheduleDeckOrderMutation(int oldIndex, int targetIndex) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (oldIndex < 0 ||
          targetIndex < 0 ||
          oldIndex >= _deckRows.length ||
          targetIndex >= _deckRows.length ||
          oldIndex == targetIndex) {
        return;
      }
      setState(() {
        final moved = _deckRows.removeAt(oldIndex);
        _deckRows.insert(targetIndex, moved);
      });
      final ids = _deckRows.map((row) => row.deck.id).toList();
      await DeckOrderStore.instance.save(ids);
    });
  }

  Widget _deckDragHandle(int index) {
    return SizedBox(
      width: _dragColumnWidth,
      child: ReorderableDragStartListener(
        index: index,
        child: Tooltip(
          message: 'Drag to reorder',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Center(
                  child: Icon(
                    Icons.drag_indicator_rounded,
                    size: 20,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _sync.refreshStatus();
      final decks = await FlashcardService.instance.fetchDecksWithCache();
      FlashcardStudyStats? stats;
      try {
        stats = await FlashcardService.instance.fetchStats();
      } catch (_) {}
      if (!mounted) return;
      final deckRows = await _deckRowsWithStoredOrder(decks);
      setState(() {
        _decks = decks;
        _deckRows = deckRows;
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final cached = await FlashcardService.instance.fetchDecksWithCache();
      final deckRows = await _deckRowsWithStoredOrder(cached);
      setState(() {
        _decks = cached;
        _deckRows = deckRows;
        _error = cached.isEmpty ? e.toString() : null;
        _loading = false;
      });
      await _sync.refreshStatus(onlineHint: false);
    }
  }

  Future<void> _manualSync() async {
    final result = await _sync.syncNow();
    if (!mounted) return;
    if (result.success) {
      final decks = await FlashcardService.instance.fetchDecksWithCache();
      FlashcardStudyStats? stats;
      try {
        stats = await FlashcardService.instance.fetchStats();
      } catch (_) {}
      final deckRows = await _deckRowsWithStoredOrder(decks);
      setState(() {
        _decks = decks;
        _deckRows = deckRows;
        _stats = stats;
      });
      await FlashcardSyncService.showConflictDialogIfNeeded(
        context,
        skipped: result.skipped,
      );
      if (!mounted) return;
      final msg =
          result.applied > 0
              ? 'Synced ${result.applied} review${result.applied == 1 ? '' : 's'}'
              : result.incremental
              ? 'Incremental sync complete'
              : 'Up to date';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offline — changes will sync when connected')),
      );
    }
  }

  Future<void> _openSharedDecks() async {
    final imported = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => SharedDecksScreen(decks: _decks),
      ),
    );
    if (imported == true && mounted) await _load();
  }

  Future<void> _startReview({int? deckId}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReviewSessionScreen(deckId: deckId),
      ),
    );
    await _load();
  }

  Future<void> _addNote() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CardEditScreen()),
    );
    if (saved == true && mounted) await _load();
  }

  Future<void> _createDeck() async {
    final name = await showAppPromptDialog(
      context,
      title: 'New deck',
      subtitle: 'New collection for your cards',
      icon: Icons.folder_outlined,
      fieldLabel: 'Deck name',
      hintText: 'e.g. Travel vocabulary',
      confirmLabel: 'Create',
    );
    if (name == null) return;

    try {
      await FlashcardService.instance.createDeck(name: name);
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _createFilteredDeck() async {
    final deck = await showFilteredDeckDialog(context, decks: _decks);
    if (deck != null && mounted) {
      await _load();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created filtered deck "${deck.name}"')),
      );
    }
  }

  Future<void> _showFabMenu() async {
    final action = await showFrostedBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.48,
          minChildSize: 0.34,
          maxChildSize: 0.62,
          builder: (context, scrollController) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppSheetHandle(),
                const AppSheetHeader(
                  title: 'Add',
                  subtitle: 'Create notes, decks, or import content',
                  icon: Icons.add_circle_outline_rounded,
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      AppSheetActionTile(
                        icon: Icons.note_add_outlined,
                        title: 'Add note',
                        subtitle: 'Create a new flashcard note',
                        onTap: () => Navigator.pop(ctx, 'note'),
                      ),
                      AppSheetActionTile(
                        icon: Icons.folder_outlined,
                        title: 'Create deck',
                        subtitle: 'New collection for your cards',
                        onTap: () => Navigator.pop(ctx, 'deck'),
                      ),
                      AppSheetActionTile(
                        icon: Icons.filter_list_rounded,
                        title: 'Filtered deck',
                        subtitle: 'Study cards matching a saved search',
                        onTap: () => Navigator.pop(ctx, 'filtered'),
                      ),
                      AppSheetActionTile(
                        icon: Icons.public_outlined,
                        title: 'Shared decks',
                        subtitle: 'Browse community decks or import a deck file',
                        onTap: () => Navigator.pop(ctx, 'shared'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    switch (action) {
      case 'note':
        await _addNote();
      case 'deck':
        await _createDeck();
      case 'filtered':
        await _createFilteredDeck();
      case 'shared':
        await _openSharedDecks();
    }
  }

  Future<void> _createBackup() async {
    try {
      await DeckBackupService.instance.performBackup();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup created')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _restoreBackup() async {
    try {
      final result = await pickAndImportFlashcards(
        context,
        format: FlashcardImportFormat.json,
      );
      if (result != null && mounted) {
        await showImportResultSnackBar(context, result);
        await _load();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _openManageNoteTypes() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NoteTypesScreen()),
    );
  }

  Future<void> _showOverflowMenu() async {
    await DecksOverflowMenu.show(
      context,
      onCreateBackup: _createBackup,
      onRestoreBackup: _restoreBackup,
      onManageNoteTypes: _openManageNoteTypes,
      onImport: _importDeck,
      onExport: _exportDeck,
      onReload: _load,
    );
  }

  Future<void> _importDeck() async {
    await showFlashcardImportSheet(
      context,
      decks: _decks,
      onImported: _load,
    );
  }

  Future<void> _exportDeck() async {
    try {
      final format = await showFlashcardExportSheet(context);
      if (!mounted || format == null) return;

      final exporter = FlashcardExportService.instance;
      switch (format) {
        case 'apkg':
          await exporter.exportApkg();
        case 'json':
          await exporter.exportJsonFile();
        case 'csv':
        case 'excel':
        case 'pdf':
        case 'share':
          final data = await FlashcardService.instance.exportJson();
          if (data == null) return;
          switch (format) {
            case 'csv':
              await exporter.exportCsv(data);
            case 'excel':
              await exporter.exportExcel(data);
            case 'pdf':
              await exporter.exportPdf(data);
            case 'share':
              await exporter.shareExport(data);
            default:
              break;
          }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            format == 'share'
                ? 'Share sheet opened'
                : 'Export started — check downloads or share sheet',
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

  Future<void> _deleteDeck(FlashcardDeckModel deck) async {
    if (!deck.isDeletable) return;

    final message =
        deck.isFiltered
            ? 'Delete filtered deck "${deck.name}"? Cards stay in their original decks.'
            : 'Delete "${deck.name}" and all ${deck.total} cards in it? This cannot be undone.';

    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete deck?'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (ok != true) return;

    try {
      await FlashcardService.instance.deleteDeck(deck.id);
      if (!mounted) return;
      await _load();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted "${deck.name}"')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _editDeck(FlashcardDeckModel deck) async {
    final saved = await showDeckEditSheet(
      context,
      deck: deck,
      allDecks: _decks,
    );
    if (saved == true && mounted) await _load();
  }

  Future<void> _showDeckOptions(FlashcardDeckModel deck) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    deck.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.play_arrow),
                  title: const Text('Study'),
                  onTap: () => Navigator.pop(ctx, 'study'),
                ),
                ListTile(
                  leading: const Icon(Icons.folder_open_outlined),
                  title: const Text('Deck overview'),
                  onTap: () => Navigator.pop(ctx, 'overview'),
                ),
                ListTile(
                  leading: const Icon(Icons.sync),
                  title: const Text('Sync now'),
                  onTap: () => Navigator.pop(ctx, 'sync'),
                ),
                if (!deck.isFiltered)
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text('Edit deck'),
                    onTap: () => Navigator.pop(ctx, 'edit'),
                  ),
                if (deck.isDeletable)
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded, color: AppColors.redWrong),
                    title: const Text('Delete deck', style: TextStyle(color: AppColors.redWrong)),
                    onTap: () => Navigator.pop(ctx, 'delete'),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
    );

    switch (action) {
      case 'study':
        await _startReview(deckId: deck.id);
      case 'overview':
        _openOverview(deck);
      case 'sync':
        await _manualSync();
      case 'edit':
        await _editDeck(deck);
      case 'delete':
        await _deleteDeck(deck);
    }
  }

  void _openOverview(FlashcardDeckModel deck) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => DeckOverviewScreen(deck: deck, allDecks: _decks),
      ),
    );
    if (changed == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const DecksListSkeleton();
    }

    if (_error != null) {
      return AppPageBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey.shade500),
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    final stats = _stats;
    final dueSummary = stats != null ? '${stats.dueNow} due' : '';

    return AppPageBackground(
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primaryPurple,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                    children: [
                      if (stats != null) ...[
                        _StatsCard(stats: stats, onReview: () => _startReview()),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Decks',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (dueSummary.isNotEmpty)
                                Text(
                                  dueSummary,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _SyncStatusButton(
                                status: _sync.status,
                                syncing: _sync.syncing,
                                onPressed: _manualSync,
                              ),
                              IconButton(
                                tooltip: 'Decks menu',
                                onPressed: _showOverflowMenu,
                                icon: Icon(
                                  Icons.more_vert,
                                  size: 22,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_decks.isEmpty)
                        const AppEmptyHint(
                          text:
                              'No decks yet. Save words or take notes to auto-create cards.',
                        )
                      else
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          buildDefaultDragHandles: false,
                          itemCount: _deckRows.length,
                          onReorder: _onDeckReorder,
                          proxyDecorator: _deckReorderProxy,
                          itemBuilder: (context, index) {
                            final row = _deckRows[index];
                            return _DeckListTile(
                              key: ValueKey('deck-row-${row.deck.id}'),
                              deck: row.deck,
                              depth: row.depth,
                              dragHandle: _deckDragHandle(index),
                              enableSwipeActions: widget.enableDeckSwipeActions,
                              onShowOptions: () => _showDeckOptions(row.deck),
                              onStudy: () => _startReview(deckId: row.deck.id),
                              onDelete:
                                  row.deck.isDeletable
                                      ? () => _deleteDeck(row.deck)
                                      : null,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              _TodayFooter(stats: stats),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 56,
            child: FloatingActionButton.extended(
              onPressed: _showFabMenu,
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncStatusButton extends StatelessWidget {
  const _SyncStatusButton({
    required this.status,
    required this.syncing,
    required this.onPressed,
  });

  final FlashcardSyncStatus status;
  final bool syncing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final (icon, color, tooltip) = switch (status) {
      FlashcardSyncStatus.synced => (
        Icons.cloud_done_outlined,
        AppColors.primaryPurple,
        'Synced — tap to refresh',
      ),
      FlashcardSyncStatus.pending => (
        Icons.cloud_upload_outlined,
        Colors.orange.shade700,
        'Pending sync — tap to upload',
      ),
      FlashcardSyncStatus.offline => (
        Icons.cloud_off_outlined,
        Colors.grey.shade600,
        'Offline — tap to retry sync',
      ),
    };

    return IconButton(
      tooltip: tooltip,
      onPressed: syncing ? null : onPressed,
      icon:
          syncing
              ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
              : Icon(icon, size: 22, color: color),
    );
  }
}

class _DeckListTile extends StatelessWidget {
  const _DeckListTile({
    super.key,
    required this.deck,
    required this.depth,
    required this.dragHandle,
    required this.onShowOptions,
    required this.onStudy,
    this.enableSwipeActions = false,
    this.onDelete,
  });

  final FlashcardDeckModel deck;
  final int depth;
  final Widget dragHandle;
  final bool enableSwipeActions;
  final VoidCallback onShowOptions;
  final VoidCallback onStudy;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final tile = Material(
      color: AppPageColors.cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onShowOptions,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.primaryPurple.withValues(alpha: 0.06),
        highlightColor: AppColors.primaryPurple.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              dragHandle,
              SizedBox(width: depth * 16.0),
              if (deck.isFiltered) ...[
                Icon(
                  Icons.filter_list,
                  size: 18,
                  color: AppColors.primaryPurple.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  deck.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DeckCountButtons(
                newCount: deck.newCount,
                learningCount: deck.learningCount,
                reviewCount: deck.reviewDueCount,
              ),
            ],
          ),
        ),
      ),
    );

    if (!enableSwipeActions) {
      return Padding(padding: const EdgeInsets.only(bottom: 8), child: tile);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey('deck-${deck.id}'),
        direction:
            onDelete != null
                ? DismissDirection.horizontal
                : DismissDirection.startToEnd,
        background: SwipeActionBackgrounds.study(
          borderRadius: BorderRadius.circular(16),
        ),
        secondaryBackground:
            onDelete != null
                ? SwipeActionBackgrounds.delete(
                    borderRadius: BorderRadius.circular(16),
                  )
                : null,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            onStudy();
          } else if (direction == DismissDirection.endToStart && onDelete != null) {
            onDelete!();
          }
          return false;
        },
        child: tile,
      ),
    );
  }
}

class _TodayFooter extends StatelessWidget {
  const _TodayFooter({required this.stats});

  final FlashcardStudyStats? stats;

  @override
  Widget build(BuildContext context) {
    final reviews = stats?.todayReviews ?? 0;
    final duration = stats?.todayDurationLabel ?? '0m';
    final streak = stats?.reviewStreakDays ?? 0;

    final summary =
        reviews > 0
            ? 'Studied $reviews card${reviews == 1 ? '' : 's'} in $duration today'
            : 'Studied 0 cards today';

    final streakText = streak > 0 ? ' · 🔥 $streak day streak' : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppPageColors.cardBg,
        border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.06))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.today_outlined, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '$summary$streakText',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats, required this.onReview});

  final FlashcardStudyStats stats;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final subtitle = stats.reviewStreakDays > 0
        ? '🔥 ${stats.reviewStreakDays} day review streak'
        : 'Tap Study now to begin your session';

    return AppHeroCard(
      value: '${stats.dueNow}',
      label: stats.dueNow == 1 ? 'card due' : 'cards due',
      subtitle: subtitle,
      icon: Icons.play_circle_outline_rounded,
      badge: stats.newCards > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${stats.newCards} new',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
      action: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onReview,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primaryPurple,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            'Study now',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
