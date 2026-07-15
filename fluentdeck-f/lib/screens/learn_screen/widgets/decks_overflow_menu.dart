import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/services/flashcard_maintenance_service.dart';
import 'package:fluentdeck/ui_elements/frosted_bottom_sheet.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';

/// Shows check / maintenance result dialog.
Future<void> showFlashcardCheckResultDialog(
  BuildContext context,
  FlashcardCheckResult result,
) async {
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder:
        (ctx) => Dialog(
          backgroundColor: AppPageColors.cardBgOf(ctx),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (result.ok ? AppColors.greenCorrect : AppColors.redWrong)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        result.ok ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                        color: result.ok ? AppColors.greenCorrect : AppColors.redWrong,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        result.ok ? 'Check complete' : 'Issues found',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(result.summary),
                        if (result.details.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ...result.details.map(
                            (d) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                '• $d',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                    ),
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
          ),
        ),
  );
}

Future<bool?> _showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  bool destructive = true,
}) {
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder:
        (ctx) => Dialog(
          backgroundColor: AppPageColors.cardBgOf(ctx),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(message, style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('Cancel', style: TextStyle(color: AppColors.primaryPurple)),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            destructive ? AppColors.redWrong : AppColors.primaryPurple,
                      ),
                      child: Text(confirmLabel),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
  );
}

Future<void> _showInfoDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder:
        (ctx) => Dialog(
          backgroundColor: AppPageColors.cardBgOf(ctx),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(message, style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                    ),
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
          ),
        ),
  );
}

/// Deck list overflow menu.
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
    final action = await showFrostedBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.58,
          minChildSize: 0.38,
          maxChildSize: 0.82,
          builder: (context, scrollController) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppSheetHandle(),
                const AppSheetHeader(
                  title: 'Decks menu',
                  subtitle: 'Backup, import, export, and maintenance',
                  icon: Icons.more_horiz_rounded,
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      AppSheetActionTile(
                        icon: Icons.fact_check_outlined,
                        title: 'Check',
                        subtitle: 'Database, media, empty cards',
                        onTap: () => Navigator.pop(ctx, 'check'),
                      ),
                      AppSheetActionTile(
                        icon: Icons.backup_outlined,
                        title: 'Create backup',
                        subtitle: 'Save a JSON snapshot of your collection',
                        onTap: () => Navigator.pop(ctx, 'backup'),
                      ),
                      AppSheetActionTile(
                        icon: Icons.restore_outlined,
                        title: 'Restore from backup',
                        subtitle: 'Merge cards from a previous export',
                        onTap: () => Navigator.pop(ctx, 'restore'),
                      ),
                      AppSheetActionTile(
                        icon: Icons.category_outlined,
                        title: 'Manage note types',
                        subtitle: 'Edit fields and templates',
                        onTap: () => Navigator.pop(ctx, 'note_types'),
                      ),
                      AppSheetActionTile(
                        icon: Icons.upload_outlined,
                        title: 'Import',
                        subtitle: 'CSV, TXT, .apkg, or JSON backup',
                        onTap: () => Navigator.pop(ctx, 'import'),
                      ),
                      AppSheetActionTile(
                        icon: Icons.download_outlined,
                        title: 'Export',
                        subtitle: 'CSV, Excel, PDF, .apkg, or JSON',
                        onTap: () => Navigator.pop(ctx, 'export'),
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
    final action = await showFrostedBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.52,
          minChildSize: 0.38,
          maxChildSize: 0.75,
          builder: (context, scrollController) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppSheetHandle(),
                const AppSheetHeader(
                  title: 'Check',
                  subtitle: 'Verify collection health and clean up',
                  icon: Icons.fact_check_outlined,
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      AppSheetActionTile(
                        icon: Icons.playlist_add_check_rounded,
                        title: 'Check all',
                        subtitle: 'Database + media + empty cards',
                        onTap: () => Navigator.pop(ctx, 'all'),
                      ),
                      AppSheetActionTile(
                        icon: Icons.storage_outlined,
                        title: 'Check database',
                        subtitle: 'Validate notes, cards, and deck links',
                        onTap: () => Navigator.pop(ctx, 'database'),
                      ),
                      AppSheetActionTile(
                        icon: Icons.perm_media_outlined,
                        title: 'Check media',
                        subtitle: 'Find missing or broken image/audio files',
                        onTap: () => Navigator.pop(ctx, 'media'),
                      ),
                      AppSheetActionTile(
                        icon: Icons.layers_clear_outlined,
                        title: 'Empty cards',
                        subtitle: 'Find and delete cards with no content',
                        onTap: () => Navigator.pop(ctx, 'empty'),
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
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder:
          (_) => Dialog(
            backgroundColor: AppPageColors.cardBgOf(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: const Padding(
              padding: EdgeInsets.all(28),
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primaryPurple,
                  ),
                ),
              ),
            ),
          ),
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
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder:
          (_) => Dialog(
            backgroundColor: AppPageColors.cardBgOf(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: const Padding(
              padding: EdgeInsets.all(28),
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primaryPurple,
                  ),
                ),
              ),
            ),
          ),
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
      await _showInfoDialog(
        context,
        title: 'Empty cards',
        message: 'No empty cards found.',
      );
      return;
    }

    final delete = await _showConfirmDialog(
      context,
      title: 'Empty cards',
      message:
          'Found ${result.count} empty card${result.count == 1 ? '' : 's'}. '
          'Delete them? This cannot be undone.',
      confirmLabel: 'Delete',
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
