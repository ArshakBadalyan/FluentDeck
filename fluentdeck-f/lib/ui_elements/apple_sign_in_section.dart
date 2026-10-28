import 'package:fluentdeck/ui_elements/app_toast.dart';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:fluentdeck/localization/app_localizations.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';

import '../services/apple_auth_service.dart';
import '../services/audio_service.dart';
import '../english_main_screen.dart';
import '../routing/app_route_names.dart';
import '../routing/app_page_routes.dart';

typedef AppleAuthComplete = void Function(Map<String, dynamic> result);

/// Shared Sign in with Apple button for login and registration screens.
class AppleSignInSection extends StatefulWidget {
  const AppleSignInSection({
    super.key,
    required this.isSignUp,
    required this.enabled,
    this.onComplete,
    this.showDivider = true,
  });

  final bool isSignUp;
  final bool enabled;

  /// False when the form draws [AuthOrDivider] itself (Apple and Google side
  /// by side under one divider).
  final bool showDivider;
  final AppleAuthComplete? onComplete;

  @override
  State<AppleSignInSection> createState() => _AppleSignInSectionState();
}

class _AppleSignInSectionState extends State<AppleSignInSection> {
  bool _loading = false;
  bool? _available;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    if (kIsWeb) {
      if (mounted) setState(() => _available = false);
      return;
    }

    final available = await SignInWithApple.isAvailable();

    if (mounted) {
      setState(() => _available = available);
    }
  }

  Future<void> _handleAppleSignIn() async {
    if (_loading || !widget.enabled) return;

    setState(() => _loading = true);

    try {
      final res = await AppleAuthService.signIn();

      if (!mounted) return;
      setState(() => _loading = false);

      widget.onComplete?.call(res);

      if (res['status'] == 'success') {
        AudioService().play('signIn');
        Navigator.pushReplacement(
          context,
          appMaterialPageRoute(
            name: AppRouteNames.main,
            builder: (_) => const EnglishMainScreen(initialMainIndex: 0),
          ),
        );
        return;
      }

      if (res['status'] == 'cancelled') {
        return;
      }

      final messageKey = res['messageKey']?.toString();
      final apiMessage = res['message']?.toString();
      AppToast.showSnackBar(context, 
        SnackBar(
          content: Text(
            (apiMessage != null && apiMessage.isNotEmpty)
                ? apiMessage
                : messageKey != null
                ? context.tr(messageKey)
                : context.tr('login-register.apple-auth-failed'),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppToast.showSnackBar(context, 
        SnackBar(content: Text(context.tr('errors.network'))),
      );
    }
  }

  void _showWebUnavailableMessage() {
    AppToast.showSnackBar(context, 
      SnackBar(content: Text(context.tr('login-register.apple-web-unavailable'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.isSignUp
        ? context.tr('login-register.sign-up-using')
        : context.tr('login-register.sign-in-using');

    final showNativeButton = !kIsWeb && _available != false;
    final showWebHint = kIsWeb;

    if (!showNativeButton && !showWebHint) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (widget.showDivider) ...[
          const SizedBox(height: 8),
          _OrDividerRow(label: label),
          const SizedBox(height: 16),
        ],
        if (_loading)
          const SizedBox(
            height: 52,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          )
        else if (showWebHint)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: widget.enabled ? _showWebUnavailableMessage : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppPageColors.textPrimaryOf(context),
                backgroundColor: AppPageColors.cardBgOf(context),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                side: BorderSide(color: AppPageColors.subtleBorderOf(context)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.apple, size: 22),
              label: Text(context.tr('login-register.apple')),
            ),
          )
        else if (!kIsWeb && (Platform.isIOS || Platform.isMacOS))
          SignInWithAppleButton(
            onPressed: widget.enabled ? _handleAppleSignIn : () {},
            // Apple's own button style: white with an outline on a light
            // page (like the Google button beside it), white on a dark one.
            style: Theme.of(context).brightness == Brightness.dark
                ? SignInWithAppleButtonStyle.white
                : SignInWithAppleButtonStyle.whiteOutlined,
            borderRadius: BorderRadius.circular(14),
            height: 52,
          )
        else
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: widget.enabled ? _handleAppleSignIn : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppPageColors.textPrimaryOf(context),
                backgroundColor: AppPageColors.cardBgOf(context),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                side: BorderSide(color: AppPageColors.subtleBorderOf(context)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.apple, size: 22),
              label: Text(context.tr('login-register.apple')),
            ),
          ),
      ],
    );
  }
}

/// "Sign in using" with a hairline on each side.
class _OrDividerRow extends StatelessWidget {
  const _OrDividerRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppPageColors.subtleBorderOf(context))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: AppPageColors.mutedOf(context)),
          ),
        ),
        Expanded(child: Divider(color: AppPageColors.subtleBorderOf(context))),
      ],
    );
  }
}

/// The divider above the social sign-in buttons, for forms that lay the
/// buttons out themselves.
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key, required this.isSignUp});

  final bool isSignUp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: _OrDividerRow(
        label: context.tr('login-register.or-continue-with'),
      ),
    );
  }
}
