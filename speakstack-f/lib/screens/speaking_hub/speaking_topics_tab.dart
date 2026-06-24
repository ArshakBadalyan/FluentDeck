import 'package:flutter/material.dart';
import 'package:untitled2/app_colors.dart';

import '../../models/speaking_session_context.dart';
import '../../models/speaking_topic_model.dart';
import '../../services/speaking_content_service.dart';
import '../../services/speaking_scores_service.dart';
import '../../services/speaking_session_service.dart';
import '../../widgets/speaking_hub_widgets.dart';

class SpeakingTopicsTab extends StatefulWidget {
  const SpeakingTopicsTab({super.key, required this.onStart});

  final ValueChanged<SpeakingSessionContext> onStart;

  @override
  State<SpeakingTopicsTab> createState() => _SpeakingTopicsTabState();
}

class _SpeakingTopicsTabState extends State<SpeakingTopicsTab> {
  static const _levels = ['intermediate', 'advanced', 'expert'];
  static const _levelLabels = ['Intermediate', 'Advanced', 'Expert'];

  int _filterIndex = 0;
  List<SpeakingTopicModel> _allTopics = [];
  List<SpeakingTopicModel> _topics = [];
  SpeakingTopicModel? _selected;
  bool _loading = true;
  String? _error;
  Map<String, int?> _scoreCache = {};

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
      await SpeakingSessionService.instance.refreshScoresFromServer();
      final allTopics = await SpeakingContentService.instance.fetchTopics();
      final scores = <String, int?>{};
      for (final topic in allTopics) {
        scores[topic.referenceKey] =
            await SpeakingScoresService.instance.getScore(topic.referenceKey);
      }

      if (!mounted) return;
      setState(() {
        _allTopics = allTopics;
        _scoreCache = scores;
        _loading = false;
      });
      _applyLevelFilter();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _applyLevelFilter() {
    final level = _levels[_filterIndex];
    final filtered =
        _allTopics.where((t) => t.levelGroup == level).toList();
    setState(() {
      _topics = filtered;
      _selected =
          filtered.any((t) => t.referenceKey == _selected?.referenceKey)
              ? _selected
              : (filtered.isNotEmpty ? filtered.first : null);
    });
  }

  String _cardSubtitle(SpeakingTopicModel topic) {
    final vocab = topic.vocabPreview;
    if (vocab.isEmpty) return topic.promptPreview;
    return '${topic.promptPreview}\nVocabulary: $vocab';
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_topics.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No topics for ${_levelLabels[_filterIndex]} yet.\n'
            'Restart Strapi or run the speaking seed script.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primaryPurple,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _topics.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final topic = _topics[index];
          return SpeakingSelectionCard(
            title: topic.title,
            subtitle: _cardSubtitle(topic),
            icon: speakingIconForKey(topic.iconKey),
            score: _scoreCache[topic.referenceKey],
            selected: _selected?.referenceKey == topic.referenceKey,
            onTap: () => setState(() => _selected = topic),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SpeakingFilterChips(
          labels: _levelLabels,
          selectedIndex: _filterIndex,
          onSelected: (index) {
            setState(() => _filterIndex = index);
            _applyLevelFilter();
          },
        ),
        Expanded(child: _buildList()),
        SpeakingStartButton(
          label: 'Start Conversation',
          enabled: _selected != null,
          onPressed:
              _selected == null
                  ? null
                  : () {
                    widget.onStart(
                      SpeakingContentService.instance.topicSessionFrom(
                        _selected!,
                      ),
                    );
                  },
        ),
      ],
    );
  }
}
