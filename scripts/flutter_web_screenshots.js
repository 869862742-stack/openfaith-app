const { chromium } = require('playwright');
const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 8080;
const WIDTH = 393;
const HEIGHT = 852;
const OUTPUT_DIR = path.join(__dirname, '..', 'screenshots', 'flutter-mobile');

const PAGES = [
  ['01', 'home', '/'],
  ['02', 'learn', '/learn'],
  ['03', 'religion_1', '/religion/1'],
  ['04', 'religion_2', '/religion/2'],
  ['05', 'book_1', '/book/1'],
  ['06', 'messages', '/messages'],
  ['07', 'chat_1', '/chat/1'],
  ['08', 'group_chat_1', '/group-chat/1'],
  ['09', 'profile', '/profile'],
  ['10', 'vip', '/vip'],
  ['11', 'settings', '/settings'],
  ['12', 'account', '/account'],
  ['13', 'notification', '/notification'],
  ['14', 'display', '/display'],
  ['15', 'language', '/language'],
  ['16', 'content', '/content'],
  ['17', 'switch', '/switch'],
  ['18', 'publish_note', '/publish/note'],
  ['19', 'publish_video', '/publish/video'],
  ['20', 'publish_plan', '/publish/plan'],
  ['21', 'drafts', '/drafts'],
  ['22', 'history', '/history'],
  ['23', 'downloads', '/downloads'],
  ['24', 'covenant', '/covenant'],
  ['25', 'scan', '/scan'],
  ['26', 'support', '/support'],
  ['27', 'gongjing', '/gongjing'],
  ['28', 'room_1', '/room/1'],
  ['29', 'privacy', '/privacy'],
  ['30', 'terms', '/terms'],
  ['31', 'welcome', '/welcome'],
  ['32', 'login', '/login'],
  ['33', 'register', '/register'],
  ['34', 'add_friend', '/add/friend'],
  ['35', 'add_group', '/add/group'],
  ['36', 'user_1', '/user/1'],
];

function startServer() {
  const buildDir = path.join(__dirname, '..', 'build', 'web');
  return new Promise((resolve, reject) => {
    const server = http.createServer((req, res) => {
      let urlPath = req.url.split('?')[0];
      let filePath = path.join(buildDir, urlPath === '/' ? 'index.html' : urlPath);
      const ext = path.extname(filePath);
      const mimeTypes = {
        '.html': 'text/html', '.js': 'application/javascript',
        '.css': 'text/css', '.json': 'application/json',
        '.png': 'image/png', '.jpg': 'image/jpeg',
        '.svg': 'image/svg+xml', '.wasm': 'application/wasm',
        '.ico': 'image/x-icon',
      };
      const contentType = mimeTypes[ext] || 'application/octet-stream';
      fs.readFile(filePath, (err, data) => {
        if (err) {
          fs.readFile(path.join(buildDir, 'index.html'), (err2, data2) => {
            if (err2) { res.writeHead(404); res.end(); }
            else { res.writeHead(200, { 'Content-Type': 'text/html' }); res.end(data2); }
          });
        } else {
          res.writeHead(200, { 'Content-Type': contentType });
          res.end(data);
        }
      });
    });
    server.listen(PORT, () => resolve(server));
    server.on('error', reject);
  });
}

async function main() {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  console.log('Starting HTTP server...');
  const server = await startServer();
  console.log('Server running on http://localhost:' + PORT);

  console.log('Launching browser...');
  const browser = await chromium.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage',
           '--use-gl=swiftshader', '--enable-webgl', '--ignore-gpu-blocklist'],
  });

  const context = await browser.newContext({
    viewport: { width: WIDTH, height: HEIGHT },
    userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X)',
    deviceScaleFactor: 2,
  });
  const page = await context.newPage();

  console.log('Loading Flutter Web app...');
  await page.goto('http://localhost:' + PORT + '/', { waitUntil: 'networkidle', timeout: 60000 });
  console.log('Waiting for Flutter CanvasKit initialization (15s)...');
  await page.waitForTimeout(15000);

  const canvasCount = await page.locator('canvas').count();
  console.log('Canvas elements: ' + canvasCount);

  for (const [idx, name, route] of PAGES) {
    try {
      console.log('[' + idx + '] ' + name + '...');
      await page.evaluate((r) => { window.location.hash = '#' + r; }, route);
      await page.waitForTimeout(5000);
      const filePath = path.join(OUTPUT_DIR, 'flutter_' + idx + '_' + name + '.png');
      await page.screenshot({ path: filePath });
      const stats = fs.statSync(filePath);
      console.log('  -> ' + stats.size + ' bytes');
    } catch (err) {
      console.error('[' + idx + '] FAILED: ' + err.message);
    }
  }

  await browser.close();
  server.close();
  console.log('Done!');
}

main().catch(console.error);
