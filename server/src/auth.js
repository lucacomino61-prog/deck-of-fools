// Passwords (PBKDF2), sessions (bearer tokens stored only as hashes), and Apple/Google
// identity tokens (RS256 JWTs checked against the providers' published keys).
import { HttpError, now, randomToken, sha256, base64url, fromBase64url } from './util.js';

// Workers cap PBKDF2 at 100,000 iterations.
const ITERATIONS = 100_000;

export async function hashPassword(password) {
  const salt = crypto.getRandomValues(new Uint8Array(16));
  const hash = await pbkdf2(password, salt, ITERATIONS);
  return `pbkdf2$${ITERATIONS}$${base64url(salt)}$${base64url(hash)}`;
}

export async function checkPassword(password, stored) {
  if (!stored) return false;
  const [scheme, iterations, salt, hash] = stored.split('$');
  if (scheme !== 'pbkdf2') return false;
  const actual = await pbkdf2(password, fromBase64url(salt), Number(iterations));
  const expected = fromBase64url(hash);
  if (actual.length !== expected.length) return false;
  let diff = 0;
  for (let i = 0; i < actual.length; i++) diff |= actual[i] ^ expected[i];
  return diff === 0;
}

async function pbkdf2(password, salt, iterations) {
  const key = await crypto.subtle.importKey('raw', new TextEncoder().encode(password), 'PBKDF2', false, ['deriveBits']);
  const bits = await crypto.subtle.deriveBits({ name: 'PBKDF2', hash: 'SHA-256', salt, iterations }, key, 256);
  return new Uint8Array(bits);
}

export async function createSession(db, userId) {
  const token = randomToken();
  const t = now();
  await db.prepare('INSERT INTO sessions (token_hash, user_id, created_at, last_seen) VALUES (?, ?, ?, ?)').bind(await sha256(token), userId, t, t).run();
  return token;
}

/** The signed-in user for a request, or null. */
export async function sessionUser(db, request) {
  const header = request.headers.get('Authorization') || '';
  const match = header.match(/^Bearer\s+(\S+)$/);
  if (!match) return null;
  const tokenHash = await sha256(match[1]);
  const user = await db.prepare('SELECT u.* FROM sessions s JOIN users u ON u.id = s.user_id WHERE s.token_hash = ?').bind(tokenHash).first();
  if (user) await db.prepare('UPDATE sessions SET last_seen = ? WHERE token_hash = ?').bind(now(), tokenHash).run();
  return user ? { ...user, tokenHash } : null;
}

export async function requireUser(db, request) {
  const user = await sessionUser(db, request);
  if (!user) throw new HttpError(401, 'Please sign in again.');
  return user;
}

// --- Apple and Google identity tokens ---

const PROVIDERS = {
  apple: { issuers: ['https://appleid.apple.com'], keys: 'https://appleid.apple.com/auth/keys', audiences: 'APPLE_CLIENT_IDS', override: 'JWKS_APPLE' },
  google: { issuers: ['https://accounts.google.com', 'accounts.google.com'], keys: 'https://www.googleapis.com/oauth2/v3/certs', audiences: 'GOOGLE_CLIENT_IDS', override: 'JWKS_GOOGLE' },
};
const keyCache = new Map();

/** Checks an identity token and returns its claims ({ sub, email, ... }). */
export async function verifyIdentityToken(env, provider, token) {
  const spec = PROVIDERS[provider];
  const parts = String(token || '').split('.');
  if (parts.length !== 3) throw new HttpError(400, 'That sign-in token is not valid.');
  const decode = (part) => JSON.parse(new TextDecoder().decode(fromBase64url(part)));
  let header;
  let claims;
  try {
    header = decode(parts[0]);
    claims = decode(parts[1]);
  } catch {
    throw new HttpError(400, 'That sign-in token is not valid.');
  }
  if (header.alg !== 'RS256') throw new HttpError(400, 'That sign-in token is not valid.');
  const jwks = await providerKeys(env, spec);
  const jwk = jwks.keys.find((k) => k.kid === header.kid);
  if (!jwk) throw new HttpError(401, 'That sign-in could not be checked. Try again.');
  const key = await crypto.subtle.importKey('jwk', jwk, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['verify']);
  const signed = new TextEncoder().encode(`${parts[0]}.${parts[1]}`);
  if (!(await crypto.subtle.verify('RSASSA-PKCS1-v1_5', key, fromBase64url(parts[2]), signed))) {
    throw new HttpError(401, 'That sign-in could not be checked. Try again.');
  }
  const audiences = String(env[spec.audiences] || '').split(',').map((a) => a.trim()).filter(Boolean);
  if (!spec.issuers.includes(claims.iss) || !audiences.includes(claims.aud) || !(claims.exp > now()) || !claims.sub) {
    throw new HttpError(401, 'That sign-in has expired or is for another app. Try again.');
  }
  return claims;
}

async function providerKeys(env, spec) {
  if (env[spec.override]) return JSON.parse(env[spec.override]);
  const cached = keyCache.get(spec.keys);
  if (cached && cached.until > Date.now()) return cached.jwks;
  const res = await fetch(spec.keys);
  if (!res.ok) throw new HttpError(503, 'Sign-in is unavailable right now. Try again soon.');
  const jwks = await res.json();
  keyCache.set(spec.keys, { jwks, until: Date.now() + 3_600_000 });
  return jwks;
}
