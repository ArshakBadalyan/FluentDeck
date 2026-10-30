// One server for the whole site: the landing page at / and the Flutter web
// app at /app/ (built with `npm run build:all`). No dependencies.
//   PORT=8080 node server.mjs
import fs from 'node:fs';
import http from 'node:http';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const DIST = path.join(path.dirname(fileURLToPath(import.meta.url)), 'dist');
const PORT = Number(process.env.PORT) || 8080;

const TYPES = {
  '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.mjs': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8', '.json': 'application/json; charset=utf-8', '.wasm': 'application/wasm',
  '.png': 'image/png', '.webp': 'image/webp', '.gif': 'image/gif', '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon', '.txt': 'text/plain; charset=utf-8', '.xml': 'application/xml',
  '.otf': 'font/otf', '.ttf': 'font/ttf', '.woff2': 'font/woff2', '.mp3': 'audio/mpeg', '.wav': 'audio/wav',
};

function resolve(urlPath) {
  const clean = path.normalize(decodeURIComponent(urlPath)).replace(/^(\.\.[/\\])+/, '');
  let file = path.join(DIST, clean);
  if (!file.startsWith(DIST)) return null; // no escaping dist/
  if (fs.existsSync(file) && fs.statSync(file).isDirectory()) file = path.join(file, 'index.html');
  if (fs.existsSync(file)) return file;
  // Any /app/... route the app handles itself → the app's index.html.
  if (clean.startsWith('/app')) return path.join(DIST, 'app', 'index.html');
  return null;
}

http
  .createServer((req, res) => {
    const urlPath = (req.url || '/').split('?')[0];
    if (urlPath === '/app') {
      res.writeHead(301, { Location: '/app/' + (req.url.includes('?') ? req.url.slice(req.url.indexOf('?')) : '') });
      res.end();
      return;
    }
    const file = resolve(urlPath);
    if (!file || !fs.existsSync(file)) {
      res.writeHead(404, { 'content-type': 'text/plain; charset=utf-8' });
      res.end('Not found');
      return;
    }
    const ext = path.extname(file).toLowerCase();
    // Hashed landing assets never change; HTML and the app shell always revalidate.
    const cache = urlPath.startsWith('/assets/') ? 'public, max-age=31536000, immutable'
      : ext === '.html' ? 'no-cache' : 'public, max-age=3600';
    res.writeHead(200, { 'content-type': TYPES[ext] || 'application/octet-stream', 'cache-control': cache });
    fs.createReadStream(file).pipe(res);
  })
  .listen(PORT, () => {
    console.log(`Riovox site on http://localhost:${PORT}  (app at /app/)`);
  });
