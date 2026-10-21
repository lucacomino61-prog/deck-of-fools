// Screenshots of the web build in headless Chrome: no window opens on the desktop.
//   node tools/shoot.mjs --out <dir> [--screens menu,help,choose,show,scoring,shop]
//                        [--width 844 --height 390 --scale 2 --wait 6000]
// Needs tools/export_web.ps1 run first and the web server up (node tools/serve_web.js).
// Each screen opens /preview/?screen=<name> in a fresh browser context (fresh save data).
// "scoring" also saves timed frames while the hand scores. Prints any page errors.
import puppeteer from 'puppeteer-core';
import fs from 'node:fs';
import path from 'node:path';

const options = {};
const argv = process.argv.slice(2);
for (let i = 0; i < argv.length; i += 2) options[argv[i].replace(/^--/, '')] = argv[i + 1];
if (!options.out) {
  console.error('usage: node tools/shoot.mjs --out <dir> [--screens a,b] [--width W --height H --scale S --wait MS]');
  process.exit(1);
}
const screens = (options.screens || 'menu').split(',');
const width = Number(options.width || 844);
const height = Number(options.height || 390);
const scale = Number(options.scale || 2);
const wait = Number(options.wait || 6000);
const port = options.port || 3790;
const chrome = options.chrome || 'C:/Program Files/Google/Chrome/Application/chrome.exe';
fs.mkdirSync(options.out, { recursive: true });

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const browser = await puppeteer.launch({
  executablePath: chrome,
  headless: true,
  args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--mute-audio'],
});
let failed = false;
try {
  for (const screen of screens) {
    const context = await browser.createBrowserContext();
    const page = await context.newPage();
    await page.setViewport({ width, height, deviceScaleFactor: scale });
    const errors = [];
    // A scripted preview plays without a real tap, so Chrome blocks vibration: expected here.
    page.on('console', (m) => {
      if (m.type() === 'error' && !m.text().includes('navigator.vibrate')) errors.push(m.text());
    });
    page.on('pageerror', (e) => errors.push(String(e)));
    await page.goto(`http://localhost:${port}/preview/?screen=${screen}`, { waitUntil: 'load' });
    await sleep(wait);
    if (screen === 'scoring') {
      for (const ms of [0, 500, 1000, 1600, 2400]) {
        await page.screenshot({ path: path.join(options.out, `scoring_${ms}.png`) });
        await sleep(ms === 0 ? 500 : 600);
      }
    }
    const file = path.join(options.out, `${screen}.png`);
    await page.screenshot({ path: file });
    const perf = await page.evaluate(() => window.foolsPerf || null);
    const perfText = perf ? `  [${perf.fps} fps, ${perf.process_ms} ms script, ${perf.draw_calls} draw calls, ${perf.objects} objects]` : '';
    console.log(`${screen}: ${file}${perfText}${errors.length ? '\n  ERRORS: ' + errors.join('\n  ') : ''}`);
    if (errors.length) failed = true;
    await context.close();
  }
} finally {
  await browser.close();
}
process.exit(failed ? 1 : 0);
