// `npm run dev`: brings the local D1 database up to date, then serves the API on
// http://localhost:8787 (Ctrl+C to stop). Emails go to the dev outbox (.dev.vars).
import { spawn, spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');
const wrangler = path.join(root, 'node_modules', 'wrangler', 'bin', 'wrangler.js');
const env = { ...process.env, CI: '1', WRANGLER_SEND_METRICS: 'false' };
const port = process.env.PORT || '8787';

const migrate = spawnSync(process.execPath, [wrangler, 'd1', 'migrations', 'apply', 'deck-of-fools', '--local'], { cwd: root, env, stdio: 'inherit' });
if (migrate.status !== 0) process.exit(migrate.status ?? 1);
const dev = spawn(process.execPath, [wrangler, 'dev', '--port', port, '--ip', '127.0.0.1', '--show-interactive-dev-session=false'], { cwd: root, env, stdio: 'inherit' });
dev.on('exit', (code) => process.exit(code ?? 0));
for (const signal of ['SIGINT', 'SIGTERM']) process.on(signal, () => dev.kill(signal));
