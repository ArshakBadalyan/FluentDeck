import 'package:flutter/material.dart';
import 'package:speakstack/data/flashcard_offline_store.dart';
import 'package:speakstack/services/flashcard_service.dart';
import 'package:speakstack/services/flashcard_sync_store.dart';

/// Sync state for the Decks tab indicator (Phase 5E).
enum FlashcardSyncStatus {
  synced,
  pending,
  offline,
}

class FlashcardSyncResult {
  final bool success;
  final int applied;
  final int skipped;
  final bool incremental;

  const FlashcardSyncResult({
    required this.success,
    this.applied = 0,
    this.skipped = 0,
    this.incremental = false,
  });
}

class FlashcardSyncService extends ChangeNotifier {
  FlashcardSyncService._();
  static final FlashcardSyncService instance = FlashcardSyncService._();

  FlashcardSyncStatus _status = FlashcardSyncStatus.synced;
  bool _syncing = false;
  FlashcardSyncLog _log = const FlashcardSyncLog();

  FlashcardSyncStatus get status => _status;
  bool get syncing => _syncing;
  FlashcardSyncLog get log => _log;

  Future<void> loadLog() async {
    _log = await FlashcardSyncStore.instance.load();
    notifyListeners();
  }

  Future<void> refreshStatus({bool? onlineHint}) async {
    final pending = await FlashcardOfflineStore.instance.pendingReviewCount();
    final online = onlineHint ?? await _probeOnline();

    if (!online) {
      _status =
          pending > 0 ? FlashcardSyncStatus.pending : FlashcardSyncStatus.offline;
    } else if (pending > 0) {
      _status = FlashcardSyncStatus.pending;
    } else {
      _status = FlashcardSyncStatus.synced;
    }
    await loadLog();
  }

  Future<bool> _probeOnline() async {
    try {
      await FlashcardService.instance.fetchStats();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<FlashcardSyncResult> syncNow() async {
    if (_syncing) {
      return const FlashcardSyncResult(success: false);
    }
    _syncing = true;
    notifyListeners();

    try {
      final result = await FlashcardService.instance.syncAll();
      await refreshStatus(onlineHint: result.online);
      return FlashcardSyncResult(
        success: result.online,
        applied: result.applied,
        skipped: result.skipped,
        incremental: result.incremental,
      );
    } catch (_) {
      await refreshStatus(onlineHint: false);
      return const FlashcardSyncResult(success: false);
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  void markPending() {
    _status = FlashcardSyncStatus.pending;
    notifyListeners();
  }

  static Future<void> showConflictDialogIfNeeded(
    BuildContext context, {
    required int skipped,
  }) async {
    if (skipped <= 0 || !context.mounted) return;
    await showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Sync conflicts'),
            content: Text(
              skipped == 1
                  ? '1 local review was skipped because the server already had a newer review. Server data wins for conflicting cards.'
                  : '$skipped local reviews were skipped because the server already had newer data. Server data wins for conflicting cards.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          ),
    );
  }
}
