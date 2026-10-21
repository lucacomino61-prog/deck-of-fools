// Small helpers shared by the routes: JSON responses with CORS, random tokens, hashing,
// request bodies and fixed-window rate limits.

export const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Authorization, Content-Type',
  'Access-Control-Max-Age': '86400',
  // The web build is cross-origin isolated (COEP require-corp), so say this may be loaded.
  'Cross-Origin-Resource-Policy': 'cross-origin',
};

export class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

export function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store', ...CORS },
  });
}

export function html(body, status = 200) {
  return new Response(body, { status, headers: { 'Content-Type': 'text/html; charset=utf-8', 'Cache-Control': 'no-store' } });
}

export async function body(request, limit = 1_100_000) {
  const text = await request.text();
  if (text.length > limit) throw new HttpError(413, 'That is too big to send.');
  if (!text) return {};
  try {
    const data = JSON.parse(text);
    if (typeof data !== 'object' || data === null || Array.isArray(data)) throw new Error();
    return data;
  } catch {
    throw new HttpError(400, 'The request body must be a JSON object.');
  }
}

export const now = () => Math.floor(Date.now() / 1000);

export function randomToken(bytes = 32) {
  const raw = crypto.getRandomValues(new Uint8Array(bytes));
  return base64url(raw);
}

export function base64url(bytes) {
  let text = '';
  for (const b of bytes) text += String.fromCharCode(b);
  return btoa(text).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

export function fromBase64url(text) {
  const padded = text.replace(/-/g, '+').replace(/_/g, '/') + '==='.slice((text.length + 3) % 4);
  const raw = atob(padded);
  const out = new Uint8Array(raw.length);
  for (let i = 0; i < raw.length; i++) out[i] = raw.charCodeAt(i);
  return out;
}

export async function sha256(text) {
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(text));
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

/** True if `key` is still under `max` hits in the current window (and counts this hit). */
export async function allow(db, key, max, windowSeconds) {
  const t = now();
  const row = await db.prepare('SELECT count, window_start FROM limits WHERE key = ?').bind(key).first();
  if (!row || t - row.window_start >= windowSeconds) {
    await db.prepare('INSERT INTO limits (key, count, window_start) VALUES (?, 1, ?) ON CONFLICT(key) DO UPDATE SET count = 1, window_start = excluded.window_start').bind(key, t).run();
    return true;
  }
  if (row.count >= max) return false;
  await db.prepare('UPDATE limits SET count = count + 1 WHERE key = ?').bind(key).run();
  return true;
}
