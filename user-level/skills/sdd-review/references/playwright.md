# Playwright for reviews

## Find the project's setup first
- Look for `playwright.config.*` (often in the frontend folder) and an `e2e/` or `tests/` folder. Reuse existing helpers, login fixtures and seed data; do not invent a parallel setup.
- RULES.md or a `TESTING.md` may say which database/ports e2e uses and whether runs can overlap. Respect it; two Playwright runs on the same ports usually collide.

## Headless (default)
```bash
npx playwright test e2e/<spec>.spec.js --reporter=line
```

## Visible, when the user wants to watch
Only when the mission says so ("visible", "headed", "show me", "I want to see it").
```bash
npx playwright test e2e/<spec>.spec.js --headed --workers=1 --reporter=line
```
- `--workers=1` keeps one browser window so the user can follow it.
- To slow it down for a person: in the config or a temporary review config, set `use: { launchOptions: { slowMo: 300 } }`.
- If you create a temporary config (for example `playwright.review.config.js`), delete it after the review and say so in the report.

## Writing a review test
- Name it after the behavior: `e2e/review-<feature>.spec.js`.
- Test what the user would do: log in as the right role, click through, assert visible text or state, not implementation details.
- Run it 3 times when it touches timing (uploads, emails, background jobs); a test that passes once is not proof.
- Save screenshots for findings: `await page.screenshot({ path: 'test-results/<finding>.png' })` and cite the path.

## Throwaway probes (audits)
- Name it `e2e/_probe-<module>.spec.js`. Use the project's isolated e2e database and seeded accounts only; never dev, staging, UAT or production data.
- Print one line per probe (`console.log('PROBE A1 ...: ' + JSON.stringify(...))`) and run with `--reporter=line`, so the evidence is easy to copy into the findings spec.
- Mix API probes (exact statuses and bodies, parallel requests with `Promise.all`) with the real form (what the person actually sees, then `page.reload()`), and take screenshots of messages.
- Delete the probe and its `test-results` leftovers when done; confirm with `git status`.

## Flaky or surprising failures
- Rerun the single spec once. If it passes, report **"suspected flake: failed once, passed on rerun"** with both results and the step that failed; do not hide it and do not call the feature broken.
- If it fails the same way twice, it is real: find the cause before blaming the change. Check whether the failure also happens without the change (git stash is risky on a busy tree; run the related spec instead, or compare with the other branch's last result).
- A spec that fails because it was written for the old behavior (a changed flash message, a removed button, a longer timeline) is a **spec to update**, not a bug; say which one it is.

## Watching a whole tour (demo)
To walk the user through the app in one visible window, switching roles, see `references/demo-tour.md`.

## Leave things clean
Remove files the test created (uploads, records) if the project has a cleanup step; check its log line.
