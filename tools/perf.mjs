// Frame timing of the web build in headless Chrome on the real GPU (no window opens).
//   node tools/perf.mjs [--screens menu,show,scoring,shop] [--width 844 --height 390 --scale 3]
//                       [--seconds 5] [--throttle 4] [--angle d3d11] [--quality 0-2 --crt 0-2 --fps 30]
// For each screen it opens /preview/?screen=<name>, lets it settle, then records every
// frame's time for a few seconds: average fps, the 95th-percentile frame, frames over 25 ms,
// and the engine's own numbers (draw calls, process time). --throttle slows the CPU like a
// phone (Chrome's CPU throttling). Needs tools/export_web.ps1 and the web server on :3790.
import puppeteer from 'puppeteer-core';

const options = {};
const argv = process.argv.slice(2);
for (let i = 0; i < argv.length; i += 2) options[argv[i].replace(/^--/, '')] = argv[i + 1];
const screens = (options.screens || 'menu,show,scoring,shop').split(',');
const width = Number(options.width || 844);
const height = Number(options.height || 390);
const scale = Number(options.scale || 3);
const seconds = Number(options.seconds || 5);
const throttle = Number(options.throttle || 1);
const port = options.port || 3790;
const chrome = options.chrome || 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const browser = await puppeteer.launch({
  executablePath: chrome,
  headless: true,
  args: [`--use-angle=${options.angle || 'd3d11'}`, '--ignore-gpu-blocklist', '--enable-gpu-rasterization', '--mute-audio'],
});
try {
  let gpuShown = false;
  for (const screen of screens) {
    const context = await browser.createBrowserContext();
    const page = await context.newPage();
    await page.setViewport({ width, height, deviceScaleFactor: scale });
    if (throttle > 1) {
      const cdp = await page.createCDPSession();
      await cdp.send('Emulation.setCPUThrottlingRate', { rate: throttle });
    }
    const errors = [];
    const longLog = [];
    page.on('pageerror', (e) => errors.push(String(e)));
    page.on('console', (m) => {
      if (m.text().startsWith('LONG FRAME')) longLog.push(m.text());
      if (m.text().startsWith('TIMING')) console.log('    ' + m.text());
    });
    const extra = ['quality', 'crt', 'fps', 'swirl', 'cardfx', 'fx'].filter((k) => options[k] !== undefined).map((k) => `&${k}=${options[k]}`).join('');
    await page.goto(`http://localhost:${port}/preview/?screen=${screen}${extra}`, { waitUntil: 'load' });
    if (!gpuShown) {
      const gpu = await page.evaluate(() => {
        const gl = document.createElement('canvas').getContext('webgl2');
        const info = gl && gl.getExtension('WEBGL_debug_renderer_info');
        return info ? gl.getParameter(info.UNMASKED_RENDERER_WEBGL) : 'unknown';
      });
      console.log(`GPU: ${gpu}  |  ${width}x${height} @${scale}x, CPU throttle ${throttle}x`);
      gpuShown = true;
    }
    // Let the engine load, bake the cards and settle; the scoring screen is timed from the
    // moment its hand is played (it sets window.foolsScoring), so the window is the scoring.
    if (screen === 'scoring') {
      await page.waitForFunction(() => window.foolsScoring, { timeout: 60000, polling: 50 });
      longLog.length = 0;
    } else {
      await sleep(7000);
    }
    const frames = await page.evaluate((ms) => new Promise((resolve) => {
      const times = [];
      let last = performance.now();
      const end = last + ms;
      const tick = (now) => {
        times.push(now - last);
        last = now;
        if (now < end) requestAnimationFrame(tick);
        else resolve(times);
      };
      requestAnimationFrame(tick);
    }), seconds * 1000);
    frames.shift();
    const sorted = [...frames].sort((a, b) => a - b);
    const avg = frames.reduce((s, v) => s + v, 0) / frames.length;
    const p95 = sorted[Math.floor(sorted.length * 0.95)];
    const worst = sorted[sorted.length - 1];
    const long = frames.filter((t) => t > 25).length;
    const perf = await page.evaluate(() => window.foolsPerf || null);
    const m1 = await page.metrics();
    await sleep(2000);
    const m2 = await page.metrics();
    const busy = ((m2.TaskDuration - m1.TaskDuration) / ((m2.Timestamp - m1.Timestamp) || 1)) * 100;
    console.log(`  main thread busy ${busy.toFixed(0)}% of the time`);
    console.log(`${screen.padEnd(8)} ${(1000 / avg).toFixed(1).padStart(5)} fps  avg ${avg.toFixed(1)} ms  p95 ${p95.toFixed(1)} ms  worst ${worst.toFixed(1)} ms  ${long} frames >25 ms of ${frames.length}` +
      (perf ? `  | engine ${perf.process_ms} ms process, ${perf.draw_calls} draws, ${perf.objects} objects, textures ${perf.texture_mb} MB, ${perf.viewports} viewports` : '') +
      (errors.length ? `\n  ERRORS: ${errors.join('\n  ')}` : ''));
    if (options.long) for (const l of longLog) console.log('    ' + l);
    await context.close();
  }
} finally {
  await browser.close();
}
