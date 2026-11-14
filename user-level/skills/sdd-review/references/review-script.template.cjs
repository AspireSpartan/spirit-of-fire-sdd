// Standard browser review script (CommonJS, Node 24). Copy to the session scratchpad as review-TASK-N.cjs,
// fill the CONFIG block, run from the project's repo root (EVIDENCE_DIR defaults to process.cwd()):
//   node <scratchpad>/review-TASK-N.cjs [--headed]. Never put the copy in the repo.
// Read-only by default: it opens pages and overlays but saves nothing. Add save paths at the marked
// section near the bottom. How to use it: review-script.md in this folder.
'use strict';
const fs = require('fs');
const os = require('os');
const path = require('path');

// ------------------------------- CONFIG (edit this block) -------------------------------
// Harness: global install in ~/.claude/tools/pw-harness; a project-only install puts it in <project>/.claude/tools/pw-harness
// (set PW_HARNESS to that folder). The installer writes harness.json there with the cached browser paths (see HARNESS.md).
const HARNESS = process.env.PW_HARNESS || path.join(os.homedir(), '.claude', 'tools', 'pw-harness');
const HARNESS_JSON = (() => { try { return JSON.parse(fs.readFileSync(path.join(HARNESS, 'harness.json'), 'utf8')); } catch { return {}; } })();
const EXECUTABLE = process.env.PW_EXECUTABLE || HARNESS_JSON.headless || '';          // headless shell
const EXECUTABLE_VISIBLE = process.env.PW_EXECUTABLE_VISIBLE || HARNESS_JSON.visible || '';  // full Chromium, only for --headed
const BASE_URL = process.env.BASE_URL || 'http://localhost:<PORT>';
const TASK = process.env.TASK || 'TASK-N';                  // names the evidence folder
const EVIDENCE_DIR = process.env.EVIDENCE_DIR || path.join(process.cwd(), '.agents', 'evidence', TASK);
// The password is read from the env var named here, set by the reviewer for the run. Never write it in this file.
const ROLES = [
  // { name: 'admin', email: '<account email>', passwordEnv: 'REVIEW_PW_ADMIN' },
];
const LOGIN = { url: '/login', email: 'input[name=email]', password: 'input[name=password]', submit: 'button[type=submit]' };
const READY = 'main';                                        // selector that proves the page rendered
const WARMUP_MS = 90000;                                     // budget for the unmeasured warm-up visits and the login form (cold dev compile); measured checks keep their own timeouts
// Optional per route: ready = a selector for the data the page shows (e.g. a list row), waited for after READY (15 s).
// Optional per route: readyRoles = ['role', ...]; the ready wait runs only for those roles (absent = every role).
// Optional per overlay: setup = async (page, { role, route, vp }) => {}; runs after the page opens, before the opener click.
//   Client state only (clicks, typing). No database writes unless the task says so. A throw logs FAIL "setup failed" and skips the overlay.
// Optional per overlay: vp = [widths]; at other widths the overlay logs INFO "not expected at this viewport" and is not clicked.
// Overlays without vp run at every width. An opener that is not visible is retried for 6 s before it is skipped.
const ROUTES = [
  // { path: '/', roles: ['admin'], ready: '<selector for loaded data>', overlays: [{ name: 'add-entry', opener: 'button[aria-label="Add entry"]', vp: [1280] }] },
];
const VIEWPORTS = [{ w: 360, h: 780 }, { w: 390, h: 844 }, { w: 1280, h: 800 }];
const ZOOM = { w: 640, h: 400 };                             // 1280x800 at 200%
// Known axe items (the project's baseline). route '*' = any route; vp optional list of widths.
const KNOWN_AXE = [
  // { rule: 'color-contrast', route: '/', vp: [1280] },
];
const AXE_TAGS = ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'];
const TAB_STOPS = 40;
const HEADED = process.argv.includes('--headed');
const SLOWMO = HEADED ? 300 : 0;
const DIALOG = '[role=dialog],[role=alertdialog]';
// ----------------------------------------------------------------------------------------

const { chromium } = require(path.join(HARNESS, 'node_modules', 'playwright-core'));
const AXE_PATH = path.join(HARNESS, 'node_modules', 'axe-core', 'axe.min.js');
fs.mkdirSync(EVIDENCE_DIR, { recursive: true });

const lines = [];
const totals = { PASS: 0, FAIL: 0, INFO: 0, newAxe: 0 };
function log(level, role, route, vp, check, detail, quiet) {
  const line = `${level} ${role} ${route} ${vp} ${check} ${detail || ''}`.trim();
  lines.push(line);
  totals[level]++;
  if (!quiet || process.env.VERBOSE) console.log(line);
}
const slug = (p) => (p === '/' ? 'root' : p.replace(/^\//, '').replace(/[^a-z0-9]+/gi, '-'));
const shot = (page, role, route, suffix) =>
  page.screenshot({ path: path.join(EVIDENCE_DIR, `${role}-${slug(route)}-${suffix}.png`) });

// Describe the element that has focus: tag, accessible name, visible focus indicator, inside a dialog?
const focusInfo = () => {
  const e = document.activeElement;
  if (!e || e === document.body || e === document.documentElement) return { tag: 'BODY' };
  const cs = getComputedStyle(e);
  const ref = (e.getAttribute('aria-labelledby') || '').split(' ').map((i) => (document.getElementById(i) || {}).innerText || '').join(' ');
  const name = (e.getAttribute('aria-label') || ref || e.innerText || e.getAttribute('title') || e.getAttribute('alt') || e.value || e.getAttribute('placeholder') || '')
    .replace(/\s+/g, ' ').trim().slice(0, 40);
  const ring = (cs.outlineStyle !== 'none' && (parseFloat(cs.outlineWidth) || 0) > 0) || cs.boxShadow !== 'none';
  return { tag: e.tagName, name, ring, field: /^(INPUT|SELECT|TEXTAREA)$/.test(e.tagName), html: e.outerHTML.slice(0, 90), inDialog: !!e.closest('[role=dialog],[role=alertdialog]') };
};

// Warm-up: unmeasured first visits that absorb a cold dev compile. A slow or failed warm-up logs INFO only, never FAIL.
let loginWarmed = false;
async function warmLogin(page) {
  if (loginWarmed) return;
  loginWarmed = true;
  const t0 = Date.now();
  try {
    await page.goto(BASE_URL + LOGIN.url, { timeout: WARMUP_MS });
    await page.locator(LOGIN.email).waitFor({ state: 'visible', timeout: WARMUP_MS });
    log('INFO', '-', LOGIN.url, '-', 'warm-up', `login page ready in ${Math.round((Date.now() - t0) / 1000)} s`);
  } catch (e) {
    log('INFO', '-', LOGIN.url, '-', 'warm-up', `login page slow or failed after ${Math.round((Date.now() - t0) / 1000)} s: ${String(e.message).replace(/\s+/g, ' ').slice(0, 120)}`);
  }
}
const warmedRoutes = new Set();
async function warmRoute(page, route) {
  if (warmedRoutes.has(route.path)) return;                  // once per run, keyed by path
  warmedRoutes.add(route.path);
  const t0 = Date.now();
  try {
    await page.goto(BASE_URL + route.path, { waitUntil: 'load', timeout: WARMUP_MS });
    await page.locator(READY).first().waitFor({ state: 'visible', timeout: WARMUP_MS });
    log('INFO', '-', route.path, '-', 'warm-up', `page ready in ${Math.round((Date.now() - t0) / 1000)} s`);
  } catch (e) {
    log('INFO', '-', route.path, '-', 'warm-up', `slow or failed after ${Math.round((Date.now() - t0) / 1000)} s: ${String(e.message).replace(/\s+/g, ' ').slice(0, 120)}`);
  }
}

async function login(page, r) {
  const pw = process.env[r.passwordEnv];
  if (!pw) throw new Error(`env var ${r.passwordEnv} is not set (password for ${r.name})`);
  await warmLogin(page);
  await page.goto(BASE_URL + LOGIN.url);
  await page.locator(LOGIN.email).fill(r.email, { timeout: WARMUP_MS });
  await page.locator(LOGIN.password).fill(pw, { timeout: WARMUP_MS });
  await page.locator(LOGIN.submit).click({ timeout: WARMUP_MS });
  await page.waitForURL((u) => !u.pathname.startsWith(LOGIN.url), { timeout: WARMUP_MS });
  log('PASS', r.name, LOGIN.url, '-', 'login', 'signed in through the form');
}

// route = the ROUTES entry. Waits for READY, then for route.ready when set. A missing ready selector is logged once per role, route and width.
const readyMissing = new Set();
async function open(page, route, role = '-', vp = '-') {
  await page.goto(BASE_URL + route.path, { waitUntil: 'load' });
  await page.locator(READY).first().waitFor({ state: 'visible', timeout: 30000 });
  const rkey = `${role}|${route.path}|${vp}`;
  if (route.ready && (!route.readyRoles || route.readyRoles.includes(role)) && !readyMissing.has(rkey)) {
    try { await page.locator(route.ready).filter({ visible: true }).first().waitFor({ state: 'visible', timeout: 15000 }); }   // the first DOM match may be hidden at this width
    catch { readyMissing.add(rkey); log('FAIL', role, route.path, vp, 'open', `ready selector "${route.ready}" never appeared`); }
  }
}

const sideways = (page) => page.evaluate(() => ({ sw: document.documentElement.scrollWidth, cw: document.documentElement.clientWidth }));

async function axeCheck(page, role, route, vp) {
  await page.addScriptTag({ path: AXE_PATH });
  const res = await page.evaluate((tags) => axe.run(document, { runOnly: { type: 'tag', values: tags } }), AXE_TAGS);
  if (!res.violations.length) return log('PASS', role, route, vp, 'axe', '0 violations');
  for (const v of res.violations) {
    const known = KNOWN_AXE.some((k) => k.rule === v.id && (k.route === '*' || k.route === route) && (!k.vp || k.vp.includes(vp)));
    const first = (v.nodes[0] && v.nodes[0].target.join(' ')) || '';
    const detail = `${known ? 'baseline' : 'NEW'} ${v.id} nodes=${v.nodes.length} first=${first.slice(0, 80)}`;
    if (known) log('INFO', role, route, vp, 'axe', detail);
    else { totals.newAxe++; log('FAIL', role, route, vp, 'axe', detail); }
  }
}

async function keyboardWalk(page, role, route, vp) {
  // Tab order wraps through the browser UI, so one BODY stop after the last control is normal; BODY at the start or twice in a row is lost focus.
  let lost = 0, noRing = 0, fieldOnly = 0, noName = 0, prevBody = false, seen = 0;
  const bad = [];
  for (let i = 1; i <= TAB_STOPS; i++) {
    await page.keyboard.press('Tab');
    const f = await page.evaluate(focusInfo);
    lines.push(`INFO ${role} ${route} ${vp} tab#${i} ${f.tag} "${f.name || ''}" indicator=${f.ring ? 'yes' : 'no'}`);
    if (f.tag.startsWith('NEXTJS')) continue;                // dev-only overlay element, not part of the app
    if (f.tag === 'BODY' && (prevBody || seen === 0)) { lost++; bad.push(`#${i} focus lost`); }   // BODY at the start or twice in a row
    prevBody = f.tag === 'BODY';
    seen++;
    if (!prevBody) {
      if (!f.ring && f.field) fieldOnly++;                   // fields often show focus by border colour: check the screenshot
      else if (!f.ring) { noRing++; bad.push(`#${i} ${f.tag} "${f.name}" no indicator`); }
      if (!f.name) noName++;
    }
  }
  await page.keyboard.press('Shift+Tab');
  const back = await page.evaluate(focusInfo);
  lines.push(`INFO ${role} ${route} ${vp} shift-tab ${back.tag} "${back.name || ''}"`);
  const detail = `${TAB_STOPS} stops, focus lost ${lost}, no indicator ${noRing}, field without outline/shadow ${fieldOnly}, unnamed ${noName}${bad.length ? '; first: ' + bad.slice(0, 3).join(' | ') : ''}`;
  log(lost || noRing ? 'FAIL' : 'PASS', role, route, vp, 'keyboard', detail);
}

// Opens the overlay on a fresh page; returns { opener, dialog } or null (after logging why).
async function openOverlay(page, role, rt, vp, ov, check) {
  const route = rt.path;
  await open(page, rt, role, vp);                            // fresh page each time
  if (ov.setup) {                                            // optional client-state steps before the opener (see CONFIG)
    try { await ov.setup(page, { role, route, vp }); }
    catch (e) { log('FAIL', role, route, vp, check, `setup failed: ${String(e.message).replace(/\s+/g, ' ').slice(0, 200)}`); return null; }
  }
  const opener = page.locator(ov.opener).first();
  try { await opener.waitFor({ state: 'visible', timeout: 6000 }); } catch { /* not visible within 6 s: skipped below */ }
  if (!(await opener.count()) || !(await opener.isVisible())) { log('INFO', role, route, vp, check, 'opener not visible at this viewport, skipped'); return null; }
  await opener.click();
  const dialog = page.locator(DIALOG).filter({ visible: true }).first();   // visible only: a hidden dialog (e.g. a closed cart) can come first in the DOM
  try { await dialog.waitFor({ state: 'visible', timeout: 5000 }); }
  catch { log('FAIL', role, route, vp, check, 'no dialog appeared after clicking the opener'); return null; }
  await page.waitForTimeout(400);                            // let the open animation settle
  return { opener, dialog };
}

// Presses Tab n times; wait = ms before reading focus (0 = rapid, as a fast keyboard user types).
// Returns a message when focus lands on a focus-guard span or anywhere outside the dialog, else null.
async function tabLoop(page, n, wait) {
  for (let i = 1; i <= n; i++) {
    await page.keyboard.press('Tab');
    if (wait) await page.waitForTimeout(wait);
    const f = await page.evaluate(focusInfo);
    const guard = /focus-guard/.test(f.html || '');
    if (guard || !f.inDialog) return `Tab #${i} moved focus to ${f.tag} "${f.name || ''}" ${guard ? '(focus-guard span) ' : ''}outside the dialog: ${f.html || ''}`;
  }
  return null;
}

async function overlayCheck(page, role, rt, vp, ov) {
  const route = rt.path;
  const check = `overlay:${ov.name}`;
  if (ov.vp && !ov.vp.includes(vp)) return log('INFO', role, route, vp, check, 'not expected at this viewport');
  let o = await openOverlay(page, role, rt, vp, ov, check);
  if (!o) return;
  await shot(page, role, route, `${vp}-${ov.name}`);
  const inside = await o.dialog.locator('a[href],button,input,select,textarea,[tabindex]:not([tabindex="-1"])').count();
  // Rapid pass first: no wait after each Tab, about 2x the control count + 4 presses (max 40). Catches a focus trap that
  // leaks while it is still redirecting (focus on a guard span, then BODY, then the page behind).
  const rapidN = Math.min(2 * inside + 4, 40);
  const rapid = await tabLoop(page, rapidN, 0);
  log(rapid ? 'FAIL' : 'PASS', role, route, vp, `${check} tab-out-rapid`, rapid || `focus stayed inside the dialog (${inside} controls, tabbed ${rapidN}x, no wait)`);
  // Settled pass on a fresh open (a leak above leaves focus behind the dialog): 60 ms after each Tab.
  o = await openOverlay(page, role, rt, vp, ov, check);
  if (!o) return;
  const settledN = Math.min(inside + 3, 40);
  const settled = await tabLoop(page, settledN, 60);
  log(settled ? 'FAIL' : 'PASS', role, route, vp, `${check} tab-out-settled`, settled || `focus stayed inside the dialog (${inside} controls, tabbed ${settledN}x, 60 ms wait)`);
  await page.keyboard.press('Escape');
  try { await o.dialog.waitFor({ state: 'hidden', timeout: 3000 }); log('PASS', role, route, vp, `${check} esc`, 'Escape closed it'); }
  catch { return log('FAIL', role, route, vp, `${check} esc`, 'dialog still open after Escape'); }
  await page.waitForTimeout(400);
  const back = await o.opener.evaluate((el) => el === document.activeElement || el.contains(document.activeElement));
  log(back ? 'PASS' : 'FAIL', role, route, vp, `${check} focus-return`, back ? 'focus is back on the opener' : 'focus did not return to the opener');
}

async function checkPage(page, role, route, r, vp) {
  const errors = [];
  const onConsole = (m) => { if (m.type() === 'error') errors.push(`console: ${m.text().slice(0, 140)}`); };
  const onPageError = (e) => errors.push(`pageerror: ${String(e.message).slice(0, 140)}`);
  page.on('console', onConsole); page.on('pageerror', onPageError);
  await open(page, route, role, vp);
  const s = await sideways(page);
  log(s.sw <= s.cw ? 'PASS' : 'FAIL', role, route.path, vp, 'sideways-scroll', `scrollWidth ${s.sw} vs clientWidth ${s.cw}`);
  await axeCheck(page, role, route.path, vp);
  await shot(page, role, route.path, vp);
  await keyboardWalk(page, role, route.path, vp);
  for (const ov of route.overlays || []) await overlayCheck(page, role, route, vp, ov);
  page.off('console', onConsole); page.off('pageerror', onPageError);
  if (errors.length) errors.slice(0, 5).forEach((e) => log('FAIL', role, route.path, vp, 'console', e));
  else log('PASS', role, route.path, vp, 'console', '0 errors');
}

async function main() {
  if (!ROLES.length || !ROUTES.length) throw new Error('fill ROLES and ROUTES in the CONFIG block');
  if (/<PORT>/.test(BASE_URL)) throw new Error('set BASE_URL (env or CONFIG) to the dev server you started');
  const exe = HEADED ? EXECUTABLE_VISIBLE : EXECUTABLE;
  if (!exe || !fs.existsSync(exe)) throw new Error(`browser not found (${exe || 'no path'}): check harness.json / HARNESS.md in ${HARNESS}, or set PW_EXECUTABLE${HEADED ? '_VISIBLE' : ''}`);
  const browser = await chromium.launch({ executablePath: exe, headless: !HEADED, slowMo: SLOWMO });
  try {
    for (const r of ROLES) {
      const context = await browser.newContext();            // separate context per role
      const page = await context.newPage();
      await login(page, r);
      for (const route of ROUTES.filter((x) => x.roles.includes(r.name))) {
        for (const v of VIEWPORTS) {
          await page.setViewportSize({ width: v.w, height: v.h });
          await warmRoute(page, route);                      // no-op after the first width of this route in the run
          await checkPage(page, r.name, route, r, v.w);
        }
        await page.setViewportSize({ width: ZOOM.w, height: ZOOM.h });   // 200% zoom
        await open(page, route, r.name, 'zoom200');
        const z = await sideways(page);
        log(z.sw <= z.cw ? 'PASS' : 'FAIL', r.name, route.path, `zoom200`, 'sideways-scroll', `scrollWidth ${z.sw} vs clientWidth ${z.cw}`);
        await shot(page, r.name, route.path, 'zoom200');
      }
      await page.setViewportSize({ width: VIEWPORTS[0].w, height: VIEWPORTS[0].h });
      await taskSpecific(page, r.name);
      await context.close();
    }
  } finally { await browser.close(); }
}

// ---- task-specific steps below ----
// Save paths a task must prove go here (values tagged for test data, cleaned by id afterwards). Use log(level, role, route, vp, check, detail).
async function taskSpecific(page, role) { /* nothing by default: the template is read-only */ }

main().catch((e) => { log('FAIL', '-', '-', '-', 'script', String(e.message).replace(/\s+/g, ' ').slice(0, 200)); })
  .finally(() => {
    const sum = `SUMMARY pass=${totals.PASS} fail=${totals.FAIL} info=${totals.INFO} axeNEW=${totals.newAxe}`;
    console.log(sum); lines.push(sum);
    fs.writeFileSync(path.join(EVIDENCE_DIR, 'run.log'), lines.join('\n') + '\n');
    process.exitCode = totals.FAIL || totals.newAxe ? 1 : 0;
  });
