import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluentdeck/localization/app_localizations.dart';

import '../services/google_auth_service.dart';
import '../services/audio_service.dart';
import '../english_main_screen.dart';
import '../routing/app_route_names.dart';
import '../routing/app_page_routes.dart';

typedef GoogleAuthComplete = void Function(Map<String, dynamic> result);

const String _googleLogoSvg = '''
<svg width="20" height="20" viewBox="0 0 18 18" xmlns="http://www.w3.org/2000/svg">
  <path fill="#4285F4" d="M17.64 9.2045c0-.6381-.0573-1.2518-.1636-1.8409H9v3.4814h4.8436c-.2086 1.125-.8427 2.0782-1.7959 2.7164v2.2582h2.9087c1.7018-1.5668 2.6836-3.8741 2.6836-6.6151z"/>
  <path fill="#34A853" d="M9 18c2.43 0 4.4673-.8059 5.9564-2.1805l-2.9087-2.2582c-.8059.54-1.8368.8591-3.0477.8591-2.3441 0-4.3282-1.5831-5.0359-3.7104H.9573v2.3318C2.4382 15.9832 5.4818 18 9 18z"/>
  <path fill="#FBBC05" d="M3.9641 10.71c-.18-.54-.2822-1.1168-.2822-1.71s.1023-1.17.2822-1.71V4.9582H.9573C.3477 6.1732 0 7.5477 0 9s.3477 2.8268.9573 4.0418L3.9641 10.71z"/>
  <path fill="#EA4335" d="M9 3.5795c1.3214 0 2.5077.4541 3.4405 1.346l2.5814-2.5814C13.4632.8918 11.4259 0 9 0 5.4818 0 2.4382 2.0168.9573 4.9582L3.9641 7.29C4.6718 5.1627 6.6559 3.5795 9 3.5795z"/>
</svg>
''';

/// Shared Sign in with Google button for login and registration screens.
class GoogleSignInSection extends StatefulWidget {
  const GoogleSignInSection({
    super.key,
    required this.isSignUp,
    required this.enabled,
    this.onComplete,
  });

  final bool isSignUp;
  final bool enabled;
  final GoogleAuthComplete? onComplete;

  @override
  State<GoogleSignInSection> createState() => _GoogleSignInSectionState();
}

class _GoogleSignInSectionState extends State<GoogleSignInSection> {
  bool _loading = false;

  void _showWebUnavailableMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('login-register.google-web-unavailable')),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    if (_loading || !widget.enabled) return;

    setState(() => _loading = true);

    try {
      final res = await GoogleAuthService.signIn();

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
                : context.tr('login-register.google-auth-failed'),
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 50,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed:
            !widget.enabled
                ? null
                : kIsWeb
                ? _showWebUnavailableMessage
                : _handleGoogleSignIn,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black87,
          side: const BorderSide(color: Colors.black26),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        icon: SvgPicture.string(_googleLogoSvg, width: 20, height: 20),
        label: Text(context.tr('login-register.google')),
      ),
    );
  }
}
