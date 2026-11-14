# Playwright for reviews

## 1. Find the project's browser-check page first
RULES.md "Commands" names it (for example `.agents/supply/BROWSER_CHECKS.md`). **If it exists, follow it and the standard script, full stop:** `references/review-script.md` and `references/review-script.template.cjs`. Do not invent another harness, and do not write specs, probes or screenshots into the repo (`e2e/`, `test-results/`). The page decides the dev server, the database rule, the accounts, the routes and the evidence folder.

## 2. Fallback: a project with a real Playwright suite
Only when there is no browser-check page but there is a `playwright.config.*` and an `e2e/` or `tests/` folder: reuse its helpers, login fixtures and seed data; RULES.md or a `TESTING.md` may say which database and ports e2e uses. Two runs on the same ports collide.
```bash
npx playwright test e2e/<spec>.spec.js --reporter=line               # headless (default)
npx playwright test e2e/<spec>.spec.js --headed --workers=1 --reporter=line   # visible, only when the mission says so
```
- Name a review test after the behavior (`e2e/review-<feature>.spec.js`), test what the user would do, and run it 3 times if it touches timing.
- A temporary config (for example `playwright.review.config.js`, `slowMo: 300` for a person to follow) is deleted after the review; say so in the report.
- Screenshots for findings: cite their path.

## 3. Probes for audits
Write the throwaway probe in the session scratchpad, starting from `review-script.template.cjs` plus your probe lines (task-specific section), on the project's isolated test environment only. Print one line per probe so the evidence is easy to copy into the findings spec. Mix API probes (exact statuses and bodies, parallel requests) with the real form (what the person sees, then reload). Screenshots go to the project's evidence folder. Delete the probe afterwards and confirm with `git status`.

## 4. Visible mode
Only when the mission says so ("visible", "headed", "show me", "I want to see it"): run the script with `--headed` (the template slows actions down). Otherwise headless.

## 5. Flaky or surprising failures
- Rerun the single check once. If it passes, report **"suspected flake: failed once, passed on rerun"** with both results and the step that failed; do not hide it and do not call the feature broken.
- If it fails the same way twice, it is real: find the cause before blaming the change. Check whether it also happens without the change (run a related check; `git stash` is risky on a busy tree).
- A check that fails because it was written for the old behavior (a changed message, a removed button) is a **script to update**, not a bug; say which one it is.

## 6. Watching a whole tour (demo)
To walk the user through the app in one visible window, switching roles, see `references/demo-tour.md`.

## 7. Leave things clean
- Delete the records the run created **by id** (never by a time window or a broad pattern); record the ids and the before/after counts in the task file. If the project defines a cleanup step (RULES.md or the browser-check page), run it and check its log line.
- Stop the dev server you started, and nothing else. Delete scratchpad scripts and probes; confirm with `git status` that the repo has no new file from the run.
