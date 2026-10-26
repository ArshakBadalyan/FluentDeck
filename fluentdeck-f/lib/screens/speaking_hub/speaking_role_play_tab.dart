import 'package:fluentdeck/ui_elements/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';

import '../../models/conversation_prompt_model.dart';
import '../../models/speaking_session_context.dart';
import '../../services/custom_role_play_service.dart';
import '../../widgets/tutor_scene.dart';
import '../../services/speaking_content_service.dart';
import '../../services/speaking_scores_service.dart';
import '../../services/speaking_session_service.dart';
import '../../services/subscription_service.dart';
import '../../ui_elements/app_skeletons.dart';
import '../../ui_elements/frosted_bottom_sheet.dart';
import '../../ui_elements/modern_page_widgets.dart';
import '../../utils/speaking_item_icons.dart';
import '../../utils/speaking_premium_gate.dart';
import '../../widgets/speaking_hub_widgets.dart';
import 'package:fluentdeck/ui_elements/app_motion.dart';

/// Free users can keep this many custom role-plays before Premium is required.
const int kFreeCustomRolePlayLimit = 1;

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
  int _customCount = 0;
  bool _isPremium = false;

  /// Custom role-plays are never locked; extras past the free limit are hidden instead.
  bool _isLocked(ConversationPromptModel s) => !s.isLocal && s.isPremiumLocked;

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
      final custom = await CustomRolePlayService.instance.fetchAll();
      final status = await SubscriptionService.instance.fetchStatus();
      // Free users only see their oldest custom role-plays, up to the limit.
      final freeCustomIds =
          (custom.map((p) => p.id).toList()..sort())
              .take(kFreeCustomRolePlayLimit)
              .toSet();
      final scenarios =
          catalog.items
              .where(
                (s) =>
                    !s.isLocal ||
                    status.isPremium ||
                    freeCustomIds.contains(s.id),
              )
              .toList();

      final scores = <String, int?>{};
      for (final s in scenarios) {
        scores[s.referenceKey] =
            await SpeakingScoresService.instance.getScore(s.referenceKey);
      }


      if (!mounted) return;
      setState(() {
        _customCount = custom.length;
        _isPremium = status.isPremium;
        _scenarios = scenarios;
        _selected =
            scenarios.any((s) => s.referenceKey == _selected?.referenceKey)
                ? _selected
                : firstUnlocked(scenarios, _isLocked) ??
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

    final confirmed = await showAppDialog<bool>(
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
    if (!_isPremium && _customCount >= kFreeCustomRolePlayLimit) {
      showSpeakingPremiumSnackBar(context);
      return;
    }

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
      return AppLoadingSwitcher(
      loading: true,
      child: const AppListSkeleton(),
    );
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

    return AppLoadingSwitcher(
      loading: false,
      child: RefreshIndicator(
      onRefresh: _load,
      color: AppColors.brandPrimary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        itemCount: _scenarios.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final scenario = _scenarios[index];
          return AppStaggeredFadeIn(
                          index: index,
                          child: SpeakingSelectionCard(
            title: scenario.displayTitle,
            subtitle: scenario.rolesSubtitle,
            icon: resolveSpeakingListIcon(
              title: scenario.displayTitle,
              iconKey: scenario.iconKey,
            ),
            score: _scoreCache[scenario.referenceKey],
            selected: _selected?.referenceKey == scenario.referenceKey,
            isPremiumLocked: _isLocked(scenario),
            trailing:
                scenario.isLocal
                    ? IconButton(
                      tooltip: 'Delete',
                      icon: Icon(Icons.delete_outline, color: AppPageColors.subtitleOf(context)),
                      onPressed: () => _deleteCustom(scenario),
                    )
                    : null,
            onTap: () {
              if (_isLocked(scenario)) {
                showSpeakingPremiumSnackBar(context);
                return;
              }
              setState(() => _selected = scenario);
            },
          ),
                        );
        },
      ),
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
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: _RolePlayIntro(onCreate: _showCreateDialog),
        ),
        if (!_isPremium)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
            child: Text(
              '${_customCount.clamp(0, kFreeCustomRolePlayLimit)} of $kFreeCustomRolePlayLimit free custom role-play used',
              style: TextStyle(fontSize: 12, color: AppPageColors.subtitleOf(context)),
            ),
          ),
        const SizedBox(height: 8),
        Expanded(child: _buildList()),
        SpeakingStartButton(
          label: 'Start Role-Play',
          enabled: _selected != null && !_isLocked(_selected!),
          onPressed:
              _selected == null || _isLocked(_selected!)
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

/// Any letter in any script (Latin, Armenian, Cyrillic, Arabic, CJK, ...).
final _letterPattern = RegExp(r'\p{L}', unicode: true);

/// A word: two or more letters (combining marks allowed, e.g. Hindi, Thai).
final _wordPattern = RegExp(r'\p{L}[\p{L}\p{M}]+', unicode: true);

/// Scripts written without spaces between words, where word counts don't apply.
final _noSpaceScriptPattern = RegExp(
  r'[\p{Script=Han}\p{Script=Hiragana}\p{Script=Katakana}'
  r'\p{Script=Thai}\p{Script=Lao}\p{Script=Khmer}\p{Script=Myanmar}]',
  unicode: true,
);

/// Rejects empty, too short/long, or junk input (e.g. "A", "aaaa", "!!!")
/// in any language.
String? _validateRolePlayText(
  String value, {
  required String field,
  required int minLength,
  required int maxLength,
  int minWords = 1,
}) {
  if (value.isEmpty) return '$field is required';
  final noSpaces = _noSpaceScriptPattern.hasMatch(value);
  // One CJK/Thai character carries roughly a word, so short text is fine.
  final min = noSpaces ? (minLength / 2).ceil() : minLength;
  final length = value.runes.length;
  if (length < min) return '$field must be at least $min characters';
  if (length > maxLength) {
    return '$field must be at most $maxLength characters';
  }
  final letters =
      _letterPattern.allMatches(value.toLowerCase()).map((m) => m[0]).toList();
  if (letters.length < min ~/ 2 || letters.toSet().length < 2) {
    return 'Please use real words';
  }
  if (!noSpaces && _wordPattern.allMatches(value).length < minWords) {
    return '$field needs at least $minWords words';
  }
  return null;
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
  String? _userRoleError;
  String? _tutorRoleError;
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
    final userRole = _userRoleController.text.trim();
    final tutorRole = _tutorRoleController.text.trim();
    final situation = _situationController.text.trim();
    setState(() {
      _titleError = _validateRolePlayText(
        title,
        field: 'Title',
        minLength: 3,
        maxLength: 60,
      );
      _userRoleError = _validateRolePlayText(
        userRole,
        field: 'My role',
        minLength: 3,
        maxLength: 40,
      );
      _tutorRoleError = _validateRolePlayText(
        tutorRole,
        field: "Tutor's role",
        minLength: 3,
        maxLength: 40,
      );
      if (_userRoleError == null &&
          _tutorRoleError == null &&
          userRole.toLowerCase() == tutorRole.toLowerCase()) {
        _tutorRoleError = 'Must differ from your role';
      }
      _situationError = _validateRolePlayText(
        situation,
        field: 'Situation',
        minLength: 20,
        maxLength: 500,
        minWords: 4,
      );
    });
    if (_titleError != null ||
        _userRoleError != null ||
        _tutorRoleError != null ||
        _situationError != null) {
      return;
    }

    Navigator.pop(
      context,
      _RolePlayDraft(
        title: title,
        userRole: userRole,
        tutorRole: tutorRole,
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
                  color: AppPageColors.subtleBorderOf(context),
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
                    color: AppColors.brandPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.brandPrimary,
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
                          errorText: _userRoleError,
                          onChanged: (_) {
                            if (_userRoleError != null) {
                              setState(() => _userRoleError = null);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          controller: _tutorRoleController,
                          label: "Tutor's role",
                          errorText: _tutorRoleError,
                          onChanged: (_) {
                            if (_tutorRoleError != null) {
                              setState(() => _tutorRoleError = null);
                            }
                          },
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
              border: Border(top: BorderSide(color: AppPageColors.subtleBorderOf(context))),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
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

/// Picture card explaining role-plays, with "Write your own scenario" under it.
class _RolePlayIntro extends StatelessWidget {
  const _RolePlayIntro({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final accent = AppPageColors.accentOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 128,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  TutorScene.online.asset,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.3),
                  excludeFromSemantics: true,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xD904191B), Color(0x0004191B)],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rehearse real moments',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Rio plays the other person. Pick a scene below.',
                        style: TextStyle(fontSize: 13, color: Color(0xFFCFEDEF)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Material(
          color: AppPageColors.cardBgOf(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: accent.withValues(alpha: 0.45), width: 1.5),
          ),
          child: InkWell(
            onTap: onCreate,
            customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.add_rounded, color: accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Write your own scenario',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: accent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
