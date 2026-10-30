import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:riovox/ui_elements/app_motion.dart';
import 'package:riovox/ui_elements/modern_page_widgets.dart';
import 'login_form.dart';
import 'register_form.dart';

enum AuthMode { register, login }

/// Sign in and create account. Each form draws its own header (Rio's tile on
/// sign in, a back arrow on create account), so the whole page slides between
/// the two.
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
        // Sign in ↔ create account: Material shared axis X (create account
        // sits "after" sign in, so it slides in from the right).
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
          child: KeyedSubtree(
            key: ValueKey(_mode),
            child: _mode == AuthMode.login
                ? LoginForm(onSwitch: _setMode)
                : RegisterForm(onSwitch: _setMode),
          ),
        ),
      ),
    );
  }
}

/// Scrolls with the keyboard but keeps [footer] at the bottom of the screen
/// when everything fits.
class AuthPageScroll extends StatelessWidget {
  const AuthPageScroll({
    super.key,
    required this.children,
    required this.footer,
    this.padding = const EdgeInsets.fromLTRB(24, 16, 24, 24),
  });

  final List<Widget> children;
  final Widget footer;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - padding.vertical).clamp(0, double.infinity),
          ),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...children,
                const Spacer(),
                const SizedBox(height: 16),
                footer,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "New here? Create an account": muted text, then a teal link.
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.leading,
    required this.link,
    required this.onTap,
    this.enabled = true,
  });

  final String leading;
  final String link;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '$leading ',
            style: TextStyle(fontSize: 15, color: AppPageColors.subtitleOf(context)),
          ),
          TextButton(
            onPressed: enabled ? onTap : null,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
              minimumSize: const Size(0, 44),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: AppPageColors.accentOf(context),
            ),
            child: Text(
              link,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bold page title and the line under it, shared by the auth pages.
class AuthHeading extends StatelessWidget {
  const AuthHeading({super.key, required this.title, required this.subtitle, this.gap = 16});

  final String title;
  final String subtitle;

  /// Space between the title and the line under it.
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 30,
            height: 1.15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            color: AppPageColors.textPrimaryOf(context),
          ),
        ),
        SizedBox(height: gap),
        Text(
          subtitle,
          style: TextStyle(fontSize: 16, height: 1.4, color: AppPageColors.subtitleOf(context)),
        ),
      ],
    );
  }
}

/// 44 dp back chevron, nudged left so the glyph lines up with the text.
class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Transform.translate(
        offset: const Offset(-10, 0),
        child: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          padding: EdgeInsets.zero,
          icon: Icon(
            Icons.chevron_left_rounded,
            size: 30,
            color: AppPageColors.textPrimaryOf(context),
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
