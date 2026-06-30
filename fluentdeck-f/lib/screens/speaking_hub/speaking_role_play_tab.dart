import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';

import '../../models/conversation_prompt_model.dart';
import '../../models/speaking_session_context.dart';
import '../../services/custom_role_play_service.dart';
import '../../services/speaking_content_service.dart';
import '../../services/speaking_scores_service.dart';
import '../../services/speaking_session_service.dart';
import '../../utils/speaking_item_icons.dart';
import '../../utils/speaking_premium_gate.dart';
import '../../widgets/speaking_hub_widgets.dart';

class SpeakingRolePlayTab extends StatefulWidget {
  const SpeakingRolePlayTab({super.key, required this.onStart});

  final ValueChanged<SpeakingSessionContext> onStart;

  @override
  State<SpeakingRolePlayTab> createState() => _SpeakingRolePlayTabState();
}

class _SpeakingRolePlayTabState extends State<SpeakingRolePlayTab> {
  static const _filters = [
    ('all', 'All'),
    ('custom', 'Custom'),
    ('daily_life', 'Daily life'),
    ('career', 'Career'),
    ('travel', 'Travel'),
    ('relationships', 'Relationships'),
    ('language_testing', 'Language testing'),
  ];

  int _filterIndex = 0;
  List<ConversationPromptModel> _scenarios = [];
  ConversationPromptModel? _selected;
  bool _loading = true;
  String? _error;
  Map<String, int?> _scoreCache = {};

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
      await SpeakingSessionService.instance.refreshScoresFromServer();
      final category = _filters[_filterIndex].$1;
      final catalog = await SpeakingContentService.instance
          .fetchRolePlayCatalog(category: category);
      final scenarios = catalog.items;

      final scores = <String, int?>{};
      for (final s in scenarios) {
        scores[s.referenceKey] =
            await SpeakingScoresService.instance.getScore(s.referenceKey);
      }

      if (!mounted) return;
      setState(() {
        _scenarios = scenarios;
        _selected =
            scenarios.any((s) => s.referenceKey == _selected?.referenceKey)
                ? _selected
                : firstUnlocked(scenarios, (s) => s.isPremiumLocked) ??
                    (scenarios.isNotEmpty ? scenarios.first : null);
        _scoreCache = scores;
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

  Future<void> _deleteCustom(ConversationPromptModel scenario) async {
    if (!scenario.isLocal) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete role-play?'),
            content: Text('Remove "${scenario.displayTitle}" from your device?'),
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

    if (confirmed != true || !mounted) return;
    await CustomRolePlayService.instance.delete(scenario.id);
    if (_selected?.referenceKey == scenario.referenceKey) {
      _selected = null;
    }
    await _load();
  }

  Future<void> _showCreateDialog() async {
    final titleController = TextEditingController();
    final userRoleController = TextEditingController(text: 'Customer');
    final tutorRoleController = TextEditingController(text: 'Shop assistant');
    final situationController = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Create custom role-play'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  TextField(
                    controller: userRoleController,
                    decoration: const InputDecoration(labelText: 'My role'),
                  ),
                  TextField(
                    controller: tutorRoleController,
                    decoration: const InputDecoration(labelText: "Tutor's role"),
                  ),
                  TextField(
                    controller: situationController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Situation'),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save'),
              ),
            ],
          ),
    );

    if (created != true || !mounted) {
      titleController.dispose();
      userRoleController.dispose();
      tutorRoleController.dispose();
      situationController.dispose();
      return;
    }

    final title = titleController.text.trim();
    final userRole = userRoleController.text.trim();
    final tutorRole = tutorRoleController.text.trim();
    final situation = situationController.text.trim();

    titleController.dispose();
    userRoleController.dispose();
    tutorRoleController.dispose();
    situationController.dispose();

    if (title.isEmpty || situation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and situation are required')),
      );
      return;
    }

    final prompt = await CustomRolePlayService.instance.create(
      title: title,
      userRole: userRole,
      tutorRole: tutorRole,
      situation: situation,
    );
    if (!mounted) return;
    setState(() => _filterIndex = _filters.indexWhere((f) => f.$1 == 'custom'));
    await _load();
    setState(() => _selected = prompt);
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_scenarios.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _filters[_filterIndex].$1 == 'custom'
                ? 'No custom role-plays yet.\nTap "Create custom role-play" above.'
                : 'No scenarios in this category.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primaryPurple,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _scenarios.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final scenario = _scenarios[index];
          return SpeakingSelectionCard(
            title: scenario.displayTitle,
            subtitle: scenario.rolesSubtitle,
            icon: resolveSpeakingListIcon(
              title: scenario.displayTitle,
              iconKey: scenario.iconKey,
            ),
            score: _scoreCache[scenario.referenceKey],
            selected: _selected?.referenceKey == scenario.referenceKey,
            isPremiumLocked: !scenario.isLocal && scenario.isPremiumLocked,
            trailing:
                scenario.isLocal
                    ? IconButton(
                      tooltip: 'Delete',
                      icon: Icon(Icons.delete_outline, color: Colors.grey.shade600),
                      onPressed: () => _deleteCustom(scenario),
                    )
                    : null,
            onTap: () {
              if (!scenario.isLocal && scenario.isPremiumLocked) {
                showSpeakingPremiumSnackBar(context);
                return;
              }
              setState(() => _selected = scenario);
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SpeakingFilterChips(
          labels: _filters.map((f) => f.$2).toList(),
          selectedIndex: _filterIndex,
          onSelected: (index) async {
            setState(() => _filterIndex = index);
            await _load();
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OutlinedButton.icon(
            onPressed: _showCreateDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create custom role-play'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryPurple,
              side: const BorderSide(color: AppColors.primaryPurple),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildList()),
        SpeakingStartButton(
          label: 'Start Role-Play',
          enabled: _selected != null && (!_selected!.isPremiumLocked || _selected!.isLocal),
          onPressed:
              _selected == null ||
                  (_selected!.isPremiumLocked && !_selected!.isLocal)
                  ? null
                  : () {
                    widget.onStart(
                      SpeakingContentService.instance.rolePlaySessionFrom(
                        _selected!,
                      ),
                    );
                  },
        ),
      ],
    );
  }
}
