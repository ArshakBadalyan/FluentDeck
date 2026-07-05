import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/screens/auth/auth_screen.dart';
import 'package:fluentdeck/services/english_level_service.dart';
import 'package:fluentdeck/ui_elements/primary_button.dart';
import 'package:fluentdeck/widgets/cefr_level_chips.dart';

const String kEnglishOnboardingSeenPrefsKey = 'english_onboarding_seen';
const String kEnglishLevelPrefsKey = 'english_level';

class EnglishOnboardingScreen extends StatefulWidget {
  const EnglishOnboardingScreen({super.key, this.startAtAuth = false});

  final bool startAtAuth;

  @override
  State<EnglishOnboardingScreen> createState() => _EnglishOnboardingScreenState();
}

class _EnglishOnboardingScreenState extends State<EnglishOnboardingScreen> {
  String? _selectedLevel;

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
    if (_selectedLevel != null) {
      await EnglishLevelService.instance.setLevelFromOnboarding(_selectedLevel!);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kEnglishOnboardingSeenPrefsKey, true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
    );
  }

  void _onLevelSelected(String? level) {
    setState(() => _selectedLevel = level);
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
              const SizedBox(height: 40),
              const Text(
                'Your level (CEFR)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Optional — choose a level or skip and continue',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              CefrLevelChips(
                selectedLevel: _selectedLevel,
                onLevelSelected: _onLevelSelected,
                allowDeselect: true,
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
