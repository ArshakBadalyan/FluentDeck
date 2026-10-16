#!/usr/bin/env node
'use strict';

/**
 * Seeds a@yopmail.com with a rich mock dataset — 135 flashcards across two
 * decks, 200+ review log entries spread over the last 45 days (with a
 * guaranteed 14-day streak), review states, speaking sessions, saved
 * words/expressions (Speak tab), and a user-progress record — so the
 * Statistics/Activity charts and Profile tab have real multi-day data to
 * render instead of empty states.
 *
 * Re-running this script wipes and re-seeds the same account idempotently.
 *
 * Usage (must run on the project's Node 20, see .nvmrc):
 *   /Users/arshak/.nvm/versions/node/v20.20.2/bin/node scripts/seed-chart-demo-user.js
 */

const { compileStrapi, createStrapi } = require('@strapi/strapi');
const { createMyNote } = require('../src/utils/flashcard-auto-create');

const EMAIL = 'a@yopmail.com';
const PASSWORD = 'a@yopmail.com';
const NICKNAME = 'ChartDemo';

function pick(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function randInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function weightedRating() {
  const r = Math.random();
  if (r < 0.1) return 'again';
  if (r < 0.25) return 'hard';
  if (r < 0.85) return 'good';
  return 'easy';
}

// Weighted hour-of-day buckets so the "Hourly breakdown" chart has shape:
// a morning bump and a bigger evening bump.
const HOUR_WEIGHTS = [
  1, 1, 1, 1, 1, 1, 2, 3, 3, 2, 2, 2,
  2, 2, 2, 2, 2, 3, 4, 5, 5, 4, 3, 2,
];
function weightedHour() {
  const total = HOUR_WEIGHTS.reduce((a, b) => a + b, 0);
  let r = Math.random() * total;
  for (let h = 0; h < 24; h += 1) {
    r -= HOUR_WEIGHTS[h];
    if (r <= 0) return h;
  }
  return 12;
}

function dateAt(daysAgo, hour, minute) {
  const d = new Date();
  d.setHours(hour, minute, randInt(0, 59), 0);
  d.setDate(d.getDate() - daysAgo);
  return d;
}

const EVERYDAY_VOCAB = [
  ['abundant', 'Existing in large quantities; plentiful.'],
  ['accomplish', 'To achieve or complete something successfully.'],
  ['acquire', 'To gain or obtain something.'],
  ['adapt', 'To adjust to new conditions.'],
  ['adequate', 'Satisfactory or acceptable in quality or quantity.'],
  ['ambiguous', 'Open to more than one interpretation.'],
  ['anticipate', 'To expect or predict something.'],
  ['apparent', 'Clearly visible or understood; obvious.'],
  ['appreciate', 'To recognize the value of something.'],
  ['approach', 'A way of dealing with something.'],
  ['arbitrary', 'Based on random choice rather than reason.'],
  ['articulate', 'To express an idea clearly.'],
  ['assess', 'To evaluate or estimate the nature of something.'],
  ['assume', 'To suppose something without proof.'],
  ['attain', 'To succeed in achieving something.'],
  ['authentic', 'Genuine and of undisputed origin.'],
  ['beneficial', 'Resulting in good; favorable.'],
  ['bizarre', 'Very strange or unusual.'],
  ['brief', 'Short in duration.'],
  ['candid', 'Truthful and straightforward.'],
  ['capable', 'Having the ability to do something.'],
  ['cautious', 'Careful to avoid risk.'],
  ['coherent', 'Logical and consistent.'],
  ['collaborate', 'To work jointly with others.'],
  ['commence', 'To begin.'],
  ['compile', 'To collect and put together information.'],
  ['comprehend', 'To understand fully.'],
  ['conceal', 'To hide something.'],
  ['concise', 'Giving information clearly in few words.'],
  ['conclude', 'To bring to an end; to decide.'],
  ['confront', 'To face up to a difficult situation.'],
  ['consistent', 'Acting the same way over time.'],
  ['constraint', 'A limitation or restriction.'],
  ['contemplate', 'To think deeply about something.'],
  ['contradict', 'To state the opposite of something said.'],
  ['convey', 'To communicate an idea or feeling.'],
  ['crucial', 'Extremely important.'],
  ['curious', 'Eager to know or learn something.'],
  ['deliberate', 'Done consciously and intentionally.'],
  ['demonstrate', 'To clearly show the existence of something.'],
  ['derive', 'To obtain something from a source.'],
  ['diligent', 'Showing care and effort in work.'],
  ['diminish', 'To make or become less.'],
  ['discern', 'To perceive or recognize something.'],
  ['distinct', 'Clearly different or separate.'],
  ['diverse', 'Showing variety.'],
  ['eager', 'Wanting to do something very much.'],
  ['elaborate', 'To explain in further detail.'],
  ['eligible', 'Having the right to do or receive something.'],
  ['eliminate', 'To completely remove or get rid of.'],
  ['emphasize', 'To give special importance to something.'],
  ['endure', 'To suffer something patiently.'],
  ['enhance', 'To improve the quality of something.'],
  ['enormous', 'Very large in size.'],
  ['ensure', 'To make certain something will happen.'],
  ['establish', 'To set up something on a firm basis.'],
  ['evaluate', 'To form an idea of the value of something.'],
  ['eventually', 'In the end; finally.'],
  ['evident', 'Clearly seen or understood.'],
  ['exceed', 'To be greater than a number or amount.'],
  ['exclude', 'To deny access to; to leave out.'],
  ['exhausted', 'Extremely tired.'],
  ['expand', 'To become larger.'],
  ['explicit', 'Stated clearly and in detail.'],
  ['extensive', 'Covering a large area; thorough.'],
  ['facilitate', 'To make an action easier.'],
  ['feasible', 'Possible to do easily.'],
  ['flexible', 'Able to change to suit new conditions.'],
  ['fluctuate', 'To rise and fall irregularly.'],
  ['fundamental', 'Forming a necessary base.'],
  ['generate', 'To produce or create something.'],
  ['genuine', 'Truly what it is said to be.'],
  ['grasp', 'To understand something fully.'],
  ['hesitate', 'To pause before doing something.'],
  ['identical', 'Exactly alike.'],
  ['illustrate', 'To explain by using examples.'],
  ['immense', 'Extremely large.'],
  ['implement', 'To put a plan into effect.'],
  ['imply', 'To suggest without stating directly.'],
  ['inevitable', 'Certain to happen; unavoidable.'],
  ['influence', 'The capacity to affect someone or something.'],
  ['initiate', 'To begin something.'],
  ['insight', 'A clear understanding of something.'],
  ['integrate', 'To combine parts into a whole.'],
  ['intentional', 'Done on purpose.'],
  ['interpret', 'To explain the meaning of something.'],
  ['invariably', 'In every case; always.'],
  ['justify', 'To show something is right or reasonable.'],
  ['legitimate', 'Conforming to the law or rules.'],
  ['maintain', 'To keep something at the same level.'],
  ['manipulate', 'To handle or control skillfully.'],
  ['mitigate', 'To make less severe.'],
  ['modify', 'To make partial changes to something.'],
  ['notable', 'Worthy of attention.'],
  ['obstacle', 'Something that blocks progress.'],
  ['obvious', 'Easily perceived or understood.'],
  ['occur', 'To happen.'],
  ['perceive', 'To become aware of through the senses.'],
  ['persist', 'To continue firmly despite difficulty.'],
  ['plausible', 'Seeming reasonable or probable.'],
  ['precise', 'Exact and accurate.'],
  ['predominant', 'Present as the strongest element.'],
  ['preliminary', 'Preceding the main part.'],
  ['presume', 'To suppose something is true.'],
  ['prevalent', 'Widespread in a particular area.'],
  ['proficient', 'Competent or skilled.'],
  ['prominent', 'Important or well known.'],
  ['prompt', 'Done without delay.'],
];

const TRAVEL_PHRASES = [
  ['Where is the nearest train station?', 'Asking for directions to the train station.'],
  ['Could you recommend a good restaurant nearby?', 'Asking a local for a dining suggestion.'],
  ['I would like to check in, please.', 'Said at a hotel front desk.'],
  ['Is breakfast included in the price?', 'Asking about hotel amenities.'],
  ['How much does a ticket to the city center cost?', 'Asking for transport fare information.'],
  ['Can I have the menu, please?', 'Requesting a restaurant menu.'],
  ['I have a reservation under the name Smith.', 'Confirming a booking.'],
  ['What time does the museum open?', 'Asking for opening hours.'],
  ['Could you call a taxi for me?', 'Requesting transportation.'],
  ['Is this seat taken?', 'Asking about seat availability.'],
  ['Excuse me, I am lost.', 'Asking a stranger for help with directions.'],
  ['Do you accept credit cards?', 'Asking about payment methods.'],
  ['I would like to exchange some money.', 'Asking at a currency exchange.'],
  ['Where can I buy a SIM card?', 'Asking about mobile connectivity.'],
  ['Could you speak more slowly, please?', 'Asking someone to slow down while speaking.'],
  ['What is the Wi-Fi password?', 'Asking for internet access details.'],
  ['I need to cancel my reservation.', 'Canceling a booking.'],
  ['Is there a pharmacy nearby?', 'Asking for the nearest pharmacy.'],
  ['Can you suggest some tourist attractions?', 'Asking for sightseeing recommendations.'],
  ['My luggage did not arrive.', 'Reporting lost baggage at the airport.'],
  ['Where is the boarding gate?', 'Asking for airport directions.'],
  ['I would like a window seat, please.', 'Requesting a seat preference.'],
  ['How long is the flight delayed?', 'Asking about flight status.'],
  ['Could I have the bill, please?', 'Asking for the restaurant check.'],
  ['Is it safe to walk here at night?', 'Asking about local safety.'],
  ['What is the local emergency number?', 'Asking for emergency contact information.'],
  ['Do you have a vegetarian option?', 'Asking about dietary choices on a menu.'],
  ['Can you recommend a good hiking trail?', 'Asking for outdoor activity suggestions.'],
  ['I need to renew my visa.', 'Discussing immigration paperwork.'],
  ['What time is checkout?', 'Asking about hotel checkout time.'],
  ['Is there a luggage storage service?', 'Asking about baggage storage.'],
  ['Could you give me directions to the airport?', 'Asking for travel directions.'],
  ['How do I get a refund for this ticket?', 'Asking about ticket refund policy.'],
  ['Is tipping customary here?', 'Asking about local tipping etiquette.'],
  ['I would like to book a guided tour.', 'Booking a sightseeing tour.'],
];

// [word/expression, definition, example sentence]
const SPEAKING_WORDS_AND_EXPRESSIONS = [
  ['break the ice', 'To say or do something that relieves tension or starts a conversation.', 'She told a joke to break the ice at the meeting.'],
  ['get the hang of it', 'To learn how to do something through practice.', 'It took me a while, but I finally got the hang of it.'],
  ['on the same page', 'In agreement; having the same understanding.', "Let's make sure we're on the same page before the meeting."],
  ['piece of cake', 'Something very easy to do.', 'The exam was a piece of cake.'],
  ['hit the books', 'To study hard.', 'I need to hit the books before the test tomorrow.'],
  ['under the weather', 'Feeling slightly ill.', "I'm feeling a bit under the weather today."],
  ['call it a day', 'To stop working on something for now.', "Let's call it a day and continue tomorrow."],
  ['out of the blue', 'Unexpectedly; without warning.', 'He called me out of the blue after years of silence.'],
  ['a blessing in disguise', 'A good thing that initially seemed bad.', 'Losing that job was a blessing in disguise.'],
  ['cost an arm and a leg', 'To be very expensive.', 'That new phone cost an arm and a leg.'],
  ['speak of the devil', 'Said when the person being discussed arrives.', 'Speak of the devil, here he comes now.'],
  ['hang in there', 'To stay strong during a difficult time.', 'Hang in there, things will get better.'],
  ['the ball is in your court', "It's your decision or responsibility now.", "I've made my offer, the ball is in your court."],
  ['once in a blue moon', 'Very rarely.', 'We only go to the cinema once in a blue moon.'],
  ['let the cat out of the bag', 'To reveal a secret accidentally.', 'He let the cat out of the bag about the surprise party.'],
  ['articulate', 'Able to express ideas clearly and effectively.', 'She gave a very articulate explanation of the problem.'],
  ['candid', 'Truthful and straightforward; frank.', 'He was candid about his mistakes.'],
  ['fluent', 'Able to speak a language easily and accurately.', 'After a year abroad, she became fluent in Spanish.'],
  ['hesitant', 'Slow to act because of uncertainty.', 'He seemed hesitant to answer the question.'],
  ['confident', 'Feeling sure of oneself.', 'She spoke with confidence during the presentation.'],
  ['get your point across', 'To successfully communicate what you mean.', 'He struggled to get his point across in the meeting.'],
  ['beat around the bush', 'To avoid saying something directly.', 'Stop beating around the bush and tell me what happened.'],
  ['food for thought', 'Something worth thinking about seriously.', 'His comment gave me food for thought.'],
  ['see eye to eye', 'To agree with someone.', "We don't always see eye to eye on politics."],
  ['keep an eye on', 'To watch or monitor something or someone.', 'Can you keep an eye on my bag for a minute?'],
  ['eloquent', 'Fluent and persuasive in speaking.', 'The speaker was eloquent and captivating.'],
  ['mumble', 'To speak quietly and unclearly.', 'He mumbled an apology and left the room.'],
  ['small talk', 'Polite conversation about unimportant topics.', 'We made small talk while waiting for the bus.'],
  ['think on your feet', 'To think and react quickly.', 'Good interviewers need to think on their feet.'],
  ['cut to the chase', 'To get to the point without wasting time.', "Let's cut to the chase and discuss the budget."],
  ['persuade', 'To convince someone to do or believe something.', 'She persuaded him to join the team.'],
  ['in a nutshell', 'Briefly summarized.', 'In a nutshell, the project was a success.'],
  ['give someone the benefit of the doubt', "To trust someone's statement without proof.", "I'll give you the benefit of the doubt this time."],
  ['bite your tongue', 'To stop yourself from saying something.', 'I had to bite my tongue to avoid an argument.'],
  ['lost for words', 'Unable to speak due to surprise or emotion.', 'I was lost for words when I heard the news.'],
  ['rule of thumb', 'A general principle based on experience.', 'As a rule of thumb, arrive 10 minutes early.'],
  ['coherent', 'Logical and consistent; easy to follow.', 'He gave a coherent explanation of the plan.'],
  ['make yourself clear', 'To ensure your meaning is understood.', 'Please make yourself clear before we proceed.'],
  ['concise', 'Giving information clearly in a few words.', 'Her answer was concise and to the point.'],
  ['on the tip of my tongue', 'Almost remembered but not quite.', "His name is on the tip of my tongue."],
  ['straight to the point', 'Direct, without unnecessary detail.', 'Her feedback was straight to the point.'],
];

async function main() {
  const appContext = await compileStrapi();
  const app = await createStrapi(appContext).load();
  try {
    await seed(app);
    console.log(`\nDone. Sign in at ${EMAIL} / ${PASSWORD} to view the seeded data.`);
  } finally {
    await app.destroy();
  }
}

async function seed(strapi) {
  const authRole = await strapi.db.query('plugin::users-permissions.role').findOne({
    where: { type: 'authenticated' },
  });
  if (!authRole) throw new Error('Could not find the "authenticated" role.');

  let user = await strapi.db.query('plugin::users-permissions.user').findOne({
    where: { email: EMAIL },
  });

  if (user) {
    console.log(`User ${EMAIL} already exists (id ${user.id}) — resetting password and wiping previously seeded data…`);
    await strapi.plugin('users-permissions').service('user').edit(user.id, {
      password: PASSWORD,
      confirmed: true,
      blocked: false,
      role: authRole.id,
      english_level: 'B2',
    });
    await strapi.db.query('api::card-review-log.card-review-log').deleteMany({ where: { user: user.id } });
    await strapi.db.query('api::card-review-state.card-review-state').deleteMany({ where: { user: user.id } });
    await strapi.db.query('api::flashcard.flashcard').deleteMany({ where: { user: user.id } });
    await strapi.db.query('api::flashcard-note.flashcard-note').deleteMany({ where: { user: user.id } });
    await strapi.db.query('api::flashcard-deck.flashcard-deck').deleteMany({ where: { user: user.id } });
    await strapi.db.query('api::speaking-session.speaking-session').deleteMany({ where: { user: user.id } });
    await strapi.db.query('api::user-progress.user-progress').deleteMany({ where: { user: user.id } });
  } else {
    user = await strapi.plugin('users-permissions').service('user').add({
      email: EMAIL,
      username: NICKNAME,
      password: PASSWORD,
      provider: 'local',
      confirmed: true,
      blocked: false,
      role: authRole.id,
      name: 'Chart',
      surname: 'Demo',
      english_level: 'B2',
      practice_language: 'en',
    });
    console.log(`Created user ${EMAIL} (id ${user.id}).`);
  }

  // --- Decks ---------------------------------------------------------
  const deck1 = await strapi.db.query('api::flashcard-deck.flashcard-deck').create({
    data: {
      name: 'Everyday Vocabulary',
      deckSlug: `everyday-vocab-${user.id}`,
      isDefault: false,
      user: user.id,
    },
  });
  const deck2 = await strapi.db.query('api::flashcard-deck.flashcard-deck').create({
    data: {
      name: 'Travel Phrases',
      deckSlug: `travel-phrases-${user.id}`,
      isDefault: false,
      user: user.id,
    },
  });
  console.log(`Created decks: "${deck1.name}" (${deck1.id}), "${deck2.name}" (${deck2.id}).`);

  // --- Flashcards ------------------------------------------------------
  const cards = [];
  for (const [front, back] of EVERYDAY_VOCAB) {
    const card = await strapi.db.query('api::flashcard.flashcard').create({
      data: { front, back, cardType: 'basic', languageCode: 'en', tags: [], user: user.id, deck: deck1.id },
    });
    cards.push(card);
  }
  for (const [front, back] of TRAVEL_PHRASES) {
    const card = await strapi.db.query('api::flashcard.flashcard').create({
      data: { front, back, cardType: 'basic', languageCode: 'en', tags: [], user: user.id, deck: deck2.id },
    });
    cards.push(card);
  }
  console.log(`Created ${cards.length} flashcards.`);

  // --- Review states -----------------------------------------------------
  // ~12% stay "new" (no state row). The rest get a state: suspended, buried,
  // or an in-progress/mature review state with varied ease/interval/dueAt.
  const reviewableCards = [];
  let suspendedCount = 0;
  let buriedCount = 0;
  for (const card of cards) {
    const roll = Math.random();
    if (roll < 0.12) continue; // stays "new"

    const firstStudiedDaysAgo = randInt(2, 70);
    const firstStudiedAt = dateAt(firstStudiedDaysAgo, randInt(7, 22), randInt(0, 59));
    const lastReviewedAt = dateAt(randInt(0, 10), randInt(7, 22), randInt(0, 59));

    if (roll < 0.19) {
      // suspended
      await strapi.db.query('api::card-review-state.card-review-state').create({
        data: {
          state: 'review',
          intervalDays: randInt(5, 60),
          easeFactor: +(randInt(18, 30) / 10).toFixed(2),
          suspended: true,
          firstStudiedAt,
          lastReviewedAt,
          flashcard: card.id,
          user: user.id,
        },
      });
      suspendedCount += 1;
      reviewableCards.push(card);
      continue;
    }

    if (roll < 0.25) {
      // buried for a couple of days
      await strapi.db.query('api::card-review-state.card-review-state').create({
        data: {
          state: 'review',
          intervalDays: randInt(5, 60),
          easeFactor: +(randInt(18, 30) / 10).toFixed(2),
          buriedUntil: dateAt(-randInt(1, 3), 6, 0),
          firstStudiedAt,
          lastReviewedAt,
          flashcard: card.id,
          user: user.id,
        },
      });
      buriedCount += 1;
      reviewableCards.push(card);
      continue;
    }

    const mature = Math.random() < 0.65;
    const intervalDays = mature ? randInt(10, 180) : randInt(0, 12);
    const dueOffset = randInt(-10, 29); // negative = overdue, within next 30 days mostly
    await strapi.db.query('api::card-review-state.card-review-state').create({
      data: {
        state: mature ? 'review' : pick(['learning', 'relearning']),
        intervalDays,
        easeFactor: +(randInt(13, 32) / 10).toFixed(2),
        dueAt: dateAt(-dueOffset, randInt(7, 22), 0),
        lapses: randInt(0, 4),
        repetitions: randInt(1, 12),
        firstStudiedAt,
        lastReviewedAt,
        flashcard: card.id,
        user: user.id,
      },
    });
    reviewableCards.push(card);
  }
  console.log(
    `Created review states for ${reviewableCards.length} cards ` +
      `(${suspendedCount} suspended, ${buriedCount} buried, ${cards.length - reviewableCards.length} left "new").`,
  );

  // --- Review logs -------------------------------------------------------
  // Last 14 days: guaranteed >=1 review/day (clean streak). Days 15-45: ~70%
  // chance of activity. Ratings/hours are weighted for realistic-looking
  // Answer buttons / Hourly breakdown charts.
  let totalLogs = 0;
  const logBatch = [];
  for (let day = 0; day < 45; day += 1) {
    let count;
    if (day < 14) {
      count = randInt(3, 12);
    } else {
      count = Math.random() < 0.7 ? randInt(1, 9) : 0;
    }
    for (let i = 0; i < count; i += 1) {
      const card = pick(reviewableCards);
      const rating = weightedRating();
      const intervalBefore = Math.random() < 0.55 ? randInt(0, 20) : randInt(21, 120);
      const intervalAfter =
        rating === 'again' ? 0 : Math.max(intervalBefore + randInt(1, 15), 1);
      logBatch.push({
        user: user.id,
        flashcard: card.id,
        deck: card.deck,
        rating,
        durationMs: randInt(2000, 18000),
        intervalBefore,
        intervalAfter,
        stateBefore: intervalBefore >= 21 ? 'review' : 'learning',
        stateAfter: rating === 'again' ? 'relearning' : intervalAfter >= 21 ? 'review' : 'learning',
        reviewedAt: dateAt(day, weightedHour(), randInt(0, 59)),
      });
    }
  }
  for (const data of logBatch) {
    await strapi.db.query('api::card-review-log.card-review-log').create({ data });
    totalLogs += 1;
  }
  console.log(`Created ${totalLogs} review log entries across the last 45 days.`);

  // --- Speaking sessions ---------------------------------------------------
  const SESSION_MODES = ['chat', 'role_play', 'topic', 'game', 'lesson'];
  const SESSION_TITLES = {
    chat: ['Free conversation', 'Daily check-in', 'Casual chat'],
    role_play: ['Ordering at a restaurant', 'Checking into a hotel', 'Job interview practice'],
    topic: ['Travel plans', 'Favorite hobbies', 'Weekend routine'],
    game: ['Word chain game', 'Guess the word', 'Rapid vocabulary round'],
    lesson: ['Present perfect tense', 'Phrasal verbs lesson', 'Travel vocabulary lesson'],
  };
  let totalSpeakingMinutes = 0;
  let sessionCount = 0;
  for (let day = 0; day < 45; day += 1) {
    if (Math.random() < 0.55) continue; // not every day has a speaking session
    const mode = pick(SESSION_MODES);
    const durationMinutes = randInt(3, 15);
    totalSpeakingMinutes += durationMinutes;
    await strapi.db.query('api::speaking-session.speaking-session').create({
      data: {
        mode,
        title: pick(SESSION_TITLES[mode]),
        score: randInt(5, 10),
        feedback: 'Good use of vocabulary; keep practicing verb tenses.',
        durationMinutes,
        turnCount: randInt(4, 20),
        completedAt: dateAt(day, weightedHour(), randInt(0, 59)),
        user: user.id,
      },
    });
    sessionCount += 1;
  }
  console.log(`Created ${sessionCount} speaking sessions (${totalSpeakingMinutes} total minutes).`);

  // --- Saved words & expressions (Speak tab "Saved phrases") -----------------
  let notesCreated = 0;
  for (const [word, definition, exampleSentence] of SPEAKING_WORDS_AND_EXPRESSIONS) {
    await createMyNote(strapi, user.id, {
      word,
      definition,
      exampleSentence,
      source: 'speaking',
      languageCode: 'en',
    });
    notesCreated += 1;
  }
  console.log(`Created ${notesCreated} saved words/expressions (source: speaking).`);

  // --- Review states for the "From speaking" deck ---------------------------
  // createMyNote() leaves every generated card in the default "new" state, so
  // the deck list's red (learning-due) and green (review-due) counts stay at
  // 0. Give a portion of these cards an actual due-now state too.
  const speakingDeck = await strapi.db.query('api::flashcard-deck.flashcard-deck').findOne({
    where: { user: user.id, deckSlug: 'from_speaking' },
  });
  if (speakingDeck) {
    const speakingCards = await strapi.db.query('api::flashcard.flashcard').findMany({
      where: { user: user.id, deck: speakingDeck.id },
    });
    let learningDue = 0;
    let reviewDue = 0;
    let speakingLogs = 0;
    for (const card of speakingCards) {
      const roll = Math.random();
      if (roll < 0.3) {
        // learning (red), due now/overdue
        await strapi.db.query('api::card-review-state.card-review-state').create({
          data: {
            state: pick(['learning', 'relearning']),
            intervalDays: randInt(0, 5),
            easeFactor: +(randInt(18, 26) / 10).toFixed(2),
            dueAt: dateAt(randInt(0, 3), randInt(7, 22), 0),
            repetitions: randInt(1, 3),
            firstStudiedAt: dateAt(randInt(1, 20), randInt(7, 22), 0),
            lastReviewedAt: dateAt(randInt(0, 3), randInt(7, 22), 0),
            flashcard: card.id,
            user: user.id,
          },
        });
        learningDue += 1;
      } else if (roll < 0.55) {
        // review (green), due now/overdue
        await strapi.db.query('api::card-review-state.card-review-state').create({
          data: {
            state: 'review',
            intervalDays: randInt(10, 60),
            easeFactor: +(randInt(22, 32) / 10).toFixed(2),
            dueAt: dateAt(randInt(0, 4), randInt(7, 22), 0),
            repetitions: randInt(2, 8),
            firstStudiedAt: dateAt(randInt(10, 40), randInt(7, 22), 0),
            lastReviewedAt: dateAt(randInt(1, 10), randInt(7, 22), 0),
            flashcard: card.id,
            user: user.id,
          },
        });
        reviewDue += 1;
      } else {
        continue; // stays "new" (blue)
      }
      // One or two review log entries per due card, recent days.
      for (let i = 0; i < randInt(1, 2); i += 1) {
        await strapi.db.query('api::card-review-log.card-review-log').create({
          data: {
            user: user.id,
            flashcard: card.id,
            deck: speakingDeck.id,
            rating: weightedRating(),
            durationMs: randInt(2000, 15000),
            intervalBefore: randInt(0, 30),
            intervalAfter: randInt(1, 40),
            reviewedAt: dateAt(randInt(0, 10), weightedHour(), randInt(0, 59)),
          },
        });
        speakingLogs += 1;
      }
    }
    console.log(
      `"From speaking" deck: ${speakingCards.length} cards, ${learningDue} learning-due, ` +
        `${reviewDue} review-due, ${speakingCards.length - learningDue - reviewDue} new, ` +
        `${speakingLogs} review logs.`,
    );
  }

  // --- User progress -------------------------------------------------------
  await strapi.db.query('api::user-progress.user-progress').create({
    data: {
      currentLevel: 'B2',
      weakAreas: [
        { errorType: 'article_usage', label: 'Article usage (a/an/the)', count: 14 },
        { errorType: 'verb_tense', label: 'Verb tense consistency', count: 11 },
        { errorType: 'preposition', label: 'Preposition choice', count: 9 },
        { errorType: 'word_order', label: 'Word order', count: 7 },
        { errorType: 'subject_verb_agreement', label: 'Subject-verb agreement', count: 5 },
      ],
      streakDays: 0,
      flashcardReviewStreakDays: 14,
      totalSpeakingMinutes,
      perfectSentencesCount: randInt(30, 55),
      uniqueWordsUsed: randInt(220, 350),
      lastPracticeAt: new Date(),
      lastFlashcardReviewAt: new Date(),
      languageLevels: {
        en: {
          tutorLevel: 'B2',
          estimatedLevel: 'B2',
          speakingTurns: 142,
          perfectSentences: 58,
          correctionCount: 37,
          uniqueWordsSpoken: 310,
          deckWordsReviewed: 286,
          firstSelectedAt: dateAt(70, 9, 0).toISOString(),
          lastActiveAt: new Date().toISOString(),
          levelHistory: [
            { estimatedLevel: 'A1', recordedAt: dateAt(45, 9, 0).toISOString(), source: 'analytics' },
            { estimatedLevel: 'A2', recordedAt: dateAt(34, 10, 0).toISOString(), source: 'analytics' },
            { estimatedLevel: 'B1', recordedAt: dateAt(21, 11, 0).toISOString(), source: 'analytics' },
            { estimatedLevel: 'B2', recordedAt: dateAt(8, 9, 30).toISOString(), source: 'analytics' },
          ],
        },
        es: {
          tutorLevel: 'A2',
          estimatedLevel: 'A2',
          speakingTurns: 18,
          perfectSentences: 5,
          correctionCount: 9,
          uniqueWordsSpoken: 40,
          deckWordsReviewed: 0,
          firstSelectedAt: dateAt(12, 18, 0).toISOString(),
          lastActiveAt: dateAt(3, 17, 0).toISOString(),
          levelHistory: [
            { estimatedLevel: 'A1', recordedAt: dateAt(12, 18, 0).toISOString(), source: 'analytics' },
            { estimatedLevel: 'A2', recordedAt: dateAt(3, 17, 0).toISOString(), source: 'analytics' },
          ],
        },
      },
      user: user.id,
    },
  });
  console.log('Created user-progress record with 2-language level history (en, es).');
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
