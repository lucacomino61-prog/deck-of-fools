// Synthesises every sound effect and the three music loops of Deck of Fools into
// game/audio/ as 16-bit mono WAV files. Everything is made here from oscillators, noise
// and plucked-string models: no recorded samples, so there is nothing to license.
//   node tools/audio/make_audio.mjs
// The music: a tarantella (6/8) in A minor for the menu, a calm Venetian barcarolle in F
// major for the shows, a faster, darker tarantella in D minor for Patron shows, and a
// music-box tune in C major for the shop. The shows and the Patron come in two layers of
// the same length, a base and a "drive" (drums and extra parts) that the game fades in as a
// show heats up. Each loop is rendered with its ringing tail wrapped onto its start, so it
// loops cleanly.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.join(here, '..', '..', 'game', 'audio');
const SFX_RATE = 44100;
const MUSIC_RATE = 32000;
const TAU = Math.PI * 2;

// --- basics ---

function rng(seed) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

const midi = (m) => 440 * Math.pow(2, (m - 69) / 12);

class Biquad {
  constructor(type, freq, q, rate) {
    this.type = type;
    this.rate = rate;
    this.x1 = this.x2 = this.y1 = this.y2 = 0;
    this.set(freq, q);
  }
  set(freq, q) {
    const w = TAU * Math.min(freq, this.rate * 0.45) / this.rate;
    const alpha = Math.sin(w) / (2 * q);
    const c = Math.cos(w);
    let b0, b1, b2;
    if (this.type === 'low') { b0 = (1 - c) / 2; b1 = 1 - c; b2 = (1 - c) / 2; }
    else if (this.type === 'high') { b0 = (1 + c) / 2; b1 = -(1 + c); b2 = (1 + c) / 2; }
    else { b0 = alpha; b1 = 0; b2 = -alpha; }
    const a0 = 1 + alpha;
    this.b0 = b0 / a0; this.b1 = b1 / a0; this.b2 = b2 / a0;
    this.a1 = -2 * c / a0; this.a2 = (1 - alpha) / a0;
  }
  run(x) {
    const y = this.b0 * x + this.b1 * this.x1 + this.b2 * this.x2 - this.a1 * this.y1 - this.a2 * this.y2;
    this.x2 = this.x1; this.x1 = x; this.y2 = this.y1; this.y1 = y;
    return y;
  }
}

/** Adds `fn(t, i)` (t in seconds from the voice's start) into `buf` from `start` seconds. */
function voice(buf, rate, start, seconds, fn) {
  const s0 = Math.round(start * rate);
  const n = Math.round(seconds * rate);
  for (let i = 0; i < n && s0 + i < buf.length; i++) {
    if (s0 + i >= 0) buf[s0 + i] += fn(i / rate, i);
  }
}

const env = (t, attack, decay) => (t < attack ? t / attack : Math.exp(-(t - attack) / decay));

/** A plucked string (Karplus-Strong with a fractional delay, so every note is in tune). */
function pluck(buf, rate, start, freq, seconds, gain, { bright = 0.6, decay = 0.996, seed = 1 } = {}) {
  const delay = rate / freq - 0.5;
  const size = Math.ceil(delay) + 4;
  const ring = new Float32Array(size);
  const at = (n) => ring[((n % size) + size) % size];
  const frac = (t) => { const i = Math.floor(t); const f = t - i; return at(i) * (1 - f) + at(i + 1) * f; };
  const r = rng(seed + Math.round(freq * 7));
  let lp = 0;
  const s0 = Math.round(start * rate);
  const n = Math.round(seconds * rate);
  for (let i = 0; i < n && s0 + i < buf.length; i++) {
    let x = 0;
    if (i < delay) { lp += bright * ((r() * 2 - 1) - lp); x = lp; }
    const y = x + decay * 0.5 * (frac(i - delay) + frac(i - delay - 1));
    ring[i % size] = y;
    const fade = i > n - 300 ? (n - i) / 300 : 1;
    if (s0 + i >= 0) buf[s0 + i] += y * gain * fade;
  }
}

/** A bell or music-box tone: frequency modulation with a decaying brightness. */
function bell(buf, rate, start, freq, seconds, gain, { ratio = 3.5, index = 2.5, decay = 0.35 } = {}) {
  voice(buf, rate, start, seconds, (t) => {
    const e = env(t, 0.002, decay);
    const mod = Math.sin(TAU * freq * ratio * t) * index * Math.exp(-t / (decay * 0.6));
    return Math.sin(TAU * freq * t + mod) * e * gain;
  });
}

/** An accordion chord: detuned reeds (musette), gently filtered, with a short swell. */
function accordion(buf, rate, start, notes, seconds, gain, { cutoff = 2600, attack = 0.02 } = {}) {
  const lp = new Biquad('low', cutoff, 0.7, rate);
  const tmp = new Float32Array(Math.round(seconds * rate) + 1);
  for (const m of notes) {
    const f = midi(m);
    for (const detune of [-0.0035, 0.0035]) {
      const fd = f * (1 + detune);
      for (let i = 0; i < tmp.length; i++) {
        const t = i / rate;
        const saw = 2 * ((fd * t) % 1) - 1;
        const sq = Math.sin(TAU * fd * 0.5 * t) > 0 ? 0.4 : -0.4;
        tmp[i] += (saw * 0.6 + sq * 0.4) * gain;
      }
    }
  }
  voice(buf, rate, start, seconds, (t, i) => {
    const release = Math.min(1, (seconds - t) / 0.05);
    const swell = Math.min(1, t / attack);
    return lp.run(tmp[i]) * swell * release * (1 + 0.08 * Math.sin(TAU * 5 * t));
  });
}

function noiseHit(buf, rate, start, seconds, gain, { type = 'band', freq = 4000, q = 1.2, attack = 0.001, decay = 0.05, seed = 7, sweepTo = null } = {}) {
  const f = new Biquad(type, freq, q, rate);
  const r = rng(seed);
  voice(buf, rate, start, seconds, (t) => {
    if (sweepTo !== null) f.set(freq + (sweepTo - freq) * (t / seconds), q);
    return f.run(r() * 2 - 1) * env(t, attack, decay) * gain;
  });
}

function tambourine(buf, rate, start, gain, seed) {
  noiseHit(buf, rate, start, 0.12, gain, { type: 'high', freq: 6500, q: 0.7, decay: 0.03, seed });
  const r = rng(seed * 13 + 5);
  for (const f of [5200, 6700, 8100]) {
    const ff = f * (0.97 + r() * 0.06);
    voice(buf, rate, start, 0.1, (t) => Math.sin(TAU * ff * t) * Math.exp(-t / 0.025) * gain * 0.25);
  }
}

function kick(buf, rate, start, gain) {
  let phase = 0;
  voice(buf, rate, start, 0.35, (t) => {
    const f = 45 + 95 * Math.exp(-t / 0.04);
    phase += TAU * f / rate;
    return Math.sin(phase) * Math.exp(-t / 0.16) * gain;
  });
}

function clap(buf, rate, start, gain, seed) {
  for (const offset of [0, 0.011, 0.022]) {
    noiseHit(buf, rate, start + offset, 0.15, gain * (offset === 0.022 ? 1 : 0.6), { type: 'band', freq: 1400, q: 0.9, decay: offset === 0.022 ? 0.07 : 0.01, seed: seed + offset * 1000 });
  }
}

/** A bowed fiddle: a sawtooth with vibrato that grows in, through a body-ish band. */
function fiddle(buf, rate, start, freq, seconds, gain, seed = 1) {
  const lp = new Biquad('low', 3200, 0.8, rate);
  const hp = new Biquad('high', 280, 0.7, rate);
  const r = rng(seed);
  let phase = 0;
  voice(buf, rate, start, seconds + 0.08, (t) => {
    const vib = 1 + 0.006 * Math.sin(TAU * 5.6 * t) * Math.min(1, t / 0.25);
    phase += freq * vib / rate;
    const saw = 2 * (phase % 1) - 1;
    const bow = (r() * 2 - 1) * 0.06;
    const level = Math.min(1, t / 0.05) * (t > seconds ? Math.max(0, 1 - (t - seconds) / 0.08) : 1);
    return hp.run(lp.run(saw + bow)) * level * gain;
  });
}

/** Castanets: two quick wooden clicks. */
function castanets(buf, rate, start, gain, seed) {
  for (const [offset, f] of [[0, 2600], [0.028, 3100]]) {
    noiseHit(buf, rate, start + offset, 0.03, gain, { freq: f, q: 4, decay: 0.005, seed: seed + f });
  }
}

/** A frame drum: a soft low thump with a skin slap. */
function frameDrum(buf, rate, start, gain, f0 = 110) {
  let phase = 0;
  voice(buf, rate, start, 0.3, (t) => {
    const f = f0 + 60 * Math.exp(-t / 0.02);
    phase += TAU * f / rate;
    return Math.sin(phase) * Math.exp(-t / 0.12) * gain;
  });
  noiseHit(buf, rate, start, 0.06, gain * 0.35, { freq: 900, q: 0.8, decay: 0.015, seed: Math.round(start * 1000) });
}

/** A soft electric piano: frequency modulation with a gentle bark and a long ring. */
function epiano(buf, rate, start, freq, seconds, gain) {
  voice(buf, rate, start, seconds, (t) => {
    const e = env(t, 0.004, 0.9) * Math.min(1, (seconds - t) / 0.08);
    const mod = Math.sin(TAU * freq * t) * 1.1 * Math.exp(-t / 0.25);
    return (Math.sin(TAU * freq * t + mod) + 0.15 * Math.sin(TAU * freq * 2 * t) * Math.exp(-t / 0.15)) * e * gain;
  });
}

/** A round, warm bass note. */
function softBass(buf, rate, start, freq, seconds, gain) {
  voice(buf, rate, start, seconds, (t) => {
    const e = env(t, 0.012, 0.55) * Math.min(1, (seconds - t) / 0.05);
    return (Math.sin(TAU * freq * t) + 0.25 * Math.sin(TAU * freq * 2 * t) + 0.08 * Math.sin(TAU * freq * 3 * t)) * e * gain;
  });
}

/** A breathy flute-like sine with vibrato, for doubling a melody softly. */
function flute(buf, rate, start, freq, seconds, gain, seed = 1) {
  const r = rng(seed);
  const bp = new Biquad('band', freq * 2, 2, rate);
  voice(buf, rate, start, seconds + 0.1, (t) => {
    const vib = 1 + 0.004 * Math.sin(TAU * 5 * t) * Math.min(1, t / 0.3);
    const level = Math.min(1, t / 0.08) * (t > seconds ? Math.max(0, 1 - (t - seconds) / 0.1) : 1);
    return (Math.sin(TAU * freq * vib * t) + bp.run(r() * 2 - 1) * 0.15) * level * gain;
  });
}

/** A crowd applauding: hundreds of random claps that swell and die away. */
function applause(buf, rate, start, seconds, gain, seed) {
  const r = rng(seed);
  const claps = Math.round(seconds * 90);
  for (let i = 0; i < claps; i++) {
    const at = start + Math.pow(r(), 1.3) * seconds;
    const shape = Math.min(1, (at - start) / 0.25) * Math.exp(-Math.max(0, at - start - 0.6) / (seconds * 0.45));
    noiseHit(buf, rate, at, 0.05, gain * shape * (0.4 + r() * 0.6), { freq: 900 + r() * 1800, q: 1 + r(), decay: 0.008 + r() * 0.01, seed: seed + i });
  }
}

/** A small room: four damped combs and two all-passes (Freeverb's shape), mixed in lightly. */
function reverb(buf, rate, wet) {
  const scale = rate / 44100;
  const combs = [1116, 1188, 1277, 1356].map((d) => ({ line: new Float32Array(Math.round(d * scale)), i: 0, store: 0 }));
  const passes = [556, 441].map((d) => ({ line: new Float32Array(Math.round(d * scale)), i: 0 }));
  const outBuf = new Float32Array(buf.length);
  for (let n = 0; n < buf.length; n++) {
    const x = buf[n] * 0.2;
    let sum = 0;
    for (const c of combs) {
      const y = c.line[c.i];
      c.store = y * 0.8 + c.store * 0.2;
      c.line[c.i] = x + c.store * 0.8;
      c.i = (c.i + 1) % c.line.length;
      sum += y;
    }
    for (const p of passes) {
      const y = p.line[p.i];
      p.line[p.i] = sum + y * 0.5;
      p.i = (p.i + 1) % p.line.length;
      sum = y - sum;
    }
    outBuf[n] = buf[n] + sum * wet;
  }
  return outBuf;
}

/** Normalises to `peak` with a soft clip; a one-shot also fades its last samples (a loop
 * must not, or it clicks where it wraps). */
function finish(buf, peak = 0.89, loop = false) {
  let max = 0;
  for (let i = 0; i < buf.length; i++) max = Math.max(max, Math.abs(buf[i]));
  const g = max > 0 ? peak / max : 1;
  const out = new Float32Array(buf.length);
  for (let i = 0; i < buf.length; i++) out[i] = Math.tanh(buf[i] * g * 1.1) / Math.tanh(1.1);
  if (!loop) {
    const fade = Math.min(64, buf.length);
    for (let i = 0; i < fade; i++) out[buf.length - 1 - i] *= i / fade;
  }
  return out;
}

function writeWav(file, samples, rate) {
  const data = Buffer.alloc(samples.length * 2);
  for (let i = 0; i < samples.length; i++) {
    data.writeInt16LE(Math.max(-32767, Math.min(32767, Math.round(samples[i] * 32767))), i * 2);
  }
  const head = Buffer.alloc(44);
  head.write('RIFF', 0); head.writeUInt32LE(36 + data.length, 4); head.write('WAVE', 8);
  head.write('fmt ', 12); head.writeUInt32LE(16, 16); head.writeUInt16LE(1, 20); head.writeUInt16LE(1, 22);
  head.writeUInt32LE(rate, 24); head.writeUInt32LE(rate * 2, 28); head.writeUInt16LE(2, 32); head.writeUInt16LE(16, 34);
  head.write('data', 36); head.writeUInt32LE(data.length, 40);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, Buffer.concat([head, data]));
}

// --- sound effects ---

const R = SFX_RATE;
const sfx = {};
const make = (name, seconds, build, peak = 0.89) => {
  const buf = new Float32Array(Math.round(seconds * R));
  build(buf);
  sfx[name] = finish(buf, peak);
};

// Picking a card up and putting it down: a papery tick with a soft wooden knock, in two
// takes each.
for (const [name, f, seed] of [['select', 1180, 3], ['select2', 1260, 5]]) {
  make(name, 0.12, (b) => {
    noiseHit(b, R, 0, 0.03, 0.6, { freq: 3200, q: 1.5, decay: 0.006, seed: 11 + seed });
    pluck(b, R, 0.004, f, 0.1, 0.5, { bright: 0.35, decay: 0.985, seed });
  }, 0.7);
}
for (const [name, f, seed] of [['deselect', 820, 4], ['deselect2', 760, 6]]) {
  make(name, 0.12, (b) => {
    noiseHit(b, R, 0, 0.03, 0.5, { freq: 2400, q: 1.5, decay: 0.006, seed: 12 + seed });
    pluck(b, R, 0.004, f, 0.1, 0.5, { bright: 0.35, decay: 0.985, seed });
  }, 0.6);
}
// Dealing: a card sliding off the deck, in three takes so a run of cards doesn't drone.
for (const [k, seed] of [[1, 21], [2, 22], [3, 23]]) {
  make(`deal${k}`, 0.14, (b) => {
    noiseHit(b, R, 0, 0.12, 0.8, { freq: 1800 + k * 300, sweepTo: 5200 + k * 200, q: 0.9, attack: 0.012, decay: 0.035, seed });
    noiseHit(b, R, 0.085, 0.03, 0.5, { freq: 3800, q: 2, decay: 0.005, seed: seed + 9 });
  }, 0.6);
}
// Throwing the hand onto the table: a whoosh, then the cards landing.
make('play', 0.38, (b) => {
  noiseHit(b, R, 0, 0.3, 0.7, { type: 'low', freq: 400, sweepTo: 3500, q: 0.8, attack: 0.12, decay: 0.08, seed: 31 });
  for (let i = 0; i < 4; i++) noiseHit(b, R, 0.16 + i * 0.035, 0.05, 0.45, { freq: 3000 + i * 250, q: 1.6, decay: 0.008, seed: 40 + i });
}, 0.75);
// A scoring card: a poker-chip clack, in three takes.
for (const [name, a, b2] of [['points', 2900, 3500], ['points2', 3100, 3700], ['points3', 2700, 3300]]) {
  make(name, 0.12, (b) => {
    for (const [at, f] of [[0, a], [0.018, b2]]) {
      noiseHit(b, R, at, 0.04, 0.5, { freq: 4200, q: 3, decay: 0.004, seed: 51 + f });
      voice(b, R, at, 0.06, (t) => Math.sin(TAU * f * t) * Math.exp(-t / 0.012) * 0.4);
    }
  }, 0.75);
}
// +Mult: a bright rising "bwip", in two takes.
for (const [name, from, rise] of [['mult', 330, 420], ['mult2', 350, 470]]) {
  make(name, 0.18, (b) => {
    let ph = 0;
    const lp = new Biquad('low', 3000, 0.9, R);
    voice(b, R, 0, 0.17, (t) => {
      const f = from + rise * Math.min(1, t / 0.07);
      ph += TAU * f / R;
      const sq = Math.sin(ph) > 0 ? 1 : -1;
      return lp.run(sq * 0.5 + Math.sin(ph * 2) * 0.3) * env(t, 0.004, 0.05) * 0.6;
    });
  }, 0.8);
}
// A hand that wins the show by itself: a boom, a rising run of bells, coins and a cheer.
make('jackpot', 2.4, (b) => {
  kick(b, R, 0, 1.0);
  voice(b, R, 0, 0.8, (t) => Math.sin(TAU * 49 * t) * Math.exp(-t / 0.3) * 0.5);
  noiseHit(b, R, 0, 1.2, 0.45, { type: 'high', freq: 3500, q: 0.6, decay: 0.35, seed: 73 });
  [72, 76, 79, 84, 88, 91, 96].forEach((m, i) => bell(b, R, 0.05 + i * 0.06, midi(m), 0.9, 0.22, { ratio: 3.5, index: 1.8, decay: 0.35 }));
  const r = rng(141);
  for (let i = 0; i < 16; i++) bell(b, R, 0.45 + i * 0.05 + r() * 0.02, midi(88 + Math.floor(r() * 12)), 0.3, 0.16, { ratio: 2.76, index: 1.3, decay: 0.09 });
  applause(b, R, 0.5, 1.8, 0.18, 151);
});
// A show won: the crowd applauding (played with the fanfare).
make('applause', 2.6, (b) => applause(b, R, 0, 2.5, 0.5, 161), 0.7);
// ×Mult: a thump under a two-note bell, with a shimmer of noise.
make('xmult', 0.9, (b) => {
  kick(b, R, 0, 0.9);
  bell(b, R, 0.01, midi(81), 0.85, 0.35, { ratio: 3.01, index: 3, decay: 0.3 });
  bell(b, R, 0.01, midi(88), 0.85, 0.25, { ratio: 2.0, index: 2, decay: 0.25 });
  noiseHit(b, R, 0, 0.4, 0.25, { type: 'high', freq: 7000, q: 0.7, decay: 0.12, seed: 61 });
});
// The hand's total landing: a deep impact with a crash.
make('slam', 1.1, (b) => {
  kick(b, R, 0, 1.0);
  voice(b, R, 0, 0.6, (t) => Math.sin(TAU * 55 * t) * Math.exp(-t / 0.25) * 0.5);
  noiseHit(b, R, 0, 1.0, 0.5, { type: 'high', freq: 3000, q: 0.6, attack: 0.002, decay: 0.3, seed: 71 });
  noiseHit(b, R, 0, 0.2, 0.6, { type: 'low', freq: 600, q: 0.7, decay: 0.04, seed: 72 });
});
// Winning a show: a little brass-and-bells fanfare.
make('win', 1.6, (b) => {
  const notes = [[0, 72], [0.11, 76], [0.22, 79], [0.36, 84]];
  for (const [at, m] of notes) {
    const lp = new Biquad('low', 1800, 1.2, R);
    const f = midi(m);
    const len = at === 0.36 ? 1.1 : 0.2;
    voice(b, R, at, len, (t) => {
      const saw = 2 * ((f * t) % 1) - 1;
      lp.set(900 + 2600 * Math.exp(-t / 0.15), 1.2);
      return lp.run(saw) * env(t, 0.015, len === 0.2 ? 0.12 : 0.45) * 0.35 * (1 + 0.05 * Math.sin(TAU * 6 * t));
    });
    bell(b, R, at, f * 2, 0.6, 0.18, { ratio: 3.5, index: 1.5, decay: 0.3 });
  }
  for (let i = 0; i < 5; i++) tambourine(b, R, 0.36 + i * 0.09, 0.25, 80 + i);
});
// Losing the run: a sad "wah, wah, wah, wahhh".
make('lose', 2.2, (b) => {
  const notes = [[0, 67, 0.32], [0.38, 66, 0.32], [0.76, 65, 0.32], [1.14, 64, 1.0]];
  for (const [at, m, len] of notes) {
    const lp = new Biquad('low', 600, 3, R);
    const f = midi(m);
    voice(b, R, at, len, (t) => {
      const vib = len > 0.5 ? 1 + 0.012 * Math.sin(TAU * 5.5 * t) * Math.min(1, t / 0.3) : 1;
      const saw = 2 * ((f * vib * t) % 1) - 1;
      lp.set(350 + 1300 * Math.sin(Math.PI * Math.min(1, t / Math.min(len, 0.35))), 3);
      return lp.run(saw) * env(t, 0.02, len * 0.6) * 0.5;
    });
  }
});
// Buying: two coin chimes, in two takes.
for (const [name, a, b2] of [['buy', 95, 100], ['buy2', 93, 98]]) {
  make(name, 0.5, (b) => {
    bell(b, R, 0, midi(a), 0.45, 0.4, { ratio: 2.76, index: 1.6, decay: 0.18 });
    bell(b, R, 0.07, midi(b2), 0.4, 0.35, { ratio: 2.76, index: 1.4, decay: 0.15 });
  });
}
// Selling: a coin dropped on the table, bouncing.
make('sell', 0.6, (b) => {
  let at = 0;
  for (let i = 0; i < 5; i++) {
    bell(b, R, at, midi(91 - i), 0.25, 0.4 * Math.pow(0.7, i), { ratio: 2.76, index: 1.2, decay: 0.07 });
    at += 0.12 * Math.pow(0.65, i);
  }
});
// A pack torn open, then a sparkle of what's inside.
make('pack', 0.7, (b) => {
  const r = rng(91);
  const bp = new Biquad('band', 2200, 0.8, R);
  voice(b, R, 0, 0.28, (t) => bp.run(r() * 2 - 1) * (0.4 + 0.6 * (r() > 0.6 ? 1 : 0.2)) * env(t, 0.01, 0.09) * 0.8);
  for (let i = 0; i < 6; i++) bell(b, R, 0.2 + i * 0.05, midi(96 + [0, 4, 7, 12, 7, 16][i]), 0.3, 0.12, { ratio: 3.5, index: 1, decay: 0.1 });
});
// Rerolling the shop: a quick riffle of the deck.
make('reroll', 0.42, (b) => {
  let at = 0;
  for (let i = 0; i < 14; i++) {
    noiseHit(b, R, at, 0.03, 0.5, { freq: 2800 + (i % 3) * 400, q: 2, decay: 0.004, seed: 100 + i });
    at += 0.032 * Math.pow(0.95, i);
  }
});
// A show starting: the theatre bell, twice.
make('show', 1.1, (b) => {
  bell(b, R, 0, midi(86), 0.9, 0.45, { ratio: 2.4, index: 2.2, decay: 0.35 });
  bell(b, R, 0.22, midi(86), 0.85, 0.4, { ratio: 2.4, index: 2.2, decay: 0.35 });
});
// Buttons: a soft, rounded click (a muted wooden tap), in two takes.
for (const [name, f, seed] of [['click', 980, 111], ['click2', 1080, 112]]) {
  make(name, 0.06, (b) => {
    voice(b, R, 0, 0.04, (t) => Math.sin(TAU * f * t) * Math.exp(-t / 0.008) * 0.5);
    noiseHit(b, R, 0, 0.02, 0.12, { type: 'low', freq: 2500, q: 0.7, decay: 0.003, seed });
  }, 0.4);
}
// The score counting up: a tiny tick.
make('tick', 0.03, (b) => {
  voice(b, R, 0, 0.025, (t) => Math.sin(TAU * 2200 * t) * Math.exp(-t / 0.004) * 0.5);
}, 0.45);
// Cashing out: a cascade of coins.
make('cash', 1.0, (b) => {
  const r = rng(121);
  for (let i = 0; i < 12; i++) bell(b, R, i * 0.055 + r() * 0.02, midi(88 + Math.floor(r() * 12)), 0.3, 0.25, { ratio: 2.76, index: 1.3, decay: 0.09 });
});
// Discarding: a swish away.
make('discard', 0.24, (b) => {
  noiseHit(b, R, 0, 0.22, 0.8, { freq: 3500, sweepTo: 700, q: 1, attack: 0.02, decay: 0.07, seed: 131 });
}, 0.65);
// Something not allowed: a low buzz.
make('error', 0.3, (b) => {
  const lp = new Biquad('low', 900, 0.8, R);
  voice(b, R, 0, 0.28, (t) => lp.run((Math.sin(TAU * 110 * t) > 0 ? 0.5 : -0.5) + (Math.sin(TAU * 117 * t) > 0 ? 0.5 : -0.5)) * env(t, 0.005, 0.12) * 0.5);
}, 0.6);

// --- music ---

const M = MUSIC_RATE;
const CHORDS = {
  Am: { notes: [57, 60, 64], root: 45, fifth: 52 }, E: { notes: [56, 59, 64], root: 40, fifth: 47 },
  Dm: { notes: [57, 62, 65], root: 38, fifth: 45 }, A7: { notes: [55, 61, 64], root: 45, fifth: 52 },
  Gm: { notes: [55, 58, 62], root: 43, fifth: 50 }, C: { notes: [60, 64, 67], root: 48, fifth: 55 },
  G: { notes: [59, 62, 67], root: 43, fifth: 50 }, F: { notes: [57, 60, 65], root: 41, fifth: 48 },
  // The barcarolle's softer seventh chords.
  Fmaj7: { notes: [53, 57, 60, 64], root: 41, fifth: 48 }, Em7: { notes: [52, 55, 59, 62], root: 40, fifth: 47 },
  Dm7: { notes: [53, 57, 60, 62], root: 38, fifth: 45 }, Cadd: { notes: [52, 55, 60, 62], root: 36, fifth: 43 },
  Bbmaj7: { notes: [53, 57, 58, 62], root: 46, fifth: 41 }, Am7: { notes: [52, 55, 57, 60], root: 45, fifth: 40 },
  Gm7: { notes: [53, 55, 58, 62], root: 43, fifth: 38 }, C7: { notes: [52, 55, 58, 60], root: 36, fifth: 43 },
};
const _ = -1;

/** Renders bars of 6/8 (each [chord, six melody eighths or null]) with an instrument plan. */
function renderTrack(bars, bpm, plan) {
  const eighth = 60 / bpm / 3;
  const length = bars.length * eighth * 6;
  const tail = 2.5;
  const buf = new Float32Array(Math.round((length + tail) * M));
  bars.forEach(([chordName, melody], bar) => {
    const chord = CHORDS[chordName];
    for (let k = 0; k < 6; k++) {
      const at = (bar * 6 + k) * eighth;
      plan.beat(buf, at, k, chord, eighth, bar);
      if (melody && melody[k] !== _) {
        let held = 1;
        while (k + held < 6 && melody[k + held] === _) held++;
        plan.note(buf, at, melody[k], held * eighth, eighth, bar * 6 + k);
      }
    }
  });
  const wet = reverb(buf, M, plan.reverb ?? 0.25);
  const loopLen = Math.round(length * M);
  const out = new Float32Array(loopLen);
  for (let i = 0; i < loopLen; i++) out[i] = wet[i];
  for (let i = loopLen; i < wet.length; i++) out[i - loopLen] += wet[i];
  return { samples: finish(out, 0.8, true), seconds: length };
}

// The tarantella, in five parts: intro, A (mandolin), A2 (mandolin and fiddle), B (in C
// major, the fiddle leads) and A3 (everyone).
const themeA = [
  ['Am', [76, 76, 76, 72, 74, 76]], ['Am', [77, 76, 74, 72, 71, 69]],
  ['E', [71, 71, 71, 68, 69, 71]], ['E', [72, 71, 69, 68, 64, 68]],
  ['Am', [76, 76, 76, 72, 74, 76]], ['Am', [77, 76, 74, 72, 74, 77]],
  ['E', [76, 74, 72, 71, 69, 68]], ['Am', [69, _, _, 69, _, _]],
];
const themeA2 = [
  ['Dm', [74, 74, 74, 77, 76, 74]], ['Dm', [72, 74, 76, 77, 79, 77]],
  ['Am', [76, 76, 76, 72, 74, 76]], ['Am', [81, 79, 77, 76, 74, 72]],
  ['E', [71, 72, 74, 76, 74, 72]], ['E', [71, 69, 68, 71, 76, 80]],
  ['Am', [81, 76, 72, 69, 72, 76]], ['Am', [69, _, _, _, _, _]],
];
const themeB = [
  ['C', [79, _, 76, 72, _, 76]], ['G', [74, _, 71, 67, _, 71]],
  ['F', [72, _, 69, 65, _, 69]], ['C', [67, _, 72, 76, _, 79]],
  ['Dm', [77, _, 74, 77, _, 81]], ['Am', [79, _, 76, 72, _, 69]],
  ['E', [71, _, 68, 64, _, 68]], ['E', [71, _, 74, 76, _, 80]],
];
const themeBars = [
  ['Am', null], ['Am', null], ['E', null], ['Am', null],
  ...themeA, ...themeA2, ...themeB, ...themeA,
];
const themePart = (bar) => (bar < 4 ? 'intro' : bar < 12 ? 'A' : bar < 20 ? 'A2' : bar < 28 ? 'B' : 'A3');
// The barcarolle for the shows: a calm Venetian boat song in 6/8, F major, in three parts.
const showBars = [
  ['Fmaj7', [72, _, _, 69, _, 72]], ['Em7', [76, _, _, 74, _, 72]],
  ['Dm7', [74, _, _, 72, _, 69]], ['Cadd', [67, _, _, _, _, _]],
  ['Bbmaj7', [69, _, 70, 72, _, 74]], ['Am7', [76, _, _, 72, _, _]],
  ['Gm7', [74, _, 72, 70, _, 67]], ['C7', [72, _, _, _, _, _]],
  ['Fmaj7', [72, _, _, 77, _, 76]], ['Em7', [74, _, _, 72, _, 74]],
  ['Dm7', [77, _, _, 76, _, 74]], ['Gm7', [74, _, _, 70, _, _]],
  ['Bbmaj7', [74, _, 72, 70, _, 69]], ['C7', [67, _, 69, 70, _, 72]],
  ['Fmaj7', [69, _, _, _, _, _]], ['Fmaj7', null],
  ['Dm7', [81, _, _, 77, _, 74]], ['Am7', [76, _, _, 72, _, 69]],
  ['Bbmaj7', [74, _, _, 70, _, 74]], ['Fmaj7', [72, _, _, _, 69, _]],
  ['Gm7', [70, _, 74, 77, _, 74]], ['Am7', [76, _, 72, 69, _, 72]],
  ['Bbmaj7', [74, _, _, 77, _, 74]], ['C7', [72, _, _, _, _, _]],
];
const patronBars = [
  ['Dm', null], ['A7', null],
  ['Dm', [74, 77, 81, 81, 77, 74]], ['Dm', [76, 77, 76, 74, 73, 74]],
  ['A7', [76, 76, 76, 73, 76, 79]], ['A7', [81, 79, 77, 76, 73, 69]],
  ['Dm', [74, 77, 81, 86, 81, 77]], ['Dm', [82, 81, 79, 77, 76, 74]],
  ['Gm', [79, 82, 79, 74, 79, 82]], ['A7', [81, _, 79, 77, 76, 73]],
  ['Gm', [79, 79, 79, 82, 81, 79]], ['Gm', [77, 79, 81, 82, 84, 82]],
  ['Dm', [81, 81, 81, 77, 79, 81]], ['Dm', [86, 84, 82, 81, 79, 77]],
  ['A7', [76, 77, 79, 81, 79, 77]], ['A7', [76, 73, 69, 73, 76, 79]],
  ['Dm', [77, 74, 69, 74, 77, 81]], ['Dm', [74, _, _, 74, _, _]],
];
const shopBars = [
  ['C', [76, _, 79, _, 76, 72]], ['C', [74, _, 76, _, _, _]],
  ['G', [74, _, 71, _, 74, 79]], ['G', [77, _, 76, _, 74, _]],
  ['Am', [76, _, 81, _, 79, 76]], ['Am', [72, _, 76, _, _, _]],
  ['F', [77, _, 76, _, 74, 72]], ['G', [74, _, _, 71, _, _]],
  ['C', [79, _, 84, _, 79, 76]], ['C', [72, _, 76, _, 79, _]],
  ['G', [79, _, 83, _, 81, 79]], ['G', [77, _, 74, _, _, _]],
  ['F', [77, _, 81, _, 79, 77]], ['G', [76, _, 74, _, 71, _]],
  ['C', [72, _, 76, _, 79, _]], ['C', [84, _, _, _, _, _]],
];

const music = {
  // The main theme (the menu): mandolin over accordion "oom-pa-pa", plucked bass and
  // tambourine; a fiddle joins in A2 and leads B; castanets and a frame drum fill A3.
  theme: renderTrack(themeBars, 100, {
    reverb: 0.25,
    beat(buf, at, k, chord, eighth, bar) {
      const part = themePart(bar);
      if (k === 0 || k === 3) pluck(buf, M, at, midi(k === 0 ? chord.root : chord.fifth), 0.6, 0.55, { bright: 0.3, decay: 0.994, seed: bar * 6 + k });
      else accordion(buf, M, at, chord.notes, eighth * 0.7, part === 'B' ? 0.035 : 0.045, { cutoff: 2400 });
      tambourine(buf, M, at, k === 0 || k === 3 ? 0.22 : 0.12, bar * 10 + k);
      if ((part === 'A2' || part === 'A3') && (k === 2 || k === 5)) castanets(buf, M, at, 0.3, bar * 6 + k);
      if (part === 'A3' && k === 0) frameDrum(buf, M, at, 0.5, 100);
      if (part === 'B' && k === 0) frameDrum(buf, M, at, 0.3, 120);
    },
    note(buf, at, m, held, eighth, n) {
      const part = themePart(Math.floor(n / 6));
      const mandolin = part === 'B' ? 0.24 : 0.42;
      pluck(buf, M, at, midi(m), held + 0.3, mandolin, { bright: 0.75, decay: 0.995, seed: n });
      for (let t = eighth / 2; t < held - 0.01; t += eighth / 2) pluck(buf, M, at + t, midi(m), eighth, mandolin * 0.52, { bright: 0.7, decay: 0.993, seed: n + Math.round(t * 100) });
      if (part === 'A2') fiddle(buf, M, at, midi(m - 12), held * 0.92, 0.07, n);
      if (part === 'B') fiddle(buf, M, at, midi(m), held * 0.95, 0.12, n);
      if (part === 'A3') {
        fiddle(buf, M, at, midi(m), held * 0.9, 0.08, n);
        accordion(buf, M, at, [m - 12], held * 0.9, 0.03, { cutoff: 2000 });
      }
    },
  }),
  // The shows (base): the barcarolle, rocking in 6/8: bass, electric piano on the offbeats,
  // a soft pad and a mandolin melody doubled by a breathy flute.
  show: renderTrack(showBars, 60, {
    reverb: 0.35,
    beat(buf, at, k, chord, eighth) {
      if (k === 0) accordion(buf, M, at, chord.notes, eighth * 6, 0.012, { cutoff: 900, attack: 0.5 });
      if (k === 0 || k === 3) softBass(buf, M, at, midi(k === 0 ? chord.root : chord.fifth), eighth * 2.8, 0.42);
      else for (const m of chord.notes) epiano(buf, M, at, midi(m + 12), eighth * (k === 2 || k === 5 ? 1.0 : 0.9), k === 1 || k === 4 ? 0.05 : 0.035);
    },
    note(buf, at, m, held, eighth, n) {
      pluck(buf, M, at, midi(m), held + 0.4, 0.26, { bright: 0.42, decay: 0.996, seed: n });
      flute(buf, M, at, midi(m), held * 0.95, 0.06, n);
    },
  }),
  // The shows (drive): what joins in as the show heats up: a soft kick and brushes, a
  // shaker, a celesta arpeggio and a rim click.
  show_drive: renderTrack(showBars, 60, {
    reverb: 0.3,
    beat(buf, at, k, chord, eighth, bar) {
      if (k === 0) kick(buf, M, at, 0.45);
      if (k === 3) kick(buf, M, at, 0.3);
      noiseHit(buf, M, at, 0.12, k === 0 || k === 3 ? 0.14 : 0.08, { type: 'high', freq: 7000, q: 0.7, attack: 0.01, decay: 0.045, seed: bar * 6 + k + 700 });
      if (k !== 0 && k !== 3) noiseHit(buf, M, at + eighth * 0.5, 0.05, 0.05, { freq: 5200, q: 1.5, decay: 0.012, seed: bar * 6 + k + 900 });
      if (k === 3) clap(buf, M, at, 0.12, bar * 7 + 3);
      const notes = chord.notes;
      bell(buf, M, at, midi(notes[(k + bar) % notes.length] + 24), 0.5, 0.06, { ratio: 4.0, index: 0.9, decay: 0.22 });
    },
    note() {},
  }),
  // The Patron (base): faster, in D minor, every note tremolo-picked over accordion and bass.
  patron: renderTrack(patronBars, 112, {
    reverb: 0.2,
    beat(buf, at, k, chord, eighth, bar) {
      if (k === 0 || k === 3) pluck(buf, M, at, midi(k === 0 ? chord.root : chord.fifth), 0.5, 0.6, { bright: 0.45, decay: 0.993, seed: bar * 6 + k });
      else accordion(buf, M, at, chord.notes, eighth * 0.6, 0.05, { cutoff: 1800 });
      tambourine(buf, M, at, k === 0 || k === 3 ? 0.14 : 0.08, bar * 10 + k + 500);
    },
    note(buf, at, m, held, eighth, n) {
      for (let t = 0; t < held - 0.01; t += eighth / 2) pluck(buf, M, at + t, midi(m), eighth * 0.9, t === 0 ? 0.42 : 0.28, { bright: 0.8, decay: 0.992, seed: n * 3 + Math.round(t * 100) });
      pluck(buf, M, at, midi(m - 12), held, 0.18, { bright: 0.5, decay: 0.994, seed: n + 900 });
    },
  }),
  // The Patron (drive): kick, claps, frame drum and a fiddle an octave below the tune.
  patron_drive: renderTrack(patronBars, 112, {
    reverb: 0.2,
    beat(buf, at, k, chord, eighth, bar) {
      if (k === 0 || k === 3) kick(buf, M, at, 0.6);
      if (k === 3) clap(buf, M, at, 0.4, bar * 7);
      if (k === 5) frameDrum(buf, M, at, 0.35, 130);
      tambourine(buf, M, at, k === 0 || k === 3 ? 0.16 : 0.1, bar * 10 + k + 800);
    },
    note(buf, at, m, held, eighth, n) {
      fiddle(buf, M, at, midi(m - 12), held * 0.9, 0.09, n + 40);
    },
  }),
  // The shop: a music box over pizzicato bass and a soft accordion pad.
  shop: renderTrack(shopBars, 84, {
    reverb: 0.35,
    beat(buf, at, k, chord, eighth, bar) {
      if (k === 0) accordion(buf, M, at, chord.notes, eighth * 6, 0.022, { cutoff: 1400, attack: 0.25 });
      if (k === 0 || k === 3) pluck(buf, M, at, midi(k === 0 ? chord.root : chord.fifth), 0.5, 0.5, { bright: 0.25, decay: 0.99, seed: bar * 6 + k + 300 });
      if (k === 1 || k === 4) noiseHit(buf, M, at, 0.06, 0.06, { type: 'high', freq: 8000, q: 0.7, decay: 0.015, seed: bar * 6 + k });
    },
    note(buf, at, m, held, eighth, n) {
      bell(buf, M, at, midi(m), held + 0.8, 0.32, { ratio: 4.0, index: 1.2, decay: 0.45 });
      bell(buf, M, at, midi(m + 12), 0.5, 0.06, { ratio: 3.0, index: 0.8, decay: 0.2 });
    },
  }),
};

// --- write everything ---

for (const [name, samples] of Object.entries(sfx)) {
  writeWav(path.join(OUT, 'sfx', `${name}.wav`), samples, SFX_RATE);
}
for (const [name, track] of Object.entries(music)) {
  writeWav(path.join(OUT, 'music', `${name}.wav`), track.samples, MUSIC_RATE);
}
const report = (name, samples, rate) => {
  let peak = 0;
  let sum = 0;
  for (const v of samples) { peak = Math.max(peak, Math.abs(v)); sum += v * v; }
  const rms = Math.sqrt(sum / samples.length);
  return `${name.padEnd(14)} ${(samples.length / rate).toFixed(2).padStart(6)} s  peak ${peak.toFixed(2)}  rms ${(20 * Math.log10(rms + 1e-9)).toFixed(1)} dB`;
};
for (const [name, samples] of Object.entries(sfx)) console.log(report(`sfx/${name}`, samples, SFX_RATE));
for (const [name, track] of Object.entries(music)) console.log(report(`music/${name}`, track.samples, MUSIC_RATE));
