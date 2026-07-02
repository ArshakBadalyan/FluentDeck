/// Card Review Screen
/// Study individual flashcards with SM-2 algorithm
/// Days 10-11 Implementation - Most Complex

import 'package:flutter/material.dart';
import '../../ui_elements/enhanced_design_system.dart';
import '../../ui_elements/design_components.dart';
import 'review_components.dart';

class ReviewScreen extends StatefulWidget {
  final String deckId;

  const ReviewScreen({Key? key, required this.deckId}) : super(key: key);

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _cardAnimController;
  int currentCardIndex = 0;
  bool isCardFlipped = false;
  bool showXP = false;
  int earnedXP = 10;

  // Mock data
  final List<FlashcardItem> cards = [
    FlashcardItem(
      front: 'Corazón',
      frontLabel: 'WORD',
      back: 'Heart',
      backLabel: 'MEANING',
      pronunciation: '[ko-ra-THÓN]',
    ),
    FlashcardItem(
      front: 'Casa',
      frontLabel: 'WORD',
      back: 'House',
      backLabel: 'MEANING',
      pronunciation: '[KAH-sah]',
    ),
    FlashcardItem(
      front: '¿Cómo estás?',
      frontLabel: 'PHRASE',
      back: 'How are you?',
      backLabel: 'ENGLISH',
      pronunciation: '[KO-mo es-TAHS]',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _cardAnimController = AnimationController(
      duration: DesignAnimations.normal,
      vsync: this,
    );
  }

  void flipCard() {
    setState(() {
      isCardFlipped = !isCardFlipped;
    });
    _cardAnimController.forward(from: 0);
  }

  void handleCardResponse(SM2Response response) {
    // Show XP
    setState(() => showXP = true);
    Future.delayed(Duration(milliseconds: 600), () {
      setState(() => showXP = false);
    });

    // Move to next card
    Future.delayed(Duration(milliseconds: 1200), () {
      if (currentCardIndex < cards.length - 1) {
        setState(() {
          currentCardIndex++;
          isCardFlipped = false;
        });
      } else {
        _showCompletionDialog();
      }
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignRadius.lg),
        ),
        child: Padding(
          padding: EdgeInsets.all(DesignSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🎉',
                style: TextStyle(fontSize: 48),
              ),
              SizedBox(height: DesignSpacing.md),
              Text(
                'Review Complete!',
                style: DesignTypography.headingLarge,
              ),
              SizedBox(height: DesignSpacing.md),
              Text(
                'You earned 50 XP and kept your 15-day streak!',
                style: DesignTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: DesignSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: PremiumButton(
                      label: 'Continue',
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = cards[currentCardIndex];

    return Scaffold(
      backgroundColor: DesignPalette.bgPrimary,
      appBar: PremiumAppBar(
        title: 'Spanish Vocabulary',
        onBack: () => Navigator.pop(context),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: DesignSpacing.lg),
            child: Center(
              child: Text(
                'Card ${currentCardIndex + 1}/${cards.length}',
                style: DesignTypography.labelMedium,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // ===== PROGRESS BAR =====
              Padding(
                padding: EdgeInsets.all(DesignSpacing.lg),
                child: PremiumProgressBar(
                  value: (currentCardIndex + 1) / cards.length,
                  color: DesignPalette.primary,
                  height: 6,
                ),
              ),

              // ===== FLASHCARD =====
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignSpacing.lg,
                    vertical: DesignSpacing.md,
                  ),
                  child: GestureDetector(
                    onTap: flipCard,
                    child: AnimatedSwitcher(
                      duration: DesignAnimations.normal,
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: _FlashcardFace(
                        key: ValueKey(isCardFlipped),
                        card: card,
                        isFlipped: isCardFlipped,
                      ),
                    ),
                  ),
                ),
              ),

              // ===== ACTION BUTTONS =====
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignSpacing.lg,
                  vertical: DesignSpacing.lg,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Again Button
                        Expanded(
                          child: GestureDetector(
                            onTap: () => handleCardResponse(SM2Response.again),
                            child: Container(
                              height: 64,
                              decoration: BoxDecoration(
                                color: Color(0xFFE53935),
                                borderRadius: BorderRadius.circular(DesignRadius.md),
                                boxShadow: DesignShadows.elevation2,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.refresh, color: Colors.white, size: 24),
                                  SizedBox(height: DesignSpacing.xs),
                                  Text(
                                    'Again',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: DesignSpacing.md),

                        // Hard Button
                        Expanded(
                          child: GestureDetector(
                            onTap: () => handleCardResponse(SM2Response.hard),
                            child: Container(
                              height: 64,
                              decoration: BoxDecoration(
                                color: DesignPalette.warning,
                                borderRadius: BorderRadius.circular(DesignRadius.md),
                                boxShadow: DesignShadows.elevation2,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.schedule, color: Colors.white, size: 24),
                                  SizedBox(height: DesignSpacing.xs),
                                  Text(
                                    'Hard',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: DesignSpacing.md),
                    Row(
                      children: [
                        // Good Button
                        Expanded(
                          child: GestureDetector(
                            onTap: () => handleCardResponse(SM2Response.good),
                            child: Container(
                              height: 64,
                              decoration: BoxDecoration(
                                color: DesignPalette.warning,
                                borderRadius: BorderRadius.circular(DesignRadius.md),
                                boxShadow: DesignShadows.elevation2,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white, size: 24),
                                  SizedBox(height: DesignSpacing.xs),
                                  Text(
                                    'Good',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: DesignSpacing.md),

                        // Easy Button
                        Expanded(
                          child: GestureDetector(
                            onTap: () => handleCardResponse(SM2Response.easy),
                            child: Container(
                              height: 64,
                              decoration: BoxDecoration(
                                color: DesignPalette.success,
                                borderRadius: BorderRadius.circular(DesignRadius.md),
                                boxShadow: DesignShadows.elevation2,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.flash_on, color: Colors.white, size: 24),
                                  SizedBox(height: DesignSpacing.xs),
                                  Text(
                                    'Easy',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: DesignSpacing.lg),

                    // Feedback
                    if (!isCardFlipped)
                      Text(
                        'Tap card to reveal answer',
                        style: DesignTypography.caption,
                      ),
                  ],
                ),
              ),
            ],
          ),

          // ===== XP POPUP =====
          if (showXP)
            Positioned(
              top: 200,
              left: 0,
              right: 0,
              child: Center(
                child: XPDisplay(
                  xpAmount: earnedXP,
                  onComplete: () {},
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cardAnimController.dispose();
    super.dispose();
  }
}

// ============================================================================
// FLASHCARD FACE
// ============================================================================

class _FlashcardFace extends StatelessWidget {
  final FlashcardItem card;
  final bool isFlipped;

  const _FlashcardFace({
    Key? key,
    required this.card,
    required this.isFlipped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignRadius.lg),
      ),
      child: Container(
        padding: EdgeInsets.all(DesignSpacing.xl),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignRadius.lg),
          gradient: isFlipped
              ? LinearGradient(
                  colors: [
                    DesignPalette.warning.withOpacity(0.1),
                    DesignPalette.warning.withOpacity(0.05),
                  ],
                )
              : LinearGradient(
                  colors: [Colors.white, Colors.grey.shade50],
                ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isFlipped ? card.backLabel : card.frontLabel,
              style: DesignTypography.caption,
            ),
            SizedBox(height: DesignSpacing.lg),
            Text(
              isFlipped ? card.back : card.front,
              style: DesignTypography.displayLarge,
              textAlign: TextAlign.center,
            ),
            if (!isFlipped) ...[
              SizedBox(height: DesignSpacing.lg),
              Text(
                card.pronunciation,
                style: DesignTypography.bodySmall,
              ),
            ],
            SizedBox(height: DesignSpacing.xl),
            Text(
              isFlipped ? 'Tap to question' : 'Tap to reveal answer',
              style: DesignTypography.caption,
            ),
          ],
        ),
      ),
    );
  }
}
