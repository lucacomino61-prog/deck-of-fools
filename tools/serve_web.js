// Serves the web export (build/web) for previews: node tools/serve_web.js [port]
// /preview/ serves build/web-preview, the build that opens one screen from ?screen=
// (tools/export_web.ps1 makes both). Sends the cross-origin isolation headers Godot's
// threaded builds need. With a certificate from tools/phone_cert.ps1 it also serves HTTPS on
// port + 1, for a phone on the same network.
const http = require('http');
const https = require('https');
const os = require('os');
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..', 'build', 'web');
const previewRoot = path.join(__dirname, '..', 'build', 'web-preview');
// /sounds/ is a page to listen to every sound effect and music loop in game/audio.
const audioRoot = path.join(__dirname, '..', 'game', 'audio');
const port = Number(process.argv[2] || process.env.PORT || 3790);
const types = {
  '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm',
  '.pck': 'application/octet-stream', '.png': 'image/png', '.svg': 'image/svg+xml', '.wav': 'audio/wav',
  '.webp': 'image/webp', '.woff2': 'font/woff2',
};

if (!fs.existsSync(path.join(root, 'index.html'))) {
  console.error(`No web build in ${root}. Export the "Web" preset first.`);
  process.exit(1);
}

const serve = (req, res) => {
  let name = decodeURIComponent(req.url.split('?')[0]);
  let base = root;
  if (name.startsWith('/preview/')) {
    base = previewRoot;
    name = name.slice('/preview'.length);
  } else if (name === '/sounds/list.json') {
    const list = (dir) => fs.readdirSync(path.join(audioRoot, dir)).filter((f) => f.endsWith('.wav')).map((f) => f.slice(0, -4));
    res.writeHead(200, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' });
    res.end(JSON.stringify({ music: list('music'), sfx: list('sfx') }));
    return;
  } else if (name === '/sounds/') {
    base = path.join(__dirname, 'audio');
    name = '/board.html';
  } else if (name.startsWith('/sounds/')) {
    base = audioRoot;
    name = name.slice('/sounds'.length);
  }
  const file = path.join(base, name === '/' ? 'index.html' : name);
  if (!file.startsWith(base) || !fs.existsSync(file)) {
    res.writeHead(404);
    res.end('not found');
    return;
  }
  res.writeHead(200, {
    'Content-Type': types[path.extname(file)] || 'application/octet-stream',
    'Content-Length': fs.statSync(file).size,
    'Cross-Origin-Opener-Policy': 'same-origin',
    'Cross-Origin-Embedder-Policy': 'require-corp',
    'Cache-Control': 'no-store',
  });
  fs.createReadStream(file).pipe(res);
};

http.createServer(serve).listen(port, () => console.log(`Deck of Fools web build on http://localhost:${port}`));

// Godot's web build only starts in a secure context: localhost is one, but a phone reaches this
// computer by its network address, which needs HTTPS.
const certDir = path.join(__dirname, '..', 'build', 'cert');
if (fs.existsSync(path.join(certDir, 'cert.pem'))) {
  const tls = { key: fs.readFileSync(path.join(certDir, 'key.pem')), cert: fs.readFileSync(path.join(certDir, 'cert.pem')) };
  const addresses = Object.values(os.networkInterfaces()).flat().filter((a) => a.family === 'IPv4' && !a.internal);
  https.createServer(tls, serve).listen(port + 1, () => {
    for (const a of addresses) console.log(`On a phone on the same network: https://${a.address}:${port + 1}`);
  });
}
