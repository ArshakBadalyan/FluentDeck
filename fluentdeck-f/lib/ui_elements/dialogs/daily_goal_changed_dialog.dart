import 'package:flutter/material.dart';
import 'package:riovox/app_colors.dart';
import 'package:riovox/localization/app_localizations.dart';
import 'package:riovox/ui_elements/modern_page_widgets.dart';

class DailyGoalChangedDialog extends StatelessWidget {
  final bool cleared;

  const DailyGoalChangedDialog({super.key, this.cleared = false});

  @override
  Widget build(BuildContext context) {
    final body = cleared
        ? context.tr('activity.my-status.goal-cleared')
        : context.tr('activity.my-status.goal-set');
    final ok = context.tr('buttons.ok');

    return Dialog(
      backgroundColor: AppPageColors.fieldBgOf(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ok,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimaryDeep,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      ok,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
