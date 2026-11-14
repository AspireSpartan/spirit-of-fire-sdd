# Demo tour: the whole app in one visible window

If the project has a browser-check page (RULES.md "Commands"), drive the tour with the harness and rules from it instead of `npx playwright test` and `e2e/` below; the steps and captions still apply.

Use when the user says "demo the whole app", "walk me through it", "show me all roles in one window". It is **not a regression test**; it is a guided, watchable run. It uses the project's **isolated test environment**, never real data.

## Shape
- **One browser window, one page.** Between roles the script **signs out and signs in again through the real login form** (Profile menu → Logout → login form), so the user can follow who is acting.
- **Rounds.** At least two rounds, with different data, so the second round shows a different branch of the flow (for example round 1 the happy path with one return for changes; round 2 a rejection and re-submit, an import, a report).
- **Role order.** Setup role first (Admin), then the creating roles, then the approving roles, ending back with Admin looking at the audit log or totals.
- **A caption on screen** says who is acting and what is being shown (small bar at the bottom of the page).
- **A failed step does not stop the tour.** Show it in a red caption, log it, carry on, and fail the test only at the end with the list of failed steps.
- **Pace** is set by environment variables: `DEMO_SLOWMO` (ms between actions, default 400) and `DEMO_BEAT` (pause after each step, default 1500). Run a fast headless dry run first (`DEMO_SLOWMO=0 DEMO_BEAT=100`) to debug the script, then the real headed run.

## Run
```bash
# dry run, fast, no window
DEMO_SLOWMO=0 DEMO_BEAT=100 npx playwright test e2e/demo-tour.spec.js --reporter=line
# the real thing, one visible window
DEMO_SLOWMO=450 DEMO_BEAT=2200 npx playwright test e2e/demo-tour.spec.js --headed --reporter=line
```
Playwright must be told to run with one worker and no saved login: in the spec use `test.use({ storageState: { cookies: [], origins: [] }, viewport: { width: 1440, height: 900 }, launchOptions: { slowMo: SLOWMO } })`.

## Building blocks (copy and adapt the selectors)

```js
// Caption overlay: survives page navigation because it is re-drawn from sessionStorage.
const installCaption = (page) => page.addInitScript(() => {
  const draw = () => {
    let el = document.getElementById('__demo_caption');
    if (!el) {
      el = document.createElement('div');
      el.id = '__demo_caption';
      el.style.cssText = 'position:fixed;left:50%;bottom:14px;transform:translateX(-50%);z-index:2147483647;max-width:80vw;padding:10px 18px;border-radius:10px;background:rgba(15,23,42,.92);color:#fff;font:600 15px/1.4 system-ui,sans-serif;pointer-events:none;text-align:center';
      document.documentElement.appendChild(el);
    }
    const raw = sessionStorage.getItem('__demo_caption');
    if (!raw) { el.style.display = 'none'; return; }
    const c = JSON.parse(raw);
    el.style.display = 'block';
    el.style.background = c.bad ? 'rgba(153,27,27,.95)' : 'rgba(15,23,42,.92)';
    el.innerHTML = `<div style="font-size:12px;letter-spacing:.08em;color:#7dd3fc">${c.who}</div><div>${c.text}</div>`;
  };
  document.addEventListener('DOMContentLoaded', draw);
  window.__demoDraw = draw;
});

const say = (page, who, text, bad = false) =>
  page.evaluate(([w, t, b]) => { sessionStorage.setItem('__demo_caption', JSON.stringify({ who: w, text: t, bad: b })); window.__demoDraw?.(); }, [who, text, bad]).catch(() => {});

const failures = [];
const act = async (page, who, title, fn) => {
  await say(page, who, title);
  try { await fn(); console.log(`  OK   ${who} | ${title}`); }
  catch (err) {
    const msg = String(err?.message ?? err).split('\n')[0];
    failures.push(`${who} | ${title} | ${msg}`);
    console.log(`  FAIL ${who} | ${title} | ${msg}`);
    await say(page, who, `STEP FAILED: ${title}`, true);
    await page.waitForTimeout(BEAT * 2);
  }
  await page.waitForTimeout(BEAT);
};

// Sign out of the current account (if any) and into the next, through the real login form.
async function signIn(page, role) {
  const menu = page.getByRole('button', { name: '<profile menu button name>' });
  if (await menu.isVisible().catch(() => false)) {
    await menu.click();
    await page.getByRole('button', { name: '<logout button name>' }).click();
    await expect(page).toHaveURL(/\/login/);
  }
  await loginViaForm(page, ACCOUNTS[role], PASSWORD);   // reuse the project's login helper
  await expect(page).toHaveURL(new RegExp(`${DASHBOARD[role]}$`));
}
```

At the end of each test: `expect(failures, 'failed steps').toEqual([])`, and reset `failures.length = 0` at the start.

## Tips learned the hard way
- Reuse the project's existing e2e helpers (login, pick-an-employee, draw-a-signature) instead of rewriting them; the demo is mostly a sequence of existing flows with captions.
- Do the long setup of a step through the **API** only when the step is not what the user came to see; show the important actions in the UI.
- The second round must not depend on the first having just run: pick data that exists in the seed, or create it in the round.
- Delete the demo spec afterwards if the user says it was only a demo; if they want it kept, say that it is not part of the regression suite.
