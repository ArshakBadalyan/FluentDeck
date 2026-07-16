import 'package:flutter/material.dart';
import 'package:fluentdeck/localization/app_localizations.dart';
import 'package:fluentdeck/routing/app_route_names.dart';
import 'package:fluentdeck/routing/app_page_routes.dart';
import 'package:fluentdeck/screens/auth/reset_password_screen.dart';
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),

              Text(
                context.tr('forgot-password.forgot-password'),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: context.tr('inputs.your-email'),
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black26),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                height: 50,
                child: ElevatedButton(
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
                              ScaffoldMessenger.of(context).showSnackBar(
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

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7E2BFF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    context.tr('forgot-password.send-email'),
                    style: const TextStyle(fontSize: 16, color: Colors.white),
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
