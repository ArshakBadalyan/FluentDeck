import 'package:flutter/material.dart';
import 'package:untitled2/app_colors.dart';
import 'package:untitled2/localization/app_localizations.dart';
import 'package:untitled2/services/audio_service.dart';
import 'package:untitled2/services/auth_service.dart';
import 'package:untitled2/ui_elements/primary_button.dart';

/// Shown on logout if the user has no password yet: set password (same rules as
/// register / Security tab) or delete account (soft-anonymize via [AuthService.deleteNicknamedUser]).
class NicknameLogoutDialog extends StatefulWidget {
  const NicknameLogoutDialog({super.key});

  @override
  State<NicknameLogoutDialog> createState() => _NicknameLogoutDialogState();
}

class _NicknameLogoutDialogState extends State<NicknameLogoutDialog> {
  static const int _minPasswordLength = 6;

  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  String _passwordError = '';
  String _confirmError = '';
  String _generalError = '';
  bool _busy = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _clearErrors() {
    setState(() {
      _passwordError = '';
      _confirmError = '';
      _generalError = '';
    });
  }

  Future<void> _saveAndLogout() async {
    if (_busy) return;
    _clearErrors();
    final password = _passwordCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();
    if (password.isEmpty || confirm.isEmpty) {
      setState(() {
        _generalError = context.tr('common.fill-all-fields');
      });
      return;
    }
    if (password.length < _minPasswordLength) {
      setState(() {
        _passwordError = context.tr('profile.security.password-min-length');
        _confirmError = '';
      });
      return;
    }
    if (password != confirm) {
      setState(() {
        _generalError = context.tr('reset-password.error-msg');
      });
      return;
    }

    setState(() => _busy = true);
    final res = await AuthService.updateUser({'password': password});

    if (!mounted) return;
    setState(() => _busy = false);

    if (res['status'] == 'success') {
      AudioService().play('formSubmit');
      if (!mounted) return;
      Navigator.of(context).pop(true);
      return;
    }

    final fe = res['fieldErrors'];
    var pErr = '';
    if (fe is Map) {
      pErr = fe['password']?.toString() ?? '';
    }
    String? general;
    if (res['messageKey'] is String &&
        (res['messageKey'] as String).isNotEmpty) {
      general = context.trServiceError(Map<String, dynamic>.from(res));
    } else {
      final m = res['message']?.toString().trim();
      if (m != null && m.isNotEmpty) general = m;
    }
    setState(() {
      _passwordError = pErr;
      if (pErr.isEmpty && general != null) {
        _generalError = general;
      }
    });
  }

  /// Same soft-delete as profile "Delete account" (Del* username / email) + logout.
  Future<void> _deleteAccount() async {
    if (_busy) return;
    setState(() => _busy = true);
    final res = await AuthService.deleteNicknamedUser();
    if (!mounted) return;
    if (res['status'] != 'success') {
      setState(() {
        _busy = false;
        _generalError = context.trServiceError(
          Map<String, dynamic>.from(res),
        );
      });
      return;
    }
    await AuthService.logout();
    if (!mounted) return;
    AudioService().play('formSubmit');
    Navigator.of(context).pop('deleted');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.tr('profile.account.logout-warning'),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr('profile.account.logout-text'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordCtrl,
                    enabled: !_busy,
                    obscureText: true,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: context.tr('inputs.password'),
                      errorText: _passwordError.isEmpty ? null : _passwordError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmCtrl,
                    enabled: !_busy,
                    obscureText: true,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: context.tr('inputs.confirm-password'),
                      errorText: _confirmError.isEmpty ? null : _confirmError,
                    ),
                  ),
                  if (_generalError.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _generalError,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  PrimaryButton(
                    text: context.tr('profile.account.save-and-logout'),
                    enabled: !_busy,
                    isLoading: _busy,
                    onPressed: _saveAndLogout,
                    color: AppColors.primaryYellow,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: _busy ? null : _deleteAccount,
                      child: Text(
                        context.tr('profile.account.delete-account'),
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.close, size: 22),
              color: Colors.black54,
              onPressed: _busy ? null : () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
