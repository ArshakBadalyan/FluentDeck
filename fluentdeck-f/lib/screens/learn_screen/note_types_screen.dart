import 'package:riovox/ui_elements/app_dialog.dart';
import 'package:riovox/ui_elements/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:riovox/app_colors.dart';
import 'package:riovox/models/flashcard_note_model.dart';
import 'package:riovox/screens/learn_screen/note_type_edit_screen.dart';
import 'package:riovox/services/flashcard_service.dart';
import 'package:riovox/ui_elements/modern_page_widgets.dart';
import 'package:riovox/ui_elements/app_motion.dart';

/// Built-in and custom note types — the field/template layouts that define
/// how a note's data is turned into cards.
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
    // Card style (built-in types) saves on tap, so there is no result to wait for.
    if (changed == true || (existing != null && !existing.isCustom)) _load();
  }

  Future<void> _deleteType(NoteTypeModel type) async {
    final id = type.customDbId;
    if (id == null) return;

    final confirmed = await showAppDialog<bool>(
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
                style: FilledButton.styleFrom(backgroundColor: AppColors.redWrong),
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
      AppToast.showSnackBar(context, SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPageColors.pageBgOf(context),
      appBar: AppBar(
        backgroundColor: AppPageColors.pageBgOf(context),
        foregroundColor: AppPageColors.textPrimaryOf(context),
        elevation: 0,
        title: const Text('Note types'),
      ),
      // The FAB grows into the editor (container transform).
      floatingActionButton: AppFabContainer<bool>(
        extended: true,
        fab: FloatingActionButton.extended(
          onPressed: () {},
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Custom type'),
        ),
        openBuilder: (_) => const NoteTypeEditScreen(),
        onClosed: (changed) {
          if (changed == true) _load();
        },
      ),
      body: AppPageBackground(child: _body()),
    );
  }

  Widget _body() {
    if (_loading) {
      return AppLoadingSwitcher(
      loading: true,
      child: const _NoteTypesSkeleton(),
    );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 40, color: AppPageColors.subtitleOf(context)),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppPageColors.subtitleOf(context)),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _load,
                style: FilledButton.styleFrom(backgroundColor: AppColors.brandPrimary),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_types.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.dashboard_customize_outlined,
                  size: 32,
                  color: AppColors.brandPrimary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No note types yet',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a custom type to define your own fields and card templates.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppPageColors.subtitleOf(context), height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return AppLoadingSwitcher(
      loading: false,
      child: ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: _types.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) => _NoteTypeCard(
        type: _types[i],
        onTap: () => _openEditor(existing: _types[i]),
        onDelete: _types[i].isCustom ? () => _deleteType(_types[i]) : null,
      ),
    ),
    );
  }
}

class _NoteTypeCard extends StatelessWidget {
  const _NoteTypeCard({required this.type, this.onTap, this.onDelete});

  final NoteTypeModel type;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPageColors.cardBgOf(context),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppPageColors.subtleBorderOf(context)),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.dashboard_customize_outlined,
                      size: 18,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      type.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (type.isCustom) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.greenCorrect.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Custom',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.greenCorrect,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded, size: 20, color: AppPageColors.subtitleOf(context)),
                      tooltip: 'Delete',
                      onPressed: onDelete,
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Style',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandPrimary,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 20, color: AppPageColors.subtitleOf(context)),
                  ],
                ],
              ),
              if (type.cardTemplateNames.isNotEmpty || type.fields.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final name in type.cardTemplateNames)
                      _MetaChip(icon: Icons.style_outlined, label: name),
                    for (final field in type.fields)
                      _MetaChip(icon: Icons.text_fields_rounded, label: field.name, muted: true),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label, this.muted = false});

  final IconData icon;
  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: muted ? AppPageColors.fieldBgOf(context) : AppColors.brandPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: muted ? AppPageColors.subtitleOf(context) : AppPageColors.accentOf(context)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: muted ? AppPageColors.subtitleOf(context) : AppPageColors.accentOf(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteTypesSkeleton extends StatelessWidget {
  const _NoteTypesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          height: 92,
          decoration: BoxDecoration(
            color: AppPageColors.cardBgOf(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppPageColors.subtleBorderOf(context)),
          ),
          padding: const EdgeInsets.all(16),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Bone.text(words: 2, fontSize: 16),
              SizedBox(height: 12),
              Bone(width: 140, height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
