import 'package:flutter/material.dart';
import 'package:speakstack/localization/app_localizations.dart';

import '../../app_colors.dart';
import '../../services/audio_service.dart';
import '../../services/auth_service.dart';
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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
                        color: Colors.grey.shade600,
                      ),
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
                        color: Colors.grey.shade600,
                      ),
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
              color: AppColors.primaryYellow,
            ),
          ],
        ),
      ),
    );
  }
}
