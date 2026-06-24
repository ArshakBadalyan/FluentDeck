import 'package:flutter/material.dart';
import 'package:speakstack/app_colors.dart';

import '../../models/speaking_game_model.dart';
import '../../models/speaking_session_context.dart';
import '../../services/speaking_content_service.dart';
import '../../services/speaking_session_service.dart';
import '../../services/speaking_scores_service.dart';
import '../../utils/speaking_item_icons.dart';
import '../../utils/speaking_premium_gate.dart';
import '../../widgets/speaking_hub_widgets.dart';

class SpeakingGamesTab extends StatefulWidget {
  const SpeakingGamesTab({super.key, required this.onStart});

  final ValueChanged<SpeakingSessionContext> onStart;

  @override
  State<SpeakingGamesTab> createState() => _SpeakingGamesTabState();
}

class _SpeakingGamesTabState extends State<SpeakingGamesTab> {
  List<SpeakingGameModel> _games = [];
  SpeakingGameModel? _selected;
  bool _loading = true;
  String? _error;
  Map<String, int?> _scoreCache = {};
  ({int total, int scoredCount}) _catalogProgress = (total: 0, scoredCount: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  SpeakingGameModel? _defaultSelection(List<SpeakingGameModel> games) {
    if (games.isEmpty) return null;
    for (final game in games) {
      if (game.slug == 'heroes-and-horrors') return game;
    }
    return games.first;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await SpeakingSessionService.instance.refreshScoresFromServer();
      final games = await SpeakingContentService.instance.fetchGames();
      final scores = <String, int?>{};
      for (final game in games) {
        scores[game.referenceKey] =
            await SpeakingScoresService.instance.getScore(game.referenceKey);
      }
      final progress = await SpeakingScoresService.instance.gameCatalogProgress(
        games.map((g) => g.referenceKey).toList(),
      );

      if (!mounted) return;
      setState(() {
        _games = games;
        _scoreCache = scores;
        _catalogProgress = progress;
        _selected =
            games.any((g) => g.referenceKey == _selected?.referenceKey)
                ? _selected
                : _defaultSelection(games);
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

  Widget _buildSelectedInfo() {
    final game = _selected;
    if (game == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                resolveSpeakingListIcon(
                  title: game.title,
                  iconKey: game.iconKey,
                  slug: game.slug,
                ),
                color: speakingIconAccent(game.title),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  game.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              if (_scoreCache[game.referenceKey] != null)
                Text(
                  '${_scoreCache[game.referenceKey]} / 10',
                  style: const TextStyle(
                    color: AppColors.primaryPurple,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          if (game.descriptionPreview.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              game.descriptionPreview,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGrid() {
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
    if (_games.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No games available yet.\nRestart Strapi or run the speaking seed script.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primaryPurple,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.92,
        ),
        itemCount: _games.length,
        itemBuilder: (context, index) {
          final game = _games[index];
          return SpeakingGameGridCard(
            title: game.title,
            icon: resolveSpeakingListIcon(
              title: game.title,
              iconKey: game.iconKey,
              slug: game.slug,
            ),
            score: _scoreCache[game.referenceKey],
            featured: game.isFeatured,
            isPremiumLocked: game.isPremiumLocked,
            selected: _selected?.referenceKey == game.referenceKey,
            onTap: () {
              if (game.isPremiumLocked) {
                showSpeakingPremiumSnackBar(context);
                return;
              }
              setState(() => _selected = game);
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progressLabel =
        _catalogProgress.total == 0
            ? ''
            : '${_catalogProgress.scoredCount} of ${_catalogProgress.total} games scored';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (progressLabel.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              progressLabel,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
        Expanded(child: _buildGrid()),
        _buildSelectedInfo(),
        SpeakingStartButton(
          label: 'Start Game',
          enabled: _selected != null && !_selected!.isPremiumLocked,
          onPressed:
              _selected == null || _selected!.isPremiumLocked
                  ? null
                  : () {
                    widget.onStart(
                      SpeakingContentService.instance.gameSessionFrom(
                        _selected!,
                      ),
                    );
                  },
        ),
      ],
    );
  }
}
