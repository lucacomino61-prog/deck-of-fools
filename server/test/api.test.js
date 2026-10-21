// The API end to end: a real `wrangler dev` on a spare port with a throwaway local D1
// database, talked to over HTTP like the game does. Apple and Google tokens are signed here
// with a test key the Worker is told to trust.
//   npm test
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawn, spawnSync } from 'node:child_process';
import { dailySetup, today } from '../src/daily.js';

const PORT = 8799;
const WRANGLER = path.join('node_modules', 'wrangler', 'bin', 'wrangler.js');
let server;
let state;
let signer;
const KID = 'test-key';

const b64url = (bytes) => Buffer.from(bytes).toString('base64url');

async function idToken(claims, { key = signer, kid = KID } = {}) {
  const header = b64url(JSON.stringify({ alg: 'RS256', kid, typ: 'JWT' }));
  const payload = b64url(JSON.stringify(claims));
  const signature = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key.privateKey, new TextEncoder().encode(`${header}.${payload}`));
  return `${header}.${payload}.${b64url(new Uint8Array(signature))}`;
}

const rsa = () => crypto.subtle.generateKey({ name: 'RSASSA-PKCS1-v1_5', modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: 'SHA-256' }, true, ['sign', 'verify']);

before(async () => {
  signer = await rsa();
  const jwk = { ...(await crypto.subtle.exportKey('jwk', signer.publicKey)), kid: KID, alg: 'RS256', use: 'sig' };
  const jwks = JSON.stringify({ keys: [jwk] });
  state = fs.mkdtempSync(path.join(os.tmpdir(), 'fools-api-'));
  const env = { ...process.env, CI: '1', WRANGLER_SEND_METRICS: 'false' };
  const migrate = spawnSync(process.execPath, [WRANGLER, 'd1', 'migrations', 'apply', 'deck-of-fools', '--local', '--persist-to', state], { env, encoding: 'utf8' });
  assert.equal(migrate.status, 0, migrate.stderr || migrate.stdout);
  const vars = {
    PUBLIC_URL: 'http://test', DEV_MAIL: '1', APPLE_CLIENT_IDS: 'com.example.fools',
    GOOGLE_CLIENT_IDS: 'google-client-id', JWKS_APPLE: jwks, JWKS_GOOGLE: jwks,
  };
  const args = [WRANGLER, 'dev', '--port', String(PORT), '--ip', '127.0.0.1', '--persist-to', state, '--show-interactive-dev-session=false'];
  for (const [name, value] of Object.entries(vars)) args.push('--var', `${name}:${value}`);
  server = spawn(process.execPath, args, { env, stdio: 'pipe' });
  let log = '';
  server.stdout.on('data', (d) => { log += d; });
  server.stderr.on('data', (d) => { log += d; });
  for (let i = 0; i < 120; i++) {
    try {
      if ((await fetch(`http://127.0.0.1:${PORT}/v1/health`)).ok) return;
    } catch {}
    await new Promise((r) => setTimeout(r, 250));
  }
  throw new Error(`wrangler dev didn't start:\n${log}`);
});

after(async () => {
  // wrangler starts workerd under it: end the whole tree, or it keeps the port and files.
  if (process.platform === 'win32') spawnSync('taskkill', ['/pid', String(server.pid), '/T', '/F']);
  else server.kill();
  // Windows lets go of the database files a moment later; a leftover temp folder is harmless.
  for (let i = 0; i < 10; i++) {
    try {
      fs.rmSync(state, { recursive: true, force: true });
      return;
    } catch {
      await new Promise((r) => setTimeout(r, 300));
    }
  }
});

async function call(method, path, { token, body, headers: extra = {} } = {}) {
  const headers = { 'Content-Type': 'application/json', ...extra };
  if (token) headers.Authorization = `Bearer ${token}`;
  const res = await fetch(`http://127.0.0.1:${PORT}${path}`, { method, headers, body: body === undefined ? undefined : JSON.stringify(body) });
  const type = res.headers.get('content-type') || '';
  return { status: res.status, data: type.includes('json') ? await res.json() : await res.text(), headers: res.headers };
}

const guest = async () => (await call('POST', '/v1/auth/guest')).data;
let emails = 0;
const freshEmail = () => `player${++emails}@example.com`;

async function lastEmailLink(to, path) {
  const box = (await call('GET', '/v1/dev/outbox')).data.emails;
  const mail = box.find((m) => m.to_addr === to);
  assert.ok(mail, `an email went to ${to}`);
  const link = mail.body.match(new RegExp(`http://test${path}\\?token=([A-Za-z0-9_-]+)`));
  assert.ok(link, 'the email has the link');
  return { url: `${path}?token=${link[1]}`, token: link[1] };
}

function run(overrides = {}) {
  return {
    seed: 'ABCD2345', deck: 'd_bergamo', stake: 1, town: 3, best_hand: 1200, won: false, jesters: ['z_zanni', 'z_arlecchino'],
    actions: [{ a: 'select_show' }, { a: 'play', cards: [1] }, { a: 'play', cards: [2] }, { a: 'play', cards: [3] }],
    ...overrides,
  };
}

test('a guest is created silently and can see itself', async () => {
  const res = await call('POST', '/v1/auth/guest');
  assert.equal(res.status, 201);
  assert.ok(res.data.token.length > 30);
  assert.equal(res.data.user.guest, true);
  assert.match(res.data.user.name, /^Guest \d{4}$/);
  const me = await call('GET', '/v1/me', { token: res.data.token });
  assert.equal(me.data.user.id, res.data.user.id);
  assert.equal((await call('GET', '/v1/me')).status, 401);
});

test('signing up as a guest keeps the same player and their save', async () => {
  const g = await guest();
  await call('PUT', '/v1/save', { token: g.token, body: { base_version: 0, data: { profile: { wins: 2 } } } });
  const email = freshEmail();
  const res = await call('POST', '/v1/auth/signup', { token: g.token, body: { email, password: 'harlequin1', name: 'Luca' } });
  assert.equal(res.status, 201);
  assert.equal(res.data.linked, true);
  assert.equal(res.data.user.id, g.user.id);
  assert.equal(res.data.user.guest, false);
  assert.equal(res.data.user.verified, false);
  const save = await call('GET', '/v1/save', { token: res.data.token });
  assert.deepEqual(save.data.data, { profile: { wins: 2 } });
  const link = await lastEmailLink(email, '/verify');
  assert.equal((await call('GET', link.url)).status, 200);
  assert.equal((await call('GET', '/v1/me', { token: res.data.token })).data.user.verified, true);
  assert.equal((await call('GET', link.url)).status, 400, 'a link works once');
});

test('email sign-up checks its inputs and refuses a taken address', async () => {
  const email = freshEmail();
  assert.equal((await call('POST', '/v1/auth/signup', { body: { email: 'nope', password: 'harlequin1', name: 'Ana' } })).status, 400);
  assert.equal((await call('POST', '/v1/auth/signup', { body: { email, password: 'short', name: 'Ana' } })).status, 400);
  assert.equal((await call('POST', '/v1/auth/signup', { body: { email, password: 'harlequin1', name: 'A' } })).status, 400);
  assert.equal((await call('POST', '/v1/auth/signup', { body: { email, password: 'harlequin1', name: 'Ana' } })).status, 201);
  const again = await call('POST', '/v1/auth/signup', { body: { email: email.toUpperCase(), password: 'harlequin1', name: 'Ana' } });
  assert.equal(again.status, 409);
});

test('logging in and out', async () => {
  const email = freshEmail();
  await call('POST', '/v1/auth/signup', { body: { email, password: 'harlequin1', name: 'Bea' } });
  assert.equal((await call('POST', '/v1/auth/login', { body: { email, password: 'wrong-pass' } })).status, 401);
  const res = await call('POST', '/v1/auth/login', { body: { email: ` ${email.toUpperCase()} `, password: 'harlequin1' } });
  assert.equal(res.status, 200);
  assert.equal(res.data.user.email, email);
  assert.equal((await call('POST', '/v1/auth/logout', { token: res.data.token })).status, 200);
  assert.equal((await call('GET', '/v1/me', { token: res.data.token })).status, 401);
});

test('a forgotten password is reset by email, and old sessions end', async () => {
  const email = freshEmail();
  const first = await call('POST', '/v1/auth/signup', { body: { email, password: 'harlequin1', name: 'Cleo' } });
  assert.deepEqual((await call('POST', '/v1/auth/forgot', { body: { email: 'nobody@example.com' } })).data, { ok: true });
  assert.deepEqual((await call('POST', '/v1/auth/forgot', { body: { email } })).data, { ok: true });
  const link = await lastEmailLink(email, '/reset');
  const page = await call('GET', link.url);
  assert.equal(page.status, 200);
  assert.match(page.data, /Choose a new password/);
  assert.equal((await call('POST', '/v1/auth/reset', { body: { token: link.token, password: 'columbine22' } })).status, 200);
  assert.equal((await call('GET', '/v1/me', { token: first.data.token })).status, 401);
  assert.equal((await call('POST', '/v1/auth/login', { body: { email, password: 'harlequin1' } })).status, 401);
  assert.equal((await call('POST', '/v1/auth/login', { body: { email, password: 'columbine22' } })).status, 200);
  assert.equal((await call('POST', '/v1/auth/reset', { body: { token: link.token, password: 'columbine33' } })).status, 400);
});

test('renaming', async () => {
  const g = await guest();
  assert.equal((await call('PATCH', '/v1/me', { token: g.token, body: { name: 'x' } })).status, 400);
  const res = await call('PATCH', '/v1/me', { token: g.token, body: { name: '  Il  Dottore ' } });
  assert.equal(res.data.user.name, 'Il Dottore');
});

test('cloud saves are versioned; a stale write gets the cloud copy back', async () => {
  const g = await guest();
  assert.deepEqual((await call('GET', '/v1/save', { token: g.token })).data, { version: 0, data: null });
  const first = await call('PUT', '/v1/save', { token: g.token, body: { base_version: 0, data: { n: 1 }, device: 'phone' } });
  assert.deepEqual(first.data, { version: 1 });
  const stale = await call('PUT', '/v1/save', { token: g.token, body: { base_version: 0, data: { n: 2 }, device: 'tablet' } });
  assert.equal(stale.status, 409);
  assert.deepEqual(stale.data.data, { n: 1 });
  assert.equal(stale.data.device, 'phone');
  const forced = await call('PUT', '/v1/save', { token: g.token, body: { base_version: 0, data: { n: 2 }, force: true } });
  assert.deepEqual(forced.data, { version: 2 });
  assert.deepEqual((await call('GET', '/v1/save', { token: g.token })).data.data, { n: 2 });
});

test('the daily setup is the same for everyone and matches the game', () => {
  assert.deepEqual(dailySetup('2026-10-21'), { date: '2026-10-21', seed: 'DAY20261021', deck: 'd_genova', stake: 1 });
  assert.equal(dailySetup('2026-12-31').deck, 'd_mantova');
  assert.equal(dailySetup('2027-01-01').deck, 'd_carnevale');
});

test('one ranked daily attempt each, then its leaderboard', async () => {
  const setup = dailySetup(today());
  const players = [await guest(), await guest(), await guest()];
  const info = await call('GET', '/v1/daily', { token: players[0].token });
  assert.equal(info.data.seed, setup.seed);
  assert.equal(info.data.attempt, null);
  const scores = [[4, 900], [6, 500], [4, 2000]];
  for (let i = 0; i < players.length; i++) {
    assert.equal((await call('POST', '/v1/daily/start', { token: players[i].token })).status, 201);
    const plays = Array.from({ length: scores[i][0] }, (_, k) => ({ a: 'play', cards: [k] }));
    const res = await call('POST', '/v1/runs', { token: players[i].token, body: run({ seed: setup.seed, deck: setup.deck, town: scores[i][0], best_hand: scores[i][1], actions: plays, daily_date: setup.date }) });
    assert.equal(res.status, 201);
    assert.equal(res.data.daily_date, setup.date);
  }
  assert.equal((await call('POST', '/v1/daily/start', { token: players[0].token })).status, 409, 'only one ranked attempt');
  const again = await call('POST', '/v1/runs', { token: players[0].token, body: run({ seed: setup.seed, deck: setup.deck, daily_date: setup.date }) });
  assert.equal(again.status, 409, 'an attempt is handed in once');
  const board = await call('GET', '/v1/leaderboards/daily', { token: players[0].token });
  const mine = board.data.entries.filter((e) => [players[0], players[1], players[2]].some((p) => p.user.name === e.name));
  assert.deepEqual(mine.map((e) => [e.town, e.best_hand]), [[6, 500], [4, 2000], [4, 900]]);
  assert.equal(board.data.me.town, 4);
  assert.equal(board.data.me.best_hand, 900);
  assert.equal((await call('GET', '/v1/daily', { token: players[0].token })).data.attempt.finished, true);
});

test('a ranked daily run must use the day\'s seed and deck', async () => {
  const setup = dailySetup(today());
  const g = await guest();
  const unstarted = await call('POST', '/v1/runs', { token: g.token, body: run({ seed: setup.seed, deck: setup.deck, daily_date: setup.date }) });
  assert.equal(unstarted.status, 409);
  await call('POST', '/v1/daily/start', { token: g.token });
  const wrongSeed = await call('POST', '/v1/runs', { token: g.token, body: run({ seed: 'OTHER123', deck: setup.deck, daily_date: setup.date }) });
  assert.equal(wrongSeed.status, 409);
});

test('runs are checked for plausibility', async () => {
  const g = await guest();
  assert.equal((await call('POST', '/v1/runs', { token: g.token, body: run({ deck: 'd_unknown' }) })).status, 400);
  assert.equal((await call('POST', '/v1/runs', { token: g.token, body: run({ seed: 'bad seed!' }) })).status, 400);
  assert.equal((await call('POST', '/v1/runs', { token: g.token, body: run({ town: 9, actions: [{ a: 'play' }] }) })).status, 422);
  assert.equal((await call('POST', '/v1/runs', { token: g.token, body: run({ best_hand: 1e30 }) })).status, 422);
  assert.equal((await call('POST', '/v1/runs', { token: g.token, body: run() })).status, 201);
  assert.equal((await call('POST', '/v1/runs', { body: run() })).status, 401);
});

test('best-hand and highest-town leaderboards rank players, with the asker\'s own row', async () => {
  const a = await guest();
  const b = await guest();
  await call('POST', '/v1/runs', { token: a.token, body: run({ best_hand: 5_000_000, town: 3, stake: 3 }) });
  await call('POST', '/v1/runs', { token: a.token, body: run({ best_hand: 10, town: 2, stake: 3 }) });
  await call('POST', '/v1/runs', { token: b.token, body: run({ best_hand: 7_000_000, town: 2, stake: 3 }) });
  const hands = await call('GET', '/v1/leaderboards/best_hand', { token: a.token });
  const order = hands.data.entries.map((e) => e.name);
  assert.ok(order.indexOf(b.user.name) < order.indexOf(a.user.name));
  assert.equal(hands.data.me.best_hand, 5_000_000);
  assert.equal(hands.data.me.rank, order.indexOf(a.user.name) + 1);
  const towns = await call('GET', '/v1/leaderboards/town?stake=3', { token: b.token });
  assert.deepEqual(towns.data.entries.slice(0, 2).map((e) => [e.name, e.town]), [[a.user.name, 3], [b.user.name, 2]]);
  assert.equal(towns.data.me.rank, 2);
  assert.equal(hands.data.entries.some((e) => 'user_id' in e), false, 'ids stay private');
});

test('profile stats come from the player\'s runs', async () => {
  const g = await guest();
  await call('POST', '/v1/runs', { token: g.token, body: run({ deck: 'd_venezia', won: true, town: 8, actions: Array.from({ length: 8 }, () => ({ a: 'play' })), jesters: ['z_zanni', 'z_lazzo'] }) });
  await call('POST', '/v1/runs', { token: g.token, body: run({ deck: 'd_venezia', jesters: ['z_lazzo'] }) });
  const stats = (await call('GET', '/v1/me/stats', { token: g.token })).data;
  assert.equal(stats.runs, 2);
  assert.equal(stats.wins, 1);
  assert.equal(stats.best_town, 8);
  assert.equal(stats.favourite_jester, 'z_lazzo');
  assert.deepEqual(stats.per_deck, [{ deck: 'd_venezia', stake: 1, runs: 2, wins: 1 }]);
});

test('Sign in with Apple: checked tokens create, find, and link players', async () => {
  const t = Math.floor(Date.now() / 1000);
  const claims = { iss: 'https://appleid.apple.com', aud: 'com.example.fools', sub: 'apple-001', email: 'fool@privaterelay.appleid.com', email_verified: 'true', exp: t + 600, iat: t };
  const created = await call('POST', '/v1/auth/apple', { body: { id_token: await idToken(claims) } });
  assert.equal(created.status, 201);
  assert.equal(created.data.created, true);
  assert.equal(created.data.user.signins.apple, true);
  assert.equal(created.data.user.verified, true);
  const again = await call('POST', '/v1/auth/apple', { body: { id_token: await idToken(claims) } });
  assert.equal(again.data.user.id, created.data.user.id);
  const g = await guest();
  const linked = await call('POST', '/v1/auth/apple', { token: g.token, body: { id_token: await idToken({ ...claims, sub: 'apple-002', email: undefined }) } });
  assert.equal(linked.data.linked, true);
  assert.equal(linked.data.user.id, g.user.id);
  assert.equal(linked.data.user.guest, false);
  assert.equal((await call('POST', '/v1/auth/apple', { body: { id_token: await idToken({ ...claims, aud: 'someone.else' }) } })).status, 401);
  assert.equal((await call('POST', '/v1/auth/apple', { body: { id_token: await idToken({ ...claims, exp: t - 10 }) } })).status, 401);
  const stranger = await rsa();
  assert.equal((await call('POST', '/v1/auth/apple', { body: { id_token: await idToken(claims, { key: stranger }) } })).status, 401);
  assert.equal((await call('POST', '/v1/auth/apple', { body: { id_token: 'not-a-token' } })).status, 400);
});

test('Google sign-in works the same way', async () => {
  const t = Math.floor(Date.now() / 1000);
  const claims = { iss: 'https://accounts.google.com', aud: 'google-client-id', sub: 'g-123', email: 'fool@gmail.com', email_verified: true, exp: t + 600 };
  const res = await call('POST', '/v1/auth/google', { body: { id_token: await idToken(claims), name: 'Gianduja' } });
  assert.equal(res.status, 201);
  assert.equal(res.data.user.name, 'Gianduja');
  assert.equal(res.data.user.email, 'fool@gmail.com');
  assert.equal((await call('POST', '/v1/auth/google', { body: { id_token: await idToken({ ...claims, iss: 'https://evil.example' }) } })).status, 401);
});

test('deleting an account removes the player and everything about them', async () => {
  const email = freshEmail();
  const res = await call('POST', '/v1/auth/signup', { body: { email, password: 'harlequin1', name: 'Gone Soon' } });
  const token = res.data.token;
  await call('PUT', '/v1/save', { token, body: { base_version: 0, data: { x: 1 } } });
  await call('POST', '/v1/runs', { token, body: run({ best_hand: 9e15 }) });
  assert.equal((await call('DELETE', '/v1/me', { token })).status, 200);
  assert.equal((await call('GET', '/v1/me', { token })).status, 401);
  assert.equal((await call('POST', '/v1/auth/login', { body: { email, password: 'harlequin1' } })).status, 401);
  const board = await call('GET', '/v1/leaderboards/best_hand');
  assert.equal(board.data.entries.some((e) => e.name === 'Gone Soon'), false);
  assert.equal((await call('POST', '/v1/auth/signup', { body: { email, password: 'harlequin1', name: 'Back Again' } })).status, 201, 'the address is free again');
});

test('the browser can call the API from the game\'s page', async () => {
  const res = await fetch(`http://127.0.0.1:${PORT}/v1/me`, { method: 'OPTIONS', headers: { Origin: 'http://localhost:3790', 'Access-Control-Request-Method': 'GET', 'Access-Control-Request-Headers': 'authorization' } });
  assert.equal(res.status, 204);
  assert.equal(res.headers.get('access-control-allow-origin'), '*');
  assert.match(res.headers.get('access-control-allow-headers'), /Authorization/);
  const health = await call('GET', '/v1/health');
  assert.equal(health.headers.get('cross-origin-resource-policy'), 'cross-origin');
});
