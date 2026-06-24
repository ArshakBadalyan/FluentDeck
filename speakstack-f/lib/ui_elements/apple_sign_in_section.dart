import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:speakstack/localization/app_localizations.dart';

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
  });

  final bool isSignUp;
  final bool enabled;
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
        AudioService().play('formSubmit');
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
      ScaffoldMessenger.of(context).showSnackBar(
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('errors.network'))),
      );
    }
  }

  void _showWebUnavailableMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
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
        const SizedBox(height: 8),
        Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ),
            const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
          ],
        ),
        const SizedBox(height: 16),
        if (_loading)
          const SizedBox(
            height: 50,
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
            height: 50,
            child: OutlinedButton.icon(
              onPressed: widget.enabled ? _showWebUnavailableMessage : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black54,
                side: const BorderSide(color: Colors.black26),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              icon: const Icon(Icons.apple, size: 22),
              label: Text(context.tr('login-register.apple')),
            ),
          )
        else if (!kIsWeb && (Platform.isIOS || Platform.isMacOS))
          SignInWithAppleButton(
            onPressed: widget.enabled ? _handleAppleSignIn : () {},
            style: SignInWithAppleButtonStyle.black,
            borderRadius: BorderRadius.circular(5),
            height: 50,
          )
        else
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: widget.enabled ? _handleAppleSignIn : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
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
