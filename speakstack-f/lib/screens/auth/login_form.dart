import 'package:flutter/material.dart';
import 'package:untitled2/english_main_screen.dart';
import 'package:untitled2/localization/app_localizations.dart';
import '../../routing/app_route_names.dart';
import '../../routing/mathe_page_routes.dart';
import '../../services/audio_service.dart';
import '../../services/auth_service.dart';
import '../../ui_elements/auth_input_decoration.dart';
import '../../ui_elements/auth_secondary_link.dart';
import '../../ui_elements/primary_button.dart';
import 'auth_screen.dart';
import 'forgot_password_screen.dart';

class LoginForm extends StatefulWidget {
  final void Function(AuthMode) onSwitch;

  const LoginForm({super.key, required this.onSwitch});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  bool get _isValid =>
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);

    final res = await AuthService.login({
      'identifier': _emailController.text.trim(),
      'password': _passwordController.text,
    });

    if (!mounted) return;
    setState(() => _loading = false);

    if (res['status'] == 'success') {
      AudioService().play('formSubmit');
      Navigator.pushReplacement(
        context,
        matheMaterialPageRoute(
          name: AppRouteNames.main,
          builder: (_) => const EnglishMainScreen(initialMainIndex: 0),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['error']?['message'] ?? context.tr('login-register.sign-in'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: authInput(context.tr('inputs.E-mail-nickname')),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _passwordController,
          obscureText: _obscure,
          decoration: authInput(context.tr('inputs.password')).copyWith(
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                matheMaterialPageRoute(
                  name: AppRouteNames.forgotPassword,
                  builder: (_) => const ForgotPasswordScreen(),
                ),
              );
            },
            child: Text(
              context.tr('login-register.forgot-password'),
              style: const TextStyle(fontSize: 14, color: Colors.black),
              textAlign: TextAlign.end,
            ),
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          text:
              _loading
                  ? '${context.tr('over.loading')}...'
                  : context.tr('login-register.sign-in'),
          enabled: _isValid && !_loading,
          onPressed: _submit,
        ),
        const Spacer(),
        AuthInlineSwitchLink(
          leadingText: context.tr('login-register.dont-have-account'),
          linkLabel: context.tr('login-register.sign-up'),
          enabled: !_loading,
          onLinkPressed: () => widget.onSwitch(AuthMode.register),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
