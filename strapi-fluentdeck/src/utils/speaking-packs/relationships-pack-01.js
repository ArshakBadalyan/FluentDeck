"use strict";

/**
 * Relationships role-play pack #1 — emotionally nuanced conversations
 * requiring opinions, agreement/disagreement, and difficult decisions,
 * distinct from the 8 existing relationships scenarios.
 */

const { rolePlay } = require("../speaking-content-catalog");

const RELATIONSHIPS_PACK_01 = [
  rolePlay(
    "Meeting your partner's parents for the first time",
    "You're having dinner with your partner's parents for the first time. Make a good impression and answer their questions naturally.",
    { difficultyLevel: "B1", category: "relationships", userRole: "Partner", tutorRole: "Partner's parent", iconKey: "favorite", order: 165,
      suggestedVocabulary: ["good impression", "nervous", "get to know", "polite", "genuinely"] },
  ),
  rolePlay(
    "Discussing moving in together",
    "You and your partner have been dating for a year. Bring up the idea of moving in together and talk through concerns.",
    { difficultyLevel: "B2", category: "relationships", userRole: "Partner", tutorRole: "Partner", iconKey: "home", order: 166,
      suggestedVocabulary: ["move in together", "ready", "finances", "space", "commitment"] },
  ),
  rolePlay(
    "Setting relationship boundaries with a friend",
    "A close friend often shows up unannounced and overstays. Explain the boundary you need without hurting the friendship.",
    { difficultyLevel: "B2", category: "relationships", userRole: "Friend", tutorRole: "Friend", iconKey: "social", order: 167,
      suggestedVocabulary: ["boundary", "unannounced", "need space", "value our friendship", "respect"] },
  ),
  rolePlay(
    "Reconnecting with an old friend after years apart",
    "You've run into a childhood friend you haven't spoken to in ten years. Catch up on what's changed in your lives.",
    { difficultyLevel: "B1", category: "relationships", userRole: "Friend", tutorRole: "Old friend", iconKey: "social", order: 168,
      suggestedVocabulary: ["catch up", "it's been years", "what have you been up to", "reconnect", "stay in touch"] },
  ),
  rolePlay(
    "Discussing finances with a partner",
    "You and your partner have very different spending habits. Have an honest conversation about money and a shared budget.",
    { difficultyLevel: "B2", category: "relationships", userRole: "Partner", tutorRole: "Partner", iconKey: "bank", order: 169,
      suggestedVocabulary: ["spending habits", "shared budget", "savings goal", "financial transparency", "compromise"] },
  ),
  rolePlay(
    "Confronting a friend who broke a promise",
    "Your friend promised to help you move but didn't show up. Tell them how it made you feel without starting a fight.",
    { difficultyLevel: "B2", category: "relationships", userRole: "Friend", tutorRole: "Friend", iconKey: "social", order: 170,
      suggestedVocabulary: ["broke a promise", "let down", "how it made me feel", "reliable", "explanation"] },
  ),
  rolePlay(
    "Comforting a friend going through a breakup",
    "Your best friend just ended a long relationship and is heartbroken. Support them through the conversation.",
    { difficultyLevel: "B1", category: "relationships", userRole: "Friend", tutorRole: "Heartbroken friend", iconKey: "favorite", order: 171,
      suggestedVocabulary: ["heartbroken", "here for you", "it takes time", "listen", "comfort"] },
  ),
  rolePlay(
    "Discussing having children with a partner",
    "You and your partner have different timelines on when to have kids. Talk through your feelings and find common ground.",
    { difficultyLevel: "C1", category: "relationships", userRole: "Partner", tutorRole: "Partner", iconKey: "favorite", order: 172,
      suggestedVocabulary: ["timeline", "common ground", "readiness", "priorities", "compromise"] },
  ),
  rolePlay(
    "Navigating a disagreement with your sibling",
    "You and your sibling disagree about how to care for an aging parent. Work through it respectfully.",
    { difficultyLevel: "B1", category: "relationships", userRole: "Sibling", tutorRole: "Sibling", iconKey: "home", order: 173,
      suggestedVocabulary: ["disagreement", "aging parent", "share responsibility", "respectfully", "fair"] },
  ),
  rolePlay(
    "Asking a friend for an honest opinion on a big decision",
    "You're considering a major life change and want your friend's honest, unfiltered opinion.",
    { difficultyLevel: "B1", category: "relationships", userRole: "Friend", tutorRole: "Friend", iconKey: "social", order: 174,
      suggestedVocabulary: ["honest opinion", "unfiltered", "big decision", "pros and cons", "trust your judgment"] },
  ),
  rolePlay(
    "Ending a friendship respectfully",
    "A friendship has become one-sided and draining. Explain, kindly but clearly, why you need to step back.",
    { difficultyLevel: "C1", category: "relationships", userRole: "Friend", tutorRole: "Friend", iconKey: "social", order: 175,
      suggestedVocabulary: ["one-sided", "drained", "step back", "no hard feelings", "closure"] },
  ),
  rolePlay(
    "Discussing long-distance relationship challenges",
    "You and your partner are about to start a long-distance relationship. Talk through expectations and how you'll stay connected.",
    { difficultyLevel: "B2", category: "relationships", userRole: "Partner", tutorRole: "Partner", iconKey: "favorite", order: 176,
      suggestedVocabulary: ["long-distance", "expectations", "stay connected", "visit schedule", "trust"] },
  ),
  rolePlay(
    "Talking to a friend about their concerning behavior",
    "You're worried a friend has been drinking too much lately. Bring it up with care, not judgment.",
    { difficultyLevel: "C1", category: "relationships", userRole: "Friend", tutorRole: "Friend", iconKey: "health", order: 177,
      suggestedVocabulary: ["concerned", "noticed", "without judgment", "support", "open up"] },
  ),
  rolePlay(
    "Planning a surprise party for a close friend",
    "You're organizing a surprise birthday party and need help keeping it secret. Coordinate with a mutual friend.",
    { difficultyLevel: "A2", category: "relationships", userRole: "Friend", tutorRole: "Mutual friend", iconKey: "birthday", order: 178,
      suggestedVocabulary: ["surprise party", "keep it a secret", "guest list", "coordinate", "excited"] },
  ),
  rolePlay(
    "Discussing blended family dynamics with a new partner",
    "Your partner has kids from a previous relationship. Talk honestly about how you'll navigate the blended family.",
    { difficultyLevel: "C1", category: "relationships", userRole: "Partner", tutorRole: "Partner", iconKey: "home", order: 179,
      suggestedVocabulary: ["blended family", "step-parent", "navigate", "boundaries", "patience"] },
  ),
  rolePlay(
    "Navigating jealousy in a friendship",
    "You feel jealous of a friend's recent success and it's affecting your friendship. Talk it through honestly with them.",
    { difficultyLevel: "B2", category: "relationships", userRole: "Friend", tutorRole: "Friend", iconKey: "social", order: 180,
      suggestedVocabulary: ["jealous", "honestly", "success", "insecure", "genuinely happy for you"] },
  ),
  rolePlay(
    "Asking a friend to be your best man or maid of honor",
    "You're getting married and want to ask your closest friend to stand by your side. Ask them.",
    { difficultyLevel: "A2", category: "relationships", userRole: "Friend", tutorRole: "Close friend", iconKey: "favorite", order: 181,
      suggestedVocabulary: ["best man", "maid of honor", "honored", "would you", "wedding party"] },
  ),
  rolePlay(
    "Having a difficult conversation with an aging parent",
    "Your parent's health is declining and they refuse extra help. Have a caring but firm conversation about next steps.",
    { difficultyLevel: "C1", category: "relationships", userRole: "Adult child", tutorRole: "Aging parent", iconKey: "home", order: 182,
      suggestedVocabulary: ["declining health", "independence", "extra help", "caring", "next steps"] },
  ),
  rolePlay(
    "Discussing different parenting styles with a co-parent",
    "You and your co-parent disagree on screen time rules for your child. Find a compromise together.",
    { difficultyLevel: "C1", category: "relationships", userRole: "Co-parent", tutorRole: "Co-parent", iconKey: "home", order: 183,
      suggestedVocabulary: ["parenting style", "screen time", "consistent rules", "compromise", "co-parent"] },
  ),
  rolePlay(
    "Making up after an argument with a partner",
    "You and your partner had a heated argument last night. Talk it through and reconnect this morning.",
    { difficultyLevel: "B1", category: "relationships", userRole: "Partner", tutorRole: "Partner", iconKey: "favorite", order: 184,
      suggestedVocabulary: ["make up", "heated argument", "apologize", "reconnect", "misunderstanding"] },
  ),
  rolePlay(
    "Supporting a grieving friend",
    "Your friend recently lost a family member. Reach out and offer meaningful support.",
    { difficultyLevel: "B2", category: "relationships", userRole: "Friend", tutorRole: "Grieving friend", iconKey: "favorite", order: 185,
      suggestedVocabulary: ["grieving", "condolences", "here for you", "loss", "support"] },
  ),
  rolePlay(
    "Discussing trust after being hurt in a relationship",
    "You were betrayed in a past relationship and struggle to trust your current partner. Open up about it.",
    { difficultyLevel: "C1", category: "relationships", userRole: "Partner", tutorRole: "Partner", iconKey: "favorite", order: 186,
      suggestedVocabulary: ["trust issues", "betrayed", "vulnerable", "reassurance", "patience"] },
  ),
  rolePlay(
    "Negotiating holiday plans between two families",
    "You and your partner both want to spend the holidays with your own families. Work out a fair plan.",
    { difficultyLevel: "B2", category: "relationships", userRole: "Partner", tutorRole: "Partner", iconKey: "holiday", order: 187,
      suggestedVocabulary: ["holiday plans", "alternate years", "fair", "compromise", "tradition"] },
  ),
  rolePlay(
    "Reconnecting with an estranged family member",
    "You haven't spoken to a sibling in years after a falling out. Reach out and try to repair the relationship.",
    { difficultyLevel: "C1", category: "relationships", userRole: "Sibling", tutorRole: "Estranged sibling", iconKey: "home", order: 188,
      suggestedVocabulary: ["estranged", "falling out", "repair", "reach out", "reconcile"] },
  ),
  rolePlay(
    "Discussing when to become exclusive in a new relationship",
    "You've been dating someone for a month and want to know if they're seeing other people. Bring it up.",
    { difficultyLevel: "B1", category: "relationships", userRole: "Partner", tutorRole: "New partner", iconKey: "favorite", order: 189,
      suggestedVocabulary: ["exclusive", "seeing other people", "define the relationship", "honest", "ready"] },
  ),
];

module.exports = { RELATIONSHIPS_PACK_01 };
