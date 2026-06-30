import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists QA parity checklist completion (Step 8).
class DecksParityChecklistStore {
  DecksParityChecklistStore._();
  static final DecksParityChecklistStore instance = DecksParityChecklistStore._();

  static const _key = 'decks_parity_checklist_v1';

  Future<Set<String>> loadChecked() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    try {
      final list = jsonDecode(raw) as List? ?? [];
      return list.map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> saveChecked(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(ids.toList()..sort()));
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

class DecksParityCheckItem {
  const DecksParityCheckItem({
    required this.id,
    required this.label,
    this.hint,
  });

  final String id;
  final String label;
  final String? hint;
}

class DecksParityCheckSection {
  const DecksParityCheckSection({
    required this.id,
    required this.title,
    required this.items,
  });

  final String id;
  final String title;
  final List<DecksParityCheckItem> items;
}

/// Screen-by-screen AnkiDroid parity QA checklist.
const decksParityChecklist = <DecksParityCheckSection>[
  DecksParityCheckSection(
    id: 'decks',
    title: 'Decks tab',
    items: [
      DecksParityCheckItem(
        id: 'decks_tabs',
        label: 'Two tabs: Decks, Card browser',
      ),
      DecksParityCheckItem(
        id: 'decks_fab',
        label: 'FAB: Add note, Create deck, Filtered deck, Get shared decks',
      ),
      DecksParityCheckItem(
        id: 'decks_overflow',
        label: 'Overflow ⋮: Check, backup, restore, note types, import, export',
      ),
      DecksParityCheckItem(
        id: 'decks_check',
        label: 'Check submenu: database, media, empty cards',
      ),
      DecksParityCheckItem(
        id: 'decks_counts',
        label: 'Blue / red / green count buttons on deck rows',
      ),
      DecksParityCheckItem(
        id: 'decks_sync',
        label: 'Cloud sync indicator and manual sync',
      ),
      DecksParityCheckItem(
        id: 'decks_footer',
        label: 'Footer today summary after reviews',
      ),
    ],
  ),
  DecksParityCheckSection(
    id: 'browser',
    title: 'Card browser',
    items: [
      DecksParityCheckItem(
        id: 'browser_options',
        label: 'Options ⋮: sort, filter, preview, select mode, filtered deck',
      ),
      DecksParityCheckItem(
        id: 'browser_sort',
        label: 'Sortable column headers (Question, Type, Due, Deck)',
      ),
      DecksParityCheckItem(
        id: 'browser_row_menu',
        label: 'Row ⋮: info, suspend, bury, tags, due, reset, grade, export, flags',
      ),
      DecksParityCheckItem(
        id: 'browser_bulk',
        label: 'Bulk Actions: suspend, bury, deck, tags, export, delete notes',
      ),
      DecksParityCheckItem(
        id: 'browser_undo_tag',
        label: 'Undo tag change (single and bulk)',
      ),
    ],
  ),
  DecksParityCheckSection(
    id: 'statistics',
    title: 'Statistics',
    items: [
      DecksParityCheckItem(
        id: 'stats_scope',
        label: 'Scope: Collection or Deck: name; range labels',
      ),
      DecksParityCheckItem(
        id: 'stats_sections',
        label: 'Charts in Anki order (Today → Future due → … → Review log)',
      ),
      DecksParityCheckItem(
        id: 'stats_pdf',
        label: 'Export PDF with readable scope/range',
      ),
      DecksParityCheckItem(
        id: 'stats_data',
        label: 'Real data after reviews (not empty stubs)',
      ),
    ],
  ),
  DecksParityCheckSection(
    id: 'settings',
    title: 'Settings',
    items: [
      DecksParityCheckItem(
        id: 'settings_hub',
        label: '11 sections: General, New study, Reviewing, Sync, … About',
      ),
      DecksParityCheckItem(
        id: 'settings_theme',
        label: 'App-wide theme (System / Light / Dark)',
      ),
      DecksParityCheckItem(
        id: 'settings_study',
        label: 'New card position and learn-ahead affect queue',
      ),
      DecksParityCheckItem(
        id: 'settings_sync',
        label: 'Sync section shows last sync and errors',
      ),
    ],
  ),
  DecksParityCheckSection(
    id: 'review',
    title: 'Review session',
    items: [
      DecksParityCheckItem(
        id: 'review_gestures',
        label: 'Configurable swipe / double-tap gestures',
      ),
      DecksParityCheckItem(
        id: 'review_undo',
        label: 'Undo last answer',
      ),
      DecksParityCheckItem(
        id: 'review_offline',
        label: 'Offline study queues pending sync upload',
      ),
      DecksParityCheckItem(
        id: 'review_leech',
        label: 'Leech auto-suspend notification',
      ),
    ],
  ),
  DecksParityCheckSection(
    id: 'platform',
    title: 'Platform QA',
    items: [
      DecksParityCheckItem(
        id: 'qa_web',
        label: 'Web (Chrome): deck list, study, browser, stats, settings',
      ),
      DecksParityCheckItem(
        id: 'qa_android',
        label: 'Android: same flows + daily reminder notification',
      ),
      DecksParityCheckItem(
        id: 'qa_sync_conflict',
        label: 'Sync conflict: server wins dialog when applicable',
      ),
      DecksParityCheckItem(
        id: 'qa_import_export',
        label: 'Import CSV/TXT/APKG/JSON and export JSON/APKG',
      ),
    ],
  ),
];

int decksParityChecklistTotalItems() =>
    decksParityChecklist.fold(0, (n, s) => n + s.items.length);
