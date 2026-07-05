/// In-app Decks help content (Phase 5G).
class DecksHelpSection {
  final String id;
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;

  const DecksHelpSection({
    required this.id,
    required this.title,
    this.paragraphs = const [],
    this.bullets = const [],
  });
}

class DecksFaqItem {
  final String question;
  final String answer;

  const DecksFaqItem({required this.question, required this.answer});
}

const decksHelpSections = <DecksHelpSection>[
  DecksHelpSection(
    id: 'getting-started',
    title: 'Getting started',
    paragraphs: [
      'The Decks section has two tabs: Decks (study home) and Card browser (search and edit). Deck statistics live under Activity → Decks.',
      'Tap a deck name to open its overview. Tap the play button or count buttons to start studying. Use the + button to add a note, create a deck, or build a filtered deck.',
    ],
    bullets: [
      'Cloud icon — synced, pending upload, or offline',
      'Globe icon — browse and import shared decks',
      'Upload / download icons — import or export your collection',
      'Settings — organized into sections: General, Reviewing, Sync, Appearance, Backups, and more',
    ],
  ),
  DecksHelpSection(
    id: 'note-types',
    title: 'Note types',
    paragraphs: [
      'You add notes, not individual cards. Each note type defines fields and how cards are generated.',
    ],
    bullets: [
      'Basic — one card: front → back',
      'Basic (reversed) — two cards: front→back and back→front',
      'Basic (optional reversed) — add a reverse card with a checkbox',
      'Basic (type answer) — type your answer before revealing',
      'Cloze — hide parts of a sentence with {{c1::text}} syntax',
      'Image occlusion — hide regions on an image; tap to reveal',
      'Custom note types — create your own fields and templates in Manage note types',
    ],
  ),
  DecksHelpSection(
    id: 'import',
    title: 'Import & export',
    paragraphs: [
      'Import supports CSV, plain-text (.txt), JSON backups, and deck packages (.apkg). Export supports CSV, PDF, JSON, and APKG.',
    ],
    bullets: [
      'Import — tap upload on the deck list; choose format and target deck',
      'APKG — optionally import scheduling (due dates and intervals)',
      'Shared decks — tap the globe icon to browse and import community decks',
      'Backup — Decks settings → Back up now (JSON); Restore from backup to merge',
      'Export — download icon on deck list; pick format and optional deck scope',
    ],
  ),
  DecksHelpSection(
    id: 'review-gestures',
    title: 'Review & gestures',
    paragraphs: [
      'During review, tap the card to reveal the answer, then rate with Again, Hard, Good, or Easy. Interval previews (e.g. 1m, 4d) show when enabled in settings.',
    ],
    bullets: [
      'Swipe left = Again, swipe right = Good (defaults; configurable in settings)',
      'Swipe up = reveal answer; swipe down = bury card',
      'Double tap — configurable (default: reveal)',
      'Undo — available from the review menu after rating',
      'Flag, mark, bury, suspend — from the review overflow menu',
      'Leech — cards with many lapses can auto-suspend when enabled',
    ],
  ),
  DecksHelpSection(
    id: 'card-browser',
    title: 'Card browser',
    paragraphs: [
      'Browse all cards across decks. Filter by deck, state, tag, or flag. Long-press or use select mode for bulk suspend, delete, or move.',
    ],
    bullets: [
      'Search — text in front/back fields',
      'Sort — front, due date, deck, or card type',
      'Preview — tap a card to preview without studying',
      'Filtered deck — save current filters as a temporary study deck',
    ],
  ),
  DecksHelpSection(
    id: 'statistics',
    title: 'Statistics',
    paragraphs: [
      'Track study progress with charts for today, future due, calendar heatmap, retention, answer-button distribution, and more.',
    ],
    bullets: [
      'Scope — Collection (all decks) or Deck: name',
      'Range — last 12 months or all history',
      'Export PDF — share or save a stats report',
      'Review log — recent ratings at the bottom of the screen',
    ],
  ),
  DecksHelpSection(
    id: 'cloud-sync',
    title: 'Cloud sync',
    paragraphs: [
      'Your collection syncs to your account on our server. Study offline anytime; ratings queue locally and upload when you sync.',
    ],
    bullets: [
      'Sync indicator — green = up to date, orange = pending reviews, grey = offline',
      'Manual sync — tap the cloud icon or Decks settings → Sync now',
      'Conflicts — if the server has a newer review, server data wins',
      'Multi-device — log in on another device and sync to see the same due counts',
    ],
  ),
];

const decksFaqItems = <DecksFaqItem>[
  DecksFaqItem(
    question: 'What is the difference between a note and a card?',
    answer:
        'A note is what you create (fields like Front and Back). A card is one reviewable item generated from that note. '
        'For example, a Basic (reversed) note creates two cards: front→back and back→front.',
  ),
  DecksFaqItem(
    question: 'How do I add a new flashcard?',
    answer:
        'Tap + on the deck list → Add note. Choose a note type and deck, fill in the fields, then save. '
        'You can also add from a deck overview or the Card browser tab.',
  ),
  DecksFaqItem(
    question: 'What do New, Learning, and Review mean?',
    answer:
        'New cards you have never studied. Learning cards are in short initial steps (minutes). '
        'Review cards have graduated to longer intervals (days or weeks). Counts on each deck row show how many are due today.',
  ),
  DecksFaqItem(
    question: 'How does spaced repetition work?',
    answer:
        'This app uses the SM-2 algorithm. Again resets progress, Hard/Good/Easy adjust the interval until your next review. '
        'Per-deck options control learning steps, daily limits, and graduating intervals.',
  ),
  DecksFaqItem(
    question: 'How do I import a deck package (.apkg)?',
    answer:
        'Tap the upload icon on the deck list → choose APKG. Optionally import scheduling to keep due dates. '
        'Media and note types are mapped to the closest built-in or custom types.',
  ),
  DecksFaqItem(
    question: 'How do I find shared decks?',
    answer:
        'Tap the globe icon on the deck list to open the shared decks page in your browser. Once you have a deck file, come back and use "Import a file" to bring it into the app.',
  ),
  DecksFaqItem(
    question: 'Can I study offline?',
    answer:
        'Yes. Start a review session while online to cache the queue. Ratings made offline are stored locally and upload when you sync. '
        'Adding new notes offline uses cached note types; editing existing notes still needs a connection.',
  ),
  DecksFaqItem(
    question: 'What happens when sync conflicts occur?',
    answer:
        'If you rated a card offline but the server already has a newer review, the server review is kept and your local rating is skipped. '
        'You will see a conflict notice after sync.',
  ),
  DecksFaqItem(
    question: 'What is a filtered deck?',
    answer:
        'A temporary deck built from a search (e.g. tag:hard or is:due). Cards stay in their original decks. '
        'Create one from + → Filtered deck or from the Card browser after filtering.',
  ),
  DecksFaqItem(
    question: 'How do review gestures work?',
    answer:
        'Enable gestures in Decks settings → Controls. Default: swipe left = Again, swipe right = Good, swipe up = reveal. '
        'You can reassign each gesture to Again, Hard, Good, Easy, reveal, bury, or undo.',
  ),
  DecksFaqItem(
    question: 'What is a leech card?',
    answer:
        'A card you miss repeatedly (many lapses). When leech auto-suspend is on, the card is suspended and you get a notification. '
        'Adjust the threshold in Decks settings → Leeches.',
  ),
  DecksFaqItem(
    question: 'How do cloze deletions work?',
    answer:
        'In a Cloze note, wrap hidden text with {{c1::answer}}. Each cloze number can generate a separate card. '
        'During review, one blank is hidden at a time.',
  ),
  DecksFaqItem(
    question: 'How do I backup my collection?',
    answer:
        'Decks settings → Back up now exports full JSON. Enable automatic backup for scheduled saves. '
        'Use Restore from backup to import a JSON file.',
  ),
  DecksFaqItem(
    question: 'How do I search in the card browser?',
    answer:
        'Open the Card browser tab, pick a deck or All decks, and type in the search field. '
        'Use the tag filter for specific tags. Sort and filter menus support state, flags, and marked notes.',
  ),
  DecksFaqItem(
    question: 'Can I use math (LaTeX) in cards?',
    answer:
        'Yes. Use \\( inline \\) or \\[ display \\] math in note fields. The editor toolbar has a Σ button to insert math. '
        'Math renders in review and preview.',
  ),
];

const cardBrowserContextualHint =
    'Search and filter all your cards here. Tap a card to preview, long-press for options, or use select mode for bulk actions.';

const statisticsContextualHint =
    'Track reviews, retention, and future due dates. Scope is Collection or a single deck; export a PDF report anytime.';
