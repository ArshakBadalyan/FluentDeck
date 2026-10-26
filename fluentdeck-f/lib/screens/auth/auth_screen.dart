import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:fluentdeck/localization/app_localizations.dart';
import 'package:fluentdeck/ui_elements/app_motion.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';
import 'package:fluentdeck/widgets/rio.dart';
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
      backgroundColor: AppPageColors.pageBgOf(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // Rio greets the learner; the title is bold and left-aligned.
              Container(
                width: 64,
                height: 64,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppPageColors.accentOf(context).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Transform.scale(
                  scale: 1.9,
                  alignment: const Alignment(0, -0.6),
                  child: Image.asset(
                    RioPose.happy.asset,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              AppFadeThroughSwitcher(
                child: Text(
                  _mode == AuthMode.login
                      ? context.tr('login-register.sign-in')
                      : context.tr('login-register.sign-up'),
                  key: ValueKey(_mode),
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: AppPageColors.textPrimaryOf(context),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              AppFadeThroughSwitcher(
                child: Text(
                  _mode == AuthMode.login
                      ? context.tr('login-register.sign-in-subtitle')
                      : context.tr('login-register.sign-up-subtitle'),
                  key: ValueKey('subtitle-$_mode'),
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.4,
                    color: AppPageColors.subtitleOf(context),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Sign in ↔ register: Material shared axis X (register sits
              // "after" sign in, so it slides in from the right).
              Expanded(
                child: PageTransitionSwitcher(
                  duration: AppMotion.duration(context, AppMotion.normal),
                  reverse: _mode == AuthMode.login,
                  transitionBuilder: (child, animation, secondaryAnimation) =>
                      SharedAxisTransition(
                        animation: animation,
                        secondaryAnimation: secondaryAnimation,
                        transitionType: SharedAxisTransitionType.horizontal,
                        fillColor: Colors.transparent,
                        child: child,
                      ),
                  child: KeyedSubtree(key: ValueKey(_mode), child: _buildForm()),
                ),
              ),
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
