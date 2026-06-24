import 'package:flutter/material.dart';
import 'package:speakstack/app_colors.dart';
import 'package:speakstack/services/flashcard_maintenance_service.dart';

/// Shows check / maintenance result dialog.
Future<void> showFlashcardCheckResultDialog(
  BuildContext context,
  FlashcardCheckResult result,
) async {
  await showDialog<void>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: Text(result.ok ? 'Check complete' : 'Issues found'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(result.summary),
                if (result.details.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...result.details.map(
                    (d) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• $d', style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
  );
}

/// AnkiDroid-style deck list overflow menu (Step 1 parity).
class DecksOverflowMenu {
  static Future<void> show(
    BuildContext context, {
    required Future<void> Function() onCreateBackup,
    required Future<void> Function() onRestoreBackup,
    required VoidCallback onManageNoteTypes,
    required VoidCallback onImport,
    required VoidCallback onExport,
    required Future<void> Function() onReload,
  }) async {
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
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Decks menu',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.fact_check_outlined),
                  title: const Text('Check'),
                  subtitle: const Text('Database, media, empty cards'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(ctx, 'check'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: const Text('Create backup'),
                  onTap: () => Navigator.pop(ctx, 'backup'),
                ),
                ListTile(
                  leading: const Icon(Icons.restore_outlined),
                  title: const Text('Restore from backup'),
                  onTap: () => Navigator.pop(ctx, 'restore'),
                ),
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Manage note types'),
                  onTap: () => Navigator.pop(ctx, 'note_types'),
                ),
                ListTile(
                  leading: const Icon(Icons.upload_outlined),
                  title: const Text('Import'),
                  onTap: () => Navigator.pop(ctx, 'import'),
                ),
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Export'),
                  onTap: () => Navigator.pop(ctx, 'export'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
    );

    if (!context.mounted || action == null) return;

    switch (action) {
      case 'check':
        await _showCheckSubmenu(context, onReload: onReload);
      case 'backup':
        await onCreateBackup();
      case 'restore':
        await onRestoreBackup();
      case 'note_types':
        onManageNoteTypes();
      case 'import':
        onImport();
      case 'export':
        onExport();
    }
  }

  static Future<void> _showCheckSubmenu(
    BuildContext context, {
    required Future<void> Function() onReload,
  }) async {
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
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Check',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.playlist_add_check),
                  title: const Text('Check all'),
                  subtitle: const Text('Database + media + empty cards'),
                  onTap: () => Navigator.pop(ctx, 'all'),
                ),
                ListTile(
                  leading: const Icon(Icons.storage_outlined),
                  title: const Text('Check database'),
                  onTap: () => Navigator.pop(ctx, 'database'),
                ),
                ListTile(
                  leading: const Icon(Icons.perm_media_outlined),
                  title: const Text('Check media'),
                  onTap: () => Navigator.pop(ctx, 'media'),
                ),
                ListTile(
                  leading: const Icon(Icons.layers_clear_outlined),
                  title: const Text('Empty cards'),
                  onTap: () => Navigator.pop(ctx, 'empty'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
    );

    if (!context.mounted || action == null) return;

    final maintenance = FlashcardMaintenanceService.instance;

    try {
      switch (action) {
        case 'all':
          final result = await _runWithLoading(context, maintenance.checkAll);
          if (!context.mounted) return;
          await showFlashcardCheckResultDialog(context, result);
        case 'database':
          final result = await _runWithLoading(context, maintenance.checkDatabase);
          if (!context.mounted) return;
          await showFlashcardCheckResultDialog(context, result);
        case 'media':
          final result = await _runWithLoading(context, maintenance.checkMedia);
          if (!context.mounted) return;
          await showFlashcardCheckResultDialog(context, result);
        case 'empty':
          await _handleEmptyCards(context, onReload: onReload);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  static Future<FlashcardCheckResult> _runWithLoading(
    BuildContext context,
    Future<FlashcardCheckResult> Function() task,
  ) async {
    if (!context.mounted) return const FlashcardCheckResult(ok: false, summary: 'Cancelled');

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      return await task();
    } finally {
      if (context.mounted) Navigator.pop(context);
    }
  }

  static Future<void> _handleEmptyCards(
    BuildContext context, {
    required Future<void> Function() onReload,
  }) async {
    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    FlashcardEmptyCardsResult result;
    try {
      result = await FlashcardMaintenanceService.instance.findEmptyCards();
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
      return;
    }

    if (context.mounted) Navigator.pop(context);
    if (!context.mounted) return;

    if (result.count == 0) {
      await showDialog<void>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Empty cards'),
              content: const Text('No empty cards found.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
              ],
            ),
      );
      return;
    }

    final delete = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Empty cards'),
            content: Text(
              'Found ${result.count} empty card${result.count == 1 ? '' : 's'}. '
              'Delete them? This cannot be undone.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: AppColors.primaryPurple),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (delete != true || !context.mounted) return;

    try {
      final deleted = await FlashcardMaintenanceService.instance.deleteEmptyCards();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted ${deleted.deleted} empty card(s)')),
      );
      await onReload();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
