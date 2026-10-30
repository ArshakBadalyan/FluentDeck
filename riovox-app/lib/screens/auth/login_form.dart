import 'package:riovox/ui_elements/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:riovox/config/brand_config.dart';
import 'package:riovox/english_main_screen.dart';
import 'package:riovox/localization/app_localizations.dart';
import 'package:riovox/ui_elements/modern_page_widgets.dart';
import 'package:riovox/widgets/rio.dart';
import '../../routing/app_route_names.dart';
import '../../routing/app_page_routes.dart';
import '../../services/audio_service.dart';
import '../../services/auth_service.dart';
import '../../utils/user_facing_api_error.dart';
import '../../ui_elements/apple_sign_in_section.dart';
import '../../ui_elements/google_sign_in_section.dart';
import '../../ui_elements/auth_input_decoration.dart';
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
    if (!_isValid || _loading) return;
    setState(() => _loading = true);

    try {
      final res = await AuthService.login({
        'identifier': _emailController.text.trim(),
        'password': _passwordController.text,
      });

      if (!mounted) return;
      setState(() => _loading = false);

      if (res['status'] == 'success') {
        AudioService().play('signIn');
        Navigator.pushReplacement(
          context,
          appMaterialPageRoute(
            name: AppRouteNames.main,
            builder: (_) => const EnglishMainScreen(initialMainIndex: 0),
          ),
        );
      } else {
        final messageKey = res['messageKey'] as String?;
        AppToast.showSnackBar(context,
          SnackBar(
            content: Text(
              messageKey != null
                  ? context.tr(messageKey)
                  : res['error']?['message'] ?? context.tr('login-register.sign-in'),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppToast.showSnackBar(context,
        SnackBar(content: Text(context.tr(userFacingErrorLocalizationKey(e)))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageScroll(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      footer: AuthFooterLink(
        leading: context.tr('login-register.new-here'),
        link: context.tr('login-register.create-account'),
        enabled: !_loading,
        onTap: () => widget.onSwitch(AuthMode.register),
      ),
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Container(
            width: 72,
            height: 72,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppPageColors.tintOf(context, AppTint.teal).bg
                  : BrandConfig.tealTintStrong,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Image.asset(
              RioPose.happy.asset,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              semanticLabel: 'Rio',
            ),
          ),
        ),
        const SizedBox(height: 24),
        AuthHeading(
          title: context.tr('login-register.welcome-back'),
          subtitle: context.tr('login-register.sign-in-subtitle'),
        ),
        const SizedBox(height: 24),
        AuthField(
          label: context.tr('login-register.email-or-nickname'),
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          autofillHints: const [AutofillHints.email, AutofillHints.username],
        ),
        const SizedBox(height: 16),
        AuthField(
          label: context.tr('inputs.password'),
          controller: _passwordController,
          obscureText: _obscure,
          autofillHints: const [AutofillHints.password],
          onSubmitted: (_) => _submit(),
          suffix: IconButton(
            icon: Icon(
              _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppPageColors.mutedOf(context),
            ),
            tooltip: _obscure ? 'Show password' : 'Hide password',
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                appMaterialPageRoute(
                  name: AppRouteNames.forgotPassword,
                  builder: (_) => const ForgotPasswordScreen(),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: AppPageColors.accentOf(context),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: const Size(0, 44),
            ),
            child: Text(
              context.tr('login-register.forgot-password-short'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 4),
        PrimaryButton(
          text: context.tr('login-register.sign-in-button'),
          isLoading: _loading,
          enabled: _isValid && !_loading,
          onPressed: _submit,
        ),
        const SizedBox(height: 8),
        // Apple and Google side by side under one divider.
        const AuthOrDivider(isSignUp: false),
        Row(
          children: [
            Expanded(
              child: AppleSignInSection(
                isSignUp: false,
                enabled: !_loading,
                showDivider: false,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GoogleSignInSection(
                isSignUp: false,
                enabled: !_loading,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
