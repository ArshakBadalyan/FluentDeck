import 'package:flutter/material.dart';
import 'package:untitled2/app_colors.dart';
import 'package:untitled2/models/exercise_model.dart';
import 'package:untitled2/models/lesson_model.dart';
import 'package:untitled2/screens/exercises_screen/exercise_screen.dart';
import 'package:untitled2/models/speaking_session_context.dart';
import 'package:untitled2/services/conversation_service.dart';
import 'package:untitled2/services/english_level_service.dart';
import 'package:untitled2/services/lesson_service.dart';
import 'package:untitled2/services/main_navigation_coordinator.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  bool _loading = true;
  String? _error;
  String _levelFilter = EnglishLevelService.defaultLevel;
  List<LessonModel> _lessons = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final level = await EnglishLevelService.instance.getLevel();
      final lessons = await LessonService.instance.fetchLessons(level: level);
      if (!mounted) return;
      setState(() {
        _levelFilter = level;
        _lessons = lessons;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _onLevelChanged(String? level) async {
    if (level == null) return;
    await EnglishLevelService.instance.setLevel(level);
    await _load();
  }

  void _openLesson(LessonModel lesson) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LessonDetailScreen(lessonId: lesson.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              const Text('Level', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _levelFilter,
                items:
                    const ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']
                        .map(
                          (level) => DropdownMenuItem(
                            value: level,
                            child: Text(level),
                          ),
                        )
                        .toList(),
                onChanged: _onLevelChanged,
              ),
            ],
          ),
        ),
        Expanded(
          child:
              _lessons.isEmpty
                  ? Center(
                    child: Text(
                      'No lessons yet.\nAdd lessons in Strapi admin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  )
                  : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _lessons.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final lesson = _lessons[index];
                        return _LessonCard(
                          lesson: lesson,
                          onTap: () => _openLesson(lesson),
                        );
                      },
                    ),
                  ),
        ),
      ],
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson, required this.onTap});

  final LessonModel lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryPurple.withValues(alpha: 0.12),
                child: Text(
                  lesson.level,
                  style: const TextStyle(
                    color: AppColors.primaryPurple,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${lesson.skillType} · ${lesson.exercises.length} exercises',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

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
