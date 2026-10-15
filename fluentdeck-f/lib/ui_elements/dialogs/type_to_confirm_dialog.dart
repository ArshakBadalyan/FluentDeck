import 'package:flutter/material.dart';

import '../../app_colors.dart';

/// Destructive-action confirmation: the confirm button stays disabled until the
/// user types [keyword]. Returns true only when confirmed.
Future<bool> showTypeToConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String keyword = 'DELETE',
}) async {
  final controller = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder:
        (ctx) => StatefulBuilder(
          builder:
              (ctx, setDialogState) => AlertDialog(
                title: Text(title),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(message),
                    const SizedBox(height: 16),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'Type '),
                          TextSpan(
                            text: keyword,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const TextSpan(text: ' to confirm.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(hintText: keyword),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed:
                        controller.text.trim() == keyword
                            ? () => Navigator.pop(ctx, true)
                            : null,
                    style: FilledButton.styleFrom(backgroundColor: AppColors.redWrong),
                    child: Text(confirmLabel),
                  ),
                ],
              ),
        ),
  );
  controller.dispose();
  return confirmed == true;
}
