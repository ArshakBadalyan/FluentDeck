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
