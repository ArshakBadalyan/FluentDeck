import 'package:fluentdeck/ui_elements/app_dialog.dart';
import 'package:fluentdeck/ui_elements/app_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/screens/profile_screen/profile_achievements_navigation.dart';
import 'package:fluentdeck/screens/profile_screen/profile_stats_header.dart';
import 'package:fluentdeck/services/achievement_service.dart';
import 'package:fluentdeck/localization/app_localizations.dart';
import 'package:fluentdeck/models/user_note_model.dart';
import 'package:fluentdeck/services/note_service.dart';
import 'package:fluentdeck/services/unsaved_changes_service.dart';
import 'package:fluentdeck/ui_elements/dialogs/account_error_info_dialog.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';

import '../../services/audio_service.dart';
import '../../services/auth_service.dart';
import '../../services/main_navigation_coordinator.dart';
import '../../services/main_tab_config.dart';
import '../../services/subscription_service.dart';
import '../../ui_elements/dialogs/account_info_save_dialog.dart';
import '../../ui_elements/app_skeletons.dart';
import '../../ui_elements/primary_button.dart';
import 'package:fluentdeck/ui_elements/app_motion.dart';

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
  AchievementSnapshot? _achievementSnapshot;
  SubscriptionStatus _subscriptionStatus = SubscriptionStatus.none;
  StudySettingsModel? _studySettings;
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_achievementSnapshot != null)
                  ProfileStatsHeader(
                    snapshot: _achievementSnapshot!,
                    displayName: _displayName,
                    onViewAchievements: _openAchievements,
                    savedWordsValue:
                        _studySettings == null
                            ? null
                            : _studySettings!.noteLimit == null
                            ? '${_studySettings!.noteCount}'
                            : '${_studySettings!.noteCount}/${_studySettings!.noteLimit}',
                  ),
                if (_achievementSnapshot != null) const SizedBox(height: 16),
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
                        () => MainNavigationCoordinator.goToTab(
                          MainTabId.profile,
                          subIndex: kProfileSubscriptionTabIndex,
                        ),
                  ),
                ),
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
          ),
        ),
      ),
    ),
    );
  }
}
