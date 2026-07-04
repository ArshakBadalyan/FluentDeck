import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/screens/profile_screen/profile_achievements_navigation.dart';
import 'package:fluentdeck/screens/profile_screen/profile_stats_header.dart';
import 'package:fluentdeck/services/achievement_service.dart';
import 'package:fluentdeck/ui_elements/app_motion.dart';
import 'package:fluentdeck/localization/app_localizations.dart';
import 'package:fluentdeck/models/placement_test_model.dart';
import 'package:fluentdeck/models/user_note_model.dart';
import 'package:fluentdeck/screens/learn_screen/placement_test_screen.dart';
import 'package:fluentdeck/services/note_service.dart';
import 'package:fluentdeck/services/unsaved_changes_service.dart';
import 'package:fluentdeck/ui_elements/dialogs/account_error_info_dialog.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';
import 'package:fluentdeck/widgets/cefr_level_chips.dart';

import '../../screens/auth/auth_screen.dart';
import '../../services/audio_service.dart';
import '../../services/auth_service.dart';
import '../../services/english_level_service.dart';
import '../../services/main_navigation_coordinator.dart';
import '../../services/main_tab_config.dart';
import '../../services/subscription_service.dart';
import '../../services/vocabulary_service.dart';
import '../../ui_elements/dialogs/account_info_save_dialog.dart';
import '../../ui_elements/dialogs/nickname_logout_dialog.dart';
import '../../ui_elements/loading_overlay.dart';
import '../../ui_elements/primary_button.dart';

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
  bool _processing = false;
  bool _needsLogoutCredentials = false;
  String? _selectedEnglishLevel;
  PlacementTestResultModel? _latestPlacement;
  AchievementSnapshot? _achievementSnapshot;
  SubscriptionStatus _subscriptionStatus = SubscriptionStatus.none;
  StudySettingsModel? _studySettings;

  bool get _hasVerifiedPlacement => _latestPlacement != null;

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
    try {
      _latestPlacement = await VocabularyService.instance.fetchLatestPlacement();
    } catch (_) {}

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

    final res = await AuthService.getUser();

    if (res['status'] == 'success') {
      final u = res['user'];

      emailCtrl.text = (u['email'] ?? '').toString();
      nameCtrl.text = (u['name'] ?? '').toString();
      surnameCtrl.text = (u['surname'] ?? '').toString();
      nicknameCtrl.text = (u['username'] ?? '').toString();
      _needsLogoutCredentials = u['needs_logout_credentials'] == true;

      if (_latestPlacement != null) {
        _selectedEnglishLevel = _latestPlacement!.suggestedLevel;
      } else {
        final englishLevel = (u['english_level'] ?? '').toString();
        if (EnglishLevelService.levels.contains(englishLevel)) {
          _selectedEnglishLevel = englishLevel;
        } else {
          final local = await EnglishLevelService.instance.getLevel();
          _selectedEnglishLevel =
              EnglishLevelService.levels.contains(local) ? local : null;
        }
      }
    }

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

  void _openAchievements() => openProfileAchievements(context);

  Future<void> _openPlacementTest() async {
    final result = await Navigator.of(context).push<PlacementTestResultModel>(
      MaterialPageRoute(builder: (_) => const PlacementTestScreen()),
    );
    if (result != null && mounted) {
      setState(() {
        _latestPlacement = result;
        _selectedEnglishLevel = result.suggestedLevel;
      });
      await EnglishLevelService.instance.applyLevelLocally(result.suggestedLevel);
      UnsavedChangesService().hasUnsavedChanges = false;
    }
  }

  void _changeEnglishLevel(String? level) {
    if (_hasVerifiedPlacement) return;
    if (level == _selectedEnglishLevel) return;
    setState(() => _selectedEnglishLevel = level);
    UnsavedChangesService().hasUnsavedChanges = true;
  }

  Future<bool> _saveProfile({bool showSuccessDialog = true}) async {
    if (_saving || _processing) return false;

    setState(() => _saving = true);

    final body = <String, dynamic>{
      'email': emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
      'name': nameCtrl.text.trim(),
      'surname': surnameCtrl.text.trim(),
      'username': nicknameCtrl.text.trim(),
    };

    final levelToSave =
        _hasVerifiedPlacement
            ? _latestPlacement!.suggestedLevel
            : _selectedEnglishLevel;
    if (levelToSave != null && EnglishLevelService.levels.contains(levelToSave)) {
      body['english_level'] = levelToSave;
    }

    final res = await AuthService.updateUser(body);

    if (!mounted) return false;
    setState(() => _saving = false);

    if (res['status'] == 'success') {
      UnsavedChangesService().hasUnsavedChanges = false;
      if (levelToSave != null) {
        await EnglishLevelService.instance.applyLevelLocally(levelToSave);
      }
      if (!mounted) return true;
      if (showSuccessDialog) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const AccountInfoSaveDialog(),
        );
        AudioService().play('formSubmit');
      }
      return true;
    }

    final message = res['message']?.toString().trim();
    if (message != null && message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AccountErrorInfoDialog(),
      );
    }
    return false;
  }

  Future<void> _logout() async {
    if (_processing) return;

    if (_needsLogoutCredentials) {
      final result = await showDialog<dynamic>(
        context: context,
        barrierDismissible: true,
        builder: (_) => const NicknameLogoutDialog(),
      );
      if (!mounted) return;
      if (result == 'deleted') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (_) => false,
        );
        return;
      }
      if (result != true) return;
      UnsavedChangesService().hasUnsavedChanges = false;
    }

    setState(() => _processing = true);
    await AuthService.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (_) => false,
    );
  }

  Future<void> _deleteAccount() async {
    if (_processing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(context.tr('profile.account.delete-account')),
            content: Text(
              '${context.tr('popups.delete-page-popup.first-text')} ${context.tr('popups.delete-page-popup.second-text')}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.tr('popups.delete-page-popup.cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(context.tr('popups.delete-page-popup.delete')),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() => _processing = true);

    final res = await AuthService.deleteNicknamedUser();
    final ok = res['status'] == 'success';

    await AuthService.logout();

    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['message']?.toString() ??
                context.tr('profile.account.delete-error'),
          ),
        ),
      );
    }
    AudioService().play('formSubmit');

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppPageBackground(child: Center(child: LoadingOverlay()));
    }

    final disableInputs = _processing;

    return PopScope(
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_achievementSnapshot != null)
                  ProfileStatsHeader(
                    snapshot: _achievementSnapshot!,
                    displayName: _displayName,
                    onViewAchievements: _openAchievements,
                  ),
                if (_achievementSnapshot != null) const SizedBox(height: 16),
                AppSectionCard(
                  title: 'FluentDeck Premium',
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
                                    ? AppColors.primaryPurple
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
                        () => MainNavigationCoordinator.goToTab(
                          MainTabId.profile,
                          subIndex: kProfileSubscriptionTabIndex,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                AppFadeIn(
                  delay: const Duration(milliseconds: 60),
                  child: AppSectionCard(
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
                          onChanged: (_) => UnsavedChangesService().hasUnsavedChanges = true,
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: nameCtrl,
                          label: context.tr('inputs.name'),
                          enabled: !disableInputs,
                          onChanged: (_) => UnsavedChangesService().hasUnsavedChanges = true,
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: surnameCtrl,
                          label: context.tr('inputs.surname'),
                          enabled: !disableInputs,
                          onChanged: (_) => UnsavedChangesService().hasUnsavedChanges = true,
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: nicknameCtrl,
                          label: context.tr('inputs.nickname'),
                          enabled: !disableInputs,
                          onChanged: (_) => UnsavedChangesService().hasUnsavedChanges = true,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              AppSectionCard(
                title: 'English level (CEFR)',
                icon: Icons.school_outlined,
                subtitle:
                    _hasVerifiedPlacement
                        ? 'Verified level — retake the test to change it'
                        : 'Select a level or take the placement test to verify',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CefrLevelChips(
                      selectedLevel: _selectedEnglishLevel,
                      verifiedLevel: _latestPlacement?.suggestedLevel,
                      onLevelSelected:
                          disableInputs || _hasVerifiedPlacement
                              ? null
                              : _changeEnglishLevel,
                    ),
                    if (_hasVerifiedPlacement) ...[
                      const SizedBox(height: 16),
                      VerifiedPlacementCard(result: _latestPlacement!),
                    ] else if (_selectedEnglishLevel != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade100),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 18, color: Colors.orange.shade800),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Take the placement test to verify $_selectedEnglishLevel and lock your level.',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.35,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: disableInputs ? null : _openPlacementTest,
                        icon: Icon(
                          _hasVerifiedPlacement ? Icons.replay_outlined : Icons.quiz_outlined,
                          size: 18,
                        ),
                        label: Text(
                          _hasVerifiedPlacement ? 'Retake level test' : 'Take level test',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_studySettings != null) ...[
                const SizedBox(height: 16),
                AppSectionCard(
                  title: 'Saved words',
                  icon: Icons.bookmark_outline_rounded,
                  subtitle: 'Words and corrections saved to your decks',
                  child: Text(
                    _studySettings!.noteLimit == null
                        ? '${_studySettings!.noteCount} notes saved (premium)'
                        : '${_studySettings!.noteCount} / ${_studySettings!.noteLimit} notes saved',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              PrimaryButton(
                text:
                    _saving
                        ? '${context.tr('buttons.save').toUpperCase()}...'
                        : context.tr('buttons.save').toUpperCase(),
                enabled: !_saving && !_processing,
                onPressed: () => _saveProfile(),
                color: AppColors.primaryYellow,
              ),
              const SizedBox(height: 24),
              AppSectionCard(
                title: 'Account actions',
                icon: Icons.manage_accounts_outlined,
                child: Column(
                  children: [
                    if (_processing)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _logout,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryPurple,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(context.tr('profile.account.log-out')),
                        ),
                      ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _processing ? null : _deleteAccount,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(context.tr('profile.account.delete')),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
