import 'package:flutter/material.dart';
import 'package:speakstack/app_colors.dart';
import 'package:speakstack/models/exercise_model.dart';
import 'package:speakstack/models/lesson_model.dart';
import 'package:speakstack/models/speaking_session_context.dart';
import 'package:speakstack/screens/exercises_screen/exercise_screen.dart';
import 'package:speakstack/services/conversation_service.dart';
import 'package:speakstack/services/lesson_service.dart';
import 'package:speakstack/services/main_navigation_coordinator.dart';

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

  void _startSpeaking(ExerciseModel exercise) {
    final lesson = _lesson;
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
    MainNavigationCoordinator.goToMainTab(0);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_lesson?.title ?? 'Lesson'),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
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
                                    backgroundColor: AppColors.primaryPurple,
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
