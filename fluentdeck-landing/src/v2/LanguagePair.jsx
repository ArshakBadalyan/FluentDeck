// "I speak [Turkish] → I want to speak [German]": both sides rotate together,
// showing that any of the app's languages can be paired with any other.
import { useEffect, useRef } from 'react';

import RotatingText from '../react-bits/RotatingText.jsx';
import Reserve from './Reserve.jsx';

/** Real pairs, in every direction: into English, out of English, and neither. */
export const PAIRS = [
  ['Spanish', 'English'],
  ['English', 'Japanese'],
  ['Turkish', 'German'],
  ['Russian', 'English'],
  ['English', 'Spanish'],
  ['Portuguese', 'French'],
  ['Arabic', 'English'],
  ['Vietnamese', 'Korean'],
  ['English', 'Italian'],
  ['Hindi', 'Mandarin'],
  ['Indonesian', 'English'],
  ['Armenian', 'Russian'],
];

export default function LanguagePair({ interval = 2600, animate = true }) {
  const from = useRef(null);
  const to = useRef(null);

  useEffect(() => {
    if (!animate) return undefined;
    const id = setInterval(() => {
      from.current?.next();
      // The target follows a beat later, so the eye reads left to right.
      setTimeout(() => to.current?.next(), 180);
    }, interval);
    return () => clearInterval(id);
  }, [animate, interval]);

  const shared = { auto: false, effect: 'slide', direction: 'up', staggerDuration: 0.02, splitLevelClassName: 'rotator-split' };

  return (
    <div className="lang-pair">
      <div className="lang-pair-side">
        <span className="lang-pair-label">I speak</span>
        <Reserve texts={[...new Set(PAIRS.map((p) => p[0]))]} sizerClass="lang-pair-word">
          <RotatingText ref={from} texts={PAIRS.map((p) => p[0])} mainClassName="lang-pair-word" {...shared} />
        </Reserve>
      </div>
      <svg className="lang-pair-arrow" width="28" height="28" viewBox="0 0 24 24" aria-hidden="true">
        <path d="M5 12h14M13 6l6 6-6 6" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
      </svg>
      <div className="lang-pair-side">
        <span className="lang-pair-label">I want to speak</span>
        <Reserve texts={[...new Set(PAIRS.map((p) => p[1]))]} sizerClass="lang-pair-word is-target">
          <RotatingText ref={to} texts={PAIRS.map((p) => p[1])} mainClassName="lang-pair-word is-target" {...shared} />
        </Reserve>
      </div>
    </div>
  );
}
