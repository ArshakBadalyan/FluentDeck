import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:untitled2/localization/app_localizations.dart';
import 'package:untitled2/services/app_review_webhook_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Play / App Store targets when CMS policy is not loaded (matches [mobile_app_update_gate] fallbacks).
const String kPlayStoreListingForReview =
    'https://play.google.com/store/apps/details?id=io.framework7.matheapp';
const String kAppStoreWriteReview =
    'https://apps.apple.com/app/id6447060725?action=write-review';

String _testerPlatformLabel() {
  if (kIsWeb) return 'Web';
  return defaultTargetPlatform == TargetPlatform.iOS ? 'iOS' : 'Android';
}

Future<void> showAppReviewSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
      ),
      child: _AppReviewSheetBody(parentContext: context),
    ),
  );
}

class _AppReviewSheetBody extends StatefulWidget {
  const _AppReviewSheetBody({required this.parentContext});

  final BuildContext parentContext;

  @override
  State<_AppReviewSheetBody> createState() => _AppReviewSheetBodyState();
}

class _AppReviewSheetBodyState extends State<_AppReviewSheetBody> {
  int? _stars;
  final TextEditingController _feedback = TextEditingController();
  bool _sending = false;

  bool get _needsFeedback =>
      _stars != null && _stars! >= 1 && _stars! <= 3;

  bool get _lowRatingFormComplete =>
      _stars != null &&
      _stars! <= 3 &&
      _feedback.text.trim().isNotEmpty;

  void _handleHighRating(int stars) {
    final platform = _testerPlatformLabel();

    unawaited(
      AppReviewWebhookService.submit(
        stars: stars,
        message: '',
        testerPlatform: platform,
      ).catchError((Object e, StackTrace st) {
        debugPrint('App review webhook (high rating): $e\n$st');
      }),
    );

    Navigator.of(context).pop();

    if (!kIsWeb) {
      final uri = Uri.parse(
        defaultTargetPlatform == TargetPlatform.iOS
            ? kAppStoreWriteReview
            : kPlayStoreListingForReview,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          final messenger =
              ScaffoldMessenger.maybeOf(widget.parentContext);
          if (messenger == null || !widget.parentContext.mounted) return;
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.instance
                    .t('profile.about-us.app-review-open-store-failed'),
              ),
            ),
          );
        }
      });
    }
  }

  Future<void> _submitLowRating() async {
    if (!_lowRatingFormComplete || _sending) return;
    final stars = _stars!;
    final msg = _feedback.text.trim();
    final platform = _testerPlatformLabel();

    setState(() => _sending = true);
    try {
      await AppReviewWebhookService.submit(
        stars: stars,
        message: msg,
        testerPlatform: platform,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('profile.about-us.app-review-thanks-feedback'),
          ),
        ),
      );
    } on AppReviewWebhookException catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        SnackBar(
          content: Text(context.tr('profile.about-us.app-review-send-error')),
        ),
      );
    } catch (e, st) {
      debugPrint('App review webhook: $e\n$st');
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        SnackBar(
          content: Text(context.tr('profile.about-us.app-review-send-error')),
        ),
      );
    }
  }

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = (String key) => context.tr('profile.about-us.$key');

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              t('app-review-title'),
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              t('app-review-subtitle'),
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final index = i + 1;
                final selected = _stars != null && index <= _stars!;
                return IconButton(
                  iconSize: 40,
                  onPressed: () {
                    if (index >= 4) {
                      _handleHighRating(index);
                    } else {
                      setState(() => _stars = index);
                    }
                  },
                  icon: Icon(
                    selected ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: selected ? Colors.amber.shade700 : Colors.grey,
                  ),
                );
              }),
            ),
            if (_needsFeedback) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _feedback,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: t('app-review-feedback-hint'),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
            if (_stars != null && _stars! <= 3) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _sending
                    ? null
                    : (_lowRatingFormComplete ? _submitLowRating : null),
                child: _sending
                    ? SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : Text(t('app-review-submit')),
              ),
            ],
            TextButton(
              onPressed: _sending ? null : () => Navigator.of(context).pop(),
              child: Text(t('app-review-cancel')),
            ),
          ],
        ),
      ),
    );
  }
}
