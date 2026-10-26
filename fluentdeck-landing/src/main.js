/* global __SITE__ */
// Site settings injected at build time from .env (vite.config.js).
const site = typeof __SITE__ === 'object' ? __SITE__ : {};
const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

document.documentElement.classList.add('js');

// Store badges: real links when configured, otherwise "Coming soon".
for (const badge of document.querySelectorAll('[data-store]')) {
  const url = badge.dataset.store === 'ios' ? site.appStoreUrl : site.playStoreUrl;
  const label = badge.querySelector('[data-store-label]');
  if (url) {
    badge.href = url;
    badge.rel = 'noopener';
    if (label) label.textContent = badge.dataset.store === 'ios' ? 'Download on the' : 'Get it on';
  } else {
    badge.removeAttribute('href');
    badge.setAttribute('aria-disabled', 'true');
    badge.setAttribute('role', 'link');
  }
}

// Mobile menu.
const toggle = document.querySelector('.nav-toggle');
const nav = document.getElementById('main-nav');
toggle?.addEventListener('click', () => {
  const open = nav.classList.toggle('open');
  toggle.setAttribute('aria-expanded', String(open));
  toggle.setAttribute('aria-label', open ? 'Close menu' : 'Open menu');
});
nav?.addEventListener('click', (e) => {
  if (e.target instanceof HTMLAnchorElement) {
    nav.classList.remove('open');
    toggle?.setAttribute('aria-expanded', 'false');
  }
});

// Menu links and the logo glide to their section (or the top), stopping
// below the sticky header. Same easing in every browser.
const header = document.querySelector('.site-header');
let glide = 0;
const stopGlide = () => cancelAnimationFrame(glide);
['wheel', 'touchstart', 'keydown'].forEach((type) => window.addEventListener(type, stopGlide, { passive: true }));

// `targetY` is re-read every frame: content above can still change height
// (lazy islands, images) while the page is gliding.
function glideTo(targetY) {
  stopGlide();
  const start = window.scrollY;
  const distance = targetY() - start;
  if (reduceMotion || Math.abs(distance) < 2) return window.scrollTo({ top: targetY(), behavior: 'instant' });
  const duration = Math.min(1600, 600 + Math.abs(distance) * 0.12);
  // Sine in-out: gentle start and end, and a lower top speed than cubic.
  const ease = (t) => -(Math.cos(Math.PI * t) - 1) / 2;
  // The clock advances at most ~2 frames per frame, so a slow frame (a
  // section mounting mid-glide) pauses the glide instead of jumping ahead.
  let elapsed = 0;
  let last = performance.now();
  const step = (now) => {
    elapsed += Math.min(now - last, 34);
    last = now;
    const t = Math.min(1, elapsed / duration);
    window.scrollTo({ top: start + (targetY() - start) * ease(t), behavior: 'instant' });
    if (t < 1) glide = requestAnimationFrame(step);
  };
  glide = requestAnimationFrame(step);
}

document.addEventListener('click', (e) => {
  const link = e.target instanceof Element ? e.target.closest('a[href^="#"]') : null;
  if (!link || link.classList.contains('skip-link') || e.metaKey || e.ctrlKey || e.shiftKey) return;
  const id = link.getAttribute('href').slice(1);
  if (!id) return;
  const target = id === 'top' ? null : document.getElementById(id);
  if (id !== 'top' && !target) return;
  e.preventDefault();
  const offset = (header?.offsetHeight ?? 0) + 12;
  glideTo(() => (target ? Math.max(0, target.getBoundingClientRect().top + window.scrollY - offset) : 0));
  history.pushState(null, '', id === 'top' ? location.pathname + location.search : `#${id}`);
});

// Reveal sections as they scroll into view.
const revealables = document.querySelectorAll('.reveal');
if (reduceMotion || !('IntersectionObserver' in window)) {
  revealables.forEach((el) => el.classList.add('visible'));
} else {
  const io = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (entry.isIntersecting) {
          entry.target.classList.add('visible');
          io.unobserve(entry.target);
        }
      }
    },
    { rootMargin: '0px 0px -10% 0px', threshold: 0.12 },
  );
  revealables.forEach((el) => io.observe(el));
}

// Hero demo: play the conversation step by step, then loop.
const demo = document.querySelector('[data-demo]');
if (demo) {
  const steps = [...demo.querySelectorAll('[data-step]')];
  const typing = demo.querySelector('.typing');
  const timings = [600, 1700, 1500, 1100, 900, 1400]; // ms before each step
  if (reduceMotion) {
    steps.forEach((el) => { if (el !== typing) el.classList.add('show'); });
    typing?.remove();
  } else {
    let timers = [];
    const play = () => {
      steps.forEach((el) => el.classList.remove('show'));
      let t = 0;
      steps.forEach((el, i) => {
        t += timings[i];
        timers.push(setTimeout(() => {
          el.classList.add('show');
          // The typing dots give way to the tutor's answer.
          if (el !== typing && typing && i === steps.length - 1) typing.classList.remove('show');
        }, t));
      });
      timers.push(setTimeout(play, t + 5000));
    };
    // Only animate while the hero is on screen.
    const visible = new IntersectionObserver(([entry]) => {
      timers.forEach(clearTimeout);
      timers = [];
      if (entry.isIntersecting) play();
    });
    visible.observe(demo);
  }
}

// Hero scene drifts slower than the page; the languages line inks itself and
// counts the language pairs as its section scrolls by.
const parallax = document.querySelector('[data-parallax]');

// Hero video: only on wide screens with motion allowed and no Save-Data; the
// still image stays underneath until the first frame plays.
const heroVideo = document.querySelector('[data-hero-video]');
if (heroVideo && !reduceMotion && !navigator.connection?.saveData && window.matchMedia('(min-width: 961px)').matches) {
  heroVideo.querySelectorAll('source[data-src]').forEach((s) => { s.src = s.dataset.src; });
  heroVideo.addEventListener('playing', () => heroVideo.classList.add('playing'), { once: true });
  heroVideo.load();
  heroVideo.play().catch(() => {});
}
const journey = document.querySelector('[data-journey]');
const journeyCount = journey?.querySelector('[data-journey-count]');
const pairs = Number(journeyCount?.dataset.to ?? 0);
if (!reduceMotion && (parallax || journey)) {
  let queued = false;
  const update = () => {
    queued = false;
    const vh = window.innerHeight;
    if (parallax && window.scrollY < vh * 1.5) parallax.style.setProperty('--parallax', `${window.scrollY * 0.28}px`);
    if (journey) {
      const box = journey.getBoundingClientRect();
      // 0 when the line enters at the bottom of the screen, 1 by the middle.
      const t = Math.min(1, Math.max(0, (vh - box.top) / (vh * 0.55)));
      journey.style.setProperty('--journey-off', String(1 - t));
      if (journeyCount) journeyCount.textContent = String(Math.round(pairs * t));
    }
  };
  window.addEventListener('scroll', () => {
    if (!queued) { queued = true; requestAnimationFrame(update); }
  }, { passive: true });
  update();
}
