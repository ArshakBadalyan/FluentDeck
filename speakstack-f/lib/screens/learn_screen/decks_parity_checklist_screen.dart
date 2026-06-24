import 'package:flutter/material.dart';
import 'package:speakstack/app_colors.dart';
import 'package:speakstack/services/decks_parity_checklist_store.dart';

/// Interactive AnkiDroid parity QA checklist (Step 8).
class DecksParityChecklistScreen extends StatefulWidget {
  const DecksParityChecklistScreen({super.key});

  @override
  State<DecksParityChecklistScreen> createState() => _DecksParityChecklistScreenState();
}

class _DecksParityChecklistScreenState extends State<DecksParityChecklistScreen> {
  Set<String> _checked = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final checked = await DecksParityChecklistStore.instance.loadChecked();
    if (!mounted) return;
    setState(() {
      _checked = checked;
      _loading = false;
    });
  }

  Future<void> _toggle(String id, bool value) async {
    final next = Set<String>.from(_checked);
    if (value) {
      next.add(id);
    } else {
      next.remove(id);
    }
    setState(() => _checked = next);
    await DecksParityChecklistStore.instance.saveChecked(next);
  }

  Future<void> _reset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Reset checklist?'),
            content: const Text('All checkmarks will be cleared.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset')),
            ],
          ),
    );
    if (ok != true) return;
    await DecksParityChecklistStore.instance.reset();
    if (!mounted) return;
    setState(() => _checked = {});
  }

  @override
  Widget build(BuildContext context) {
    final total = decksParityChecklistTotalItems();
    final done = _checked.length;
    final pct = total == 0 ? 0.0 : done / total;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parity checklist'),
        actions: [
          IconButton(
            tooltip: 'Reset',
            onPressed: _reset,
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$done / $total verified',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: pct,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                            color: AppColors.primaryPurple,
                            backgroundColor: AppColors.primaryPurple.withValues(alpha: 0.12),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Manual QA for AnkiDroid parity. Check each item on Web and Android.',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...decksParityChecklist.map(_section),
                ],
              ),
    );
  }

  Widget _section(DecksParityCheckSection section) {
    final sectionDone = section.items.where((i) => _checked.contains(i.id)).length;

    return ExpansionTile(
      initiallyExpanded: sectionDone < section.items.length,
      title: Text(section.title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('$sectionDone / ${section.items.length}'),
      children:
          section.items
              .map(
                (item) => CheckboxListTile(
                  value: _checked.contains(item.id),
                  activeColor: AppColors.primaryPurple,
                  title: Text(item.label),
                  subtitle: item.hint != null ? Text(item.hint!) : null,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (v) => _toggle(item.id, v == true),
                ),
              )
              .toList(),
    );
  }
}
