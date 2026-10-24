import 'package:flutter/material.dart';

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
                // The tutor otter's cozy study (character sheet "Worldview & Setting").
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420, maxHeight: 340),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/tutor/worldview.webp',
                        fit: BoxFit.cover,
                        semanticLabel: 'Rio the otter tutor at a desk with books and a laptop',
                      ),
                    ),
                  ),
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
