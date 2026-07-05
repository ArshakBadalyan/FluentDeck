import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';

import '../../models/conversation_prompt_model.dart';
import '../../models/speaking_session_context.dart';
import '../../services/custom_role_play_service.dart';
import '../../services/speaking_content_service.dart';
import '../../services/speaking_scores_service.dart';
import '../../services/speaking_session_service.dart';
import '../../ui_elements/frosted_bottom_sheet.dart';
import '../../ui_elements/modern_page_widgets.dart';
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
    ('business', 'Business'),
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
    final result = await showFrostedBottomSheet<_RolePlayDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => const _CreateRolePlaySheet(),
    );

    if (result == null || !mounted) return;

    final prompt = await CustomRolePlayService.instance.create(
      title: result.title,
      userRole: result.userRole,
      tutorRole: result.tutorRole,
      situation: result.situation,
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

class _RolePlayDraft {
  const _RolePlayDraft({
    required this.title,
    required this.userRole,
    required this.tutorRole,
    required this.situation,
  });

  final String title;
  final String userRole;
  final String tutorRole;
  final String situation;
}

class _CreateRolePlaySheet extends StatefulWidget {
  const _CreateRolePlaySheet();

  @override
  State<_CreateRolePlaySheet> createState() => _CreateRolePlaySheetState();
}

class _CreateRolePlaySheetState extends State<_CreateRolePlaySheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _userRoleController;
  late final TextEditingController _tutorRoleController;
  late final TextEditingController _situationController;
  String? _titleError;
  String? _situationError;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _userRoleController = TextEditingController(text: 'Customer');
    _tutorRoleController = TextEditingController(text: 'Shop assistant');
    _situationController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _userRoleController.dispose();
    _tutorRoleController.dispose();
    _situationController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    final situation = _situationController.text.trim();
    setState(() {
      _titleError = title.isEmpty ? 'Give your role-play a title' : null;
      _situationError = situation.isEmpty ? 'Describe the situation' : null;
    });
    if (_titleError != null || _situationError != null) return;

    Navigator.pop(
      context,
      _RolePlayDraft(
        title: title,
        userRole: _userRoleController.text.trim(),
        tutorRole: _tutorRoleController.text.trim(),
        situation: situation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.primaryPurple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Create custom role-play',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Rubik',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _titleController,
                    label: 'Title',
                    hint: 'e.g. Ordering coffee',
                    textCapitalization: TextCapitalization.sentences,
                    errorText: _titleError,
                    onChanged: (_) {
                      if (_titleError != null) setState(() => _titleError = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _userRoleController,
                          label: 'My role',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          controller: _tutorRoleController,
                          label: "Tutor's role",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _situationController,
                    label: 'Situation',
                    hint: 'What happens in this conversation?',
                    minLines: 3,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    errorText: _situationError,
                    onChanged: (_) {
                      if (_situationError != null) {
                        setState(() => _situationError = null);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Create role-play'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
