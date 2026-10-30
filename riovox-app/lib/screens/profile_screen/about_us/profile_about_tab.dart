import 'package:riovox/ui_elements/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:riovox/screens/profile_screen/about_us/help_faq_page.dart';
import 'package:riovox/localization/app_localizations.dart';
import 'package:riovox/services/screen_tutorial_service.dart';
import 'package:riovox/screens/profile_screen/about_us/release_notes_page.dart';
import 'package:riovox/services/consent_service.dart';
import 'package:riovox/ui_elements/modern_page_widgets.dart';
import 'package:riovox/ui_elements/screen_tutorial_explain_sheet.dart';
import 'package:riovox/services/user_session.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:riovox/ui_elements/riovox_wordmark.dart';
import 'package:riovox/widgets/rio.dart';
import 'package:riovox/ui_elements/app_motion.dart';
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
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Future<void> _openPrivacyOptions() async {
    await AdConsentService.showPrivacyOptionsForm();
    await _refreshPrivacyOptionsVisibility();
  }

  Future<void> _contactSupport() async {
    final email = context.tr('privacy-content.contact-email');
    await launchUrl(Uri.parse('mailto:$email?subject=Riovox%20help'));
  }

  Future<void> _openExplainOnePartSheet() =>
      _hideScreenExplanation
          ? Future<void>.value()
          : ScreenTutorialExplainSheet.show(context);

  Future<void> _confirmResetAllTutorialTours() async {
    if (_hideScreenExplanation) return;
    final confirmed = await showAppDialog<bool>(
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
    final rows = <Widget>[
      AppNavRow(
        title: 'Help and FAQ',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const HelpFaqPage()),
        ),
      ),
      AppNavRow(title: 'Contact support', onTap: _contactSupport),
      AppNavRow(
        title: "What's new",
        onTap: () => _openPage(context, const ReleaseNotesPopup()),
      ),
      AppNavRow(
        title: context.tr('profile.about-us.privacy'),
        onTap: () => _openPage(context, const PrivacyPopup()),
      ),
      if (_showPrivacyOptions)
        AppNavRow(
          title: context.tr('profile.about-us.privacy-settings'),
          onTap: _openPrivacyOptions,
        ),
      AppNavRow(
        title: 'Open-source software',
        onTap: () => _openPage(context, const SoftwarePage()),
      ),
      if (!_hideScreenExplanation)
        AppNavRow(
          title: context.tr('profile.about-us.show-tips'),
          onTap: _openExplainOnePartSheet,
        ),
      if (widget.showResetAllScreenTips && !_hideScreenExplanation)
        AppNavRow(
          title: context.tr('profile.about-us.reset-intro-tours'),
          onTap: _confirmResetAllTutorialTours,
        ),
    ];
    return AppPageBackground(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
        children: [
          const _AboutHeader(),
          const SizedBox(height: 12),
          Material(
            color: AppPageColors.cardBgOf(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppPageColors.subtleBorderOf(context)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) Divider(height: 1, thickness: 1, color: AppPageColors.rowDividerOf(context)),
                  rows[i],
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          _RateCard(onTap: () => showAppReviewSheet(context)),
        ],
      ),
    );
  }
}

/// Soft-yellow "Enjoying Riovox?" card that opens the review sheet.
class _RateCard extends StatelessWidget {
  const _RateCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint = AppPageColors.tintOf(context, AppTint.reward);
    return AppPressScale(
      child: Material(
        color: tint.bg,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.star_rounded, size: 24, color: AppPageColors.tintIconOf(context, AppTint.reward)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enjoying Riovox?',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppPageColors.textPrimaryOf(context)),
                      ),
                      const SizedBox(height: 2),
                      Text('A quick rating helps a lot', style: TextStyle(fontSize: 13, color: tint.fg)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutHeader extends StatelessWidget {
  const _AboutHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: AppPageColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppPageColors.subtleBorderOf(context)),
      ),
      child: Column(
        children: [
          Image.asset(RioPose.happy.asset, height: 96, excludeFromSemantics: true),
          const SizedBox(height: 8),
          const RiovoxWordmark(height: 30),
          const SizedBox(height: 8),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snap) {
              final version = snap.data?.version;
              return Text(
                version == null
                    ? 'AI speaking practice'
                    : 'Version $version · AI speaking practice',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppPageColors.subtitleOf(context)),
              );
            },
          ),
        ],
      ),
    );
  }
}
