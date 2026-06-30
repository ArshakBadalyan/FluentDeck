import 'package:flutter/material.dart';
import 'package:fluentdeck/localization/app_localizations.dart';
import 'package:fluentdeck/routing/app_route_names.dart';
import 'package:fluentdeck/routing/app_page_routes.dart';
import 'package:fluentdeck/ui_elements/auth_secondary_link.dart';
import '../../services/auth_service.dart';
import 'auth_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _loading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('reset-password.error-msg'))),
      );
      return;
    }

    setState(() => _loading = true);

    final res = await AuthService.resetPassword({
      'code': _codeController.text.trim(),
      'password': _passwordController.text,
      'passwordConfirmation': _confirmController.text,
    });

    if (!mounted) return;
    setState(() => _loading = false);

    if (res['status'] == 'success') {
      Navigator.pushReplacement(
        context,
        appMaterialPageRoute(
          name: AppRouteNames.auth,
          builder: (_) => const AuthScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['message'] ?? context.tr('reset-password.reset-password'),
          ),
        ),
      );
    }
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
                context.tr('reset-password.reset-password'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 40),

              TextField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: context.tr('inputs.paste-email'),
                  enabledBorder: UnderlineInputBorder(),
                  focusedBorder: UnderlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: _passwordController,
                obscureText: _obscure1,
                decoration: InputDecoration(
                  labelText: context.tr('inputs.enter-password'),
                  enabledBorder: const UnderlineInputBorder(),
                  focusedBorder: const UnderlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure1 ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _obscure1 = !_obscure1),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: _confirmController,
                obscureText: _obscure2,
                decoration: InputDecoration(
                  labelText: context.tr('inputs.enter-password-again'),
                  enabledBorder: const UnderlineInputBorder(),
                  focusedBorder: const UnderlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure2 ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _obscure2 = !_obscure2),
                  ),
                ),
              ),

              const Spacer(),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7E2BFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _loading
                        ? '${context.tr('over.loading')}...'
                        : context.tr('reset-password.reset-password'),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              AuthSecondaryLink(
                label: context.tr('reset-password.back-to-login'),
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

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
