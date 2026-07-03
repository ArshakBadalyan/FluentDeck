import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluentdeck/localization/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

bool get _tappableContactLinks =>
    kIsWeb || defaultTargetPlatform == TargetPlatform.android;

class PrivacyPopup extends StatelessWidget {
  const PrivacyPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.instance.t('profile.about-us.privacy')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Close',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: _PrivacyContent(),
      ),
    );
  }
}

class _PrivacyContent extends StatelessWidget {
  const _PrivacyContent();

  @override
  Widget build(BuildContext context) {
    String t(String key) => context.tr('privacy-content.$key');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t('summary')),
        const SizedBox(height: 16),

        Text(t('intro-title'), style: _h3),
        Text(t('intro-text')),
        const SizedBox(height: 16),

        Text(t('collection-title'), style: _h3),
        Text(t('collection-text')),
        const SizedBox(height: 16),

        Text(t('cookies-title'), style: _h3),
        Text(t('cookies-text')),
        const SizedBox(height: 16),

        Text(t('third-party-title'), style: _h3),
        Text(t('third-party-text')),
        const SizedBox(height: 8),
        _Bullet(t('third-party-bullet-1')),
        _Bullet(t('third-party-bullet-2')),
        _Bullet(t('third-party-bullet-3')),
        const SizedBox(height: 8),

        Text(t('third-party-note')),
        const SizedBox(height: 16),

        Text(t('deletion-title'), style: _h3),
        Text(t('deletion-text')),
        const SizedBox(height: 16),

        Text(t('security-title'), style: _h3),
        Text(t('security-text')),
        const SizedBox(height: 16),

        Text(t('changes-title'), style: _h3),
        Text(t('changes-text')),
        const SizedBox(height: 16),

        Text(t('contact-title'), style: _h3),
        Column(
          children: [
            _tappableContactLinks
                ? GestureDetector(
                  onTap:
                      () =>
                          launchUrl(Uri.parse('mailto:${t('contact-email')}')),
                  child: Text(
                    t('contact-email'),
                    style: const TextStyle(
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
                : Text(t('contact-email')),

            const SizedBox(height: 6),

            _tappableContactLinks
                ? GestureDetector(
                  onTap: () => launchUrl(Uri.parse(t('contact-website'))),
                  child: Text(
                    t('contact-website'),
                    style: const TextStyle(
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
                : Text(t('contact-website')),
          ],
        ),
        const SizedBox(height: 20),

        Text(t('date'), style: const TextStyle(fontStyle: FontStyle.italic)),
      ],
    );
  }
}

const TextStyle _h3 = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [const Text('• '), Expanded(child: Text(text))],
    );
  }
}
