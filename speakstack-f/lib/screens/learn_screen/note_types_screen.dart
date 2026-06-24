import 'package:flutter/material.dart';
import 'package:speakstack/app_colors.dart';
import 'package:speakstack/models/flashcard_note_model.dart';
import 'package:speakstack/screens/learn_screen/note_type_edit_screen.dart';
import 'package:speakstack/services/flashcard_service.dart';

/// Built-in and custom note types (Phase 5C).
class NoteTypesScreen extends StatefulWidget {
  const NoteTypesScreen({super.key});

  @override
  State<NoteTypesScreen> createState() => _NoteTypesScreenState();
}

class _NoteTypesScreenState extends State<NoteTypesScreen> {
  bool _loading = true;
  String? _error;
  List<NoteTypeModel> _types = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final types = await FlashcardService.instance.fetchNoteTypesWithCache();
      if (!mounted) return;
      setState(() {
        _types = types;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openEditor({NoteTypeModel? existing}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => NoteTypeEditScreen(existing: existing)),
    );
    if (changed == true) _load();
  }

  Future<void> _deleteType(NoteTypeModel type) async {
    final id = type.customDbId;
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete note type?'),
            content: Text(
              'Delete "${type.name}"? Existing notes using this type are not removed.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await FlashcardService.instance.deleteCustomNoteType(id);
      if (!mounted) return;
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
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
        title: const Text('Note types'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        backgroundColor: AppColors.primaryPurple,
        icon: const Icon(Icons.add),
        label: const Text('Custom type'),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
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
              )
              : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                itemCount: _types.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final type = _types[i];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: type.isCustom ? () => _openEditor(existing: type) : null,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    type.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (type.isCustom)
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('Custom', style: TextStyle(fontSize: 11)),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryPurple.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    type.id,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primaryPurple.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ),
                                if (type.isCustom) ...[
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20),
                                    color: Colors.red.shade400,
                                    tooltip: 'Delete',
                                    onPressed: () => _deleteType(type),
                                  ),
                                ],
                              ],
                            ),
                            if (type.cardTemplateNames.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Cards: ${type.cardTemplateNames.join(', ')}',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                              ),
                            ],
                            if (type.fields.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Fields: ${type.fields.map((f) => f.name).join(', ')}',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
