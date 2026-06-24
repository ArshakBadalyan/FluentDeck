import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/app_localizations.dart';

class MobileForceUpdateScreen extends StatelessWidget {
  const MobileForceUpdateScreen({
    super.key,
    required this.storeUrl,
  });

  final String storeUrl;

  Future<void> _openStore() async {
    final uri = Uri.parse(storeUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.instance;
    final title = loc.t(
      'app-update.force-title',
      fallback: 'Update required 📲✨',
    );
    final body = loc.t(
      'app-update.force-body',
      fallback: 'Please update EnglishApp to continue.',
    );
    final action = loc.t(
      'app-update.update-action',
      fallback: 'Update',
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                body,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _openStore,
                  child: Text(action),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
