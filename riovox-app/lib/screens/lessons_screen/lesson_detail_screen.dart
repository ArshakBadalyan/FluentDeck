import 'package:flutter/material.dart';
import 'package:riovox/ui_elements/modern_page_widgets.dart';
import 'package:riovox/app_colors.dart';
import 'package:riovox/models/exercise_model.dart';
import 'package:riovox/models/lesson_model.dart';
import 'package:riovox/models/speaking_session_context.dart';
import 'package:riovox/screens/exercises_screen/exercise_screen.dart';
import 'package:riovox/services/conversation_service.dart';
import 'package:riovox/services/lesson_service.dart';
import 'package:riovox/services/main_navigation_coordinator.dart';
import 'package:riovox/services/main_tab_config.dart';
import 'package:riovox/ui_elements/app_skeletons.dart';
import 'package:riovox/services/conversation_start_ad.dart';

class LessonDetailScreen extends StatefulWidget {
  const LessonDetailScreen({super.key, required this.lessonId});

  final int lessonId;

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  bool _loading = true;
  LessonModel? _lesson;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lesson = await LessonService.instance.fetchLessonById(widget.lessonId);
    if (!mounted) return;
    setState(() {
      _lesson = lesson;
      _loading = false;
    });
  }

  void _openExercise(ExerciseModel exercise) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) => ExerciseScreen(
              exercise: exercise,
              lessonTitle: _lesson?.title ?? 'Lesson',
            ),
      ),
    );
  }

  Future<void> _startSpeaking(ExerciseModel exercise) async {
    final lesson = _lesson;
    await ConversationStartAd.instance.showIfNeeded();
    if (!mounted) return;
    ConversationService.instance.startSession(
      SpeakingSessionContext(
        mode: SpeakingMode.lesson,
        title: lesson?.title ?? 'Lesson',
        referenceKey: lesson != null ? 'lesson_${lesson.id}' : 'lesson',
        lessonId: lesson?.id,
        lessonDescription: lesson?.description,
        lessonObjectives:
            'Practice ${lesson?.skillType ?? 'speaking'} at ${lesson?.level ?? 'B1'} level.',
        exercisePrompt: exercise.prompt,
        openingMessage:
            'Welcome to "${lesson?.title ?? 'this lesson'}". ${exercise.prompt}',
      ),
      openingMessage:
          'Welcome to "${lesson?.title ?? 'this lesson'}". ${exercise.prompt}',
    );
    MainNavigationCoordinator.goToTab(MainTabId.speak);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_lesson?.title ?? 'Lesson'),
        backgroundColor: AppPageColors.pageBgOf(context),
        foregroundColor: AppPageColors.textPrimaryOf(context),
      ),
      body:
          _loading
              ? const AppListSkeleton()
              : _lesson == null
              ? const Center(child: Text('Lesson not found'))
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_lesson!.description != null &&
                      _lesson!.description!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(_lesson!.description!),
                    ),
                  ..._lesson!.exercises.map((exercise) {
                    final isSpeaking =
                        exercise.type == 'speakingPrompt' ||
                        exercise.type == 'conversation';
                    final isPractice =
                        exercise.type == 'multipleChoice' ||
                        exercise.type == 'fillBlank';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(exercise.prompt),
                        subtitle: Text(exercise.type),
                        trailing:
                            isSpeaking
                                ? FilledButton(
                                  onPressed: () => _startSpeaking(exercise),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.brandPrimary,
                                  ),
                                  child: const Text('Speak'),
                                )
                                : isPractice
                                ? FilledButton(
                                  onPressed: () => _openExercise(exercise),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primaryYellow,
                                    foregroundColor: Colors.black87,
                                  ),
                                  child: const Text('Practice'),
                                )
                                : null,
                      ),
                    );
                  }),
                ],
              ),
    );
  }
}
