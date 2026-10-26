import 'package:fluentdeck/ui_elements/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:fluentdeck/localization/app_localizations.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';
import 'package:fluentdeck/routing/app_route_names.dart';
import 'package:fluentdeck/routing/app_page_routes.dart';
import 'package:fluentdeck/screens/auth/reset_password_screen.dart';
import 'package:fluentdeck/ui_elements/auth_input_decoration.dart';
import 'package:fluentdeck/ui_elements/auth_secondary_link.dart';
import '../../services/auth_service.dart';
import 'auth_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPageColors.pageBgOf(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: IconButton(
                  tooltip: 'Back',
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: AppPageColors.textPrimaryOf(context),
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              const SizedBox(height: 12),

              // Bold, left-aligned title with a one-line explanation.
              Text(
                context.tr('forgot-password.forgot-password'),
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: AppPageColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr('forgot-password.subtitle'),
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: AppPageColors.subtitleOf(context),
                ),
              ),

              const SizedBox(height: 28),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: authInput(context, context.tr('inputs.your-email')),
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 56,
                // FilledButton (not ElevatedButton+hardcoded colors): the
                // app's own filledButtonTheme already pairs light/dark
                // backgrounds with correctly readable text in both modes.
                child: FilledButton(
                  onPressed:
                      _loading
                          ? null
                          : () async {
                            setState(() => _loading = true);
                            debugPrint(
                              'FORGOT EMAIL = "$_emailController.text.trim()"',
                            );

                            final res = await AuthService.forgotPassword(
                              _emailController.text.trim(),
                            );
                            debugPrint('FORGOT RESPONSE = $res');

                            if (!mounted) return;
                            setState(() => _loading = false);

                            if (res['status'] == 'success') {
                              Navigator.push(
                                context,
                                appMaterialPageRoute(
                                  name: AppRouteNames.resetPassword,
                                  builder:
                                      (_) => const ResetPasswordScreen(),
                                ),
                              );
                            } else {
                              AppToast.showSnackBar(context, 
                                SnackBar(
                                  content: Text(
                                    res['message'] ??
                                        context.tr(
                                          'forgot-password.send-email',
                                        ),
                                  ),
                                ),
                              );
                            }
                          },

                  style: FilledButton.styleFrom(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    context.tr('forgot-password.send-email'),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              AuthSecondaryLink(
                label: context.tr('forgot-password.back-to-start'),
                enabled: !_loading,
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    appMaterialPageRoute(
                      name: AppRouteNames.auth,
                      builder: (_) => const AuthScreen(),
                    ),
                  );
                },
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
