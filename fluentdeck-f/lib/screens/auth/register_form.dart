import 'dart:async';

import 'package:riovox/ui_elements/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:riovox/app_colors.dart';
import 'package:riovox/localization/app_localizations.dart';
import 'package:riovox/models/speaking_preferences.dart';
import 'package:riovox/english_main_screen.dart';
import 'package:riovox/screens/profile_screen/about_us/privacy_policy_page.dart';
import 'package:riovox/services/app_feature_config_service.dart';
import 'package:riovox/services/speaking_preferences_service.dart';
import 'package:riovox/ui_elements/modern_page_widgets.dart';
import '../../routing/app_route_names.dart';
import '../../routing/app_page_routes.dart';
import '../../services/audio_service.dart';
import '../../services/auth_service.dart';
import '../../ui_elements/auth_input_decoration.dart';
import '../../ui_elements/primary_button.dart';
import '../../utils/user_facing_api_error.dart';
import 'auth_screen.dart';

/// Shortest password the form accepts.
const int kMinPasswordLength = 8;

class RegisterForm extends StatefulWidget {
  final void Function(AuthMode) onSwitch;

  const RegisterForm({super.key, required this.onSwitch});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _submitLocked = false;
  bool _obscure = true;

  /// The password message shows once the learner has tried to submit.
  bool _triedSubmit = false;

  /// "I speak" (help and translations) → "I want to speak" (practice).
  late String _native = _defaultNative();
  late String _target = _native == 'en' ? 'es' : 'en';

  static Map<String, String> get _nativeOptions => {
    for (final e in SpeakingPreferences.translationLanguageOptions.entries)
      if (e.key != 'none') e.key: e.value,
  };

  static String _defaultNative() {
    final app = AppLocalizations.instance.language;
    return _nativeOptions.containsKey(app) ? app : 'en';
  }

  bool get _passwordTooShort => _passwordController.text.length < kMinPasswordLength;

  bool get _isFilled =>
      _nicknameController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty &&
      _emailController.text.trim().contains('@');

  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(() => setState(() {}));
    _emailController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
    // The subtitle names the real free minutes; defaults until it loads.
    unawaited(
      AppFeatureConfigService.instance.fetch().then((_) {
        if (mounted) setState(() {});
      }).catchError((Object _) {}),
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickLanguage({required bool native}) async {
    final options = native
        ? _nativeOptions
        : SpeakingPreferences.selectablePracticeLanguages(current: _target);
    final picked = await showAppSelectSheet<String>(
      context: context,
      title: context.tr(native ? 'login-register.i-speak' : 'login-register.i-want-to-speak'),
      selected: native ? _native : _target,
      options: [
        for (final e in options.entries) AppSelectOption(value: e.key, label: e.value),
      ],
    );
    if (picked == null || !mounted) return;
    setState(() {
      final code = picked.value;
      if (native) {
        // Picking the other side's language swaps the pair.
        if (code == _target) _target = _native;
        _native = code;
      } else {
        if (code == _native && _nativeOptions.containsKey(_target)) _native = _target;
        _target = code;
      }
    });
  }

  /// Best effort: the account exists even if this fails; the languages can
  /// be changed later in Settings.
  Future<void> _saveLanguages() async {
    try {
      final service = SpeakingPreferencesService.instance;
      final prefs = await service.load(forceRefresh: true);
      await service.save(
        prefs.copyWith(practiceLanguage: _target, translationLanguage: _native),
      );
    } catch (_) {}
  }

  Future<void> _submit() async {
    setState(() => _triedSubmit = true);
    if (_submitLocked || _loading || !_isFilled || _passwordTooShort) return;

    _submitLocked = true;
    setState(() => _loading = true);

    try {
      final res = await AuthService.register({
        'username': _nicknameController.text.trim(),
        'password': _passwordController.text,
        'email': _emailController.text.trim(),
      });

      if (!mounted) return;

      if (res['status'] == 'success') {
        await _saveLanguages();
        if (!mounted) return;
        AudioService().play('signIn');
        Navigator.pushReplacement(
          context,
          appMaterialPageRoute(
            name: AppRouteNames.main,
            builder: (_) => const EnglishMainScreen(initialMainIndex: 0),
          ),
        );
        return;
      }

      setState(() {
        _loading = false;
        _submitLocked = false;
      });
      final messageKey = res['messageKey'] as String?;
      final apiMessage = res['error'] is Map
          ? res['error']['message']?.toString()
          : null;
      AppToast.showSnackBar(context,
        SnackBar(
          content: Text(
            messageKey != null
                ? context.tr(messageKey)
                : (apiMessage != null && apiMessage.isNotEmpty)
                    ? apiMessage
                    : context.tr('login-register.sign-up'),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _submitLocked = false;
        });
        AppToast.showSnackBar(context,
          SnackBar(content: Text(context.tr(userFacingErrorLocalizationKey(e)))),
        );
      }
    }
  }

  void _openPrivacy() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const PrivacyPopup()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final minutes = AppFeatureConfigService.instance.config.freeDailyMinutes;
    final muted = AppPageColors.subtitleOf(context);
    final accent = AppPageColors.accentOf(context);
    Widget link(String text) => InkWell(
      onTap: _openPrivacy,
      borderRadius: BorderRadius.circular(4),
      child: Text(text, style: TextStyle(fontSize: 12, height: 1.5, color: accent)),
    );

    return AuthPageScroll(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      footer: AuthFooterLink(
        leading: context.tr('login-register.have-account'),
        link: context.tr('login-register.sign-in-link'),
        enabled: !_loading,
        onTap: () => widget.onSwitch(AuthMode.login),
      ),
      children: [
        AuthBackButton(onPressed: () => widget.onSwitch(AuthMode.login)),
        const SizedBox(height: 14),
        AuthHeading(
          gap: 14,
          title: context.tr('login-register.start-free'),
          subtitle: context.tr(
            'login-register.sign-up-subtitle-minutes',
            vars: {'count': minutes},
          ),
        ),
        const SizedBox(height: 18),
        Text(
          context.tr('login-register.language-pair'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppPageColors.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _LanguageButton(
                label: _nativeOptions[_native] ?? _native,
                semanticPrefix: context.tr('login-register.i-speak'),
                selected: false,
                onTap: _loading ? null : () => _pickLanguage(native: true),
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_rounded, size: 20, color: AppColors.voice),
            const SizedBox(width: 10),
            Expanded(
              child: _LanguageButton(
                label: SpeakingPreferences.practiceLanguageOptions[_target] ?? _target,
                semanticPrefix: context.tr('login-register.i-want-to-speak'),
                selected: true,
                onTap: _loading ? null : () => _pickLanguage(native: false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AuthField(
          label: context.tr('inputs.nickname'),
          controller: _nicknameController,
          autocorrect: false,
          autofillHints: const [AutofillHints.newUsername],
        ),
        const SizedBox(height: 14),
        AuthField(
          label: context.tr('login-register.email'),
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: 14),
        AuthField(
          label: context.tr('inputs.password'),
          controller: _passwordController,
          obscureText: _obscure,
          autofillHints: const [AutofillHints.newPassword],
          onSubmitted: (_) => _submit(),
          errorText: _triedSubmit && _passwordTooShort
              ? context.tr(
                  'login-register.password-min',
                  vars: {'count': kMinPasswordLength},
                )
              : null,
          suffix: IconButton(
            icon: Icon(
              _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppPageColors.mutedOf(context),
            ),
            tooltip: _obscure ? 'Show password' : 'Hide password',
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          text: context.tr('login-register.create-account-button'),
          isLoading: _loading,
          enabled: _isFilled && !_loading,
          analyticsId: 'auth.register.submit',
          onPressed: _submit,
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              context.tr('login-register.legal-before'),
              style: TextStyle(fontSize: 12, height: 1.5, color: muted),
            ),
            link(context.tr('login-register.terms')),
            Text(
              context.tr('login-register.legal-and'),
              style: TextStyle(fontSize: 12, height: 1.5, color: muted),
            ),
            // The link and the end of the sentence wrap together.
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                link(context.tr('login-register.privacy')),
                Text(
                  context.tr('login-register.legal-after'),
                  style: TextStyle(fontSize: 12, height: 1.5, color: muted),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// One side of the language pair; the language being learned is highlighted.
class _LanguageButton extends StatelessWidget {
  const _LanguageButton({
    required this.label,
    required this.semanticPrefix,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String semanticPrefix;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tint = AppPageColors.tintOf(context, AppTint.teal);
    return Semantics(
      button: true,
      label: '$semanticPrefix: $label',
      excludeSemantics: true,
      child: Material(
        color: selected ? tint.bg : AppPageColors.cardBgOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: selected
              ? BorderSide(color: AppPageColors.accentOf(context), width: 2)
              : BorderSide(color: AppPageColors.subtleBorderOf(context)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 52,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: selected ? tint.fg : AppPageColors.textPrimaryOf(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
