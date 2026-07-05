import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluentdeck/screens/auth/auth_screen.dart';
import 'package:fluentdeck/ui_elements/primary_button.dart';

const String kEnglishOnboardingSeenPrefsKey = 'english_onboarding_seen';
const String kEnglishLevelPrefsKey = 'english_level';

class EnglishOnboardingScreen extends StatefulWidget {
  const EnglishOnboardingScreen({super.key, this.startAtAuth = false});

  final bool startAtAuth;

  @override
  State<EnglishOnboardingScreen> createState() => _EnglishOnboardingScreenState();
}

class _EnglishOnboardingScreenState extends State<EnglishOnboardingScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.startAtAuth) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openAuth());
    }
  }

  Future<void> _openAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kEnglishOnboardingSeenPrefsKey, true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
    );
  }

  Future<void> _continue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kEnglishOnboardingSeenPrefsKey, true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Text(
                'Practice English\nby speaking',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Talk with an AI tutor, get gentle corrections, and build confidence.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
              const Spacer(),
              PrimaryButton(
                text: 'Get started',
                enabled: true,
                onPressed: _continue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
