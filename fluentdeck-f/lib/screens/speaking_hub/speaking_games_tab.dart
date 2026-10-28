import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';

import '../../models/speaking_game_model.dart';
import '../../models/speaking_session_context.dart';
import '../../services/speaking_content_service.dart';
import '../../services/speaking_session_service.dart';
import '../../services/speaking_scores_service.dart';
import '../../utils/speaking_item_icons.dart';
import '../../utils/speaking_premium_gate.dart';
import '../../ui_elements/app_skeletons.dart';
import '../../ui_elements/modern_page_widgets.dart';
import '../../widgets/speaking_hub_widgets.dart';
import 'package:fluentdeck/ui_elements/app_motion.dart';

class SpeakingGamesTab extends StatefulWidget {
  const SpeakingGamesTab({super.key, required this.onStart});

  final ValueChanged<SpeakingSessionContext> onStart;

  @override
  State<SpeakingGamesTab> createState() => _SpeakingGamesTabState();
}

class _SpeakingGamesTabState extends State<SpeakingGamesTab> {
  List<SpeakingGameModel> _games = [];
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
      final games = await SpeakingContentService.instance.fetchGames();
      final scores = <String, int?>{};
      for (final game in games) {
        scores[game.referenceKey] =
            await SpeakingScoresService.instance.getScore(game.referenceKey);
      }

      if (!mounted) return;
      setState(() {
        _games = games;
        _scoreCache = scores;
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

  Widget _buildGrid() {
    if (_loading) {
      return AppLoadingSwitcher(
      loading: true,
      child: const AppGridSkeleton(count: 6, crossAxisCount: 2, childAspectRatio: 1.2),
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
    if (_games.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No games available yet.\nRestart Strapi or run the speaking seed script.',
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
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        // Two columns on phones; web/tablet show more instead of huge cards.
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
          mainAxisExtent: 150,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
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
            subtitle: game.descriptionPreview,
            score: _scoreCache[game.referenceKey],
            featured: game.isFeatured,
            isPremiumLocked: game.isPremiumLocked,
            // A tap starts the game (Today · Games).
            onTap: () {
              if (game.isPremiumLocked) {
                showSpeakingPremiumSnackBar(context);
                return;
              }
              widget.onStart(SpeakingContentService.instance.gameSessionFrom(game));
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
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
          child: Text(
            'Quick games that get you talking without overthinking.',
            style: TextStyle(fontSize: 14, color: AppPageColors.subtitleOf(context)),
          ),
        ),
        Expanded(child: _buildGrid()),
      ],
    );
  }
}
