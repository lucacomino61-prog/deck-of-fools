// Deck of Fools API (Cloudflare Worker + D1).
//   Accounts: a silent guest on first launch, upgraded by email + password, Apple or Google,
//   keeping everything; email confirmation and password reset; deletion.
//   Cloud save: one save per player, versioned; a stale write gets 409 with the cloud copy so
//   the game can ask which to keep.
//   Runs: finished runs are handed in with their seed and action log, checked for
//   plausibility and rate-limited; they feed the leaderboards and the profile stats.
//   Daily run: the same seed for everyone each UTC day, one ranked attempt each.
import { CORS, HttpError, json, html, body, now, randomToken, sha256, allow } from './util.js';
import { hashPassword, checkPassword, createSession, sessionUser, requireUser, verifyIdentityToken } from './auth.js';
import { sendMail, verifyEmail, resetEmail } from './mail.js';
import { DECKS, today, dailySetup, acceptableDates } from './daily.js';
import { verifiedPage, resetPage } from './pages.js';

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const NAME = /^[\p{L}\p{N} _.'-]{2,20}$/u;
const TOKEN = /^[A-Za-z0-9_-]{20,100}$/;
const MAX_SAVE = 1_000_000;
const LEADERBOARD_SIZE = 50;

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: CORS });
    try {
      return await route(request, env);
    } catch (error) {
      if (error instanceof HttpError) return json({ error: error.message }, error.status);
      console.error(error);
      return json({ error: 'Something went wrong on our side. Try again.' }, 500);
    }
  },
};

async function route(request, env) {
  const url = new URL(request.url);
  const path = url.pathname;
  const method = request.method;
  const db = env.DB;
  const key = `${method} ${path}`;
  switch (key) {
    case 'GET /v1/health':
      return json({ ok: true, time: now() });
    case 'POST /v1/auth/guest':
      return guest(request, env);
    case 'POST /v1/auth/signup':
      return signup(request, env);
    case 'POST /v1/auth/login':
      return login(request, env);
    case 'POST /v1/auth/logout': {
      const user = await requireUser(db, request);
      await db.prepare('DELETE FROM sessions WHERE token_hash = ?').bind(user.tokenHash).run();
      return json({ ok: true });
    }
    case 'POST /v1/auth/apple':
      return identity(request, env, 'apple');
    case 'POST /v1/auth/google':
      return identity(request, env, 'google');
    case 'POST /v1/auth/forgot':
      return forgot(request, env);
    case 'POST /v1/auth/reset':
      return reset(request, env);
    case 'POST /v1/auth/resend-verification': {
      const user = await requireUser(db, request);
      if (user.email && !user.email_verified) await sendVerification(env, user);
      return json({ ok: true });
    }
    case 'GET /verify':
      return verify(url, env);
    case 'GET /reset': {
      const token = url.searchParams.get('token') || '';
      return TOKEN.test(token) ? html(resetPage(token)) : html(verifiedPage(false), 400);
    }
    case 'GET /v1/me':
      return json({ user: publicUser(await requireUser(db, request)) });
    case 'PATCH /v1/me':
      return rename(request, env);
    case 'DELETE /v1/me':
      return deleteAccount(request, env);
    case 'GET /v1/me/stats':
      return stats(request, env);
    case 'GET /v1/save':
      return getSave(request, env);
    case 'PUT /v1/save':
      return putSave(request, env);
    case 'GET /v1/daily':
      return daily(request, env);
    case 'POST /v1/daily/start':
      return startDaily(request, env);
    case 'POST /v1/runs':
      return submitRun(request, env);
    case 'GET /v1/leaderboards/daily':
      return dailyBoard(request, env, url);
    case 'GET /v1/leaderboards/best_hand':
      return bestHandBoard(request, env);
    case 'GET /v1/leaderboards/town':
      return townBoard(request, env, url);
    case 'GET /v1/dev/outbox':
      if (env.DEV_MAIL !== '1') break;
      return json({ emails: (await db.prepare('SELECT * FROM outbox ORDER BY id DESC LIMIT 20').all()).results });
  }
  throw new HttpError(404, 'Not found.');
}

function publicUser(user) {
  return {
    id: user.id,
    name: user.name,
    email: user.email,
    verified: Boolean(user.email_verified),
    guest: Boolean(user.guest),
    signins: { password: Boolean(user.password_hash), apple: Boolean(user.apple_sub), google: Boolean(user.google_sub) },
    created_at: user.created_at,
  };
}

async function signedIn(env, user) {
  const fresh = await env.DB.prepare('SELECT * FROM users WHERE id = ?').bind(user.id).first();
  return { token: await createSession(env.DB, user.id), user: publicUser(fresh) };
}

const ip = (request) => request.headers.get('CF-Connecting-IP') || 'local';

function guestName() {
  return `Guest ${1000 + Math.floor(Math.random() * 9000)}`;
}

// --- accounts ---

async function guest(request, env) {
  if (!(await allow(env.DB, `guest:${ip(request)}`, 30, 3600))) throw new HttpError(429, 'Too many new players from here. Try again later.');
  const id = crypto.randomUUID();
  await env.DB.prepare('INSERT INTO users (id, name, guest, created_at) VALUES (?, ?, 1, ?)').bind(id, guestName(), now()).run();
  return json(await signedIn(env, { id }), 201);
}

function cleanEmail(value) {
  const email = String(value || '').trim().toLowerCase();
  if (email.length > 254 || !EMAIL.test(email)) throw new HttpError(400, 'Enter a valid email address.');
  return email;
}

function cleanPassword(value) {
  const password = String(value || '');
  if (password.length < 8) throw new HttpError(400, 'Your password needs at least 8 characters.');
  if (password.length > 200) throw new HttpError(400, 'That password is too long.');
  return password;
}

function cleanName(value) {
  const name = String(value || '').trim().replace(/\s+/g, ' ');
  if (!NAME.test(name)) throw new HttpError(400, 'Names are 2 to 20 letters, numbers or spaces.');
  return name;
}

/** Email sign-up. With a guest's token it upgrades that guest, so nothing is lost. */
async function signup(request, env) {
  const data = await body(request);
  const email = cleanEmail(data.email);
  const password = cleanPassword(data.password);
  const name = cleanName(data.name);
  const db = env.DB;
  if (await db.prepare('SELECT 1 FROM users WHERE email = ?').bind(email).first()) {
    throw new HttpError(409, 'That email already has an account. Log in instead.');
  }
  const hash = await hashPassword(password);
  const current = await sessionUser(db, request);
  let user;
  if (current && current.guest) {
    await db.prepare('UPDATE users SET email = ?, password_hash = ?, name = ?, guest = 0 WHERE id = ?').bind(email, hash, name, current.id).run();
    user = { ...current, email, name };
  } else {
    user = { id: crypto.randomUUID(), email, name };
    await db.prepare('INSERT INTO users (id, name, email, password_hash, guest, created_at) VALUES (?, ?, ?, ?, 0, ?)').bind(user.id, name, email, hash, now()).run();
  }
  await sendVerification(env, user);
  return json({ ...(await signedIn(env, user)), linked: Boolean(current && current.guest) }, 201);
}

async function login(request, env) {
  const data = await body(request);
  const email = cleanEmail(data.email);
  if (!(await allow(env.DB, `login:${email}`, 10, 900))) throw new HttpError(429, 'Too many tries. Wait 15 minutes and try again.');
  const user = await env.DB.prepare('SELECT * FROM users WHERE email = ?').bind(email).first();
  if (!user || !(await checkPassword(String(data.password || ''), user.password_hash))) {
    throw new HttpError(401, "That email and password don't match.");
  }
  return json(await signedIn(env, user));
}

/** Apple or Google sign-in: finds the player by their provider id, links it to the guest
 * playing on this device, or creates a new player. */
async function identity(request, env, provider) {
  const data = await body(request);
  const claims = await verifyIdentityToken(env, provider, data.id_token);
  const column = provider === 'apple' ? 'apple_sub' : 'google_sub';
  const db = env.DB;
  const existing = await db.prepare(`SELECT * FROM users WHERE ${column} = ?`).bind(claims.sub).first();
  if (existing) return json({ ...(await signedIn(env, existing)), linked: false, created: false });
  const current = await sessionUser(db, request);
  const email = claims.email && claims.email_verified !== false && claims.email_verified !== 'false' ? String(claims.email).toLowerCase() : null;
  const emailFree = email && !(await db.prepare('SELECT 1 FROM users WHERE email = ?').bind(email).first());
  if (current) {
    await db.prepare(`UPDATE users SET ${column} = ?, guest = 0, email = COALESCE(email, ?), email_verified = CASE WHEN email IS NULL AND ? IS NOT NULL THEN 1 ELSE email_verified END WHERE id = ?`)
      .bind(claims.sub, emailFree ? email : null, emailFree ? email : null, current.id).run();
    return json({ ...(await signedIn(env, current)), linked: true, created: false });
  }
  const id = crypto.randomUUID();
  const name = data.name ? cleanName(data.name) : guestName().replace('Guest', 'Player');
  await db.prepare(`INSERT INTO users (id, name, email, email_verified, ${column}, guest, created_at) VALUES (?, ?, ?, ?, ?, 0, ?)`)
    .bind(id, name, emailFree ? email : null, emailFree ? 1 : 0, claims.sub, now()).run();
  return json({ ...(await signedIn(env, { id })), linked: false, created: true }, 201);
}

async function sendVerification(env, user) {
  const token = randomToken();
  await env.DB.prepare('INSERT INTO tokens (token_hash, user_id, kind, expires_at) VALUES (?, ?, ?, ?)').bind(await sha256(token), user.id, 'verify', now() + 7 * 86400).run();
  await sendMail(env, user.email, 'Confirm your Deck of Fools email', verifyEmail(`${env.PUBLIC_URL}/verify?token=${token}`));
}

async function useToken(env, token, kind) {
  if (!TOKEN.test(String(token || ''))) return null;
  const tokenHash = await sha256(token);
  const row = await env.DB.prepare('SELECT * FROM tokens WHERE token_hash = ? AND kind = ?').bind(tokenHash, kind).first();
  if (!row) return null;
  await env.DB.prepare('DELETE FROM tokens WHERE token_hash = ?').bind(tokenHash).run();
  return row.expires_at > now() ? row : null;
}

async function verify(url, env) {
  const row = await useToken(env, url.searchParams.get('token'), 'verify');
  if (row) await env.DB.prepare('UPDATE users SET email_verified = 1 WHERE id = ?').bind(row.user_id).run();
  return html(verifiedPage(Boolean(row)), row ? 200 : 400);
}

/** Always answers the same, so it can't be used to find out who has an account. */
async function forgot(request, env) {
  const data = await body(request);
  const email = cleanEmail(data.email);
  if (await allow(env.DB, `forgot:${email}`, 3, 3600)) {
    const user = await env.DB.prepare('SELECT * FROM users WHERE email = ?').bind(email).first();
    if (user) {
      const token = randomToken();
      await env.DB.prepare('INSERT INTO tokens (token_hash, user_id, kind, expires_at) VALUES (?, ?, ?, ?)').bind(await sha256(token), user.id, 'reset', now() + 3600).run();
      await sendMail(env, email, 'Reset your Deck of Fools password', resetEmail(`${env.PUBLIC_URL}/reset?token=${token}`));
    }
  }
  return json({ ok: true });
}

async function reset(request, env) {
  const data = await body(request);
  const password = cleanPassword(data.password);
  const row = await useToken(env, data.token, 'reset');
  if (!row) throw new HttpError(400, 'That link has expired. Ask for a new one in the game.');
  await env.DB.batch([
    env.DB.prepare('UPDATE users SET password_hash = ? WHERE id = ?').bind(await hashPassword(password), row.user_id),
    env.DB.prepare('DELETE FROM sessions WHERE user_id = ?').bind(row.user_id),
  ]);
  return json({ ok: true });
}

async function rename(request, env) {
  const user = await requireUser(env.DB, request);
  const data = await body(request);
  const name = cleanName(data.name);
  await env.DB.prepare('UPDATE users SET name = ? WHERE id = ?').bind(name, user.id).run();
  return json({ user: publicUser({ ...user, name }) });
}

/** Deletes the player and everything stored about them (Apple requires this in the app). */
async function deleteAccount(request, env) {
  const user = await requireUser(env.DB, request);
  await env.DB.batch(['daily', 'runs', 'saves', 'tokens', 'sessions'].map((table) => env.DB.prepare(`DELETE FROM ${table} WHERE user_id = ?`).bind(user.id))
    .concat([env.DB.prepare('DELETE FROM users WHERE id = ?').bind(user.id)]));
  return json({ deleted: true });
}

// --- cloud save ---

async function getSave(request, env) {
  const user = await requireUser(env.DB, request);
  const row = await env.DB.prepare('SELECT version, data, device, updated_at FROM saves WHERE user_id = ?').bind(user.id).first();
  return json(row ? { version: row.version, data: JSON.parse(row.data), device: row.device, updated_at: row.updated_at } : { version: 0, data: null });
}

/** Writes the save if the device saw the latest version (or says force); otherwise 409 with
 * the cloud copy, so the game can ask which one to keep. */
async function putSave(request, env) {
  const user = await requireUser(env.DB, request);
  const data = await body(request, MAX_SAVE + 10_000);
  if (typeof data.data !== 'object' || data.data === null) throw new HttpError(400, 'Nothing to save.');
  const text = JSON.stringify(data.data);
  if (text.length > MAX_SAVE) throw new HttpError(413, 'That save is too big.');
  const db = env.DB;
  const row = await db.prepare('SELECT version, data, device, updated_at FROM saves WHERE user_id = ?').bind(user.id).first();
  const current = row ? row.version : 0;
  if (!data.force && Number(data.base_version || 0) !== current) {
    return json({ error: 'The cloud has a newer save.', version: current, data: JSON.parse(row.data), device: row.device, updated_at: row.updated_at }, 409);
  }
  const version = current + 1;
  const device = String(data.device || '').slice(0, 60);
  await db.prepare('INSERT INTO saves (user_id, version, data, device, updated_at) VALUES (?, ?, ?, ?, ?) ON CONFLICT(user_id) DO UPDATE SET version = excluded.version, data = excluded.data, device = excluded.device, updated_at = excluded.updated_at')
    .bind(user.id, version, text, device, now()).run();
  return json({ version });
}

// --- the daily run ---

async function daily(request, env) {
  const setup = dailySetup(today());
  const user = await sessionUser(env.DB, request);
  let attempt = null;
  if (user) {
    const row = await env.DB.prepare('SELECT d.run_id, r.town, r.best_hand, r.won FROM daily d LEFT JOIN runs r ON r.id = d.run_id WHERE d.date = ? AND d.user_id = ?').bind(setup.date, user.id).first();
    if (row) attempt = { finished: row.run_id !== null, town: row.town, best_hand: row.best_hand, won: Boolean(row.won) };
  }
  return json({ ...setup, attempt });
}

/** Starts this player's one ranked attempt for today. */
async function startDaily(request, env) {
  const user = await requireUser(env.DB, request);
  const setup = dailySetup(today());
  const result = await env.DB.prepare('INSERT OR IGNORE INTO daily (date, user_id, started_at) VALUES (?, ?, ?)').bind(setup.date, user.id, now()).run();
  if (!result.meta.changes) throw new HttpError(409, "You've already played today's ranked daily run. Practice is unlimited.");
  return json(setup, 201);
}

// --- runs and leaderboards ---

/** A finished run. The server can't replay the rules (they live in the game), so it checks
 * that the claim is plausible for the action log handed in, limits how often a player can
 * submit, and keeps the log for later checks. */
async function submitRun(request, env) {
  const user = await requireUser(env.DB, request);
  const data = await body(request);
  const seed = String(data.seed || '');
  const deck = String(data.deck || '');
  const stake = Number(data.stake);
  const town = Number(data.town);
  const bestHand = Number(data.best_hand);
  const challenge = String(data.challenge || '');
  const actions = Array.isArray(data.actions) ? data.actions : null;
  const jesters = Array.isArray(data.jesters) ? data.jesters.map(String).slice(0, 20) : [];
  if (!/^[A-Z0-9]{4,24}$/.test(seed) || !DECKS.includes(deck) || !Number.isInteger(stake) || stake < 1 || stake > 8
    || !Number.isInteger(town) || town < 1 || town > 1000 || !Number.isFinite(bestHand) || bestHand < 0
    || (challenge && !/^c_[a-z0-9_]+$/.test(challenge)) || !actions || actions.length > 50_000
    || actions.some((a) => typeof a !== 'object' || a === null || typeof a.a !== 'string')) {
    throw new HttpError(400, "That run doesn't look right.");
  }
  // Every town past the first needs at least its Patron show played, and a score needs a hand.
  const plays = actions.filter((a) => a.a === 'play').length;
  const plausible = plays >= Math.max(town - 1, bestHand > 0 ? 1 : 0) && (town > 8 || bestHand <= 1e18);
  if (!plausible) throw new HttpError(422, "That run doesn't add up, so it wasn't ranked.");
  if (!(await allow(env.DB, `runs:${user.id}`, 30, 3600))) throw new HttpError(429, 'Too many runs handed in. Try again later.');

  let dailyDate = null;
  if (data.daily_date) {
    const date = String(data.daily_date);
    const setup = acceptableDates().includes(date) ? dailySetup(date) : null;
    const attempt = setup && await env.DB.prepare('SELECT run_id FROM daily WHERE date = ? AND user_id = ?').bind(date, user.id).first();
    if (!setup || !attempt || attempt.run_id !== null || seed !== setup.seed || deck !== setup.deck || stake !== setup.stake || challenge) {
      throw new HttpError(409, "That isn't today's ranked daily attempt.");
    }
    dailyDate = date;
  }
  // Helped by Maestri, wagon props or the campaign: kept off the leaderboards. A daily run
  // never is (the game brings no help to it).
  const assisted = data.assisted && !dailyDate ? 1 : 0;
  const result = await env.DB.prepare('INSERT INTO runs (user_id, seed, deck, stake, challenge, daily_date, won, town, best_hand, jesters, actions, created_at, assisted) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)')
    .bind(user.id, seed, deck, stake, challenge, dailyDate, data.won ? 1 : 0, town, bestHand, JSON.stringify(jesters), JSON.stringify(actions), now(), assisted).run();
  const runId = result.meta.last_row_id;
  if (dailyDate) await env.DB.prepare('UPDATE daily SET run_id = ? WHERE date = ? AND user_id = ?').bind(runId, dailyDate, user.id).run();
  return json({ run_id: runId, daily_date: dailyDate }, 201);
}

/** Top entries plus the asking player's own row and rank, even when it's off the list. */
async function board(env, user, query, binds, rankQuery) {
  const rows = (await env.DB.prepare(`${query} LIMIT ${LEADERBOARD_SIZE}`).bind(...binds).all()).results;
  const entries = rows.map((row, i) => ({ rank: i + 1, ...row, me: Boolean(user && row.user_id === user.id) }));
  let me = entries.find((e) => e.me) || null;
  if (!me && user) me = await rankQuery(user);
  return json({ entries: entries.map(({ user_id, ...rest }) => rest), me: me && (({ user_id, ...rest }) => rest)(me) });
}

async function dailyBoard(request, env, url) {
  const user = await sessionUser(env.DB, request);
  const date = url.searchParams.get('date') || today();
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) throw new HttpError(400, 'Dates look like 2026-10-21.');
  const ranked = 'FROM daily d JOIN runs r ON r.id = d.run_id JOIN users u ON u.id = d.user_id WHERE d.date = ?';
  return board(env, user, `SELECT u.name, d.user_id, r.town, r.best_hand, r.won ${ranked} ORDER BY r.town DESC, r.best_hand DESC, r.created_at ASC`, [date], async (u) => {
    const mine = await env.DB.prepare(`SELECT u.name, d.user_id, r.town, r.best_hand, r.won, r.created_at ${ranked} AND d.user_id = ?`).bind(date, u.id).first();
    if (!mine) return null;
    const ahead = await env.DB.prepare(`SELECT COUNT(*) AS n ${ranked} AND (r.town > ? OR (r.town = ? AND (r.best_hand > ? OR (r.best_hand = ? AND r.created_at < ?))))`)
      .bind(date, mine.town, mine.town, mine.best_hand, mine.best_hand, mine.created_at).first();
    const { created_at, ...row } = mine;
    return { rank: ahead.n + 1, ...row, me: true };
  });
}

async function bestHandBoard(request, env) {
  const user = await sessionUser(env.DB, request);
  const best = 'SELECT r.user_id, u.name, MAX(r.best_hand) AS best_hand FROM runs r JOIN users u ON u.id = r.user_id WHERE r.assisted = 0 GROUP BY r.user_id';
  return board(env, user, `${best} ORDER BY best_hand DESC`, [], async (u) => {
    const mine = await env.DB.prepare(`SELECT * FROM (${best}) WHERE user_id = ?`).bind(u.id).first();
    if (!mine) return null;
    const ahead = await env.DB.prepare(`SELECT COUNT(*) AS n FROM (${best}) WHERE best_hand > ?`).bind(mine.best_hand).first();
    return { rank: ahead.n + 1, ...mine, me: true };
  });
}

async function townBoard(request, env, url) {
  const user = await sessionUser(env.DB, request);
  const stake = Number(url.searchParams.get('stake') || 1);
  if (!Number.isInteger(stake) || stake < 1 || stake > 8) throw new HttpError(400, 'Stakes go from 1 to 8.');
  const best = "SELECT r.user_id, u.name, MAX(r.town) AS town FROM runs r JOIN users u ON u.id = r.user_id WHERE r.stake = ? AND r.challenge = '' AND r.assisted = 0 GROUP BY r.user_id";
  return board(env, user, `${best} ORDER BY town DESC`, [stake], async (u) => {
    const mine = await env.DB.prepare(`SELECT * FROM (${best}) WHERE user_id = ?`).bind(stake, u.id).first();
    if (!mine) return null;
    const ahead = await env.DB.prepare(`SELECT COUNT(*) AS n FROM (${best}) WHERE town > ?`).bind(stake, mine.town).first();
    return { rank: ahead.n + 1, ...mine, me: true };
  });
}

// --- profile stats ---

/** Win rate per deck and stake, favourite Jester, best hand and highest town, from runs. */
async function stats(request, env) {
  const user = await requireUser(env.DB, request);
  const db = env.DB;
  const perDeck = (await db.prepare("SELECT deck, stake, COUNT(*) AS runs, SUM(won) AS wins FROM runs WHERE user_id = ? AND challenge = '' GROUP BY deck, stake ORDER BY deck, stake").bind(user.id).all()).results;
  const totals = await db.prepare('SELECT COUNT(*) AS runs, COALESCE(SUM(won), 0) AS wins, COALESCE(MAX(best_hand), 0) AS best_hand, COALESCE(MAX(town), 0) AS best_town FROM runs WHERE user_id = ?').bind(user.id).first();
  const held = (await db.prepare('SELECT jesters FROM runs WHERE user_id = ? ORDER BY id DESC LIMIT 500').bind(user.id).all()).results;
  const counts = {};
  for (const row of held) for (const id of JSON.parse(row.jesters)) counts[id] = (counts[id] || 0) + 1;
  const favourite = Object.entries(counts).sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]))[0];
  return json({ ...totals, per_deck: perDeck, favourite_jester: favourite ? favourite[0] : null });
}
