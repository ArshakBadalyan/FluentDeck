import 'package:fluentdeck/ui_elements/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';

import '../../models/conversation_prompt_model.dart';
import '../../models/speaking_session_context.dart';
import '../../services/custom_role_play_service.dart';
import '../../widgets/tutor_scene.dart';
import '../../services/speaking_content_service.dart';
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
  List<ConversationPromptModel> _scenarios = [];
  ConversationPromptModel? _selected;
  bool _loading = true;
  String? _error;
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
      final catalog = await SpeakingContentService.instance
          .fetchRolePlayCatalog(category: 'all');
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
            'No scenarios yet.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final featured = firstUnlocked(_scenarios, _isLocked);
    final rest = _scenarios.where((s) => s != featured).toList();
    return AppLoadingSwitcher(
      loading: false,
      child: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.brandPrimary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            if (featured != null) ...[
              AppStaggeredFadeIn(
                index: 0,
                child: _FeaturedRolePlay(
                  scenario: featured,
                  onTap: () => _start(featured),
                ),
              ),
              const SizedBox(height: 12),
            ],
            AppStaggeredFadeIn(
              index: 1,
              child: _GroupedList(
                children: [
                  _WriteYourOwnRow(onTap: _showCreateDialog),
                  for (final scenario in rest)
                    _RolePlayRow(
                      scenario: scenario,
                      locked: _isLocked(scenario),
                      onTap: () => _start(scenario),
                      onDelete: scenario.isLocal ? () => _deleteCustom(scenario) : null,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _start(ConversationPromptModel scenario) {
    if (_isLocked(scenario)) {
      showSpeakingPremiumSnackBar(context);
      return;
    }
    widget.onStart(SpeakingContentService.instance.rolePlaySessionFrom(scenario));
  }

  @override
  Widget build(BuildContext context) => _buildList();
}

/// "B1 · with hiring manager" style detail for a scenario.
String _rolePlayDetail(ConversationPromptModel s, {bool long = false}) {
  final level = s.difficultyLevel.trim().toUpperCase();
  final tutor = s.tutorRole.trim();
  final parts = <String>[
    if (long && tutor.isNotEmpty) 'Rio plays the ${tutor.toLowerCase()}',
    if (level.isNotEmpty) level,
    if (!long && tutor.isNotEmpty) 'with ${tutor.toLowerCase()}',
  ];
  return parts.isEmpty ? s.scenario : parts.join(' · ');
}

/// The picture card at the top: the first scenario, ready to start.
class _FeaturedRolePlay extends StatelessWidget {
  const _FeaturedRolePlay({required this.scenario, required this.onTap});

  final ConversationPromptModel scenario;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppPressScale(
      child: Material(
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 168,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(TutorScene.online.asset, fit: BoxFit.cover, excludeFromSemantics: true),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xD904191B), Color(0x0004191B)],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.voice,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Start here',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          scenario.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _rolePlayDetail(scenario, long: true),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: Color(0xFFCFEDEF)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One white card holding rows split by hairlines.
class _GroupedList extends StatelessWidget {
  const _GroupedList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppPageColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppPageColors.subtleBorderOf(context)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) Divider(height: 1, thickness: 1, color: AppPageColors.rowDividerOf(context)),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _RolePlayRow extends StatelessWidget {
  const _RolePlayRow({
    required this.scenario,
    required this.locked,
    required this.onTap,
    this.onDelete,
  });

  final ConversationPromptModel scenario;
  final bool locked;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: locked ? 0.55 : 1,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              SpeakingListIconBadge(
                icon: resolveSpeakingListIcon(title: scenario.displayTitle, iconKey: scenario.iconKey),
                title: scenario.displayTitle,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scenario.displayTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppPageColors.textPrimaryOf(context),
                      ),
                    ),
                    Text(
                      _rolePlayDetail(scenario),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: AppPageColors.subtitleOf(context)),
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  tooltip: 'Delete',
                  icon: Icon(Icons.delete_outline, color: AppPageColors.subtitleOf(context)),
                  onPressed: onDelete,
                ),
              Icon(
                locked ? Icons.lock_outline : Icons.chevron_right_rounded,
                size: locked ? 18 : 20,
                color: AppPageColors.mutedOf(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// First row: a dashed "+" tile and "Write your own scenario".
class _WriteYourOwnRow extends StatelessWidget {
  const _WriteYourOwnRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint = AppPageColors.tintOf(context, AppTint.teal);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CustomPaint(
              painter: _DashedRRectPainter(color: tint.fg.withValues(alpha: 0.45)),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.add_rounded, size: 22, color: tint.fg),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Write your own scenario',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: tint.fg),
                  ),
                  Text(
                    'Any situation you want to rehearse',
                    style: TextStyle(fontSize: 13, color: AppPageColors.subtitleOf(context)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius((Offset.zero & size).deflate(1), const Radius.circular(14)));
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) => old.color != color;
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
