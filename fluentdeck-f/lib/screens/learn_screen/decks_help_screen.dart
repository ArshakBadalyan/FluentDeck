import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/data/decks_help_content.dart';

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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Help & FAQ'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryPurple,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: AppColors.primaryPurple,
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
          'Learn how Decks works — study, import, sync, and review like Anki.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _expanded,
          onExpansionChanged: (v) => setState(() => _expanded = v),
          title: Text(
            widget.section.title,
            style: const TextStyle(fontWeight: FontWeight.w600),
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
                      child: Text(p, style: TextStyle(color: Colors.grey.shade800, height: 1.45)),
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
                            Text('• ', style: TextStyle(color: AppColors.primaryPurple)),
                            Expanded(
                              child: Text(
                                b,
                                style: TextStyle(color: Colors.grey.shade800, height: 1.4),
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${decksFaqItems.length} common questions about Decks, import, sync, and review.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 12),
        ...decksFaqItems.map(
          (item) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: Text(
                  item.question,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      item.answer,
                      style: TextStyle(color: Colors.grey.shade800, height: 1.45),
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
