// Rio, the otter mascot, in three scenes. Loaded by src/v2/main.jsx once the page
// has drawn; frames live in public/media/otter/, voice lines in .../otter/voice/.
// Pictures load per scene, only when a visitor gets near it (see preload/whenNear).
// Reduced motion or a data-saving/2G connection: one still Rio, nothing else.
//   1. Hero: stands by the phone's left edge; click and it runs behind the phone and pops out on the right to say hello.
//   3. More screens (desktop): hide-and-seek behind the screenshot cards.
//   4. Final section: the water rises, then the otter pops up through it.

const IMG = (name) => `/media/otter/${name}.webp`;
// Frames each scene swaps to, fetched ahead so a swap never flashes empty.
const RUN = ['run-1', 'run-2', 'run-3', 'run-4'];
const HERO_TALK = ['turn-front', 'turn-talk-mid', 'turn-talk'];
const HERO_FRAMES = ['turn-jump', ...HERO_TALK, ...RUN];
const FACE_TALK = ['face-happy', 'face-talk-mid', 'face-talk'];
const FAN_FRAMES = [...FACE_TALK, ...RUN, 'climb', 'peek', 'scream', 'fall-1', 'fall-2', 'dazed', 'ladder', 'limp-1', 'limp-2',
  'face-excited', 'face-sleepy'];
const END_FRAMES = ['face-excited', ...FACE_TALK];
const preload = (names) => names.forEach((name) => { new Image().src = IMG(name); });
/**
 * Moves Rio's mouth (closed / half / open) for `ms`, then rests on `rest`. At least ~1 s, so
 * Rio still "talks" with sound off. Any other frame change cancels it (pic.dataset.talk).
 */
function lipSync(pic, [closed, mid, open], ms, rest = closed) {
  const token = String(Math.random());
  pic.dataset.talk = token;
  const seq = [mid, open, mid, closed, open, mid, open, mid, closed];
  const end = performance.now() + Math.max(ms, 1100);
  let i = 0;
  return new Promise((done) => {
    const step = () => {
      if (pic.dataset.talk !== token) return done();
      if (performance.now() >= end) { pic.src = IMG(rest); delete pic.dataset.talk; return done(); }
      pic.src = IMG(seq[i % seq.length]);
      i += 1;
      setTimeout(step, 80 + Math.random() * 70);
    };
    step();
  });
}
/** Says a voice line and moves the mouth with it. */
async function speak(pic, frames, key, rest) {
  const ms = await sound.say(key);
  return lipSync(pic, frames, ms, rest);
}
/** Runs `fn` once, when `el` comes within `margin` of the screen. */
function whenNear(el, fn, margin = '600px') {
  const io = new IntersectionObserver(([e]) => {
    if (!e.isIntersecting) return;
    io.disconnect();
    fn();
  }, { rootMargin: margin });
  io.observe(el);
}

const HELLO = {
  English: 'Hello!', Spanish: '¡Hola!', French: 'Bonjour !', German: 'Hallo!', Italian: 'Ciao!',
  Portuguese: 'Olá!', Japanese: 'こんにちは', Korean: '안녕하세요', Turkish: 'Merhaba!', Russian: 'Привет!',
  Arabic: 'مرحبا', Mandarin: '你好！', Hindi: 'नमस्ते', Vietnamese: 'Xin chào!', Indonesian: 'Halo!', Armenian: 'Բարեւ!',
};
// The pop-up otter's hellos (voice + bubble) skip these.
const NO_HELLO = ['Russian', 'Armenian'];
const TEASES = ['Nope! 😜', 'Cold! ❄️', '¡Frío! 🥶', 'Non non! 😝', 'Not here! 🙃', 'Hehe, wrong one!', 'Warmer… no, colder! 😆', 'Try again! 🐾'];

const CSS = `
.otter-bubble { position: absolute; z-index: 60; transform: translate(-50%, -100%) scale(.6); transform-origin: 50% 100%;
  opacity: 0; pointer-events: none; white-space: nowrap; padding: 9px 15px; border-radius: 18px; background: #fff;
  color: #0f1d1f; font: 700 15px/1.2 Rubik, system-ui, sans-serif; box-shadow: 0 10px 30px rgba(0,0,0,.35);
  transition: opacity .2s, transform .3s cubic-bezier(.3,1.6,.5,1); }
.otter-bubble::after { content: ''; position: absolute; left: 50%; top: 100%; margin-left: calc(-8px - var(--tail, 0px)); border: 8px solid transparent; border-top-color: #fff; }
.otter-bubble.show { opacity: 1; transform: translate(-50%, -100%) scale(1); }
/* Side bubble: starts just right of the anchor, tail on its left. */
.otter-bubble.side { transform: translate(-14px, -100%) scale(.6); transform-origin: 0 100%; }
.otter-bubble.side.show { transform: translate(-14px, -100%) scale(1); }
.otter-bubble.side::after { left: calc(22px - var(--tail, 0px)); margin-left: -8px; }
.otter-img { display: block; width: auto; user-select: none; -webkit-user-drag: none; }
.otter-water { animation: otter-water 2.4s linear infinite; }
.otter-ripple { transform-box: fill-box; transform-origin: center; animation: otter-ripple 2.4s ease-out infinite; }
.otter-ripple.r2 { animation-delay: 1.2s; }
.otter-drop { opacity: 0; }
.splash .otter-drop { animation: otter-drop .7s ease-out; }

/* 1. Hero: stands in front of the phone, back turned; click to turn round.
   Two stacked frames crossfade, so each pose flows into the next. */
.otter-stand { position: absolute; z-index: 4; width: 200px; height: 200px; transform: translateX(-50%); cursor: pointer; }
.otter-stand .anim { position: absolute; inset: 0; transform-origin: 50% 100%; animation: otter-breathe 3.2s ease-in-out infinite; }
.otter-stand .anim .otter-img { position: absolute; left: 50%; bottom: 0; width: auto; height: 200px; transform: translateX(-50%); }
.otter-stand .anim .otter-img.left { transform: translateX(-50%) scaleX(-1); }
.otter-stand.behind { z-index: -1; } /* .hero-visual is isolated below, so this is just under the phone */
.hero-visual { isolation: isolate; }
.hero-visual .goal-card { left: -120px; z-index: 5; } /* a little left, and in front of the otter */
.otter-stand.ot-crouch .anim { animation: none; transform: scale(1.08, .86); transition: transform .12s ease-out; }
.otter-stand.ot-air .anim { animation: otter-leap .42s cubic-bezier(.3,.7,.4,1); }
.otter-stand.ot-land .anim { animation: otter-land .3s ease-out; }
.otter-stand.still { cursor: default; }
.otter-stand.still .anim { animation: none; }
.otter-stand.ot-hi .anim { animation: otter-hop .45s ease-in-out 2, otter-breathe 3.2s ease-in-out .9s infinite; }

/* 3. Fan hide-and-seek */
.ot-actor { position: absolute; left: 0; top: 0; z-index: 30; cursor: pointer; will-change: transform; }
.ot-actor.behind { z-index: 0; pointer-events: none; }
.ot-actor.gone { visibility: hidden; }
.ot-spin { transform-origin: 50% 70%; }
.ot-body { position: relative; transform-origin: 50% 100%; }
.ot-body.flip { transform: scaleX(-1); }
.ot-body.hop { animation: otter-hop .5s ease-in-out infinite; }
.ot-body.shake { animation: otter-shake .45s ease-in-out; }
.ot-body .otter-img { height: 150px; }
.ot-glow { position: absolute; inset: 0; opacity: 0; transition: opacity .8s; pointer-events: none;
  background: radial-gradient(ellipse 42% 34% at 24% 74%, rgba(255,35,35,.85), rgba(255,60,60,.35) 55%, transparent 75%);
  -webkit-mask: var(--frame) center / 100% 100% no-repeat; mask: var(--frame) center / 100% 100% no-repeat; }
.ot-glow.on { opacity: 1; }
.ot-stars { position: absolute; left: 50%; top: 6px; width: 110px; height: 34px; margin-left: -55px; opacity: 0; pointer-events: none; }
.ot-stars.on { opacity: 1; }
.ot-stars span { position: absolute; left: 50%; top: 50%; font-size: 20px; animation: otter-orbit 1s linear infinite; }
.ot-stars span:nth-child(2) { animation-delay: -.33s; } .ot-stars span:nth-child(3) { animation-delay: -.66s; }
.ot-peeker { position: absolute; left: 0; top: 0; z-index: 0; cursor: pointer; visibility: hidden; transition: visibility 0s .35s; }
.ot-peeker.out { visibility: visible; transition-delay: 0s; }
.ot-peeker .otter-img { height: 88px; transform: translateY(100%); transition: transform .35s cubic-bezier(.5,0,.9,.5); }
.ot-peeker.out .otter-img { transform: translateY(14%); transition: transform .55s cubic-bezier(.3,1.5,.5,1); }
.ot-ladder { position: absolute; left: 0; top: 0; z-index: 35; pointer-events: none; transform-origin: 50% 100%; visibility: hidden; }
.ot-ladder .otter-img { height: 210px; }

/* 4. Final section */
.otter-host { padding-bottom: 230px !important; }
.otter-stage { position: absolute; left: 50%; bottom: 0; z-index: 2; width: 300px; margin-left: -150px; height: 230px; }
.otter-stage .otter-pop { position: absolute; left: 50%; bottom: 20px; transform: translate(-50%, 190px);
  transition: transform .5s cubic-bezier(.6,0,.9,.4); cursor: pointer; }
.otter-stage.otter-up .otter-pop { transform: translate(-50%, 0); transition: transform .75s cubic-bezier(.3,1.5,.5,1); }
.otter-stage .otter-pop .otter-img { height: 190px; transform-origin: 50% 100%; }
.otter-stage.wiggle .otter-pop .otter-img { animation: otter-wiggle .5s ease-in-out infinite; }
.otter-stage.excited .otter-pop .otter-img { animation: otter-hop .45s ease-in-out infinite; }
.otter-stage .otter-sea-svg { position: absolute; left: 0; bottom: 0; width: 100%; height: auto; transform: translateY(70px);
  transition: transform .7s cubic-bezier(.6,0,.8,.4); pointer-events: none; }
.otter-stage.water-up .otter-sea-svg { transform: none; transition: transform .9s cubic-bezier(.2,.8,.3,1); }

/* Sound: the permission card, then a small speaker toggle. */
.otter-mute { position: fixed; left: 16px; bottom: 16px; z-index: 90; width: 44px; height: 44px; border-radius: 50%; border: 1px solid rgba(255,255,255,.12);
  background: #0f2226; color: #f3f4f6; font-size: 18px; cursor: pointer; box-shadow: 0 10px 24px rgba(0,0,0,.35); }

@keyframes otter-water { to { transform: translateX(-40px); } }
@keyframes otter-ripple { from { transform: scale(.6); opacity: .7; } to { transform: scale(1.35); opacity: 0; } }
@keyframes otter-drop { 0% { opacity: 1; transform: translate(0,0); } 100% { opacity: 0; transform: translate(var(--dx), -46px); } }
@keyframes otter-hop { 50% { transform: translateY(-10px); } }
@keyframes otter-wiggle { 0%,100% { transform: rotate(0); } 25% { transform: rotate(-5deg); } 75% { transform: rotate(5deg); } }
@keyframes otter-boop { 0%,100% { transform: translate(-50%, 0) scale(1); } 40% { transform: translate(-50%, -6px) scale(1.08); } }
@keyframes otter-breathe { 0%,100% { transform: scale(1, 1); } 50% { transform: scale(1.02, .985); } }
@keyframes otter-leap { from { transform: translateY(0); } 50% { transform: translateY(-70px) rotate(-6deg); } to { transform: translateY(0); } }
@keyframes otter-land { 0% { transform: scale(1.1, .85); } 60% { transform: scale(.96, 1.05); } 100% { transform: none; } }
@keyframes otter-shake { 0%,100% { transform: translateX(0); } 20% { transform: translateX(-6px); } 40% { transform: translateX(6px); } 60% { transform: translateX(-4px); } 80% { transform: translateX(4px); } }
@keyframes otter-orbit { from { transform: translate(-50%,-50%) rotate(0) translateX(46px) rotate(0) scaleY(.9); }
  to { transform: translate(-50%,-50%) rotate(360deg) translateX(46px) rotate(-360deg) scaleY(.9); } }
`;

/** Sea strip with edges that fade out (no box behind the otter). */
function sea(id, width = 280, depth = 60) {
  const y = 16;
  const waves = `M0 ${y} q10 -6 20 0 ${'t20 0 '.repeat(Math.ceil(width / 20) + 2)}V${y + depth} H0 Z`;
  return `
    <svg class="otter-sea-svg" viewBox="0 0 ${width} ${y + depth}" aria-hidden="true">
      <defs>
        <linearGradient id="${id}-sea" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2ec4cf"/><stop offset="1" stop-color="#0a6870"/></linearGradient>
        <linearGradient id="${id}-fade" x1="0" y1="0" x2="1" y2="0">
          <stop offset="0" stop-color="#fff" stop-opacity="0"/><stop offset=".2" stop-color="#fff"/>
          <stop offset=".8" stop-color="#fff"/><stop offset="1" stop-color="#fff" stop-opacity="0"/>
        </linearGradient>
        <mask id="${id}-mask" maskUnits="userSpaceOnUse" x="0" y="0" width="${width}" height="${y + depth}">
          <rect width="${width}" height="${y + depth}" fill="url(#${id}-fade)"/>
        </mask>
      </defs>
      <ellipse class="otter-ripple" cx="${width / 2}" cy="${y + 2}" rx="${width * 0.3}" ry="7" fill="none" stroke="#7ee6ec" stroke-width="2"/>
      <ellipse class="otter-ripple r2" cx="${width / 2}" cy="${y + 2}" rx="${width * 0.3}" ry="7" fill="none" stroke="#7ee6ec" stroke-width="2"/>
      <g mask="url(#${id}-mask)"><path class="otter-water" d="${waves}" fill="url(#${id}-sea)"/></g>
      <g fill="#7ee6ec">
        <circle class="otter-drop" cx="${width / 2 - 26}" cy="${y}" r="3" style="--dx:-18px"/>
        <circle class="otter-drop" cx="${width / 2}" cy="${y - 2}" r="3.5" style="--dx:0px"/>
        <circle class="otter-drop" cx="${width / 2 + 26}" cy="${y}" r="3" style="--dx:18px"/>
      </g>
    </svg>`;
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const pick = (list) => list[Math.floor(Math.random() * list.length)];

// ── Sound: voice lines (Kokoro, in public/media/otter/voice) + synthesized effects ──
const sound = (() => {
  const KEY = 'otter-sound';
  let on = false;
  let ctx = null;
  let voice = null;
  const buffers = new Map();
  const read = () => { try { return localStorage.getItem(KEY); } catch { return null; } };
  const save = (v) => { try { localStorage.setItem(KEY, v); } catch { /* private mode */ } };

  function audio() {
    if (!ctx) ctx = new (window.AudioContext || window.webkitAudioContext)();
    if (ctx.state === 'suspended') ctx.resume();
    return ctx;
  }
  async function load(key) {
    if (!buffers.has(key)) {
      buffers.set(key, fetch(`/media/otter/voice/${key}.mp3`).then((r) => r.arrayBuffer()).then((b) => audio().decodeAudioData(b)).catch(() => null));
    }
    return buffers.get(key);
  }
  /** Plays a voice line; resolves with its length in ms (0 when sound is off). */
  async function say(key) {
    if (!on) return 0;
    const buf = await load(key);
    if (!buf || !on) return 0;
    try { voice?.stop(); } catch { /* already ended */ }
    const src = audio().createBufferSource();
    src.buffer = buf;
    const g = ctx.createGain();
    g.gain.value = 0.9;
    src.connect(g).connect(ctx.destination);
    src.start();
    voice = src;
    return buf.duration * 1000;
  }

  // Effects, made on the fly.
  function noise(seconds) {
    const c = audio();
    const b = c.createBuffer(1, Math.ceil(c.sampleRate * seconds), c.sampleRate);
    const d = b.getChannelData(0);
    for (let i = 0; i < d.length; i += 1) d[i] = Math.random() * 2 - 1;
    const s = c.createBufferSource();
    s.buffer = b;
    return s;
  }
  function env(g, t, peak, dur) {
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(peak, t + 0.01);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
  }
  function tone(type, f0, f1, dur, peak) {
    const c = audio(); const t = c.currentTime;
    const o = c.createOscillator(); const g = c.createGain();
    o.type = type;
    o.frequency.setValueAtTime(f0, t);
    o.frequency.exponentialRampToValueAtTime(f1, t + dur);
    env(g, t, peak, dur);
    o.connect(g).connect(c.destination);
    o.start(t); o.stop(t + dur + 0.02);
  }
  function hiss(f0, f1, q, dur, peak) {
    const c = audio(); const t = c.currentTime;
    const n = noise(dur + 0.05); const f = c.createBiquadFilter(); const g = c.createGain();
    f.type = 'bandpass'; f.Q.value = q;
    f.frequency.setValueAtTime(f0, t);
    f.frequency.exponentialRampToValueAtTime(f1, t + dur);
    env(g, t, peak, dur);
    n.connect(f).connect(g).connect(c.destination);
    n.start(t); n.stop(t + dur + 0.05);
  }
  const EFFECTS = {
    splash: () => { hiss(1400, 300, 0.8, 0.45, 0.35); hiss(3000, 900, 1.5, 0.25, 0.12); },
    step: () => hiss(500, 180, 1.2, 0.05, 0.12),
    pop: () => tone('sine', 520, 980, 0.09, 0.25),
    whoosh: () => hiss(300, 2200, 0.9, 0.5, 0.18),
    thud: () => tone('sine', 140, 45, 0.25, 0.5),
    bonk: () => { tone('triangle', 900, 180, 0.28, 0.4); tone('sine', 1800, 700, 0.12, 0.15); },
  };
  const sfx = (name) => { if (on) EFFECTS[name]?.(); };

  function set(v, remember = true) {
    on = v;
    if (remember) save(v ? 'on' : 'off');
    if (v) audio(); // voice lines are fetched one by one, the first time each is said
    if (toggle) {
      toggle.textContent = v ? '🔊' : '🔇';
      toggle.setAttribute('aria-label', v ? 'Turn otter sounds off' : 'Turn otter sounds on');
    }
  }
  let toggle = null;
  function showToggle() {
    toggle = document.createElement('button');
    toggle.className = 'otter-mute';
    toggle.addEventListener('click', () => { set(!on); if (on) say('hiii'); });
    document.body.append(toggle);
    set(on, false); // only a visitor's own tap is remembered
  }
  /** A tap on Rio before any choice counts as "yes, let Rio talk" (browsers allow sound after a tap). */
  function wake() { if (read() === null) set(true); }
  function init() {
    const saved = read();
    on = saved === 'on';
    showToggle();
    if (!on) toggle.setAttribute('aria-label', 'Turn on Rio\'s voice and sounds');
  }
  const asked = () => read() !== null;
  return { init, say, sfx, wake, asked };
})();

function img(name, extra = '') {
  return `<img class="otter-img" src="${IMG(name)}" alt="" draggable="false" ${extra}>`;
}

/** A speech bubble inside `host`, placed with `.at(x, y)` (host coordinates). */
function bubble(host) {
  const el = document.createElement('div');
  el.className = 'otter-bubble';
  el.setAttribute('role', 'status');
  host.append(el);
  let timer = 0;
  return {
    el,
    x: 0,
    at(x, y) { this.x = x; el.style.left = `${x}px`; el.style.top = `${y}px`; return this; },
    // Slide the bubble back inside the screen (phones), keeping its tail on the otter.
    fit() {
      el.style.left = `${this.x}px`;
      el.style.setProperty('--tail', '0px');
      const w = el.offsetWidth;
      const left = host.getBoundingClientRect().left + this.x - (el.classList.contains('side') ? 14 : w / 2);
      const room = document.documentElement.clientWidth - 8;
      const shift = left + w > room ? room - (left + w) : left < 8 ? 8 - left : 0;
      el.style.left = `${this.x + shift}px`;
      el.style.setProperty('--tail', `${shift}px`);
    },
    say(text, ms = 2400) {
      clearTimeout(timer);
      el.textContent = text;
      this.fit();
      el.classList.add('show');
      if (ms) timer = setTimeout(() => el.classList.remove('show'), ms);
      return this;
    },
    hide() { clearTimeout(timer); el.classList.remove('show'); },
  };
}

// ── 1. Hero: stands in front of the phone ──────────────────────────────────
// Back turned, watching the tutor. Click: spins round to side-on. Click
// again: turns to face you (side → three-quarter → front) and says hi.
// Left alone, it turns back to the phone the same way.
function standScene({ still = false } = {}) {
  const visual = document.querySelector('.hero-visual');
  const phone = visual?.querySelector('.phone');
  if (!phone) return;

  const otter = document.createElement('div');
  otter.className = 'otter-stand';
  otter.setAttribute('role', 'button');
  otter.setAttribute('tabindex', '0');
  otter.setAttribute('aria-label', 'Say hi to Rio the otter');
  otter.innerHTML = `<div class="anim">${img(still ? 'turn-front' : 'turn-back')}</div>`;
  visual.append(otter);
  const pic = otter.querySelector('.otter-img');

  // Two spots: on the phone's left edge (back turned, watching the tutor) and on its right corner (facing you).
  // It runs between them behind the phone and hops out on the other side.
  // The otter's picture is 200px wide but Rio fills about -80..+65px around its centre;
  // clamp so all of Rio stays on screen on narrow phones.
  const onScreen = (x) => {
    const left = visual.getBoundingClientRect().left;
    const max = document.documentElement.clientWidth - 6 - 65 - left;
    return Math.max(80 - left + 6, Math.min(x, max));
  };
  const spot = {
    left: () => onScreen(phone.offsetLeft + 20),
    right: () => onScreen(phone.offsetLeft + phone.offsetWidth - 20),
  };
  let at = still ? 'right' : 'left';
  let x = 0;
  const setX = (v) => { x = v; otter.style.left = `${v}px`; };
  const place = () => {
    setX(spot[at]());
    otter.style.top = `${phone.offsetTop + phone.offsetHeight + 18 - 200}px`;
  };
  place();
  window.addEventListener('resize', place);
  if (still) {
    otter.classList.add('still');
    otter.removeAttribute('role');
    otter.removeAttribute('tabindex');
    otter.setAttribute('aria-hidden', 'true');
    return;
  }
  // The rest of the turn only loads when someone is about to play with Rio.
  ['pointerenter', 'touchstart', 'focus'].forEach((ev) => otter.addEventListener(ev, () => preload(HERO_FRAMES), { once: true, passive: true }));
  // Until the visitor has chosen, Rio hints that it can talk.
  const talk = bubble(visual);
  if (!sound.asked()) {
    setTimeout(() => {
      if (sound.asked()) return;
      talk.at(x, phone.offsetTop + phone.offsetHeight + 18 - 190).say('Tap me, I can talk! 🔊', 4500);
    }, 2500);
  }

  const play = (cls) => { otter.classList.remove('ot-crouch', 'ot-air', 'ot-land', 'ot-hi'); void otter.offsetWidth; if (cls) otter.classList.add(cls); };
  function tween(ms, fn) {
    return new Promise((done) => {
      const t0 = performance.now();
      const tick = (now) => {
        const t = Math.min(1, (now - t0) / ms);
        fn(t);
        if (t < 1) requestAnimationFrame(tick); else done();
      };
      requestAnimationFrame(tick);
    });
  }

  // Run behind the phone to just past its far edge, then hop out to the spot, landing on `face`.
  async function cross(to, face) {
    const goingRight = to === 'right';
    const out = goingRight ? phone.offsetLeft + phone.offsetWidth + 90 : phone.offsetLeft - 90;
    play('ot-crouch');
    await sleep(120);
    play();
    otter.classList.add('behind');
    delete pic.dataset.talk;
    pic.classList.toggle('left', !goingRight);
    const from = x;
    let k = 0;
    const legs = setInterval(() => {
      pic.src = IMG(`run-${(k % 4) + 1}`);
      if (k % 2 === 0) sound.sfx('step');
      k += 1;
    }, 90);
    await tween(Math.abs(out - from) * 2.2, (t) => setX(from + (out - from) * t));
    clearInterval(legs);
    // Clear of the phone: back in front, and a hop to the spot.
    otter.classList.remove('behind');
    const end = spot[to]();
    pic.classList.toggle('left', end < out); // the leap faces the way it hops
    pic.src = IMG('turn-jump');
    play('ot-air');
    sound.sfx('whoosh');
    await tween(380, (t) => setX(out + (end - out) * t));
    pic.classList.remove('left');
    pic.src = IMG(face);
    play('ot-land');
    sound.sfx('step');
    at = to;
    await sleep(300);
    play();
  }

  // First click: Rio introduces itself. After that, hello in a different language on every click.
  let hellos = ['intro'];
  let last = '';
  const nextHello = () => {
    if (!hellos.length) {
      hellos = Object.keys(HELLO).filter((l) => !NO_HELLO.includes(l)).sort(() => Math.random() - 0.5);
      if (hellos[0] === last) hellos.push(hellos.shift()); // never the same twice in a row
    }
    last = hellos.shift();
    return last;
  };

  let busy = false;
  let idle = 0;
  const waitThenGoBack = () => {
    clearTimeout(idle);
    idle = setTimeout(async () => {
      busy = true;
      await cross('left', 'turn-back');
      busy = false;
    }, 7000);
  };

  otter.addEventListener('keydown', (e) => {
    if (e.key !== 'Enter' && e.key !== ' ') return;
    e.preventDefault();
    otter.click();
  });
  otter.addEventListener('click', async () => {
    sound.wake();
    talk.hide();
    if (busy) return;
    busy = true;
    if (at === 'left') await cross('right', 'turn-front');
    play('ot-hi');
    const hello = nextHello();
    busy = false;
    waitThenGoBack();
    await speak(pic, HERO_TALK, hello === 'intro' ? 'intro' : `hello-${hello}`);
    waitThenGoBack(); // count the 7 s from when Rio stops talking
  });
}

// ── 3. More screens: hide-and-seek (desktop fan only) ──────────────────────
function fanScene() {
  if (!window.matchMedia('(min-width: 961px)').matches) return;
  const island = document.querySelector('[data-island="fan"]');
  if (!island) return;
  whenNear(island, () => { preload(FAN_FRAMES); waitForCards(island); });
}

function waitForCards(island) {
  const found = () => island.querySelector('.bounce-cards');
  if (found()) return startGame(found());
  const mo = new MutationObserver(() => {
    if (!found()) return;
    mo.disconnect();
    startGame(found());
  });
  mo.observe(island, { childList: true, subtree: true });
}

function startGame(root) {
  const cards = [...root.querySelectorAll('.bounce-cards__card')];
  if (cards.length < 2) return;
  const LAST = cards.length - 1;
  const H = 150; // otter height on the fan

  // The otter: actor (position) > spin (rotation) > body (flip) > frame + red glow + stars.
  const actor = document.createElement('div');
  actor.className = 'ot-actor gone';
  actor.innerHTML = `<div class="ot-spin"><div class="ot-body">${img('face-happy')}<div class="ot-glow"></div>
    <div class="ot-stars"><span>⭐</span><span>✨</span><span>⭐</span></div></div></div>`;
  const spin = actor.querySelector('.ot-spin');
  const body = actor.querySelector('.ot-body');
  const frame = actor.querySelector('.ot-body .otter-img');
  const glow = actor.querySelector('.ot-glow');
  const stars = actor.querySelector('.ot-stars');

  const peeker = document.createElement('div');
  peeker.className = 'ot-peeker';
  peeker.innerHTML = img('peek');

  const ladder = document.createElement('div');
  ladder.className = 'ot-ladder';
  ladder.innerHTML = img('ladder');

  root.append(peeker, actor, ladder);
  const talk = bubble(root);

  // ── geometry (root coordinates) ──
  const ground = () => root.offsetHeight - 6;
  const cornerX = () => {
    const leftRoom = root.getBoundingClientRect().left - document.documentElement.getBoundingClientRect().left;
    return -Math.min(110, Math.max(0, leftRoom - 70));
  };
  function card(i) {
    const r = root.getBoundingClientRect();
    const c = cards[i].getBoundingClientRect();
    const m = new DOMMatrixReadOnly(getComputedStyle(cards[i]).transform);
    const angle = Math.atan2(m.b, m.a);
    const half = (cards[i].offsetHeight * Math.hypot(m.a, m.b)) / 2;
    const cx = c.left - r.left + c.width / 2;
    const cy = c.top - r.top + c.height / 2;
    return { cx, cy, topX: cx + Math.sin(angle) * half, topY: cy - Math.cos(angle) * half, angle: (angle * 180) / Math.PI };
  }

  // ── the actor ──
  const pos = { x: 0, y: 0 };
  let frameTimer = 0;
  const render = () => { actor.style.transform = `translate(${pos.x}px, ${pos.y}px) translate(-50%, -100%)`; };
  const setFrame = (name) => {
    delete frame.dataset.talk; // stops any lip sync
    frame.src = IMG(name);
    glow.style.setProperty('--frame', `url(${IMG(name)})`);
  };
  // Running and limping frames tap a footstep on every other frame.
  const cycle = (names, ms) => {
    clearInterval(frameTimer);
    let k = 0;
    setFrame(names[0]);
    const steps = /^(run|limp)/.test(names[0]);
    if (names.length > 1) {
      frameTimer = setInterval(() => {
        k += 1;
        setFrame(names[k % names.length]);
        if (steps && k % 2 === 0) sound.sfx('step');
      }, ms);
    }
  };
  const face = (dir) => body.classList.toggle('flip', dir < 0);
  const say = (text, ms) => talk.at(pos.x, pos.y - H - 8).say(text, ms);

  /** Move along the ground at `speed` px/s; `onStep(x)` runs every frame. */
  function walkTo(x, speed, onStep) {
    return new Promise((resolve) => {
      const from = pos.x;
      const dur = (Math.abs(x - from) / speed) * 1000;
      const t0 = performance.now();
      const step = (now) => {
        const t = Math.min(1, (now - t0) / Math.max(dur, 1));
        pos.x = from + (x - from) * t;
        render();
        onStep?.(pos.x);
        if (t < 1) requestAnimationFrame(step);
        else resolve();
      };
      requestAnimationFrame(step);
    });
  }

  /** Generic tween: `fn(t)` gets 0..1 over `ms`. */
  function tween(ms, fn, ease = (t) => t) {
    return new Promise((resolve) => {
      const t0 = performance.now();
      const step = (now) => {
        const t = Math.min(1, (now - t0) / ms);
        fn(ease(t));
        if (t < 1) requestAnimationFrame(step);
        else resolve();
      };
      requestAnimationFrame(step);
    });
  }

  // Cards pop as if hovered: send the fan the same pointer events a mouse would.
  const hoverAt = (x) => {
    const r = root.getBoundingClientRect();
    root.dispatchEvent(new PointerEvent('pointermove', { clientX: r.left + x, clientY: r.top + root.offsetHeight / 2, pointerType: 'mouse' }));
  };
  const unhover = () => root.dispatchEvent(new PointerEvent('pointerleave', { pointerType: 'mouse' }));

  // ── peeking over a card's top edge ──
  let follow = 0;
  const stick = (i) => {
    const c = card(i);
    peeker.style.transform = `translate(${c.topX}px, ${c.topY}px) rotate(${c.angle}deg) translate(-50%, -100%)`;
    return c;
  };
  function peekAt(i, ms = 1300) {
    const c = stick(i);
    peeker.classList.add('out');
    cancelAnimationFrame(follow);
    // Follow the card until it has fully ducked away (visibility flips after the transition).
    const loop = () => {
      stick(i);
      if (getComputedStyle(peeker).visibility === 'visible') follow = requestAnimationFrame(loop);
    };
    follow = requestAnimationFrame(loop);
    clearTimeout(peekAt.timer);
    peekAt.timer = setTimeout(() => peeker.classList.remove('out'), ms);
    return c;
  }

  // ── game state ──
  let state = 'corner'; // corner | busy | hiding
  let hiding = LAST;
  let firstHide = true;
  let peekLoop = 0;
  let idleTimer = 0;

  function toCorner() {
    state = 'corner';
    pos.x = cornerX();
    pos.y = ground();
    actor.classList.remove('behind', 'gone');
    face(1);
    cycle(['face-happy'], 0);
    render();
    clearTimeout(idleTimer);
    idleTimer = setTimeout(() => {
      if (state !== 'corner') return;
      setFrame('face-sleepy');
      say('zZz…', 0);
    }, 9000);
  }

  const stopPeek = () => { clearInterval(peekLoop); clearTimeout(peekAt.timer); peeker.classList.remove('out'); };

  async function runToLast() {
    state = 'busy';
    stopPeek();
    clearTimeout(idleTimer);
    talk.hide();
    face(1);
    cycle(['run-1', 'run-2', 'run-3', 'run-4'], 95);
    const c = card(LAST);
    await walkTo(c.cx, 430, hoverAt);
    unhover();
    // Slip behind the last card and climb up out of sight.
    actor.classList.add('behind');
    cycle(['climb'], 0);
    await tween(700, (t) => { pos.y = ground() - t * 140; render(); });
    actor.classList.add('gone');
    pos.y = ground();
    hiding = LAST;
    firstHide = true;
    state = 'hiding';
    await sleep(900);
    if (state === 'hiding') peekAt(hiding, 1400);
    startPeekLoop();
  }

  function startPeekLoop() {
    clearInterval(peekLoop);
    peekLoop = setInterval(() => { if (state === 'hiding' && firstHide) peekAt(hiding, 1200); }, 4200);
  }

  async function relocate() {
    state = 'busy';
    stopPeek();
    const c = card(hiding);
    talk.at(c.topX, c.topY - 10).say('Oops! 🙈', 1100);
    sound.say('oops');
    await sleep(600);
    const choices = cards.map((_, i) => i).filter((i) => i !== hiding && i !== LAST);
    const next = pick(choices);
    // Scurry behind the cards: only the feet show under their bottom edges.
    const from = card(hiding);
    const to = card(next);
    pos.x = from.cx;
    pos.y = ground();
    actor.classList.add('behind');
    actor.classList.remove('gone');
    face(to.cx < from.cx ? -1 : 1);
    cycle(['run-1', 'run-2', 'run-3', 'run-4'], 85);
    await walkTo(to.cx, 520);
    cycle(['run-1'], 0); // stop the legs (and their footsteps) once hidden
    actor.classList.add('gone');
    hiding = next;
    firstHide = false;
    state = 'hiding';
  }

  // Wrong card: a teasing voice over the card you picked; it doesn't show itself.
  function tease(i) {
    const c = card(i);
    const k = Math.floor(Math.random() * TEASES.length);
    talk.at(c.topX, c.topY - 10).say(TEASES[k], 1600);
    sound.say(`tease-${k}`);
  }

  async function fall() {
    state = 'busy';
    stopPeek();
    const c = card(hiding);
    // Pops up over the card's edge, screaming…
    actor.classList.remove('behind', 'gone');
    face(1);
    cycle(['scream'], 0);
    pos.x = c.topX;
    pos.y = c.topY + 70;
    render();
    say('AAAAH!! 😱', 1300);
    sound.say('scream');
    await tween(220, (t) => { pos.y = c.topY + 70 - t * 30; render(); });
    // …and falls backwards to the ground, legs kicking (two flailing frames).
    cycle(['fall-1', 'fall-2'], 110);
    sound.sfx('whoosh');
    const top = pos.y;
    await tween(680, (t) => {
      pos.y = top + (ground() - top) * t;
      spin.style.transform = `rotate(${Math.sin(t * Math.PI * 3) * 8}deg)`;
      render();
    }, (t) => t * t);
    spin.style.transform = '';
    cycle(['fall-2'], 0);
    sound.sfx('thud');
    body.classList.add('shake');
    // The ladder topples after it, onto its head.
    ladder.style.visibility = 'visible';
    const lx = pos.x + 34;
    const headY = ground() - H + 30;
    await tween(560, (t) => {
      const y = c.topY + 40 + (headY - (c.topY + 40)) * t;
      ladder.style.transform = `translate(${lx}px, ${y}px) translate(-50%, -100%) rotate(${8 + t * 64}deg)`;
    }, (t) => t * t);
    cycle(['dazed'], 0);
    say('BONK! 💥', 1200);
    sound.sfx('bonk');
    setTimeout(() => sound.say('bonk'), 250);
    stars.classList.add('on');
    body.classList.remove('shake');
    await tween(240, (t) => {
      ladder.style.transform = `translate(${lx + t * 40}px, ${headY + t * 30}px) translate(-50%, -100%) rotate(${72 - t * 10}deg)`;
    });
    await sleep(900);
    // The ladder slides off; red bottom; limps home rubbing it.
    await tween(400, (t) => { ladder.style.opacity = String(1 - t); });
    ladder.style.visibility = 'hidden';
    ladder.style.opacity = '';
    stars.classList.remove('on');
    face(-1);
    cycle(['limp-1', 'limp-2'], 300);
    glow.classList.add('on');
    sound.say('ouch');
    await walkTo(cornerX(), 150, (x) => { pos.y = ground() + Math.abs(Math.sin(x / 18)) * -5; render(); });
    glow.classList.remove('on');
    toCorner();
    say('Again? Click me! 🙂', 2600);
    speak(frame, FACE_TALK, 'again');
  }

  // ── clicks ──
  root.addEventListener('click', (e) => {
    sound.wake();
    const target = e.target instanceof Element ? e.target : null;
    if (!target) return;
    if (state === 'corner' && actor.contains(target)) { runToLast(); return; }
    if (state !== 'hiding') return;
    const el = target.closest('.bounce-cards__card');
    const i = peeker.contains(target) ? hiding : cards.indexOf(el);
    if (i < 0) return;
    if (i !== hiding) tease(i);
    else if (firstHide) relocate();
    else fall();
  });
  actor.addEventListener('pointerenter', () => {
    if (state !== 'corner') return;
    clearTimeout(idleTimer);
    setFrame('face-excited');
    say('Play hide-and-seek? Click me!', 1800);
    speak(frame, FACE_TALK, 'play', 'face-excited');
  });
  actor.addEventListener('pointerleave', () => { if (state === 'corner') setFrame('face-happy'); });

  // First time the fan is on screen: run to the last card.
  toCorner();
  let started = false;
  new IntersectionObserver(([e]) => {
    if (!e.isIntersecting || started) return;
    started = true;
    setTimeout(runToLast, 1400);
  }, { threshold: 0.55 }).observe(root);
}

// ── 4. Final section: confident ────────────────────────────────────────────
function finalScene() {
  const section = document.querySelector('.final-cta');
  if (!section) return;

  const stage = document.createElement('div');
  stage.className = 'otter-stage';
  stage.innerHTML = `<div class="otter-pop">${img('face-happy', 'loading="lazy" aria-label="Rio the otter"')}</div>${sea('otter-end', 300, 70)}`;
  section.classList.add('otter-host');
  section.append(stage);
  const pop = stage.querySelector('.otter-pop');
  const otter = pop.querySelector('img');
  const talk = bubble(stage);
  talk.el.classList.add('side');
  talk.at(236, 58); // right next to the otter's head, clear of the button above
  const timers = [];
  const later = (ms, fn) => timers.push(setTimeout(fn, ms));
  const set = (cls, on) => stage.classList.toggle(cls, on);
  const flash = (cls, ms) => { set(cls, false); void stage.offsetWidth; set(cls, true); later(ms, () => set(cls, false)); };
  const look = (name) => { delete otter.dataset.talk; otter.src = IMG(name); };
  const speakLine = (key, rest) => speak(otter, FACE_TALK, key, rest);
  // Ducks under the water and pops back up.
  const dive = () => {
    set('otter-up', false);
    flash('splash', 700);
    sound.sfx('splash');
    later(650, () => { set('otter-up', true); flash('splash', 700); sound.sfx('splash'); });
  };

  let here = false;
  let clicks = 0;

  function arrive() {
    if (here) return;
    here = true;
    timers.splice(0).forEach(clearTimeout);
    look('face-happy');
    set('water-up', true); // first the water rises…
    sound.sfx('whoosh');
    later(850, () => { set('otter-up', true); flash('splash', 700); sound.sfx('splash'); }); // …then the otter pops up through it
    later(1900, dive);
    later(3000, () => {
      set('wiggle', true);
      talk.say('You made it! Your turn to talk 👋', 3200);
      speakLine('made-it').then(() => set('wiggle', false));
    });
  }

  function leave() {
    if (!here) return;
    here = false;
    timers.splice(0).forEach(clearTimeout);
    set('excited', false);
    talk.say('Bye! See you soon 👋', 1000);
    speakLine('bye');
    later(900, () => { set('otter-up', false); flash('splash', 700); }); // dives
    later(1500, () => set('water-up', false)); // then the water goes down
  }

  whenNear(section, () => preload(END_FRAMES));
  new IntersectionObserver(([e]) => (e.isIntersecting ? arrive() : leave()), { threshold: 0.3 }).observe(section);

  pop.addEventListener('mouseenter', () => { if (here) { look('face-excited'); set('wiggle', true); } });
  pop.addEventListener('mouseleave', () => { set('wiggle', false); look('face-happy'); });
  pop.addEventListener('click', () => {
    sound.wake();
    if (!here) return;
    clicks += 1;
    flash('splash', 700);
    if (clicks % 5 === 0) {
      dive();
      talk.say('🐚 *crack!* You found my snack!');
      speakLine('snack');
      return;
    }
    const lang = pick(Object.keys(HELLO).filter((l) => !NO_HELLO.includes(l)));
    talk.say(HELLO[lang], 1800);
    sound.sfx('splash');
    speakLine(`hello-${lang}`);
  });

  // The final button: the otter cheers. Delegated: the button re-renders when its island mounts.
  const ctaOf = (node) => (node instanceof Element ? node.closest('.final-cta a.btn') : null);
  section.addEventListener('mouseover', (e) => {
    if (!here || !ctaOf(e.target) || ctaOf(e.relatedTarget)) return;
    look('face-excited');
    set('excited', true);
    talk.say('That one! Go on 🎉', 0);
    speakLine('cheer', 'face-excited');
  });
  section.addEventListener('mouseout', (e) => {
    if (!ctaOf(e.target) || ctaOf(e.relatedTarget)) return;
    set('excited', false);
    look('face-happy');
    talk.hide();
  });
}

export default function mountOtter() {
  const style = document.createElement('style');
  style.textContent = CSS;
  document.head.append(style);
  const net = navigator.connection;
  const calm = window.matchMedia('(prefers-reduced-motion: reduce)').matches
    || net?.saveData || /(^|-)2g$/.test(net?.effectiveType || '');
  if (calm) return standScene({ still: true });
  sound.init();
  standScene();
  fanScene();
  finalScene();
}
