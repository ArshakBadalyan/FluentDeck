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
  bool _showPlacementPrompt = false;

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
    if (level == null) {
      setState(() {
        _selectedLevel = null;
        _showPlacementPrompt = false;
      });
      return;
    }

    setState(() {
      _selectedLevel = level;
      _showPlacementPrompt = true;
    });

    _showPlacementTestDialog(level);
  }

  Future<void> _showPlacementTestDialog(String level) async {
    await showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Verify your level'),
            content: Text(
              'After you sign up, take the quick placement test (~2 min) to '
              'verify $level. Your verified level will be locked until you retake the test.\n\n'
              'Tap the level again if you prefer to skip for now.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                ),
                child: const Text('Got it'),
              ),
            ],
          ),
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
              if (_showPlacementPrompt && _selectedLevel != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryPurple.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.quiz_outlined,
                        size: 20,
                        color: AppColors.primaryPurple.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Pass the placement test after sign up to verify $_selectedLevel. '
                          'Tap $_selectedLevel again to unselect and continue without a level.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
