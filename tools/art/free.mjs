// Paints the cards the paid run left out (Favors, Warrants, decks) with a free generator:
// FLUX.1 [schnell] (Apache 2.0) on Cloudflare Workers AI, inside the account's free daily
// allowance: 10,000 neurons a day, which ran out after 71 pictures at 8 steps (~140 each;
// it resets at 00:00 UTC, and past it calls fail with code 4006). It calls the REST API with
// the token `npx wrangler login` saved; run `npx wrangler whoami` first, which renews an
// expired one.
//   node tools/art/free.mjs <raw dir> [--only warrant/w_baule,… | --tour | --progression] [--jobs 3]
// --tour paints only batch 12's art (the 10 cities without a deck, the theatre boxes, the
// map's two textures); --progression batch 13's (Messer Grifone, the Wagon's 7 card backs).
// Saves <raw dir>/<kind>/<id>.jpg (or .png, by what comes back) and skips ones already there;
// then tools/art/convert.gd makes the game's art from them.
// Plain https to one IPv4 address that answers, rather than fetch: from here IPv6 doesn't
// connect and some of api.cloudflare.com's IPv4 addresses time out, so fetch and wrangler dev
// (10 s connect timeout, first address only) give up.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import net from 'node:net';
import dns from 'node:dns/promises';
import https from 'node:https';
import { freeBriefs, TOUR_ART, PROGRESSION_ART } from './prompts.mjs';

const HOST = 'api.cloudflare.com';

const MODEL = '@cf/black-forest-labs/flux-1-schnell';
const arg = (name) => { const i = process.argv.indexOf(name); return i > 0 ? process.argv[i + 1] : null; };
const dir = process.argv[2];
const only = arg('--only')?.split(',')
  ?? (process.argv.includes('--tour') ? TOUR_ART : (process.argv.includes('--progression') ? PROGRESSION_ART : null));
const jobs = Number(arg('--jobs') || 3);
if (!dir || dir.startsWith('--')) {
  console.log('usage: node tools/art/free.mjs <raw dir> [--only kind/id,…] [--jobs 3]');
  process.exit(1);
}

function wranglerToken() {
  const homes = [path.join(os.homedir(), '.wrangler'), path.join(os.homedir(), '.config', '.wrangler')];
  for (const home of homes) {
    const file = path.join(home, 'config', 'default.toml');
    if (!fs.existsSync(file)) continue;
    const text = fs.readFileSync(file, 'utf8');
    const token = text.match(/^oauth_token\s*=\s*"([^"]+)"/m)?.[1];
    const expires = text.match(/^expiration_time\s*=\s*"([^"]+)"/m)?.[1];
    if (token && expires && Date.parse(expires) < Date.now() + 60_000) throw new Error('the wrangler login has expired: run `npx wrangler whoami` to renew it');
    if (token) return token;
  }
  throw new Error('no wrangler login found: run `npx wrangler login`');
}

/** The first of the host's IPv4 addresses that takes a connection within a few seconds. */
async function reachableAddress() {
  for (const { address } of await dns.lookup(HOST, { all: true, family: 4 })) {
    const ok = await new Promise((resolve) => {
      const socket = net.connect({ host: address, port: 443, timeout: 4000 });
      socket.on('connect', () => { socket.destroy(); resolve(true); });
      socket.on('timeout', () => { socket.destroy(); resolve(false); });
      socket.on('error', () => resolve(false));
    });
    if (ok) return address;
  }
  throw new Error(`none of ${HOST}'s addresses answer`);
}
let address = null;
const lookup = (host, options, cb) => (options.all ? cb(null, [{ address, family: 4 }]) : cb(null, address, 4));

/** One API call; when the connection fails, picks an address again and retries. */
async function call(method, url, token, body) {
  for (let attempt = 1; ; attempt++) {
    address ??= await reachableAddress();
    try {
      return await request(method, url, token, body);
    } catch (e) {
      if (attempt >= 4 || !(e.code || e.message === 'timed out')) throw e;
      address = null;
    }
  }
}

function request(method, url, token, body) {
  return new Promise((resolve, reject) => {
    const req = https.request(url, {
      method, lookup, timeout: 120_000,
      headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' },
    }, (res) => {
      const chunks = [];
      res.on('data', (c) => chunks.push(c));
      res.on('end', () => {
        const text = Buffer.concat(chunks).toString();
        let json;
        try { json = JSON.parse(text); } catch { return reject(new Error(`HTTP ${res.statusCode}: ${text.slice(0, 200)}`)); }
        if (res.statusCode !== 200 || !json.success) return reject(new Error(`HTTP ${res.statusCode}: ${JSON.stringify(json.errors ?? json).slice(0, 300)}`));
        resolve(json.result);
      });
    });
    req.on('timeout', () => req.destroy(new Error('timed out')));
    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

const token = wranglerToken();
const [account] = await call('GET', 'https://api.cloudflare.com/client/v4/accounts', token);
const todo = Object.entries(freeBriefs()).filter(([key]) => (!only || only.includes(key))
  && !['.jpg', '.png'].some((ext) => fs.existsSync(path.join(dir, key + ext))));
console.log(`${todo.length} to paint`);

let made = 0;
let failed = 0;
async function paint([key, prompt]) {
  fs.mkdirSync(path.dirname(path.join(dir, key)), { recursive: true });
  // The connection here drops now and then: a few tries each, and carry on regardless.
  for (let attempt = 1; attempt <= 3; attempt++) {
    try {
      const { image } = await call('POST', `https://api.cloudflare.com/client/v4/accounts/${account.id}/ai/run/${MODEL}`, token, { prompt, steps: 8 });
      const bytes = Buffer.from(image, 'base64');
      // Godot picks the image reader by the file's extension, so name it after its contents.
      const ext = bytes[0] === 0x89 && bytes[1] === 0x50 ? '.png' : '.jpg';
      fs.writeFileSync(path.join(dir, key + ext), bytes);
      made++;
      console.log(key);
      return;
    } catch (e) {
      if (attempt === 3) {
        failed++;
        console.error(`${key}: ${e.message}`);
      } else await new Promise((r) => setTimeout(r, 3000 * attempt));
    }
  }
}
const queue = [...todo];
await Promise.all(Array.from({ length: jobs }, async () => { while (queue.length) await paint(queue.shift()); }));
console.log(`painted ${made}, failed ${failed}`);
