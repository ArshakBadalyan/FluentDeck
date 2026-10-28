import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/config/brand_config.dart';
import 'package:fluentdeck/localization/app_localizations.dart';
import 'package:fluentdeck/screens/auth/auth_screen.dart';
import 'package:fluentdeck/services/app_feature_config_service.dart';
import 'package:fluentdeck/ui_elements/app_motion.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';
import 'package:fluentdeck/ui_elements/primary_button.dart';
import 'package:fluentdeck/utils/practice_time_format.dart';
import 'package:fluentdeck/widgets/rio.dart';

const String kEnglishOnboardingSeenPrefsKey = 'english_onboarding_seen';
const String kEnglishLevelPrefsKey = 'english_level';

/// First-run intro (before sign-in): what Riovox does and how to use it —
/// speak with the AI tutor, what to practise, mistakes → flashcards, progress,
/// and what's free. Text lives under `onboarding.*` in assets/locales.
class EnglishOnboardingScreen extends StatefulWidget {
  const EnglishOnboardingScreen({
    super.key,
    this.startAtAuth = false,
    this.authMode = AuthMode.login,
    this.nextScreenBuilder,
  });

  final bool startAtAuth;

  /// Which form the auth screen opens on (sign-up for new web visitors).
  final AuthMode authMode;

  /// Screen shown after onboarding; sign-in by default (overridable in tests).
  final WidgetBuilder? nextScreenBuilder;

  @override
  State<EnglishOnboardingScreen> createState() => _EnglishOnboardingScreenState();
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.id,
    required this.icon,
    required this.rio,
    required this.accent,
    this.chips = const [],
  });

  final String id;
  final IconData icon;

  /// Rio's pose on this page (shown in place of [icon]).
  final RioPose rio;
  final Color accent;

  /// Keys of short highlights shown under the text.
  final List<String> chips;
}

const _pages = [
  _OnboardingPage(
    id: 'speak',
    icon: Icons.mic_rounded,
    rio: RioPose.wave,
    // Brand teal glow behind Rio on the first screen (Lagoon Daylight).
    accent: AppColors.brandPrimary,
    chips: ['voice-or-text', 'gentle-corrections', 'remembers-you'],
  ),
  _OnboardingPage(
    id: 'practice',
    icon: Icons.forum_rounded,
    rio: RioPose.excited,
    accent: AppColors.brandPrimary,
    chips: ['topics', 'role-plays', 'games', 'languages'],
  ),
  _OnboardingPage(
    id: 'flashcards',
    icon: Icons.style_rounded,
    rio: RioPose.catchFish,
    accent: AppColors.brandPrimaryDeep,
    chips: ['auto-saved', 'spaced-repetition', 'anki-import'],
  ),
  _OnboardingPage(
    id: 'progress',
    icon: Icons.local_fire_department_rounded,
    rio: RioPose.determined,
    accent: AppColors.primaryYellow,
    chips: ['daily-goal', 'streak', 'cefr-level'],
  ),
  _OnboardingPage(
    id: 'plan',
    icon: Icons.workspace_premium_rounded,
    rio: RioPose.happy,
    accent: AppColors.brandPrimary,
  ),
];

class _EnglishOnboardingScreenState extends State<EnglishOnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  bool get _isLast => _page == _pages.length - 1;

  @override
  void initState() {
    super.initState();
    if (widget.startAtAuth) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
      return;
    }
    // The plan page shows the real free / Premium minutes. The config is
    // public (no sign-in needed); defaults are used until it arrives.
    unawaited(
      AppFeatureConfigService.instance.fetch().then((_) {
        if (mounted) setState(() {});
      }).catchError((Object _) {}),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kEnglishOnboardingSeenPrefsKey, true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder:
            widget.nextScreenBuilder ??
            (_) => AuthScreen(initialMode: widget.authMode),
      ),
    );
  }

  void _next() {
    if (_isLast) {
      unawaited(_finish());
      return;
    }
    _controller.nextPage(
      duration: AppMotion.duration(context, AppMotion.normal),
      curve: AppMotion.standardCurve,
    );
  }

  Future<void> _pickLanguage() async {
    final l10n = AppLocalizations.instance;
    final picked = await showAppSelectSheet<String>(
      context: context,
      title: context.tr('onboarding.language'),
      selected: l10n.language,
      options: [
        for (final option in l10n.availableOptions)
          AppSelectOption(
            value: option.code,
            label: option.code == 'en'
                ? option.nativeName
                : '${option.nativeName}  ·  ${option.englishName}',
          ),
      ],
    );
    if (picked == null) return;
    await l10n.setLanguage(picked.value);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.startAtAuth) {
      return Scaffold(backgroundColor: AppPageColors.pageBgOf(context));
    }
    final current = AppLocalizations.instance;
    final currentName =
        current.availableOptions
            .where((o) => o.code == current.language)
            .firstOrNull
            ?.nativeName ??
        'English';

    return Scaffold(
      backgroundColor: AppPageColors.pageBgOf(context),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 14, 0),
              child: Row(
                children: [
                  // App language, as a pill: globe + its name.
                  OutlinedButton.icon(
                    onPressed: _pickLanguage,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      backgroundColor: AppPageColors.cardBgOf(context),
                      foregroundColor: AppPageColors.textPrimaryOf(context),
                      side: BorderSide(color: AppPageColors.subtleBorderOf(context)),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    icon: const Icon(Icons.language_rounded, size: 16),
                    label: Text(currentName),
                  ),
                  const Spacer(),
                  // Skip disappears on the last page (the button there finishes).
                  AnimatedOpacity(
                    opacity: _isLast ? 0 : 1,
                    duration: AppMotion.duration(context, AppMotion.fast),
                    child: TextButton(
                      onPressed: _isLast ? null : () => unawaited(_finish()),
                      style: TextButton.styleFrom(
                        foregroundColor: AppPageColors.accentOf(context),
                        minimumSize: const Size(44, 44),
                        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      child: Text(context.tr('onboarding.skip')),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _OnboardingPageView(page: _pages[i]),
              ),
            ),
            _PageDots(count: _pages.length, index: _page),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
              child: PrimaryButton(
                text: context.tr(_isLast ? 'onboarding.get-started' : 'onboarding.next'),
                enabled: true,
                analyticsId: _isLast ? 'onboarding.get_started' : 'onboarding.next',
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({required this.page});

  final _OnboardingPage page;

  /// Teal accents switch to the lighter on-dark teal in dark mode, or the
  /// icon and ticks would vanish into the dark background.
  Color _accentFor(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (dark &&
        (page.accent == AppColors.brandPrimary ||
            page.accent == AppColors.brandPrimaryDeep)) {
      return AppColors.brandPrimaryOnDark;
    }
    return page.accent;
  }

  @override
  Widget build(BuildContext context) {
    final key = 'onboarding.pages.${page.id}';
    final accent = _accentFor(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Highlights take turns: teal, coral, yellow.
    const tints = [AppTint.teal, AppTint.voice, AppTint.reward];
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              AppFadeIn(
                child: Container(
                  width: 260,
                  height: 260,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.2),
                      radius: 0.7,
                      colors: [
                        dark ? accent.withValues(alpha: 0.18) : BrandConfig.tealGlow,
                        AppPageColors.pageBgOf(context),
                      ],
                    ),
                  ),
                  child: RioImage(page.rio, height: 200, motion: RioMotion.pop),
                ),
              ),
              const SizedBox(height: 22),
              AppFadeIn(
                delay: const Duration(milliseconds: 60),
                child: Text(
                  context.tr('$key.title'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    letterSpacing: -0.6,
                    color: AppPageColors.textPrimaryOf(context),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              AppFadeIn(
                delay: const Duration(milliseconds: 120),
                child: Text(
                  context.tr('$key.body'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: AppPageColors.subtitleOf(context),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              if (page.id == 'plan')
                const _PlanSummary()
              else
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (i, chip) in page.chips.indexed)
                      AppStaggeredFadeIn(
                        index: i + 3,
                        child: _Highlight(
                          text: context.tr('$key.chips.$chip'),
                          tint: tints[i % tints.length],
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _Highlight extends StatelessWidget {
  const _Highlight({required this.text, required this.tint});

  final String text;
  final AppTint tint;

  @override
  Widget build(BuildContext context) {
    final colors = AppPageColors.tintOf(context, tint);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.fg),
      ),
    );
  }
}

/// Free vs Premium, from the server's limits (defaults until it loads).
class _PlanSummary extends StatelessWidget {
  const _PlanSummary();

  @override
  Widget build(BuildContext context) {
    final config = AppFeatureConfigService.instance.config;
    Widget row(IconData icon, Color color, String title, String body) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPageColors.cardBgOf(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppPageColors.subtleBorderOf(context)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppPageColors.textPrimaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: TextStyle(color: AppPageColors.subtitleOf(context), height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return Column(
      children: [
        AppStaggeredFadeIn(
          index: 3,
          child: row(
            Icons.lock_open_rounded,
            AppPageColors.accentOf(context),
            context.tr('onboarding.pages.plan.free-title'),
            context.tr(
              'onboarding.pages.plan.free-body',
              vars: {'time': formatPracticeMinutes(config.freeDailyMinutes)},
            ),
          ),
        ),
        AppStaggeredFadeIn(
          index: 4,
          child: row(
            Icons.workspace_premium_rounded,
            AppColors.primaryYellow,
            context.tr('onboarding.pages.plan.premium-title'),
            context.tr(
              'onboarding.pages.plan.premium-body',
              vars: {'time': formatPracticeMinutes(config.premiumDailyMinutes)},
            ),
          ),
        ),
      ],
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final accent = AppPageColors.accentOf(context);
    final idle = Theme.of(context).brightness == Brightness.dark
        ? accent.withValues(alpha: 0.25)
        : BrandConfig.tealTintStrong;
    return Semantics(
      label: 'Step ${index + 1} of $count',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: AppMotion.duration(context, AppMotion.normal),
              curve: AppMotion.standardCurve,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == index ? accent : idle,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}
