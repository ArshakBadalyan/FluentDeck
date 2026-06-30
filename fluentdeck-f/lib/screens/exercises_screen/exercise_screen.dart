import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/models/exercise_model.dart';
import 'package:fluentdeck/services/user_progress_service.dart';
import 'package:fluentdeck/ui_elements/primary_button.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({
    super.key,
    required this.exercise,
    required this.lessonTitle,
  });

  final ExerciseModel exercise;
  final String lessonTitle;

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  int? _selectedIndex;
  final _fillController = TextEditingController();
  bool? _isCorrect;
  bool _submitted = false;

  bool get _isMultipleChoice => widget.exercise.type == 'multipleChoice';
  bool get _isFillBlank => widget.exercise.type == 'fillBlank';

  @override
  void initState() {
    super.initState();
    _fillController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _fillController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitted) return;

    final correct = widget.exercise.correctAnswer?.trim() ?? '';
    bool ok = false;

    if (_isMultipleChoice) {
      if (_selectedIndex == null || widget.exercise.options.isEmpty) return;
      final chosen = widget.exercise.options[_selectedIndex!].trim();
      ok = _normalize(chosen) == _normalize(correct);
    } else if (_isFillBlank) {
      ok = _normalize(_fillController.text) == _normalize(correct);
    }

    setState(() {
      _submitted = true;
      _isCorrect = ok;
    });

    try {
      await UserProgressService.instance.recordExerciseCompletion(
        exerciseId: widget.exercise.id,
        lessonId: widget.exercise.lessonId,
        correct: ok,
        exerciseLabel: widget.exercise.prompt,
      );
    } catch (_) {
      // Progress sync is best-effort; answer feedback still shows.
    }
  }

  String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lessonTitle),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            _isMultipleChoice
                ? 'Multiple choice'
                : _isFillBlank
                ? 'Fill in the blank'
                : widget.exercise.type,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            widget.exercise.prompt,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          if (_isMultipleChoice) ...[
            for (var i = 0; i < widget.exercise.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color:
                      _selectedIndex == i
                          ? AppColors.primaryPurple.withValues(alpha: 0.12)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap:
                        _submitted
                            ? null
                            : () => setState(() => _selectedIndex = i),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              _selectedIndex == i
                                  ? AppColors.primaryPurple
                                  : Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(widget.exercise.options[i]),
                    ),
                  ),
                ),
              ),
          ],
          if (_isFillBlank) ...[
            TextField(
              controller: _fillController,
              enabled: !_submitted,
              decoration: InputDecoration(
                hintText: 'Type your answer',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ],
          if (_submitted && _isCorrect != null) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:
                    (_isCorrect!
                            ? AppColors.greenCorrect
                            : AppColors.redWrong)
                        .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isCorrect! ? 'Correct!' : 'Not quite',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color:
                          _isCorrect!
                              ? AppColors.greenCorrect
                              : AppColors.redWrong,
                    ),
                  ),
                  if (!_isCorrect! && correct.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('Answer: ${widget.exercise.correctAnswer}'),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (!_submitted)
            PrimaryButton(
              text: 'Check answer',
              enabled:
                  _isMultipleChoice
                      ? _selectedIndex != null
                      : _fillController.text.trim().isNotEmpty,
              onPressed: _submit,
            )
          else
            PrimaryButton(
              text: 'Done',
              enabled: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }

  String get correct => widget.exercise.correctAnswer?.trim() ?? '';
}
