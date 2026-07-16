import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';

import '../../models/speaking_session_context.dart';
import '../../widgets/speaking_hub_widgets.dart';

class SpeakingChatTab extends StatelessWidget {
  const SpeakingChatTab({super.key, required this.onStart});

  final ValueChanged<SpeakingSessionContext> onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 72,
                  color: AppColors.primaryPurple.withValues(alpha: 0.65),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Free-form conversation with your AI tutor. '
                  'Speak naturally and get instant grammar feedback.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    fontFamily: 'Rubik',
                    color: Color(0xFF777481),
                  ),
                ),
              ],
            ),
          ),
        ),
        SpeakingStartButton(
          label: 'Start Conversation',
          onPressed: () {
            onStart(SpeakingSessionContext.freeChat());
          },
        ),
      ],
    );
  }
}
