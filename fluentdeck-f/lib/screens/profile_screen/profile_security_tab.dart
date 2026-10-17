import 'package:fluentdeck/ui_elements/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:fluentdeck/localization/app_localizations.dart';

import '../../app_colors.dart';
import '../../services/audio_service.dart';
import '../../services/auth_service.dart';
import '../../services/user_progress_service.dart';
import '../../screens/auth/auth_screen.dart';
import '../../ui_elements/dialogs/type_to_confirm_dialog.dart';
import '../../ui_elements/modern_page_widgets.dart';
import '../../ui_elements/primary_button.dart';

class ProfileSecurityTab extends StatefulWidget {
  const ProfileSecurityTab({super.key});

  @override
  State<ProfileSecurityTab> createState() => _ProfileSecurityTabState();
}

class _ProfileSecurityTabState extends State<ProfileSecurityTab> {
  final passwordCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  bool _hidePassword = true;
  bool _hideConfirm = true;
  bool _saving = false;
  bool _resetting = false;
  bool _deletingAccount = false;

  @override
  void initState() {
    super.initState();
    passwordCtrl.addListener(_onTextChanged);
    confirmCtrl.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    passwordCtrl.removeListener(_onTextChanged);
    confirmCtrl.removeListener(_onTextChanged);
    passwordCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return passwordCtrl.text.isNotEmpty && confirmCtrl.text.isNotEmpty;
  }

  Future<void> _changePassword() async {
    final password = passwordCtrl.text.trim();
    final confirm = confirmCtrl.text.trim();

    if (password.isEmpty || confirm.isEmpty) {
      _show(context.tr('common.fill-all-fields'));
      return;
    }

    if (password.length < 6) {
      _show(context.tr('profile.security.password-min-length'));
      return;
    }

    if (password != confirm) {
      _show(context.tr('reset-password.error-msg'));
      return;
    }

    setState(() => _saving = true);

    final res = await AuthService.updateUser({'password': password});

    setState(() => _saving = false);

    if (res['status'] == 'success') {
      AudioService().play('formSubmit');

      passwordCtrl.clear();
      confirmCtrl.clear();
      _show(context.tr('profile.security.popup-text'));
    } else {
      _show(
        res['message']?.toString() ??
            context.tr('profile.security.change-error'),
      );
    }
  }

  void _show(String text) {
    AppToast.showSnackBar(context, SnackBar(content: Text(text)));
  }

  Future<void> _confirmResetLearningData() async {
    final confirmed = await showTypeToConfirmDialog(
      context,
      title: 'Delete all learning data?',
      message:
          'This permanently deletes your decks, cards, review history, '
          'My Notes, speaking sessions and scores, and resets Activity '
          '(language history, deck words, weak areas, streaks). '
          'Your account, subscription and settings are kept.',
      confirmLabel: 'Delete everything',
    );
    if (!confirmed || !mounted) return;

    setState(() => _resetting = true);
    final ok = await UserProgressService.instance.resetLearningData();
    if (!mounted) return;
    setState(() => _resetting = false);
    AppToast.showSnackBar(context, 
      SnackBar(
        content: Text(
          ok
              ? 'All learning data deleted'
              : 'Could not delete learning data. Try again.',
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showTypeToConfirmDialog(
      context,
      title: context.tr('profile.account.delete-account'),
      message:
          '${context.tr('popups.delete-page-popup.first-text')} '
          '${context.tr('popups.delete-page-popup.second-text')}',
      confirmLabel: context.tr('popups.delete-page-popup.delete'),
    );
    if (!confirmed || !mounted) return;

    setState(() => _deletingAccount = true);
    final res = await AuthService.deleteNicknamedUser();
    final ok = res['status'] == 'success';
    await AuthService.logout();
    if (!mounted) return;

    if (!ok) {
      AppToast.showSnackBar(context, 
        SnackBar(
          content: Text(
            res['message']?.toString() ?? context.tr('profile.account.delete-error'),
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

  Widget _dangerButton({
    required String label,
    required String busyLabel,
    required bool busy,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _resetting || _deletingAccount ? null : onPressed,
        icon:
            busy
                ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : const Icon(Icons.delete_outline_rounded),
        label: Text(busy ? busyLabel : label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.redWrong,
          side: BorderSide(color: AppColors.redWrong.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPageBackground(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSectionCard(
              title: context.tr('inputs.new-password'),
              icon: Icons.lock_outline_rounded,
              subtitle: 'Choose a strong password with at least 6 characters',
              child: Column(
                children: [
                  AppTextField(
                    controller: passwordCtrl,
                    label: context.tr('inputs.new-password'),
                    obscureText: _hidePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _hidePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppPageColors.subtitleOf(context),
                      ),
                      tooltip: _hidePassword ? 'Show password' : 'Hide password',
                      onPressed: () => setState(() => _hidePassword = !_hidePassword),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: confirmCtrl,
                    label: context.tr('inputs.confirm-new-password'),
                    obscureText: _hideConfirm,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _hideConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppPageColors.subtitleOf(context),
                      ),
                      tooltip: _hideConfirm ? 'Show password' : 'Hide password',
                      onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
                    ),
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
              enabled: _isFormValid && !_saving,
              onPressed: _changePassword,
            ),
            const SizedBox(height: 28),
            AppSectionCard(
              title: 'Delete learning data',
              icon: Icons.delete_forever_outlined,
              subtitle:
                  'Start fresh: removes decks, cards, My Notes, speaking history and '
                  'all Activity stats. Your account and settings stay.',
              child: _dangerButton(
                label: 'Delete all learning data',
                busyLabel: 'Deleting…',
                busy: _resetting,
                onPressed: _confirmResetLearningData,
              ),
            ),
            const SizedBox(height: 16),
            AppSectionCard(
              title: context.tr('profile.account.delete-account'),
              icon: Icons.person_remove_outlined,
              subtitle:
                  'Permanently deletes your account and all its data. '
                  'This cannot be undone.',
              child: _dangerButton(
                label: context.tr('profile.account.delete-account'),
                busyLabel: 'Deleting account…',
                busy: _deletingAccount,
                onPressed: _confirmDeleteAccount,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
