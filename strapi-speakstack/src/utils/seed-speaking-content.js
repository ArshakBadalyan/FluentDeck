"use strict";

const {
  ROLE_PLAY_SCENARIOS,
  SPEAKING_TOPICS,
  LEGACY_CATEGORY_MAP,
} = require("./speaking-content-catalog");

const SPEAKING_GAMES = [
  {
    title: "Heroes & Horrors",
    slug: "heroes-and-horrors",
    description: "A voice-driven fantasy adventure where you make choices and speak your actions.",
    iconKey: "dragon",
    order: 1,
    openingMessage:
      "Welcome to Heroes & Horrors! You enter a misty forest at dusk. You hear something moving in the shadows. What do you do?",
    systemPrompt: `You are the Dungeon Master for "Heroes & Horrors", a spoken English RPG for language learners.
- Set vivid but concise scenes (2-3 sentences).
- After each user action, describe what happens and present a new situation or choice.
- Keep language clear for B1-B2 learners; gently model natural phrasing in your narration.
- Encourage the user to describe actions and dialogue out loud in complete sentences.
- Track a simple story state: location, goal, and one inventory item when relevant.
- Add light tension and fantasy flavor (quests, creatures, mysteries, choices with consequences).
- Never kill the player instantly; give them chances to recover or try another approach.
- Praise creative answers; if grammar is off, weave a natural correction into the story once per turn max.
- End every scene with a clear question so the user knows what to say next.`,
  },
  {
    title: "Would You Rather",
    slug: "would-you-rather",
    description: "Choose between two options and explain your reasoning in English.",
    iconKey: "would_you_rather",
    order: 2,
    openingMessage:
      "Let's play Would You Rather! Here's the first one: Would you rather travel to the past or the future? Tell me your choice and why.",
    systemPrompt: `You are hosting "Would You Rather" for English practice.
- Present two interesting options each round.
- Ask the user to choose one and explain their reasoning in 2-4 sentences.
- Briefly react to their answer, then offer the next pair.
- Keep options varied: lifestyle, travel, food, technology, social situations.`,
  },
  {
    title: "Emoji Pictionary",
    slug: "emoji-pictionary",
    description: "Guess or describe what a string of emojis represents.",
    iconKey: "emoji",
    order: 3,
    openingMessage: "🍕✈️🇮🇹 — What do these emojis describe? Say your guess out loud!",
    systemPrompt: `You are hosting Emoji Pictionary for English learners.
- Give a clue using 2-5 emojis that represent a word, phrase, place, or activity.
- If the user guesses correctly, praise them and give the next emoji clue.
- If wrong, give a small hint and let them try again once.
- After a correct guess, briefly teach a related vocabulary word or phrase.`,
  },
  {
    title: "Cryptic Clues",
    slug: "cryptic-clues",
    description: "Solve riddles and word clues by speaking your answers.",
    iconKey: "detective",
    order: 4,
    openingMessage:
      "I have keys but no locks. I have space but no room. You can enter but can't go outside. What am I?",
    systemPrompt: `You are hosting Cryptic Clues for English practice.
- Give one riddle or cryptic clue at a time.
- Accept spoken answers; be flexible with wording if the meaning is correct.
- After each solved clue, give a one-line explanation and the next clue.
- Adjust difficulty based on user performance.`,
  },
  {
    title: "20 Questions",
    slug: "20-questions",
    description: "Think of something; the AI asks yes/no questions to guess it.",
    iconKey: "question",
    order: 5,
    openingMessage:
      "Think of a person, place, or thing. I have 20 yes-or-no questions. Say 'ready' when you've chosen something!",
    systemPrompt: `You are playing 20 Questions with an English learner.
- The user thinks of something; you ask ONE yes/no question per turn.
- Track how many questions you have asked (max 20).
- When you guess, ask "Am I right?"
- If you run out of questions, ask the user to reveal the answer and teach 1-2 related words.`,
  },
  {
    title: "Quick Quill",
    slug: "quick-quill",
    description: "Rapid speaking prompts to build fluency under light time pressure.",
    iconKey: "quill",
    order: 6,
    openingMessage:
      "Quick Quill! You'll get short prompts — answer as quickly and clearly as you can. First prompt: Describe your favorite season in two sentences.",
    systemPrompt: `You are hosting Quick Quill, a fluency game for English learners.
- Give short speaking prompts (one at a time).
- Prompt types: describe, opinion, compare, story starter, finish the sentence.
- After the user responds, give brief feedback on clarity, then immediately give the next prompt.
- Keep prompts varied and conversational; encourage fuller answers over time.`,
  },
];

/** Remaps legacy role-play categories to Fully Fluent filter values. */
async function migrateRolePlayCategories(strapi) {
  for (const [legacy, next] of Object.entries(LEGACY_CATEGORY_MAP)) {
    const rows = await strapi.db.query("api::conversation-prompt.conversation-prompt").findMany({
      where: { category: legacy },
    });
    for (const row of rows) {
      await strapi.db.query("api::conversation-prompt.conversation-prompt").update({
        where: { id: row.id },
        data: { category: next },
      });
    }
  }
}

/** Upserts role-play rows by title so partial/old CMS data still gets the full catalog. */
async function seedRolePlayScenarios(strapi) {
  await migrateRolePlayCategories(strapi);

  const now = new Date().toISOString();
  let created = 0;

  for (const item of ROLE_PLAY_SCENARIOS) {
    const existing = await strapi.entityService.findMany(
      "api::conversation-prompt.conversation-prompt",
      {
        filters: { title: item.title },
        limit: 1,
      },
    );
    if (existing?.length > 0) {
      continue;
    }

    await strapi.entityService.create(
      "api::conversation-prompt.conversation-prompt",
      {
        data: {
          ...item,
          publishedAt: now,
        },
      },
    );
    created += 1;
  }

  return { skipped: created === 0, created };
}

/** Upserts speaking topics by title so the full catalog is always available. */
async function seedSpeakingTopics(strapi) {
  const now = new Date().toISOString();
  let created = 0;

  for (const item of SPEAKING_TOPICS) {
    const existing = await strapi.entityService.findMany(
      "api::speaking-topic.speaking-topic",
      {
        filters: { title: item.title },
        limit: 1,
      },
    );
    if (existing?.length > 0) {
      continue;
    }

    await strapi.entityService.create("api::speaking-topic.speaking-topic", {
      data: {
        ...item,
        publishedAt: now,
      },
    });
    created += 1;
  }

  return { skipped: created === 0, created };
}

/** Upserts speaking games by slug. */
async function seedSpeakingGames(strapi) {
  const now = new Date().toISOString();
  let created = 0;

  for (const item of SPEAKING_GAMES) {
    const existing = await strapi.entityService.findMany(
      "api::speaking-game.speaking-game",
      {
        filters: { slug: item.slug },
        limit: 1,
      },
    );
    if (existing?.length > 0) {
      continue;
    }

    await strapi.entityService.create("api::speaking-game.speaking-game", {
      data: {
        ...item,
        publishedAt: now,
      },
    });
    created += 1;
  }

  return { skipped: created === 0, created };
}

async function seedSpeakingContent(strapi) {
  const rolePlay = await seedRolePlayScenarios(strapi);
  const topics = await seedSpeakingTopics(strapi);
  const games = await seedSpeakingGames(strapi);
  return { rolePlay, topics, games };
}

module.exports = {
  ROLE_PLAY_SCENARIOS,
  SPEAKING_TOPICS,
  SPEAKING_GAMES,
  migrateRolePlayCategories,
  seedRolePlayScenarios,
  seedSpeakingTopics,
  seedSpeakingGames,
  seedSpeakingContent,
};
