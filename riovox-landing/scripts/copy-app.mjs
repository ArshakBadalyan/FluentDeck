// Copies the Flutter web build into dist/app/, so dist/ holds the whole site:
// the landing page at / and the app at /app/.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const from = path.resolve(root, '../riovox-app/build/web');
const to = path.join(root, 'dist', 'app');

if (!fs.existsSync(path.join(from, 'index.html'))) {
  console.error('No Flutter web build found. Run: npm run build:app');
  process.exit(1);
}
fs.rmSync(to, { recursive: true, force: true });
fs.cpSync(from, to, { recursive: true });
console.log(`Web app copied to ${path.relative(root, to)}/`);
