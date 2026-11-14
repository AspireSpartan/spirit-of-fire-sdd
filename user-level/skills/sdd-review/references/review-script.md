# The standard review script

One script defines the browser check set for every review, audit and Coder self-check: `review-script.template.cjs` (this folder). The template is the single place the checks are defined; read its header and function names rather than a copy of the list here. In short, per role x route: three viewports plus a 200% zoom row, axe (baseline vs NEW), console errors, sideways scroll, a 40-stop keyboard walk, and for each overlay: Tab-out-of-dialog (a rapid pass with no wait and a settled pass), Esc, focus return. Screenshots and a `run.log` go to the evidence folder.

## Use it
1. Find the project's browser-check page (RULES.md "Commands"). It gives the harness path, how to start a dev server, the test accounts and where their password lives, the routes per role, the axe baseline and the evidence folder. If the project has no such page, ask Cutter before running anything against a real database.
2. Copy the template to the **session scratchpad** as `review-TASK-N.cjs`. Never put the script in the repo.
3. Fill the CONFIG block from the page: `BASE_URL` (or set env `BASE_URL`), `TASK`, `ROLES`, `LOGIN` selectors, `ROUTES` (with overlay opener selectors), `KNOWN_AXE`. The password is read from the env var named in `passwordEnv`; set it from where the browser-check page says, without echoing it, and never write it in the script, the log or the task file.
   Optional per route: `ready` (a selector for the loaded data, waited for after the page's main element; 15 s), and `readyRoles` (a list of roles; the ready wait runs only for those roles, so a selector only one role has does not FAIL for the others). Optional per overlay: `vp` (a list of widths; at other widths the overlay is logged as `not expected at this viewport` and not clicked), and `setup` (`async (page, { role, route, vp }) => {}`: client-state steps such as clicking a service tile or typing, run after the page opens and before the opener click; on each pass, since every pass re-opens the page; never a database write unless the task says so; a throw logs `FAIL ... setup failed: <message>` and skips the overlay). An opener that is not visible is retried for 6 s before it is skipped.
   Dialog lookups count only visible dialogs (`filter({ visible: true })`), so a hidden dialog elsewhere in the DOM (for example a closed cart) is not picked.

## Warm-up (cold dev server)
- `WARMUP_MS` (90 s) is the budget for the login form and for the first visit to each route. Before the first login of a run the script makes one unmeasured visit to the login page; before the first width of each route (once per run, keyed by path) one unmeasured visit to the route, waiting for `READY`. Both log `INFO ... warm-up` with the time taken, or the failure. A slow or failed warm-up is never a FAIL.
- Measured checks keep their own timeouts (READY 30 s, ready 15 s, opener 6 s, dialog 5 s). If a measured check FAILs right after a cold start, rerun on the warm server before reporting it as a finding.

## Scope the run
- A full matrix (every route, role and width) is slow: about 20 s per role x route x width on a warm server (one real project: 4 roles x 6 routes x 3 widths took about 25 min on a cold server).
- For a review, run the routes the diff touches plus their overlays, with the roles that can open them (RULES.md / BROWSER_CHECKS.md tables). Run the full matrix only when the task asks for it.
4. Start the dev server exactly as the page says, run from the repo root (`EVIDENCE_DIR` defaults to `.agents/evidence/<TASK>` under the current directory; with a global depot set `EVIDENCE_DIR` to the `.agents/evidence/` line of the Depot map plus the task), then run:
   - headless (default): `node <scratchpad>/review-TASK-N.cjs`
   - visible, only when the brief says the user wants to watch: `node <scratchpad>/review-TASK-N.cjs --headed`
5. Read the output: one line `PASS|FAIL|INFO <role> <route> <viewport> <check> <detail>` per check and a `SUMMARY` line; the same lines (plus every Tab stop) are in `<evidence folder>/run.log`. Exit code 1 means a FAIL or a NEW axe item.
6. Paste the summary into the **Browser evidence** block (see `SKILL.md`). A FAIL is a finding to report, or a deliberate baseline listed in the project's decisions; do not hide it by editing the script.
7. Stop your dev server, delete nothing you did not create, and confirm with `git status` that the repo has no new script or `test-results/` folder.

## Task-specific steps
The template is read-only. A task that must prove a save path adds its steps under the line `// ---- task-specific steps below ----` (function `taskSpecific`): use test values the project tags for cleanup, record the ids, delete them by id afterwards and write before/after counts in the task file.
Read-only overlays may need seeded rows to open; the project's browser-check page gives the seed recipe. Logins may add session rows, so "counts identical" excludes the session table (record its delta on its own line).

## Notes
- The harness is one pinned install outside the repo (`~/.claude/tools/pw-harness`; a project-only install: `<project>/.claude/tools/pw-harness`, set `PW_HARNESS`); the script requires `playwright-core` and `axe-core` by absolute path from it. It reads the browser paths from the harness's `harness.json` (written by the installer; `PW_EXECUTABLE` and `PW_EXECUTABLE_VISIBLE` override) and always passes `executablePath`; never run `playwright install`.
- Focus indicator means computed outline or box-shadow is visible; form fields that show focus only through a border colour are counted separately, so check their screenshots. The Next.js dev-only overlay element is skipped in the keyboard walk.
- Check wording follows common practice in the MIT-licensed Currents `accessibility.md` and `mobile-testing.md` Playwright skills (viewport matrix, axe tags, keyboard and focus checks); the code is our own.
- Overlay Tab-out runs twice on a fresh open. The **rapid** pass presses Tab with no wait (about 2x the control count + 4, max 40) and FAILs when focus lands on a focus-guard span or anywhere outside the dialog: a fast typist can beat a trap that is still redirecting. The **settled** pass waits 60 ms per Tab and FAILs only on a lasting escape. Report both lines; a rapid FAIL with a settled PASS is a real focus-trap leak, not noise.
- Keyboard walk limit: one BODY stop mid-walk is counted as a normal wrap through the browser UI and is not a FAIL (only BODY at the start or twice in a row is). A single real focus loss to BODY can therefore hide; check the screenshot or the per-stop lines in `run.log` when something feels off.
- axe baseline matching is by rule and route (and optional viewport), not per node. A new node of a baseline rule on a baseline route prints as `baseline`; compare the `nodes=` count on those INFO lines with the project's recorded baseline.
