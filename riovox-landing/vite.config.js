import fs from 'node:fs';
import path from 'node:path';
import react from '@vitejs/plugin-react';
import { defineConfig, loadEnv } from 'vite';

/** The Flutter web build, served at /app/ (see README "One domain"). */
const APP_BUILD = path.resolve(__dirname, '../riovox-app/build/web');

/**
 * Site settings come from .env (see .env.example). They are written into
 * index.html at `__NAME__` tokens, and robots.txt / sitemap.xml are generated
 * at build time from SITE_URL, so the same code deploys to any domain.
 */
const DEFAULTS = {
  SITE_URL: 'https://riovox.app',
  // Where the Flutter web app lives. Same domain by default.
  WEB_APP_URL: '/app/',
  APP_STORE_URL: '',
  PLAY_STORE_URL: '',
  PRIVACY_URL: '',
  TERMS_URL: '',
  CONTACT_EMAIL: 'hello@riovox.app',
};

export default defineConfig(({ mode }) => {
  const env = { ...DEFAULTS, ...pick(loadEnv(mode, process.cwd(), ''), Object.keys(DEFAULTS)) };
  const site = env.SITE_URL.replace(/\/+$/, '');
  const appUrl = (auth) => `${env.WEB_APP_URL}${env.WEB_APP_URL.includes('?') ? '&' : '?'}auth=${auth}`;

  return {
    define: {
      __SITE__: JSON.stringify({
        webAppUrl: env.WEB_APP_URL,
        appStoreUrl: env.APP_STORE_URL,
        playStoreUrl: env.PLAY_STORE_URL,
      }),
    },
    plugins: [
      react(),
      {
        name: 'riovox-site-settings',
        transformIndexHtml(html) {
          return html
            .replaceAll('__SITE_URL__', site)
            .replaceAll('__SIGNUP_URL__', appUrl('signup'))
            .replaceAll('__SIGNIN_URL__', appUrl('signin'))
            .replaceAll('__PRIVACY_URL__', env.PRIVACY_URL || '#')
            .replaceAll('__TERMS_URL__', env.TERMS_URL || '#')
            .replaceAll('__CONTACT_EMAIL__', env.CONTACT_EMAIL)
            .replaceAll('__YEAR__', String(new Date().getFullYear()));
        },
        // `npm run dev`: serve the Flutter web build at /app/ too (build it
        // once with `npm run build:app`), so the buttons work locally.
        configureServer(server) {
          server.middlewares.use('/app', (req, res, next) => {
            if (!fs.existsSync(APP_BUILD)) {
              res.statusCode = 404;
              res.setHeader('content-type', 'text/plain; charset=utf-8');
              res.end('The web app is not built yet. Run: npm run build:app');
              return;
            }
            const urlPath = decodeURIComponent((req.url || '/').split('?')[0]);
            let file = path.join(APP_BUILD, urlPath);
            if (!file.startsWith(APP_BUILD) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) {
              file = path.join(APP_BUILD, 'index.html'); // app routes → the app
            }
            res.setHeader('content-type', contentType(file));
            fs.createReadStream(file).pipe(res);
          });
        },
        generateBundle() {
          const today = new Date().toISOString().slice(0, 10);
          this.emitFile({
            type: 'asset',
            fileName: 'robots.txt',
            // The app (/app/) is behind sign-in: nothing there for search engines.
            source: `User-agent: *\nAllow: /\nDisallow: /app/\n\nSitemap: ${site}/sitemap.xml\n`,
          });
          this.emitFile({
            type: 'asset',
            fileName: 'sitemap.xml',
            source:
              '<?xml version="1.0" encoding="UTF-8"?>\n' +
              '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n' +
              `  <url><loc>${site}/</loc><lastmod>${today}</lastmod><changefreq>weekly</changefreq><priority>1.0</priority></url>\n` +
              '</urlset>\n',
          });
        },
      },
    ],
  };
});

function contentType(file) {
  const types = {
    '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.mjs': 'text/javascript',
    '.json': 'application/json', '.css': 'text/css', '.wasm': 'application/wasm',
    '.png': 'image/png', '.svg': 'image/svg+xml', '.ico': 'image/x-icon', '.otf': 'font/otf',
    '.ttf': 'font/ttf', '.woff2': 'font/woff2', '.mp3': 'audio/mpeg', '.wav': 'audio/wav',
  };
  return types[path.extname(file).toLowerCase()] || 'application/octet-stream';
}

function pick(obj, keys) {
  return Object.fromEntries(keys.filter((k) => obj[k] !== undefined && obj[k] !== '').map((k) => [k, obj[k]]));
}
