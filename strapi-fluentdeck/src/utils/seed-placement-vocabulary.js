'use strict';

/**
 * Seeds published vocabulary entries for the placement test when the catalog is empty.
 */

const PLACEMENT_WORDS = [
  { word: 'hello', cefrLevel: 'A1', definition: 'A greeting.' },
  { word: 'water', cefrLevel: 'A1', definition: 'A clear liquid for drinking.' },
  { word: 'friend', cefrLevel: 'A1', definition: 'A person you like and trust.' },
  { word: 'happy', cefrLevel: 'A1', definition: 'Feeling pleasure or joy.' },
  { word: 'travel', cefrLevel: 'A2', definition: 'To go from one place to another.' },
  { word: 'weather', cefrLevel: 'A2', definition: 'Conditions such as sun, rain, or wind.' },
  { word: 'important', cefrLevel: 'A2', definition: 'Having great value or meaning.' },
  { word: 'remember', cefrLevel: 'A2', definition: 'To keep something in your memory.' },
  { word: 'experience', cefrLevel: 'B1', definition: 'Knowledge from doing or seeing things.' },
  { word: 'decision', cefrLevel: 'B1', definition: 'A choice you make after thinking.' },
  { word: 'environment', cefrLevel: 'B1', definition: 'The natural world around us.' },
  { word: 'achieve', cefrLevel: 'B1', definition: 'To succeed in doing something.' },
  { word: 'negotiate', cefrLevel: 'B2', definition: 'To discuss to reach an agreement.' },
  { word: 'ambiguous', cefrLevel: 'B2', definition: 'Open to more than one meaning.' },
  { word: 'consequence', cefrLevel: 'B2', definition: 'A result of an action.' },
  { word: 'perspective', cefrLevel: 'B2', definition: 'A point of view.' },
  { word: 'scrutinize', cefrLevel: 'C1', definition: 'To examine something very closely.' },
  { word: 'paradigm', cefrLevel: 'C1', definition: 'A typical example or model.' },
  { word: 'nuance', cefrLevel: 'C1', definition: 'A small difference in meaning.' },
  { word: 'coherent', cefrLevel: 'C1', definition: 'Logical and easy to understand.' },
  { word: 'quintessential', cefrLevel: 'C2', definition: 'The most perfect example of something.' },
  { word: 'ubiquitous', cefrLevel: 'C2', definition: 'Present everywhere.' },
  { word: 'ephemeral', cefrLevel: 'C2', definition: 'Lasting for a very short time.' },
  { word: 'serendipity', cefrLevel: 'C2', definition: 'Finding something good by luck.' },
];

async function seedPlacementVocabulary(strapi) {
  const publishedCount = await strapi.db
    .query('api::vocabulary-entry.vocabulary-entry')
    .count({ where: { publishedAt: { $notNull: true } } });

  if (publishedCount >= 24) {
    return { skipped: true, created: 0 };
  }

  let created = 0;
  const now = new Date();

  for (const [index, item] of PLACEMENT_WORDS.entries()) {
    const externalId = `placement-seed-${item.cefrLevel}-${item.word}`;
    const existing = await strapi.db.query('api::vocabulary-entry.vocabulary-entry').findOne({
      where: { externalId },
    });
    if (existing) continue;

    await strapi.db.query('api::vocabulary-entry.vocabulary-entry').create({
      data: {
        word: item.word,
        lemma: item.word,
        definition: item.definition,
        cefrLevel: item.cefrLevel,
        entryType: 'word',
        source: 'placement-seed',
        externalId,
        frequencyRank: index + 1,
        publishedAt: now,
      },
    });
    created += 1;
  }

  return { skipped: false, created };
}

module.exports = { seedPlacementVocabulary, PLACEMENT_WORDS };
