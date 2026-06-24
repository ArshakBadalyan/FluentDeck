import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:untitled2/app_colors.dart';
import 'package:untitled2/models/flashcard_stats_model.dart';
import 'package:untitled2/services/flashcard_service.dart';
import 'package:untitled2/utils/html_text_utils.dart';

class ReviewLogScreen extends StatefulWidget {
  const ReviewLogScreen({super.key, this.deckId});

  final int? deckId;

  @override
  State<ReviewLogScreen> createState() => _ReviewLogScreenState();
}

class _ReviewLogScreenState extends State<ReviewLogScreen> {
  bool _loading = true;
  String? _error;
  List<FlashcardReviewLogEntry> _log = const [];

  static const _pageBg = Color(0xFFF7F5FB);

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
      final log = await FlashcardService.instance.fetchReviewLog(
        deckId: widget.deckId,
        limit: 200,
      );
      if (!mounted) return;
      setState(() {
        _log = log;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        title: const Text('Review log'),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                ),
              )
              : _log.isEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No review log entries yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, height: 1.45),
                  ),
                ),
              )
              : RefreshIndicator(
                onRefresh: _load,
                color: AppColors.primaryPurple,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: _log.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return ReviewLogEntryTile(entry: _log[index]);
                  },
                ),
              ),
    );
  }
}

class ReviewLogEntryTile extends StatelessWidget {
  const ReviewLogEntryTile({super.key, required this.entry});

  final FlashcardReviewLogEntry entry;

  static Color ratingColor(String rating) {
    switch (rating) {
      case 'again':
        return AppColors.redWrong;
      case 'hard':
        return const Color(0xFFFF9800);
      case 'good':
        return AppColors.primaryYellow;
      case 'easy':
        return AppColors.greenCorrect;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = ratingColor(entry.rating);
    final fmt = DateFormat('MMM d, yyyy · h:mm a');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              entry.rating.isNotEmpty ? entry.rating[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stripHtml(entry.front ?? ''),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    entry.rating,
                    if (entry.reviewedAt != null)
                      fmt.format(entry.reviewedAt!.toLocal()),
                    if (entry.durationMs > 0)
                      '${(entry.durationMs / 1000).toStringAsFixed(0)}s',
                  ].join(' · '),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
