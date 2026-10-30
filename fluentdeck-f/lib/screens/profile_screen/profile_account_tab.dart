import 'package:riovox/ui_elements/app_dialog.dart';
import 'package:riovox/ui_elements/app_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:riovox/app_colors.dart';
import 'package:riovox/screens/profile_screen/profile_achievements_navigation.dart';
import 'package:riovox/models/speaking_preferences.dart';
import 'package:riovox/services/speaking_preferences_service.dart';
import 'package:riovox/services/achievement_service.dart';
import 'package:riovox/localization/app_localizations.dart';
import 'package:riovox/models/user_note_model.dart';
import 'package:riovox/services/note_service.dart';
import 'package:riovox/services/unsaved_changes_service.dart';
import 'package:riovox/ui_elements/dialogs/account_error_info_dialog.dart';
import 'package:riovox/ui_elements/modern_page_widgets.dart';

import '../../services/audio_service.dart';
import '../../services/auth_service.dart';
import '../../services/subscription_service.dart';
import 'profile_subscription_tab.dart';
import '../../ui_elements/dialogs/account_info_save_dialog.dart';
import '../../ui_elements/app_skeletons.dart';
import '../../ui_elements/primary_button.dart';
import 'package:riovox/ui_elements/app_motion.dart';

class ProfileAccountTab extends StatefulWidget {
  const ProfileAccountTab({super.key});

  @override
  State<ProfileAccountTab> createState() => _ProfileAccountTabState();
}

class _ProfileAccountTabState extends State<ProfileAccountTab> {
  final emailCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final surnameCtrl = TextEditingController();
  final nicknameCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  final bool _processing = false;
  AchievementSnapshot? _achievementSnapshot;
  SubscriptionStatus _subscriptionStatus = SubscriptionStatus.none;
  StudySettingsModel? _studySettings;
  SpeakingPreferences _speakingPrefs = const SpeakingPreferences();

  /// The name and email form shows once the pencil is tapped.
  bool _editing = false;
  /// Field values as last loaded/saved; Save stays disabled until one differs.
  List<String> _savedValues = const [];

  List<String> get _currentValues => [
    emailCtrl.text.trim(),
    nameCtrl.text.trim(),
    surnameCtrl.text.trim(),
    nicknameCtrl.text.trim(),
  ];

  bool get _hasChanges => !listEquals(_currentValues, _savedValues);

  void _onFieldChanged(String _) {
    setState(() {});
    UnsavedChangesService().hasUnsavedChanges = _hasChanges;
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
    UnsavedChangesService().discardCallback = _loadUser;
    UnsavedChangesService().saveCallback = () => _saveProfile(showSuccessDialog: false);
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    nameCtrl.dispose();
    surnameCtrl.dispose();
    nicknameCtrl.dispose();
    UnsavedChangesService().discardCallback = null;
    UnsavedChangesService().saveCallback = null;
    super.dispose();
  }

  Future<void> _loadUser() async {
    AchievementSnapshot? achievements;
    try {
      achievements = await AchievementService.instance.load();
    } catch (_) {}

    try {
      _subscriptionStatus = await SubscriptionService.instance.fetchStatus();
    } catch (_) {}

    try {
      _studySettings = await NoteService.instance.fetchStudySettings();
    } catch (_) {}

    try {
      _speakingPrefs = await SpeakingPreferencesService.instance.load();
    } catch (_) {}

    final res = await AuthService.getUser();

    if (res['status'] == 'success') {
      final u = res['user'];

      emailCtrl.text = (u['email'] ?? '').toString();
      nameCtrl.text = (u['name'] ?? '').toString();
      surnameCtrl.text = (u['surname'] ?? '').toString();
      nicknameCtrl.text = (u['username'] ?? '').toString();
    }
    _savedValues = _currentValues;

    if (!mounted) return;
    setState(() {
      _achievementSnapshot = achievements;
      _loading = false;
    });
  }

  String get _displayName {
    final parts =
        [nameCtrl.text.trim(), surnameCtrl.text.trim()]
            .where((p) => p.isNotEmpty)
            .toList();
    if (parts.isNotEmpty) return parts.join(' ');
    final nick = nicknameCtrl.text.trim();
    if (nick.isNotEmpty) return nick;
    return 'Learner';
  }

  /// "Spanish → English · Free plan".
  String get _identitySubtitle {
    final target = SpeakingPreferences.practiceLanguageOptions[_speakingPrefs.practiceLanguage] ??
        _speakingPrefs.practiceLanguage.toUpperCase();
    final native = _speakingPrefs.translationLanguage == 'none'
        ? null
        : SpeakingPreferences.translationLanguageOptions[_speakingPrefs.translationLanguage];
    final plan = _subscriptionStatus.isPremium ? 'Premium' : 'Free plan';
    return '${native == null ? target : '$native → $target'} · $plan';
  }

  static String _streakLabel(int days) => days == 1 ? '1 day' : '$days days';

  void _openAchievements() => openProfileAchievements(context);

  Future<bool> _saveProfile({bool showSuccessDialog = true}) async {
    if (_saving || _processing) return false;
    if (!_hasChanges) return true;

    setState(() => _saving = true);

    final body = <String, dynamic>{
      'email': emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
      'name': nameCtrl.text.trim(),
      'surname': surnameCtrl.text.trim(),
      'username': nicknameCtrl.text.trim(),
    };

    final res = await AuthService.updateUser(body);

    if (!mounted) return false;
    setState(() => _saving = false);

    if (res['status'] == 'success') {
      setState(() => _savedValues = _currentValues);
      UnsavedChangesService().hasUnsavedChanges = false;
      if (!mounted) return true;
      if (showSuccessDialog) {
        showAppDialog(
          context: context,
          barrierDismissible: true,
          builder: (_) => const AccountInfoSaveDialog(),
        );
        AudioService().play('save');
      }
      return true;
    }

    final message = res['message']?.toString().trim();
    if (message != null && message.isNotEmpty) {
      AppToast.showSnackBar(context, 
        SnackBar(content: Text(message)),
      );
    } else {
      showAppDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => const AccountErrorInfoDialog(),
      );
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return AppLoadingSwitcher(
      loading: true,
      child: const ProfileAccountSkeleton(),
    );
    }

    final disableInputs = _processing;

    return AppLoadingSwitcher(
      loading: false,
      child: PopScope(
      canPop: !UnsavedChangesService().hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;

        final shouldPop = await UnsavedChangesService().showConfirmDialog(
          context,
          onSave: () => _saveProfile(showSuccessDialog: false),
        );
        if (shouldPop == true && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: AppPageBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _IdentityCard(
                  name: _displayName,
                  subtitle: _identitySubtitle,
                  editing: _editing,
                  onEdit: () => setState(() => _editing = !_editing),
                ),
                const SizedBox(height: 12),
                if (_achievementSnapshot != null) ...[
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _StatTile(
                            icon: Icons.local_fire_department_rounded,
                            value: _streakLabel(_achievementSnapshot!.progress?.streakDays ?? 0),
                            label: 'Practice streak',
                            tint: AppTint.reward,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatTile(
                            icon: Icons.workspace_premium_outlined,
                            value: '${_achievementSnapshot!.unlockedCount} of ${_achievementSnapshot!.achievements.length}',
                            label: 'Badges earned',
                            onTap: _openAchievements,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _InfoRows(
                  rows: [
                    ('Daily goal', '${_speakingPrefs.correctSentenceGoal} sentences'),
                    if (_achievementSnapshot?.progress != null)
                      ('Words spoken', '${_achievementSnapshot!.progress!.uniqueWordsUsed}'),
                    if (_studySettings != null)
                      (
                        'Saved words',
                        _studySettings!.noteLimit == null
                            ? '${_studySettings!.noteCount}'
                            : '${_studySettings!.noteCount} of ${_studySettings!.noteLimit} free',
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (!_subscriptionStatus.isPremium)
                  _GoPremiumBanner(
                    onTap: () => openPremiumScreen(context),
                  )
                else
                AppSectionCard(
                  title: 'Riovox Premium',
                  icon: Icons.workspace_premium_outlined,
                  subtitleWidget: Text.rich(
                    TextSpan(
                      text: 'Current plan: ',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppPageColors.subtitleOf(context),
                      ),
                      children: [
                        TextSpan(
                          text:
                              _subscriptionStatus.isPremium
                                  ? (kFluentDeckPlans
                                          .where(
                                            (p) =>
                                                p.productId ==
                                                _subscriptionStatus.productId,
                                          )
                                          .firstOrNull
                                          ?.title ??
                                      'Premium')
                                  : 'Free',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color:
                                _subscriptionStatus.isPremium
                                    ? AppColors.brandPrimary
                                    : AppPageColors.subtitleOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  child: AppNavRow(
                    title:
                        _subscriptionStatus.isPremium
                            ? 'Manage subscription'
                            : 'Upgrade to Premium',
                    icon: Icons.workspace_premium_rounded,
                    onTap:
                        () => openPremiumScreen(context),
                  ),
                ),
                if (_editing) ...[
                const SizedBox(height: 16),
                AppSectionCard(
                  title: 'Account',
                  icon: Icons.person_outline_rounded,
                  subtitle: 'Your personal information',
                  child: Column(
                    children: [
                      AppTextField(
                        controller: emailCtrl,
                        label: context.tr('inputs.E-mail-address'),
                        enabled: !disableInputs,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: _onFieldChanged,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: nameCtrl,
                        label: context.tr('inputs.name'),
                        enabled: !disableInputs,
                        onChanged: _onFieldChanged,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: surnameCtrl,
                        label: context.tr('inputs.surname'),
                        enabled: !disableInputs,
                        onChanged: _onFieldChanged,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: nicknameCtrl,
                        label: context.tr('inputs.nickname'),
                        enabled: !disableInputs,
                        onChanged: _onFieldChanged,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              PrimaryButton(
                text:
                    _saving
                        ? '${context.tr('buttons.save').toUpperCase()}...'
                        : context.tr('buttons.save').toUpperCase(),
                enabled: !_saving && !_processing && _hasChanges,
                onPressed: () => _saveProfile(),
              ),
                ],
            ],
          ),
        ),
      ),
    ),
    );
  }
}

/// Free plan: one dark-teal banner inviting an upgrade (Lagoon Daylight).
class _GoPremiumBanner extends StatelessWidget {
  const _GoPremiumBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppPressScale(
      child: Material(
        color: AppColors.brandPrimaryDeep,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: AppColors.primaryYellow,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Go Premium',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'More speaking time every day, all voices, no ads',
                        style: TextStyle(fontSize: 13, color: Color(0xFFBFE4E7)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Avatar initial, name, languages and plan, and the edit pencil.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.name,
    required this.subtitle,
    required this.editing,
    required this.onEdit,
  });

  final String name;
  final String subtitle;
  final bool editing;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final accent = AppPageColors.accentOf(context);
    final initial = name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppPageColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPageColors.subtleBorderOf(context)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: accent,
            child: Text(
              initial,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppPageColors.onAccentOf(context)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppPageColors.textPrimaryOf(context)),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 14, color: AppPageColors.subtitleOf(context))),
              ],
            ),
          ),
          IconButton(
            tooltip: editing ? 'Close' : 'Edit profile',
            icon: Icon(editing ? Icons.close_rounded : Icons.edit_outlined, color: accent),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}

/// Icon, big value, small label; the reward tint fills it soft yellow.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    this.tint,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final AppTint? tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = tint == null ? null : AppPageColors.tintOf(context, tint!);
    final iconColor = AppPageColors.tintIconOf(context, tint ?? AppTint.reward);
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppPageColors.textPrimaryOf(context)),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 13, color: colors?.fg ?? AppPageColors.subtitleOf(context))),
        ],
      ),
    );
    return AppPressScale(
      enabled: onTap != null,
      child: Material(
        color: colors?.bg ?? AppPageColors.cardBgOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: colors == null ? BorderSide(color: AppPageColors.subtleBorderOf(context)) : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: onTap == null ? content : InkWell(onTap: onTap, child: content),
      ),
    );
  }
}

/// Label on the left, bold value on the right, rows split by hairlines.
class _InfoRows extends StatelessWidget {
  const _InfoRows({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppPageColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPageColors.subtleBorderOf(context)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: AppPageColors.rowDividerOf(context)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(rows[i].$1, style: TextStyle(fontSize: 15, color: AppPageColors.textPrimaryOf(context))),
                  ),
                  Text(
                    rows[i].$2,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppPageColors.textPrimaryOf(context)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
