import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/models/placement_test_model.dart';
import 'package:fluentdeck/services/vocabulary_service.dart';
import 'package:fluentdeck/ui_elements/primary_button.dart';
import 'package:fluentdeck/widgets/cefr_level_chips.dart';

class PlacementTestScreen extends StatefulWidget {
  const PlacementTestScreen({super.key});

  @override
  State<PlacementTestScreen> createState() => _PlacementTestScreenState();
}

class _PlacementTestScreenState extends State<PlacementTestScreen> {
  bool _loading = true;
  String? _error;
  List<PlacementQuestionModel> _questions = const [];
  int _index = 0;
  final List<Map<String, dynamic>> _answers = [];
  PlacementTestResultModel? _result;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final questions = await VocabularyService.instance.fetchPlacementQuestions();
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _answer(String response) {
    if (_index >= _questions.length) return;
    final q = _questions[_index];
    _answers.add({
      'vocabularyEntryId': q.vocabularyEntryId,
      'cefrLevel': q.cefrLevel,
      'response': response,
    });
    if (_index + 1 >= _questions.length) {
      _submit();
    } else {
      setState(() => _index += 1);
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final result = await VocabularyService.instance.submitPlacement(_answers);
      if (!mounted) return;
      setState(() {
        _result = result;
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Level test'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading || _submitting) {
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
              FilledButton(onPressed: _loadQuestions, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_result != null) {
      return _ResultView(result: _result!);
    }

    if (_questions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.quiz_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'No placement questions available',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'The vocabulary catalog needs to be loaded on the server. '
                'Restart Strapi or contact support, then try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, height: 1.4),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _loadQuestions, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final q = _questions[_index];
    final progress = (_index + 1) / _questions.length;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            color: AppColors.primaryPurple,
          ),
          const SizedBox(height: 8),
          Text(
            'Question ${_index + 1} of ${_questions.length}',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const Spacer(),
          Text(
            'Do you know this word?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          Text(
            q.word,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            q.cefrLevel,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const Spacer(),
          _AnswerButton(
            label: 'I know it',
            color: AppColors.greenCorrect,
            onPressed: () => _answer('know'),
          ),
          const SizedBox(height: 10),
          _AnswerButton(
            label: 'Not sure',
            color: AppColors.primaryYellow,
            onPressed: () => _answer('not_sure'),
          ),
          const SizedBox(height: 10),
          _AnswerButton(
            label: "Don't know",
            color: AppColors.redWrong,
            onPressed: () => _answer('dont_know'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result});

  final PlacementTestResultModel result;

  @override
  Widget build(BuildContext context) {
    final suggestions = result.studySuggestions;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VerifiedPlacementCard(result: result),
          const SizedBox(height: 24),
          CefrLevelChips(
            selectedLevel: result.suggestedLevel,
            verifiedLevel: result.suggestedLevel,
          ),
          if (suggestions != null) ...[
            const SizedBox(height: 32),
            const Text(
              'Suggested setup',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _SuggestionRow(
              label: 'New words / day',
              value: '${suggestions.dailyNewWords}',
            ),
            _SuggestionRow(
              label: 'Reviews / day',
              value: '${suggestions.dailyReviews}',
            ),
            _SuggestionRow(
              label: 'Speak minutes / day',
              value: '${suggestions.speakMinutes}',
            ),
            if (suggestions.deckSetup.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Decks: ${suggestions.deckSetup.join(', ')}',
                style: TextStyle(color: Colors.grey.shade800),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              suggestions.message,
              style: TextStyle(color: Colors.grey.shade700, height: 1.4),
            ),
          ],
          const SizedBox(height: 32),
          PrimaryButton(
            text: 'DONE',
            enabled: true,
            onPressed: () => Navigator.of(context).pop(result),
            color: AppColors.primaryYellow,
          ),
        ],
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
