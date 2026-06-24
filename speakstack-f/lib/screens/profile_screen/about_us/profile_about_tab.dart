import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:speakstack/localization/app_localizations.dart';
import 'package:speakstack/services/screen_tutorial_service.dart';
import 'package:speakstack/screens/profile_screen/about_us/release_notes_page.dart';
import 'package:speakstack/services/consent_service.dart';
import 'package:speakstack/ui_elements/modern_page_widgets.dart';
import 'package:speakstack/ui_elements/screen_tutorial_explain_sheet.dart';
import 'package:speakstack/services/user_session.dart';
import 'app_review_sheet.dart';
import 'privacy_policy_page.dart';
import 'software_page.dart';

class ProfileAboutTab extends StatefulWidget {
  const ProfileAboutTab({super.key, this.showResetAllScreenTips = false});

  /// Full tutorial reset (prefs wipe). Offered only to admin accounts.
  final bool showResetAllScreenTips;

  @override
  State<ProfileAboutTab> createState() => _ProfileAboutTabState();
}

class _ProfileAboutTabState extends State<ProfileAboutTab> {
  bool _showPrivacyOptions = false;
  bool _hideScreenExplanation = false;

  @override
  void initState() {
    super.initState();
    _refreshPrivacyOptionsVisibility();
    _refreshScreenExplanationVisibility();
  }

  Future<void> _refreshPrivacyOptionsVisibility() async {
    final show = await AdConsentService.isPrivacyOptionsRequired();
    if (!mounted) return;
    if (show != _showPrivacyOptions) {
      setState(() => _showPrivacyOptions = show);
    }
  }

  Future<void> _refreshScreenExplanationVisibility() async {
    final hide = await UserSession.instance.hideScreenExplanation;
    if (!mounted) return;
    if (hide != _hideScreenExplanation) {
      setState(() => _hideScreenExplanation = hide);
    }
  }

  void _openPage(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page, fullscreenDialog: true),
    );
  }

  Future<void> _openPrivacyOptions() async {
    await AdConsentService.showPrivacyOptionsForm();
    await _refreshPrivacyOptionsVisibility();
  }

  Future<void> _openExplainOnePartSheet() =>
      _hideScreenExplanation
          ? Future<void>.value()
          : ScreenTutorialExplainSheet.show(context);

  Future<void> _confirmResetAllTutorialTours() async {
    if (_hideScreenExplanation) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(ctx.tr('profile.about-us.reset-intro-title')),
          content: Text(ctx.tr('profile.about-us.reset-intro-body')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.tr('popups.delete-page-popup.cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ctx.tr('profile.about-us.reset-intro-confirm')),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    await ScreenTutorialReplayCoordinator.resetAll();
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return AppPageBackground(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          AppSectionCard(
            title: context.tr('profile.about-us.privacy'),
            icon: Icons.info_outline_rounded,
            subtitle: 'Help, legal, and app information',
            padding: const EdgeInsets.fromLTRB(8, 18, 8, 8),
            child: Column(
              children: [
                if (!_hideScreenExplanation)
                  AppNavRow(
                    title: context.tr('profile.about-us.show-tips'),
                    icon: Icons.lightbulb_outline_rounded,
                    onTap: _openExplainOnePartSheet,
                  ),
                if (widget.showResetAllScreenTips && !_hideScreenExplanation)
                  AppNavRow(
                    title: context.tr('profile.about-us.reset-intro-tours'),
                    icon: Icons.restart_alt_rounded,
                    onTap: _confirmResetAllTutorialTours,
                  ),
                if (!kIsWeb)
                  AppNavRow(
                    title: context.tr('profile.about-us.write-review'),
                    icon: Icons.star_outline_rounded,
                    onTap: () => showAppReviewSheet(context),
                  ),
                AppNavRow(
                  title: context.tr('profile.about-us.privacy'),
                  icon: Icons.privacy_tip_outlined,
                  onTap: () => _openPage(context, const PrivacyPopup()),
                ),
                if (_showPrivacyOptions)
                  AppNavRow(
                    title: context.tr('profile.about-us.privacy-settings'),
                    icon: Icons.settings_outlined,
                    onTap: _openPrivacyOptions,
                  ),
                AppNavRow(
                  title: context.tr('profile.about-us.software-licenses'),
                  icon: Icons.code_outlined,
                  onTap: () => _openPage(context, const SoftwarePage()),
                ),
                AppNavRow(
                  title: context.tr('profile.about-us.release-notes'),
                  icon: Icons.new_releases_outlined,
                  onTap: () => _openPage(context, const ReleaseNotesPopup()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
