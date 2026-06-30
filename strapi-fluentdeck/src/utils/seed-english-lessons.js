"use strict";

const SAMPLE_LESSONS = [
  {
    title: "Introducing yourself",
    level: "A2",
    skillType: "speaking",
    order: 1,
    description: "Practice basic introductions and small talk.",
    exercises: [
      {
        type: "speakingPrompt",
        prompt: "Tell me about yourself. Where are you from?",
        aiFeedbackEnabled: true,
      },
      {
        type: "multipleChoice",
        prompt: 'Choose the correct greeting: "Nice to ___ you."',
        correctAnswer: "meet",
        options: ["meet", "met", "meeting", "meets"],
      },
      {
        type: "fillBlank",
        prompt: 'Complete: "My name ___ Anna."',
        correctAnswer: "is",
      },
    ],
  },
  {
    title: "Past tense practice",
    level: "B1",
    skillType: "grammar",
    order: 2,
    description: "Common past tense mistakes and corrections.",
    exercises: [
      {
        type: "conversation",
        prompt: "Talk about what you did last weekend.",
        aiFeedbackEnabled: true,
      },
      {
        type: "multipleChoice",
        prompt: "Yesterday I ___ to the cinema.",
        correctAnswer: "went",
        options: ["go", "went", "gone", "going"],
      },
      {
        type: "fillBlank",
        prompt: 'She ___ (not / go) to work yesterday.',
        correctAnswer: "didn't go",
      },
    ],
  },
  {
    title: "Travel vocabulary",
    level: "B1",
    skillType: "vocabulary",
    order: 3,
    description: "Words and phrases for airports and hotels.",
    exercises: [
      {
        type: "speakingPrompt",
        prompt: "Describe your last trip. Where did you go?",
        aiFeedbackEnabled: true,
      },
      {
        type: "multipleChoice",
        prompt: "At the airport you need a ___ to board the plane.",
        correctAnswer: "boarding pass",
        options: ["boarding pass", "luggage", "receipt", "menu"],
      },
    ],
  },
];

/**
 * Inserts sample lessons when the collection is empty (dev bootstrap).
 */
async function seedEnglishLessons(strapi) {
  const existing = await strapi.documents("api::lesson.lesson").findMany({
    limit: 1,
  });
  if (existing?.length > 0) {
    return { skipped: true, created: 0 };
  }

  let created = 0;
  const now = new Date().toISOString();

  for (const lesson of SAMPLE_LESSONS) {
    const { exercises, ...lessonFields } = lesson;
    const row = await strapi.documents("api::lesson.lesson").create({
      data: {
        ...lessonFields,
        publishedAt: now,
      },
    });

    for (const exercise of exercises) {
      await strapi.documents("api::exercise.exercise").create({
        data: {
          ...exercise,
          lesson: row.id,
          publishedAt: now,
        },
      });
    }

    created += 1;
    strapi.log.info(`[seed] Created lesson: ${lesson.title}`);
  }

  return { skipped: false, created };
}

module.exports = { SAMPLE_LESSONS, seedEnglishLessons };
