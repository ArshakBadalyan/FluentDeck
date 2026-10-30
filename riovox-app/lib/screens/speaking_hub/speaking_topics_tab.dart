import 'package:flutter/material.dart';
import 'package:riovox/app_colors.dart';

import '../../models/speaking_session_context.dart';
import '../../models/speaking_topic_model.dart';
import '../../services/speaking_content_service.dart';
import '../../utils/speaking_item_icons.dart';
import '../../utils/speaking_premium_gate.dart';
import '../../ui_elements/app_skeletons.dart';
import '../../widgets/speaking_hub_widgets.dart';
import 'package:riovox/ui_elements/app_motion.dart';

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
      final catalog = await SpeakingContentService.instance.fetchTopicsCatalog();
      final allTopics = catalog.items;

      if (!mounted) return;
      setState(() {
        _allTopics = allTopics;
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
              : firstUnlocked(filtered, (t) => t.isPremiumLocked) ??
                  (filtered.isNotEmpty ? filtered.first : null);
    });
  }

  Widget _buildList() {
    if (_loading) {
      return AppLoadingSwitcher(
      loading: true,
      child: const AppListSkeleton(),
    );
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

    return AppLoadingSwitcher(
      loading: false,
      child: RefreshIndicator(
      onRefresh: _load,
      color: AppColors.brandPrimary,
      // Grid of topic cards (Today · Topics): two columns on phones, more on
      // web/tablet instead of two huge cards.
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        itemCount: _topics.length,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 240,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          // Room for a two-line title and two lines of description.
          mainAxisExtent: 178,
        ),
        itemBuilder: (context, index) {
          final topic = _topics[index];
          return SpeakingTopicGridCard(
            title: topic.title,
            subtitle: topic.promptPreview,
            icon: resolveSpeakingListIcon(
              title: topic.title,
              iconKey: topic.iconKey,
            ),
            selected: _selected?.referenceKey == topic.referenceKey,
            isPremiumLocked: topic.isPremiumLocked,
            onTap: () {
              if (topic.isPremiumLocked) {
                showSpeakingPremiumSnackBar(context);
                return;
              }
              setState(() => _selected = topic);
            },
          );
        },
      ),
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
          label: _selected == null ? 'Start conversation' : 'Talk about ${_selected!.title}',
          enabled: _selected != null && !_selected!.isPremiumLocked,
          onPressed:
              _selected == null || _selected!.isPremiumLocked
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
