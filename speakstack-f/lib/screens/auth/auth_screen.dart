import 'package:flutter/material.dart';
import 'package:speakstack/localization/app_localizations.dart';
import 'login_form.dart';
import 'register_form.dart';

enum AuthMode { register, login }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.initialMode = AuthMode.login});

  final AuthMode initialMode;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late AuthMode _mode = widget.initialMode;

  void _setMode(AuthMode mode) {
    setState(() => _mode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 56),
              Text(
                _mode == AuthMode.login
                    ? context.tr('login-register.sign-in')
                    : context.tr('login-register.sign-up'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 48),
              Expanded(child: _buildForm()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    switch (_mode) {
      case AuthMode.login:
        return LoginForm(onSwitch: _setMode);
      case AuthMode.register:
        return RegisterForm(onSwitch: _setMode);
    }
  }
}
