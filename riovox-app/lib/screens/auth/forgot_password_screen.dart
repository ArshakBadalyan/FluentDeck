import 'package:riovox/ui_elements/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:riovox/config/brand_config.dart';
import 'package:riovox/localization/app_localizations.dart';
import 'package:riovox/ui_elements/app_motion.dart';
import 'package:riovox/ui_elements/modern_page_widgets.dart';
import 'package:riovox/routing/app_route_names.dart';
import 'package:riovox/routing/app_page_routes.dart';
import 'package:riovox/screens/auth/reset_password_screen.dart';
import 'package:riovox/ui_elements/auth_input_decoration.dart';
import 'package:riovox/ui_elements/primary_button.dart';
import '../../services/auth_service.dart';
import 'auth_screen.dart';

/// Asks for the email, sends the reset email, then says to check the inbox;
/// the button then opens the screen where the code from that email goes.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _loading = true);
    final res = await AuthService.forgotPassword(_emailController.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);
    if (res['status'] == 'success') {
      setState(() => _sent = true);
    } else {
      AppToast.showSnackBar(context,
        SnackBar(
          content: Text(res['message'] ?? context.tr('forgot-password.send-email')),
        ),
      );
    }
  }

  void _enterCode() {
    Navigator.push(
      context,
      appMaterialPageRoute(
        name: AppRouteNames.resetPassword,
        builder: (_) => const ResetPasswordScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final success = AppPageColors.tintOf(context, AppTint.success);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppPageColors.pageBgOf(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthBackButton(onPressed: () => Navigator.of(context).maybePop()),
              const SizedBox(height: 14),
              AuthHeading(
                gap: 14,
                title: context.tr('forgot-password.title'),
                subtitle: context.tr('forgot-password.subtitle-short'),
              ),
              const SizedBox(height: 22),
              AuthField(
                label: context.tr('login-register.email'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                autofillHints: const [AutofillHints.email],
                onSubmitted: (_) {
                  if (!_sent && _emailController.text.trim().contains('@')) _send();
                },
              ),
              const SizedBox(height: 14),
              PrimaryButton(
                text: context.tr(
                  _sent ? 'forgot-password.enter-code' : 'forgot-password.send-link',
                ),
                isLoading: _loading,
                enabled: !_loading && (_sent || _emailController.text.trim().contains('@')),
                onPressed: _sent ? _enterCode : _send,
              ),
              AnimatedSize(
                duration: AppMotion.duration(context, AppMotion.normal),
                curve: AppMotion.standardCurve,
                alignment: Alignment.topCenter,
                child: !_sent
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: 26),
                        child: AppFadeIn(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: success.bg,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.mail_outline_rounded, size: 22, color: success.fg),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.tr('forgot-password.check-inbox'),
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: success.fg,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        context.tr('forgot-password.check-inbox-body'),
                                        style: TextStyle(
                                          fontSize: 14,
                                          height: 1.4,
                                          color: dark
                                              ? AppPageColors.textPrimaryOf(context)
                                              : BrandConfig.successBody,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
