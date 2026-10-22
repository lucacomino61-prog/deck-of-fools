// Keeps track of painting the card art in batches through the Higgsfield image tools (which
// the agent calls; this script only plans, records and downloads), so nothing is painted
// twice and an interrupted run picks up where it stopped. State: tools/art/state.json.
//   node tools/art/queue.mjs next 2            the next 2 requests, as JSON for a batch call
//   node tools/art/queue.mjs submit 5=<job> …   record submitted jobs by request index
//   node tools/art/queue.mjs result 5=<url> …   record finished paintings
//   node tools/art/queue.mjs retry 5 …          forget a failed job so it's asked again
//   node tools/art/queue.mjs download <dir>     fetch every finished painting not yet saved
//   node tools/art/queue.mjs status
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { allBriefs, otherBriefs, STYLE, OBJECT_STYLE, BACK_STYLE } from './prompts.mjs';

const here = path.dirname(fileURLToPath(import.meta.url));
const STATE = path.join(here, 'state.json');
const MODEL = 'gpt_image_2_5';
// state.json (git-ignored: the repository is public) holds the account's result URLs; the
// account's folder for a bare timestamp comes from a recorded URL or HIGGSFIELD_BASE.

const briefs = { ...Object.fromEntries(Object.entries(allBriefs()).map(([id, b]) => [`zanni/${id}`, b])), ...otherBriefs() };
const keys = Object.keys(briefs);
const state = fs.existsSync(STATE) ? JSON.parse(fs.readFileSync(STATE, 'utf8')) : {};
const save = () => fs.writeFileSync(STATE, JSON.stringify(state, null, 1));
const [cmd, ...args] = process.argv.slice(2);

const pairs = () => args.map((a) => a.split('=')).map(([i, v]) => [keys[Number(i)], v]);
const base = () => process.env.HIGGSFIELD_BASE
  || Object.values(state).map((s) => s.url).find(Boolean)?.replace(/[^/]+$/, '')
  || '';

switch (cmd) {
  case 'next': {
    const n = Number(args[0] || 2);
    const todo = keys.map((k, i) => [k, i]).filter(([k]) => !state[k]?.job && !state[k]?.url).slice(0, n);
    console.log(JSON.stringify(todo.map(([k, i]) => ({ index: i, params: { model: MODEL, aspect_ratio: '3:4', prompt: briefs[k] } }))));
    break;
  }
  case 'short': {
    // The next N, one per line: "index|S|subject", S naming the shared style text that ends the
    // brief (J Jester, O object, B card back), which is left out.
    const n = Number(args[0] || 4);
    const tails = { J: STYLE, O: OBJECT_STYLE, B: BACK_STYLE };
    const todo = keys.map((k, i) => [k, i]).filter(([k]) => !state[k]?.job && !state[k]?.url).slice(0, n);
    for (const [k, i] of todo) {
      const [tag, tail] = Object.entries(tails).find(([, t]) => briefs[k].endsWith(t));
      console.log(`${i}|${tag}|${briefs[k].slice(0, -tail.length - 1)}`);
    }
    break;
  }
  case 'submit':
    for (const [k, job] of pairs()) state[k] = { ...state[k], job };
    save();
    break;
  case 'result':
    // A full URL, or just the result's timestamp ("20261022_081740"): Higgsfield names each
    // result hf_<timestamp>_<job id>.png under the account's folder.
    for (const [k, v] of pairs()) {
      if (!v.startsWith('http') && !base()) throw new Error('give the full URL the first time (or set HIGGSFIELD_BASE)');
      state[k] = { ...state[k], url: v.startsWith('http') ? v : `${base()}hf_${v}_${state[k].job}.png` };
    }
    save();
    break;
  case 'retry':
    for (const i of args) delete state[keys[Number(i)]];
    save();
    break;
  case 'download': {
    const dir = args[0];
    let n = 0;
    for (const k of keys) {
      const s = state[k];
      const file = path.join(dir, `${k}.png`);
      if (!s?.url || fs.existsSync(file)) continue;
      fs.mkdirSync(path.dirname(file), { recursive: true });
      // The connection here drops now and then: a few tries each, and carry on regardless.
      for (let attempt = 1; attempt <= 4; attempt++) {
        try {
          const res = await fetch(s.url, { signal: AbortSignal.timeout(60000) });
          if (!res.ok) throw new Error(`HTTP ${res.status}`);
          fs.writeFileSync(file, Buffer.from(await res.arrayBuffer()));
          n++;
          break;
        } catch (e) {
          if (attempt === 4) console.error(`${k}: ${e.message}`);
          else await new Promise((r) => setTimeout(r, 2000 * attempt));
        }
      }
    }
    console.log(`downloaded ${n}`);
    break;
  }
  case 'status': {
    const done = keys.filter((k) => state[k]?.url).length;
    const pending = keys.filter((k) => state[k]?.job && !state[k]?.url);
    console.log(`${done} of ${keys.length} painted; pending: ${pending.map((k) => `${keys.indexOf(k)}=${state[k].job}`).join(' ') || 'none'}`);
    break;
  }
  default:
    console.log('commands: next N | submit i=job | result i=url | retry i | download dir | status');
}
