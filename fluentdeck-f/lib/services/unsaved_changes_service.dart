import 'package:flutter/material.dart';
import 'package:fluentdeck/localization/app_localizations.dart';

class UnsavedChangesService extends ChangeNotifier {
  static final UnsavedChangesService _instance =
      UnsavedChangesService._internal();

  factory UnsavedChangesService() => _instance;

  UnsavedChangesService._internal();

  VoidCallback? discardCallback;
  Future<bool> Function()? saveCallback;

  bool _hasUnsavedChanges = false;

  bool get hasUnsavedChanges => _hasUnsavedChanges;

  set hasUnsavedChanges(bool value) {
    if (_hasUnsavedChanges != value) {
      _hasUnsavedChanges = value;
      notifyListeners();
    }
  }

  Future<bool> showConfirmDialog(
    BuildContext context, {
    Future<bool> Function()? onSave,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${context.tr('popups.leave-page-popup.first-title')}\n${context.tr('popups.leave-page-popup.second-title')}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        '${context.tr('popups.leave-page-popup.first-text')}\n${context.tr('popups.leave-page-popup.second-text')}.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 42,
                              child: ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(context, true);
                                  UnsavedChangesService().discardCallback
                                      ?.call();
                                  UnsavedChangesService().hasUnsavedChanges =
                                      false;
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    context.tr('popups.leave-page-popup.leave'),
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 42,
                              child: ElevatedButton(
                                onPressed: () async {
                                  final saveFn = onSave ?? saveCallback;
                                  if (saveFn == null) {
                                    if (context.mounted) {
                                      Navigator.pop(context, false);
                                    }
                                    return;
                                  }
                                  final saved = await saveFn();
                                  if (!context.mounted) return;
                                  if (saved) {
                                    hasUnsavedChanges = false;
                                    Navigator.pop(context, true);
                                  }
                                },

                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7C3AED),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    context.tr('buttons.save'),
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 14,
                                      letterSpacing: 1.2,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Positioned(
                  right: 4,
                  top: 4,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                    tooltip: 'Close',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),
    );

    if (result == true) {
      hasUnsavedChanges = false;
      return true;
    }
    return false;
  }
}
