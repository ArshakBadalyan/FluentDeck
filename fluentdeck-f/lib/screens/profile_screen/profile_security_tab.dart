import 'package:fluentdeck/ui_elements/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:fluentdeck/localization/app_localizations.dart';

import '../../app_colors.dart';
import '../../services/audio_service.dart';
import '../../services/auth_service.dart';
import '../../services/deck_backup_service.dart';
import '../../services/main_navigation_coordinator.dart';
import '../../services/main_tab_config.dart';
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
  bool _backingUp = false;

  /// The new-password fields show once "Change" is tapped.
  bool _changingPassword = false;
  String? _email;

  @override
  void initState() {
    super.initState();
    passwordCtrl.addListener(_onTextChanged);
    confirmCtrl.addListener(_onTextChanged);
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    final res = await AuthService.getUser();
    if (!mounted || res['status'] != 'success') return;
    final email = (res['user']?['email'] ?? '').toString().trim();
    setState(() => _email = email.isEmpty ? null : email);
  }

  Future<void> _backUpDecks() async {
    setState(() => _backingUp = true);
    try {
      await DeckBackupService.instance.performBackup();
      if (!mounted) return;
      AppToast.showSnackBar(context, const SnackBar(content: Text('Backup created')));
    } catch (e) {
      if (!mounted) return;
      AppToast.showSnackBar(context, SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _backingUp = false);
    }
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
    if (!mounted) return;

    setState(() => _saving = false);

    if (res['status'] == 'success') {
      AudioService().play('save');

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
    AudioService().play('save');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = _resetting || _deletingAccount;
    return AppPageBackground(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RowsCard(
              rows: [
                _SecurityRow(
                  title: 'Email',
                  subtitle: _email ?? '—',
                  action: 'Change',
                  onTap: () => MainNavigationCoordinator.goToTab(MainTabId.profile, subIndex: 0),
                ),
                _SecurityRow(
                  title: 'Password',
                  subtitle: 'At least 6 characters',
                  action: _changingPassword ? 'Cancel' : 'Change',
                  onTap: () => setState(() => _changingPassword = !_changingPassword),
                ),
              ],
            ),
            if (_changingPassword) ...[
              const SizedBox(height: 12),
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
              const SizedBox(height: 16),
              PrimaryButton(
                text:
                    _saving
                        ? '${context.tr('buttons.save').toUpperCase()}...'
                        : context.tr('buttons.save').toUpperCase(),
                enabled: _isFormValid && !_saving,
                onPressed: _changePassword,
              ),
            ],
            const SizedBox(height: 18),
            Text(
              'YOUR DATA',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: AppPageColors.subtitleOf(context),
              ),
            ),
            const SizedBox(height: 10),
            _RowsCard(
              rows: [
                _SecurityRow(
                  title: _backingUp ? 'Backing up…' : 'Back up decks',
                  onTap: _backingUp ? null : _backUpDecks,
                ),
                _SecurityRow(
                  title: _resetting ? 'Deleting…' : 'Delete all learning data',
                  subtitle: 'Decks, notes, speaking history and stats. Your account stays.',
                  danger: true,
                  onTap: busy ? null : _confirmResetLearningData,
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: busy ? null : _confirmDeleteAccount,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.redWrong,
                  backgroundColor: AppPageColors.cardBgOf(context),
                  side: BorderSide(color: AppColors.redWrong.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                child: Text(
                  _deletingAccount ? 'Deleting account…' : context.tr('profile.account.delete-account'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Deleting removes your decks and history for good.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppPageColors.subtitleOf(context)),
            ),
          ],
        ),
      ),
    );
  }
}

/// White card holding rows split by hairlines.
class _RowsCard extends StatelessWidget {
  const _RowsCard({required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPageColors.cardBgOf(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppPageColors.subtleBorderOf(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: AppPageColors.rowDividerOf(context)),
            rows[i],
          ],
        ],
      ),
    );
  }
}

/// Title and detail, then a teal action word or a chevron.
class _SecurityRow extends StatelessWidget {
  const _SecurityRow({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.action,
    this.danger = false,
  });

  final String title;
  final String? subtitle;
  final String? action;
  final bool danger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: subtitle == null ? FontWeight.w500 : FontWeight.w700,
                      color: danger ? AppColors.redWrong : AppPageColors.textPrimaryOf(context),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: TextStyle(fontSize: 13, color: AppPageColors.subtitleOf(context))),
                  ],
                ],
              ),
            ),
            if (action != null)
              Text(
                action!,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppPageColors.accentOf(context)),
              )
            else
              Icon(Icons.chevron_right_rounded, size: 20, color: AppPageColors.mutedOf(context)),
          ],
        ),
      ),
    );
  }
}
