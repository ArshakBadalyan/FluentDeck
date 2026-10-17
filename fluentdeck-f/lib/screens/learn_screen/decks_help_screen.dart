import 'package:flutter/material.dart';
import 'package:fluentdeck/data/decks_help_content.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';

/// In-app Decks help and FAQ (Phase 5G).
class DecksHelpScreen extends StatefulWidget {
  const DecksHelpScreen({
    super.key,
    this.initialTab = 0,
    this.initialSectionId,
  });

  final int initialTab;
  final String? initialSectionId;

  @override
  State<DecksHelpScreen> createState() => _DecksHelpScreenState();
}

class _DecksHelpScreenState extends State<DecksHelpScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _sectionKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    for (final section in decksHelpSections) {
      _sectionKeys[section.id] = GlobalKey();
    }
    if (widget.initialSectionId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSection());
    }
  }

  void _scrollToSection() {
    final id = widget.initialSectionId;
    if (id == null) return;
    final key = _sectionKeys[id];
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = AppPageColors.accentOf(context);
    return Scaffold(
      backgroundColor: AppPageColors.pageBgOf(context),
      appBar: AppBar(
        backgroundColor: AppPageColors.pageBgOf(context),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        title: const Text('Help & FAQ'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: accentColor,
          unselectedLabelColor: AppPageColors.subtitleOf(context),
          indicatorColor: accentColor,
          tabs: const [
            Tab(text: 'Guide'),
            Tab(text: 'FAQ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _GuideTab(
            sectionKeys: _sectionKeys,
            expandSectionId: widget.initialSectionId,
          ),
          const _FaqTab(),
        ],
      ),
    );
  }
}

class _GuideTab extends StatelessWidget {
  const _GuideTab({
    required this.sectionKeys,
    this.expandSectionId,
  });

  final Map<String, GlobalKey> sectionKeys;
  final String? expandSectionId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Learn how Decks works — study, import, sync, and review flashcards.',
          style: TextStyle(
            fontSize: 14,
            color: AppPageColors.subtitleOf(context),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        ...decksHelpSections.map(
          (section) => _HelpSectionTile(
            key: sectionKeys[section.id],
            section: section,
            initiallyExpanded: section.id == expandSectionId,
          ),
        ),
      ],
    );
  }
}

class _HelpSectionTile extends StatefulWidget {
  const _HelpSectionTile({
    super.key,
    required this.section,
    this.initiallyExpanded = false,
  });

  final DecksHelpSection section;
  final bool initiallyExpanded;

  @override
  State<_HelpSectionTile> createState() => _HelpSectionTileState();
}

class _HelpSectionTileState extends State<_HelpSectionTile> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final bodyColor = Theme.of(context).textTheme.bodyLarge?.color;
    final accentColor = AppPageColors.accentOf(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: AppPageColors.cardBgOf(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppPageColors.subtleBorderOf(context)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _expanded,
          onExpansionChanged: (v) => setState(() => _expanded = v),
          iconColor: accentColor,
          collapsedIconColor: AppPageColors.subtitleOf(context),
          title: Text(
            widget.section.title,
            style: TextStyle(fontWeight: FontWeight.w600, color: bodyColor),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...widget.section.paragraphs.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(p, style: TextStyle(color: bodyColor, height: 1.45)),
                    ),
                  ),
                  if (widget.section.bullets.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    ...widget.section.bullets.map(
                      (b) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• ', style: TextStyle(color: accentColor)),
                            Expanded(
                              child: Text(
                                b,
                                style: TextStyle(color: bodyColor, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqTab extends StatelessWidget {
  const _FaqTab();

  @override
  Widget build(BuildContext context) {
    final bodyColor = Theme.of(context).textTheme.bodyLarge?.color;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${decksFaqItems.length} common questions about Decks, import, sync, and review.',
          style: TextStyle(fontSize: 14, color: AppPageColors.subtitleOf(context)),
        ),
        const SizedBox(height: 12),
        ...decksFaqItems.map(
          (item) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 0,
            color: AppPageColors.cardBgOf(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: AppPageColors.subtleBorderOf(context)),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                iconColor: AppPageColors.accentOf(context),
                collapsedIconColor: AppPageColors.subtitleOf(context),
                title: Text(
                  item.question,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: bodyColor,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      item.answer,
                      style: TextStyle(color: bodyColor, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
