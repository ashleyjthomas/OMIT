// Headless end-to-end run of the OMIT3 task for a given version.
// Serves chs/ over http, loads a local-CDN copy of index.html, auto-plays through,
// dumps the data CSV and takes screenshots of key pages.
const { chromium } = require('playwright');
const http = require('http'); const fs = require('fs'); const path = require('path');
const ROOT = path.resolve(__dirname, '..');
const version = process.argv[2] || 'V1';
const shots = process.argv[3] === 'shots';
const mime = { '.html': 'text/html', '.js': 'application/javascript', '.css': 'text/css', '.png': 'image/png', '.mp3': 'audio/mpeg', '.json': 'application/json' };
const server = http.createServer((req, res) => {
  let p = decodeURIComponent(req.url.split('?')[0]);
  if (p === '/' || p === '/index.html') {
    let html = fs.readFileSync(path.join(ROOT, 'index.html'), 'utf8')
      .replace(/https:\/\/cdn.jsdelivr.net\/npm\/jspsych@7.3.4\/dist\//g, '/test/node_modules/jspsych/dist/')
      .replace(/https:\/\/cdn.jsdelivr.net\/npm\/jspsych@7.3.4\/css\//g, '/test/node_modules/jspsych/css/')
      .replace(/https:\/\/cdn.jsdelivr.net\/npm\/@jspsych\/plugin-preload@1.1.3\/dist\//g, '/test/node_modules/@jspsych/plugin-preload/dist/')
      .replace(/https:\/\/cdn.jsdelivr.net\/npm\/@jspsych\/plugin-html-button-response@1.2.0\/dist\//g, '/test/node_modules/@jspsych/plugin-html-button-response/dist/');
    res.writeHead(200, { 'content-type': 'text/html' }); return res.end(html);
  }
  if (p === '/favicon.ico') { res.writeHead(204); return res.end(); }
  const f = path.join(ROOT, p);
  if (!fs.existsSync(f) || fs.statSync(f).isDirectory()) { res.writeHead(404); return res.end(); }
  res.writeHead(200, { 'content-type': mime[path.extname(f)] || 'application/octet-stream' }); fs.createReadStream(f).pipe(res);
});
(async () => {
  await new Promise((r) => server.listen(0, r));
  const port = server.address().port;
  const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium', args: ['--headless=new', '--autoplay-policy=no-user-gesture-required', '--mute-audio'] });
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  const errors = [];
  page.on('pageerror', (e) => errors.push('PAGEERROR ' + e.message));
  page.on('console', (m) => { if (m.type() === 'error') errors.push('CONSOLE ' + m.text()); });
  page.on('requestfailed', (r) => errors.push('REQFAIL ' + r.url()));
  page.on('response', (r) => { if (r.status() >= 400) errors.push('HTTP' + r.status() + ' ' + r.url()); });
  await page.goto(`http://localhost:${port}/?version=${version}`);
  await page.click('button:has-text("Start")', { timeout: 60000 });
  const outDir = path.join(__dirname, 'out'); fs.mkdirSync(outDir, { recursive: true });
  let step = 0; const seen = new Set();
  const start = Date.now();
  while (!(await page.evaluate(() => window.OMIT3_DONE)) && Date.now() - start < 600000) {
    // zones ready? click a random one (alternate sides so both get exercised)
    const ready = await page.$('.omit3-stage.ready .zone');
    const item = await page.evaluate(() => (window.jsPsych && jsPsych.getCurrentTrial() && jsPsych.getCurrentTrial().data) ? jsPsych.getCurrentTrial().data.item + '|' + (jsPsych.getCurrentTrial().data.trial || 'pr') : '');
    if (shots && item && !seen.has(item)) { seen.add(item); await page.screenshot({ path: path.join(outDir, `${version}_${String(step).padStart(2, '0')}_${item.replace('|', '_')}.png`) }); }
    if (ready) {
      const zones = await page.$$('.omit3-stage.ready .zone');
      await zones[step % 2].click(); step++;
      await page.waitForTimeout(300);
      continue;
    }
    const next = await page.$('.omit3-next');
    if (next && await next.isVisible()) { await next.click(); step++; await page.waitForTimeout(200); continue; }
    await page.waitForTimeout(150);
  }
  const csv = await page.evaluate(() => jsPsych.data.get().filter({ trial_type: 'omit3-scene' }).csv());
  fs.writeFileSync(path.join(outDir, `data_${version}.csv`), csv);
  console.log('version', version, 'done in', Math.round((Date.now() - start) / 1000), 's; rows', csv.split('\n').length - 2);
  const uniq = [...new Set(errors)]; if (uniq.length) console.log('ERRORS:\n' + uniq.slice(0, 20).join('\n'));
  await browser.close(); server.close();
})();
