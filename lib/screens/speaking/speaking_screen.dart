/// Speaking Practice Screen
/// AI-powered conversation practice
/// Days 12-13 Implementation

import 'package:flutter/material.dart';
import '../../ui_elements/enhanced_design_system.dart';
import '../../ui_elements/design_components.dart';
import 'speaking_components.dart';

class SpeakingScreen extends StatefulWidget {
  @override
  State<SpeakingScreen> createState() => _SpeakingScreenState();
}

class _SpeakingScreenState extends State<SpeakingScreen> {
  bool isRecording = false;
  String transcription = '';
  String aiResponse = '';
  int sessionXP = 0;

  final List<ConversationTopic> topics = [
    ConversationTopic(
      title: 'Ordering Food',
      emoji: '🍽️',
      difficulty: 'Beginner',
      starter: 'Quiero pedir un café, por favor.',
    ),
    ConversationTopic(
      title: 'Travel Questions',
      emoji: '✈️',
      difficulty: 'Intermediate',
      starter: '¿Dónde están los baños?',
    ),
    ConversationTopic(
      title: 'Business Meeting',
      emoji: '💼',
      difficulty: 'Advanced',
      starter: 'Tenemos que hablar sobre el proyecto.',
    ),
  ];

  void toggleRecording() {
    setState(() => isRecording = !isRecording);

    if (!isRecording && transcription.isEmpty) {
      setState(() => transcription = 'Me gustaría un café con leche, por favor.');
      Future.delayed(Duration(milliseconds: 1500), () {
        setState(() {
          aiResponse =
              'Perfecto. ¿Algo más para acompañar? ¿Un pastel o una galleta?';
          sessionXP += 10;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignPalette.bgPrimary,
      body: Column(
        children: [
          // ===== HEADER =====
          SafeArea(
            bottom: false,
            child: Container(
              decoration: BoxDecoration(
                gradient: DesignGradients.primaryGradient,
                boxShadow: DesignShadows.elevation2,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: DesignSpacing.lg,
                vertical: DesignSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Speaking Practice',
                        style: DesignTypography.headingMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: DesignSpacing.xs),
                      Text(
                        'Chat with AI tutor',
                        style: DesignTypography.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '+$sessionXP',
                        style: DesignTypography.labelLarge.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'XP',
                        style: DesignTypography.caption.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ===== MAIN CONTENT =====
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(DesignSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== ACTIVE CONVERSATION =====
                  if (transcription.isNotEmpty) ...[
                    Text('Your Message', style: DesignTypography.labelMedium),
                    SizedBox(height: DesignSpacing.sm),
                    Container(
                      padding: EdgeInsets.all(DesignSpacing.md),
                      decoration: BoxDecoration(
                        gradient: DesignGradients.primaryGradient,
                        borderRadius: BorderRadius.circular(DesignRadius.md),
                      ),
                      child: Text(
                        transcription,
                        style: DesignTypography.bodySmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: DesignSpacing.lg),
                    Text('AI Response', style: DesignTypography.labelMedium),
                    SizedBox(height: DesignSpacing.sm),
                    Container(
                      padding: EdgeInsets.all(DesignSpacing.md),
                      decoration: BoxDecoration(
                        color: DesignPalette.bgTertiary,
                        border: Border.all(
                          color: DesignPalette.bgSecondary,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(DesignRadius.md),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (aiResponse.isEmpty)
                            SkeletonLoader(width: double.infinity, height: 40)
                          else
                            Text(
                              aiResponse,
                              style: DesignTypography.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: DesignSpacing.xl),
                  ] else ...[
                    // ===== TOPIC SUGGESTIONS =====
                    Text(
                      'Choose a Topic',
                      style: DesignTypography.headingMedium,
                    ),
                    SizedBox(height: DesignSpacing.md),
                    ...topics.map((topic) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: DesignSpacing.md),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => transcription = topic.starter);
                            toggleRecording();
                          },
                          child: GorgeousCard(
                            title: '${topic.emoji} ${topic.title}',
                            subtitle: topic.difficulty,
                            headerColor: DesignPalette.primary,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Starter phrase:',
                                  style: DesignTypography.caption,
                                ),
                                SizedBox(height: DesignSpacing.sm),
                                Text(
                                  topic.starter,
                                  style: DesignTypography.bodySmall,
                                ),
                                SizedBox(height: DesignSpacing.md),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Icon(Icons.info_outline,
                                        size: 16,
                                        color: DesignPalette.textSecondary),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        setState(
                                            () => transcription = topic.starter);
                                        toggleRecording();
                                      },
                                      icon: Icon(Icons.mic, size: 16),
                                      label: Text('Start'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            DesignPalette.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              DesignRadius.md),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),

          // ===== VOICE INPUT =====
          if (transcription.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(DesignSpacing.lg),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: toggleRecording,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isRecording
                            ? DesignGradients.warningGradient
                            : DesignGradients.successGradient,
                        boxShadow: DesignShadows.elevation4,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isRecording ? Icons.stop : Icons.mic,
                            color: Colors.white,
                            size: 32,
                          ),
                          SizedBox(height: DesignSpacing.xs),
                          Text(
                            isRecording ? 'Stop' : 'Speak',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: DesignSpacing.md),
                  if (isRecording)
                    Text(
                      'Listening...',
                      style: DesignTypography.bodySmall.copyWith(
                        color: DesignPalette.warning,
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
