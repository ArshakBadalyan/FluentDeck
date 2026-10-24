// Landing page: static, SEO-readable HTML with React Bits components
// mounted as small "islands" on top of it.
import { lazy, Suspense } from 'react';
import { createRoot } from 'react-dom/client';

import '../main.js'; // v1 behaviour: store badges, mobile menu, reveals, chat demo
import Aurora from '../react-bits/Aurora.jsx';
import CardSwap, { Card } from '../react-bits/CardSwap.jsx';
import CountUp from '../react-bits/CountUp.jsx';
import Magnet from '../react-bits/Magnet.jsx';
import RotatingText from '../react-bits/RotatingText.jsx';
import ShinyText from '../react-bits/ShinyText.jsx';
import SpotlightCard from '../react-bits/SpotlightCard.jsx';
import LanguagePair from './LanguagePair.jsx';
import Reserve from './Reserve.jsx';
import { SCREENS } from './screens.js';

// Below the fold: each loads in its own chunk when its section comes near.
const BorderGlow = lazy(() => import('../react-bits/BorderGlow.jsx'));
const BounceCards = lazy(() => import('../react-bits/BounceCards.jsx'));
const FlipCard = lazy(() => import('../react-bits/FlipCard.jsx'));
const LineWaves = lazy(() => import('../react-bits/LineWaves.jsx'));
const LogoLoop = lazy(() => import('../react-bits/LogoLoop.jsx'));
const StarBorder = lazy(() => import('../react-bits/StarBorder.jsx'));

const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
const wide = window.matchMedia('(min-width: 961px)').matches;

/** Languages a learner can practice (the headline rotates through them). */
const LANGUAGES = [
  'English', 'Spanish', 'French', 'German', 'Italian', 'Portuguese', 'Japanese', 'Korean',
  'Turkish', 'Russian', 'Arabic', 'Mandarin', 'Hindi', 'Vietnamese', 'Indonesian', 'Armenian',
];

/** Runs `cb` once, when `el` comes within `margin` of the viewport. */
function whenNear(el, cb, margin = '300px') {
  if (!('IntersectionObserver' in window)) return cb();
  const io = new IntersectionObserver(([entry]) => {
    if (!entry.isIntersecting) return;
    io.disconnect();
    cb();
  }, { rootMargin: margin });
  io.observe(el);
}

/**
 * Mounts an island once it is near the viewport. Until its lazy component
 * has loaded, the island keeps showing its original static HTML.
 */
function mountNear(el, render, prepare) {
  whenNear(el, () => {
    prepare?.();
    const html = el.innerHTML;
    createRoot(el).render(
      <Suspense fallback={<div style={{ display: 'contents' }} dangerouslySetInnerHTML={{ __html: html }} />}>
        {render(html)}
      </Suspense>,
    );
  });
}

const islands = (name) => document.querySelectorAll(`[data-island="${name}"]`);

/** Replaces an element's static content with a React tree built from it. */
function mount(el, render) {
  const html = el.innerHTML;
  createRoot(el).render(render(html));
}

// Headline: "Speak [English / Spanish / …] without the social anxiety."
islands('languages').forEach((el) =>
  mount(el, () => (
    <Reserve texts={LANGUAGES} sizerClass="reserve-highlight">
    <RotatingText
      texts={LANGUAGES}
      effect="slide"
      direction="up"
      highlight
      highlightColor="#0D7C86"
      staggerFrom="last"
      staggerDuration={0.025}
      splitLevelClassName="rotator-split"
      rotationInterval={2200}
      auto={!reduceMotion}
    />
    </Reserve>
  )),
);

// "Inside the app": the same languages, in a lighter style (coral text with
// a teal underline, blurring in) so it doesn't repeat the hero's teal block.
islands('languages-inline').forEach((el) =>
  mount(el, () => (
    <Reserve texts={LANGUAGES}>
    <RotatingText
      texts={LANGUAGES}
      effect="blur"
      staggerFrom="first"
      staggerDuration={0.03}
      mainClassName="lang-inline-text"
      splitLevelClassName="rotator-split"
      rotationInterval={2600}
      auto={!reduceMotion}
    />
    </Reserve>
  )),
);

// Languages: any pair works, so show pairs in every direction.
islands('language-pair').forEach((el) => mount(el, () => <LanguagePair animate={!reduceMotion} />));

// Eyebrow badge: a light sheen across "AI speaking tutor · Free to start".
islands('shiny').forEach((el) =>
  mount(el, () => (
    <ShinyText text={el.textContent} color="#2ec4cf" shineColor="#ffffff" speed={3} disabled={reduceMotion} />
  )),
);

// Stats: numbers count up when they scroll into view.
islands('count').forEach((el) =>
  mount(el, () => <CountUp to={Number(el.dataset.to)} duration={1.6} startWhen={!reduceMotion} />),
);

// Main button pulls gently toward the cursor (desktop pointers only).
islands('magnet').forEach((el) =>
  mount(el, (html) => (
    <Magnet padding={80} magnetStrength={4} disabled={reduceMotion || !wide}>
      <span dangerouslySetInnerHTML={{ __html: html }} />
    </Magnet>
  )),
);

// Feature cards: a soft teal spotlight follows the pointer.
islands('spotlight').forEach((el) =>
  mount(el, (html) => (
    <SpotlightCard className="feature-spot" spotlightColor="rgba(46, 196, 207, 0.22)" theme="dark">
      <div dangerouslySetInnerHTML={{ __html: html }} />
    </SpotlightCard>
  )),
);

// Hero background: a slow aurora in brand teal and voice coral. WebGL is the
// heaviest piece, so it only runs on wide screens without reduced motion.
if (wide && !reduceMotion) {
  islands('aurora').forEach((el) =>
    mount(el, () => (
      <Aurora colorStops={['#0A6870', '#2EC4CF', '#E2553A']} amplitude={0.9} blend={0.55} speed={0.6} />
    )),
  );
}

// "See it in action": a 3D stack of real app screens.
islands('screens').forEach((el) => {
  const size = wide ? { width: 300, height: 600 } : { width: 230, height: 470 };
  mount(el, () => (
    <CardSwap
      {...size}
      cardDistance={44}
      verticalDistance={50}
      delay={4200}
      autoplay={!reduceMotion}
      pauseOnHover
      theme="fluentdeck"
      cardRadius={28}
    >
      {SCREENS.map((s) => (
        <Card key={s.title} customClass="screen-card">
          <div className="screen-card-head">{s.title}</div>
          <img
            src={s.src}
            alt={s.alt}
            loading="lazy"
            draggable={false}
            onError={(e) => {
              if (e.currentTarget.src.endsWith(s.fallback)) return;
              e.currentTarget.src = s.fallback;
            }}
          />
        </Card>
      ))}
    </CardSwap>
  ));
});

// More app screens: a fan of real screens on desktop. Phones keep the plain
// scrolling row, which is lighter and easier to read at that size.
if (wide) {
  islands('fan').forEach((el) => {
    const shots = [...el.querySelectorAll('img')].map((img) => ({ src: img.getAttribute('src'), alt: img.alt }));
    const captions = [...el.querySelectorAll('figcaption')].map((c) => c.textContent);
    mountNear(el, () => (
      <>
        <BounceCards
          images={shots}
          containerWidth={980}
          containerHeight={520}
          cardSize={210}
          spread={170}
          rotation={7}
          arc={14}
          pushDistance={120}
          borderWidth={0}
          radius={26}
          animationDelay={0.2}
          enableHover={!reduceMotion}
        />
        <p className="fan-captions">{captions.join(' · ')}</p>
      </>
    ), () => el.classList.remove('shots'));
  });
}

// "Try it": the real correction from the demo conversation, as a flashcard.
islands('flip').forEach((el) =>
  mountNear(el, () => (
    <FlipCard
      width={340}
      height={220}
      radius={24}
      background="#0f2a2d"
      color="#f1f7f7"
      tilt={wide && !reduceMotion}
      glareOpacity={0.12}
      ariaLabel="Flashcard: tap to see the answer"
      front={
        <div className="flash-face">
          <span className="flash-label">Fill the gap</span>
          <p className="flash-text">Yesterday I ___ my answers.</p>
          <span className="flash-hint">(practice) · tap to flip</span>
        </div>
      }
      back={
        <div className="flash-face">
          <span className="flash-label is-answer">Answer</span>
          <p className="flash-text">Yesterday I <mark>practiced</mark> my answers.</p>
          <span className="flash-hint">Past simple: add -ed</span>
        </div>
      }
    />
  )),
);

// Languages: a slow marquee of every language, in its own script.
const NATIVE = [
  'English', 'Español', 'Français', 'Deutsch', 'Italiano', 'Português', '中文', '日本語',
  'Русский', 'हिन्दी', 'Türkçe', '한국어', 'العربية', 'Tiếng Việt', 'Bahasa Indonesia', 'Հայերեն',
];
islands('lang-loop').forEach((el) =>
  mountNear(el, () => (
    <LogoLoop
      logos={NATIVE.map((name) => ({ node: <span className="loop-lang">{name}</span>, title: name }))}
      speed={reduceMotion ? 0 : 42}
      gap={12}
      logoHeight={40}
      pauseOnHover
      fadeOut
      ariaLabel="Languages you can practice"
    />
  )),
);

// Premium Yearly: an edge glow that follows the pointer. The badge stays
// outside the glow so it can sit over the card's top edge.
islands('glow').forEach((el) => {
  let badgeHtml = '';
  let body = '';
  mountNear(
    el,
    () => (
      <>
        <span dangerouslySetInnerHTML={{ __html: badgeHtml }} />
        <BorderGlow
          className="plan-glow-card"
          backgroundColor="#0f1d1f"
          borderRadius={22}
          glowColor="184 63 50"
          colors={['#2ec4cf', '#0d7c86', '#ff7a59']}
          glowRadius={32}
          animated={!reduceMotion}
        >
          <div className="plan-glow-body" dangerouslySetInnerHTML={{ __html: body }} />
        </BorderGlow>
      </>
    ),
    () => {
      const badge = el.querySelector('.badge');
      badgeHtml = badge ? badge.outerHTML : '';
      badge?.remove();
      body = el.innerHTML;
      el.classList.add('plan-glow');
    },
  );
});

// Final call to action: a star travels round the button.
islands('star').forEach((el) => {
  const a = el.querySelector('a');
  mountNear(el, () => (
    <StarBorder
      as="a"
      href={a.getAttribute('href')}
      className="btn btn-primary btn-large star-cta"
      radius={14}
      thickness={2}
      duration={5}
      color="#2ec4cf"
      backgroundColor="#0d7c86"
      textColor="#ffffff"
    >
      {a.textContent.trim()}
    </StarBorder>
  ));
});

// Behind the final call to action: calm voice-like lines. WebGL, so wide
// screens only, and only once the section is about to scroll into view.
if (wide && !reduceMotion) {
  islands('waves').forEach((el) =>
    mountNear(el, () => (
        <LineWaves
          color1="#0d7c86"
          color2="#2ec4cf"
          color3="#ff7a59"
          speed={0.18}
          lineCount={46}
          lineWidth={1.1}
          glow={0.45}
          brightness={0.7}
          rotation={-18}
          edgeFade={0.6}
          clickRipple={false}
          opacity={0.55}
          maxDevicePixelRatio={1.5}
        />
    )),
  );
}
