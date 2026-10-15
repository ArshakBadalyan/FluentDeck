import 'package:flutter/material.dart';
import 'package:fluentdeck/localization/app_localizations.dart';

import '../screens/auth/auth_screen.dart';
import '../ui_elements/dialogs/nickname_logout_dialog.dart';
import 'auth_service.dart';
import 'unsaved_changes_service.dart';

/// Log out from anywhere (Profile app-bar icon).
///
/// Nickname-only accounts (no password yet) get [NicknameLogoutDialog] first so
/// they can add credentials or delete the account instead of losing access;
/// everyone else confirms with a short dialog.
Future<void> runLogoutFlow(BuildContext context) async {
  final res = await AuthService.getUser();
  if (!context.mounted) return;
  final user = res['user'];
  final needsCredentials = user is Map && user['needs_logout_credentials'] == true;

  if (needsCredentials) {
    final result = await showDialog<dynamic>(
      context: context,
      builder: (_) => const NicknameLogoutDialog(),
    );
    if (!context.mounted) return;
    if (result == 'deleted') {
      _goToAuth(context);
      return;
    }
    if (result != true) return;
    UnsavedChangesService().hasUnsavedChanges = false;
  } else {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(ctx.tr('profile.account.log-out')),
            content: const Text('You can sign back in any time.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(ctx.tr('profile.account.log-out')),
              ),
            ],
          ),
    );
    if (confirmed != true || !context.mounted) return;
  }

  await AuthService.logout();
  if (!context.mounted) return;
  _goToAuth(context);
}

void _goToAuth(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const AuthScreen()),
    (_) => false,
  );
}
