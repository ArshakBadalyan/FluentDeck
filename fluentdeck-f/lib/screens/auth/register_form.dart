import 'package:flutter/material.dart';
import 'package:fluentdeck/localization/app_localizations.dart';

import 'package:fluentdeck/english_main_screen.dart';
import '../../routing/app_route_names.dart';
import '../../routing/app_page_routes.dart';
import '../../services/audio_service.dart';
import '../../services/auth_service.dart';
import '../../ui_elements/apple_sign_in_section.dart';
import '../../ui_elements/auth_input_decoration.dart';
import '../../ui_elements/auth_secondary_link.dart';
import '../../ui_elements/primary_button.dart';
import '../../utils/user_facing_api_error.dart';
import 'auth_screen.dart';

class RegisterForm extends StatefulWidget {
  final void Function(AuthMode) onSwitch;

  const RegisterForm({super.key, required this.onSwitch});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _submitLocked = false;
  bool _obscure = true;

  bool get _isValid =>
      _nicknameController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty &&
      _emailController.text.trim().contains('@');

  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(() => setState(() {}));
    _emailController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitLocked || _loading || !_isValid) return;

    _submitLocked = true;
    setState(() => _loading = true);

    try {
      final res = await AuthService.register({
        'username': _nicknameController.text.trim(),
        'password': _passwordController.text,
        'email': _emailController.text.trim(),
      });

      if (!mounted) return;

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

      setState(() {
        _loading = false;
        _submitLocked = false;
      });
      final messageKey = res['messageKey'] as String?;
      final apiMessage = res['error'] is Map
          ? res['error']['message']?.toString()
          : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            messageKey != null
                ? context.tr(messageKey)
                : (apiMessage != null && apiMessage.isNotEmpty)
                    ? apiMessage
                    : context.tr('login-register.sign-up'),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _submitLocked = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr(userFacingErrorLocalizationKey(e)))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _nicknameController,
          decoration: authInput(context.tr('inputs.nickname')),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          decoration: authInput(context.tr('inputs.E-mail-address')),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _passwordController,
          obscureText: _obscure,
          decoration: authInput(context.tr('inputs.password')).copyWith(
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
              tooltip: _obscure ? 'Show password' : 'Hide password',
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          text:
              _loading
                  ? '${context.tr('over.loading')}...'
                  : context.tr('login-register.sign-up'),
          enabled: _isValid && !_loading,
          onPressed: _submit,
        ),
        AppleSignInSection(
          isSignUp: true,
          enabled: !_loading,
        ),
        const Spacer(),
        AuthInlineSwitchLink(
          leadingText: context.tr('login-register.already-have-account'),
          linkLabel: context.tr('login-register.sign-in'),
          enabled: !_loading,
          onLinkPressed: () => widget.onSwitch(AuthMode.login),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
