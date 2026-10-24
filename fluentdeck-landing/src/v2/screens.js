// Real app screens shown in the "See it in action" card stack, in order.
// Files live in public/media/live/ (captured from the running app; see README).
// Captured with a seeded demo learner (scripts/demo-data.mjs) and a real AI chat.
// If a file is missing, the onboarding screen stands in.
export const SCREENS = [
  { src: '/media/live/conversation-demo.webp', fallback: '/media/app/onboarding-light-1.webp', title: 'Job interview role-play', alt: 'A learner tells the AI tutor about a job interview and gets gentle corrections: practiced, I am worried' },
  { src: '/media/live/decks.webp', fallback: '/media/app/onboarding-light-3.webp', title: 'Your decks', alt: 'Flashcard decks, including Job interview English, with cards due and today\'s study time' },
  { src: '/media/live/review.webp', fallback: '/media/app/onboarding-light-2.webp', title: 'Smart review', alt: 'Reviewing the card Tell me about yourself, with Again, Hard, Good and Easy intervals' },
  { src: '/media/live/progress.webp', fallback: '/media/app/onboarding-light-4.webp', title: 'Your progress', alt: 'Progress: speaking turns, deck words, unique words spoken and AI tutor level B1' },
];
