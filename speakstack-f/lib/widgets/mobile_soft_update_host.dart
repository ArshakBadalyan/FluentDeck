import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/app_localizations.dart';
import '../services/mobile_app_update_gate.dart';

/// Shows the optional upgrade dialog once, after first frame ([child] is visible).
/// [offer] comes from [MobileAppUpdateBootstrap.softOffer].
class MobileSoftUpdateHost extends StatefulWidget {
  const MobileSoftUpdateHost({
    super.key,
    required this.offer,
    required this.child,
  });

  final MobileSoftUpdateOffer offer;
  final Widget child;

  @override
  State<MobileSoftUpdateHost> createState() => _MobileSoftUpdateHostState();
}

class _MobileSoftUpdateHostState extends State<MobileSoftUpdateHost> {
  bool _offered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _offered) return;
      _offered = true;
      await _showDialogOnce();
    });
  }

  Future<void> _showDialogOnce() async {
    if (!mounted) return;

    final loc = AppLocalizations.instance;
    final title = loc.t(
      'app-update.soft-title',
      fallback: 'New update available',
    );
    final defaultBody = loc.t(
      'app-update.soft-default-body',
      fallback:
          'A new version is ready with improvements. Update whenever you like.',
    );
    final bodyText =
        widget.offer.bodyText.isNotEmpty ? widget.offer.bodyText : defaultBody;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(child: Text(bodyText)),
            actions: [
              TextButton(
                onPressed: () async {
                  await MobileAppUpdateBootstrap.rememberSoftDismissed(
                    widget.offer.campaignId,
                  );
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                },
                child: Text(
                  loc.t('app-update.later-action', fallback: 'Later'),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final uri = Uri.parse(widget.offer.storeUrl);
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                },
                child: Text(
                  loc.t('app-update.update-action', fallback: 'Update'),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
