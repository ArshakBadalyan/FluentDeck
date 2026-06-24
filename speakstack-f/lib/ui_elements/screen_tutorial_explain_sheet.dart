import 'package:flutter/material.dart';
import 'package:speakstack/localization/app_localizations.dart';
import 'package:speakstack/services/screen_tutorial_segments.dart';
import 'package:speakstack/services/screen_tutorial_service.dart';
import 'package:speakstack/ui_elements/screen_tutorial_overlay.dart';

/// Modal list of spotlight segments for the **current** main + sub-tab
/// (`ScreenTutorialReplayCoordinator`).
abstract final class ScreenTutorialExplainSheet {
  static Future<void> show(
    BuildContext rootContext, {
    bool includeChromeSegments = true,
  }) async {
    final main = ScreenTutorialReplayCoordinator.readMainTabIndex();
    final sub = ScreenTutorialReplayCoordinator.readSubTabIndex();
    if (main == null || !rootContext.mounted) return;

    final options = ScreenTutorialSegmentCatalog.optionsFor(
      main,
      sub,
      includeChromeSegments: includeChromeSegments,
    );
    if (options.isEmpty) {
      ScaffoldMessenger.of(rootContext).showSnackBar(
        SnackBar(
          content: Text(
            rootContext.tr('screen-tutorial.sheet.no-page-tips'),
          ),
        ),
      );
      return;
    }

    final titleKey =
        includeChromeSegments
            ? 'screen-tutorial.sheet.all-tips-title'
            : 'screen-tutorial.sheet.this-page-title';
    final subtitleKey =
        includeChromeSegments
            ? 'screen-tutorial.sheet.all-tips-subtitle'
            : 'screen-tutorial.sheet.this-page-subtitle';

    await showModalBottomSheet<void>(
      context: rootContext,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) {
        final maxH = MediaQuery.of(sheetCtx).size.height * 0.72;
        return SafeArea(
          child: SizedBox(
            height: maxH,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Text(
                    sheetCtx.tr(titleKey),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Text(
                    sheetCtx.tr(subtitleKey),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.3,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: options.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final o = options[i];
                      return ListTile(
                        title: Text(ctx.tr(o.labelKey)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          Navigator.pop(sheetCtx);
                          if (!rootContext.mounted) return;
                          await ScreenTutorialOverlay.showSegment(
                            rootContext,
                            segmentId: o.id,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
