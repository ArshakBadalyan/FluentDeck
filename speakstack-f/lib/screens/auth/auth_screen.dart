import 'package:flutter/material.dart';
import 'package:untitled2/localization/app_localizations.dart';
import 'login_form.dart';
import 'register_form.dart';
import 'nickname_form.dart';
import '../../ui_elements/auth_tab_switcher.dart';

enum AuthMode { register, login, nickname }

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
              if (_mode != AuthMode.login) ...[
                AuthTabSwitcher(current: _mode, onChanged: _setMode),
                const SizedBox(height: 32),
              ],
              const SizedBox(height: 32),
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
      case AuthMode.nickname:
        return NicknameForm(onSwitch: _setMode);
      case AuthMode.register:
        return RegisterForm(onSwitch: _setMode);
    }
  }
}
