import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/data/decks_help_content.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';

class _Faq {
  const _Faq(this.question, this.answer);
  final String question;
  final String answer;
}

class _FaqGroup {
  const _FaqGroup(this.title, this.icon, this.items);
  final String title;
  final IconData icon;
  final List<_Faq> items;
}

// Shares its Q&A text with the Decks "?" guide (decks_help_content.dart)
// instead of duplicating it, grouped here by topic to match this page's style.
_Faq _d(int i) => _Faq(decksFaqItems[i].question, decksFaqItems[i].answer);

final _groups = <_FaqGroup>[
  _FaqGroup('Getting started', Icons.flag_outlined, [
    _Faq(
      'How do I change the language I am learning?',
      'Profile → Settings → AI Speaking → "Language you are learning". The AI '
          'tutor switches to the same language automatically; you can still pick '
          'a different tutor language below it.',
    ),
    _Faq(
      'Where are notifications and sound settings?',
      'Profile → Settings → Notifications, and Profile → Settings → Sound.',
    ),
    _Faq(
      'How do I see tips for the screen I am on?',
      'Profile → About → Show tips… highlights parts of the screen and explains them.',
    ),
  ]),
  _FaqGroup('Speaking & AI tutor', Icons.mic_none_rounded, [
    _Faq(
      'How do I talk to the tutor?',
      'Open Speak → Chat and tap the mic. To type instead, turn on "Type '
          'messages" in the chat settings (the sliders icon).',
    ),
    _Faq(
      'What does "Auto-start recording" do?',
      'After the tutor finishes speaking, the mic opens again by itself after '
          'a short delay, so you can keep the conversation going hands-free.',
    ),
    _Faq(
      'How do I save a word or phrase from the chat?',
      'Select the text in a tutor message and choose Save. Add a definition, '
          'example and translation yourself, or use Generate with AI / Translate with AI.',
    ),
  ]),
  _FaqGroup('My Notes & decks', Icons.style_outlined, [
    _Faq(
      'What is the difference between My Notes and Decks?',
      'They are the same notes. Every word in My Notes is also a flashcard in a '
          'deck ("From speaking" or "Saved words"), so editing it in one place '
          'updates the other.',
    ),
    _Faq(
      'How do I add a whole deck to My Notes?',
      'My Notes → the add-decks button → pick the decks. Their cards appear in '
          'My Notes; nothing is copied, and removing them from My Notes keeps the deck cards.',
    ),
    _Faq(
      'What do Generate with AI and Translate with AI do?',
      'Generate with AI writes a short definition and example in the word\'s own '
          'language (Premium). Translate with AI translates the word into your '
          'translation language, set in Settings → AI Speaking (Premium).',
    ),
  ]),
  _FaqGroup('Reviewing cards', Icons.replay_rounded, [
    _Faq(
      'How are review dates chosen?',
      'Rate each card Again, Hard, Good or Easy. Cards you know well come back '
          'after longer and longer gaps; cards you miss come back soon. The time '
          'next to each button shows when you will see the card again.',
    ),
    _Faq(
      'Where are flag, star, suspend and bury?',
      'During review, tap the ⋯ button (phones) to open the card tools. On '
          'tablet and web they are in the top bar next to the gear.',
    ),
    _Faq(
      'How do I see a translation of a card?',
      'Reveal the answer, then tap "Show translation" or "Translate to …". The '
          'translation is saved, so next time it shows straight away.',
    ),
    _d(2), // New / Learning / Review
    _d(3), // How spaced repetition (SM-2) works
    _d(9), // How review gestures work
    _d(10), // What a leech card is
  ]),
  _FaqGroup('Account & data', Icons.person_outline_rounded, [
    _Faq(
      'What does Premium add?',
      'Up to 4 hours of AI conversation a day (free: 5 minutes), unlimited saved '
          'words, Generate with AI, CEFR level detection and all tutor voices. '
          'Monthly or Yearly — Yearly starts with a 7-day free trial.',
    ),
    _Faq(
      'How do I start over?',
      'Profile → Security → Delete learning data removes your decks, cards, My '
          'Notes, speaking history and Activity stats. Your account and settings stay.',
    ),
    _Faq(
      'How do I delete my account?',
      'Profile → Security → Delete account. Type DELETE to confirm; this cannot be undone.',
    ),
  ]),
  _FaqGroup('Notes & note types', Icons.description_outlined, [
    _d(0), // Note vs card
    _d(1), // Adding a new flashcard
    _d(11), // Cloze deletions
    _d(14), // Math / LaTeX
  ]),
  _FaqGroup('Card browser & filtered decks', Icons.search_rounded, [
    _d(8), // What a filtered deck is
    _d(13), // Searching in the card browser
  ]),
  _FaqGroup('Import, export & backup', Icons.cloud_sync_outlined, [
    _d(4), // Importing an .apkg
    _d(5), // Finding shared decks
    _d(6), // Studying offline
    _d(7), // Sync conflicts
    _d(12), // Backing up the collection
  ]),
];

/// Profile → About → Help & FAQ.
class HelpFaqPage extends StatefulWidget {
  const HelpFaqPage({super.key});

  @override
  State<HelpFaqPage> createState() => _HelpFaqPageState();
}

class _HelpFaqPageState extends State<HelpFaqPage> {
  String _query = '';

  List<_FaqGroup> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _groups;
    return [
      for (final g in _groups)
        if (g.items.any(
          (f) =>
              f.question.toLowerCase().contains(q) ||
              f.answer.toLowerCase().contains(q),
        ))
          _FaqGroup(g.title, g.icon, [
            for (final f in g.items)
              if (f.question.toLowerCase().contains(q) ||
                  f.answer.toLowerCase().contains(q))
                f,
          ]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final groups = _filtered;
    return Scaffold(
      backgroundColor: AppPageColors.pageBgOf(context),
      appBar: AppBar(
        backgroundColor: AppPageColors.pageBgOf(context),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        title: const Text('Help & FAQ'),
      ),
      body: AppPageBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search help',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppPageColors.cardBgOf(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppPageColors.subtleBorderOf(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppPageColors.subtleBorderOf(context)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (groups.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'No answers match "$_query". Try another word or contact support.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppPageColors.subtitleOf(context)),
                ),
              ),
            for (final group in groups) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
                child: Row(
                  children: [
                    Icon(group.icon, size: 18, color: AppColors.brandPrimary),
                    const SizedBox(width: 8),
                    Text(
                      group.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppPageColors.cardBgOf(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppPageColors.subtleBorderOf(context)),
                ),
                clipBehavior: Clip.antiAlias,
                // ExpansionTile's header is a ListTile; it needs a Material
                // ancestor right next to it to paint ink splashes, and the
                // DecoratedBox above (for the card background) blocks that
                // from reaching the Scaffold's Material. This transparent
                // Material doesn't change the look, it just re-establishes
                // that ancestor at the right spot.
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    children: [
                      for (var i = 0; i < group.items.length; i++) ...[
                        if (i > 0)
                          Divider(height: 1, color: AppPageColors.subtleBorderOf(context)),
                        Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                          initiallyExpanded: _query.isNotEmpty,
                          iconColor: AppColors.brandPrimary,
                          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          title: Text(
                            group.items[i].question,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          children: [
                            Text(
                              group.items[i].answer,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.45,
                                color: AppPageColors.subtitleOf(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
