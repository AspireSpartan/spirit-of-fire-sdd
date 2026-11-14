// Spirit of Fire browser-check harness: smoke test. Prints "<playwright-core version> <axe-core version> ok".
// Run: node "<harness folder>\smoke.cjs". Reads the browser path from harness.json (PW_EXECUTABLE overrides).
// Opens an in-memory page only: no network, no project, no dev server.
'use strict';
const fs = require('fs');
const path = require('path');
const h = __dirname;
const mod = (name) => path.join(h, 'node_modules', name);
let cfg = {};
try { cfg = JSON.parse(fs.readFileSync(path.join(h, 'harness.json'), 'utf8')); } catch { /* fall back to PW_EXECUTABLE */ }
const exe = process.env.PW_EXECUTABLE || cfg.headless;
(async () => {
  if (!exe || !fs.existsSync(exe)) throw new Error(`browser not found: ${exe || 'no path in harness.json'}`);
  const { chromium } = require(mod('playwright-core'));
  const browser = await chromium.launch({ executablePath: exe });
  try {
    const page = await browser.newPage();
    await page.setContent('<title>ok</title><main><h1>x</h1></main>');
    await page.addScriptTag({ path: path.join(mod('axe-core'), 'axe.min.js') });
    const axeVersion = await page.evaluate(() => window.axe.version);
    console.log(require(path.join(mod('playwright-core'), 'package.json')).version, axeVersion, await page.title());
  } finally {
    await browser.close();
  }
})().catch((e) => { console.error(`smoke failed: ${String(e.message).split('\n')[0]}`); process.exit(1); });
