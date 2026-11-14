# Changelog

## v0.5: browser checks that ship, 2026-11-14

v0.4.1 said Douglas reviews "in a browser (Playwright)" but shipped nothing to make that work: `playwright.md` assumed a `playwright.config` and an `e2e/` folder most projects do not have, `RULES.md` had one line for it, and there was no shared Playwright install. A real project (Next.js, Windows) running v0.4.1 built the missing pieces by hand on 2026-11-13 and 14. v0.5 generalizes them and ships them, so a fresh install has them and `-Update` no longer rolls them back.

### New
- **Browser-check page** `.agents/supply/BROWSER_CHECKS.md` (project template): 1 Harness, 2 Dev server for a run, 3 Database, 4 Accounts per role, 5 Routes per module and role, 6 Gate paths, 7 Check set, 8 Test data (+ 8b overlay setup example), 9 Evidence, Axe baseline. Every project value is a `<...>` placeholder. `RULES.md` "Commands" now says `Browser checks: .agents/supply/BROWSER_CHECKS.md`.
- **Shared harness** `user-level/tools/pw-harness/`: `package.json` with exact pins (`playwright-core` 1.65.0, `axe-core` 4.14.0), `smoke.cjs`, and a `HARNESS.md` template. No browser is downloaded: it reuses the Playwright cache and always passes `executablePath`.
- **Installer part `Browser`**: a normal install asks **"Install browser checks? (Y/N)"**; `-Skip Browser` skips it without questions. On Y it runs `npm install --save-exact --ignore-scripts` with `PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1`, finds the cached Chromium in `%LOCALAPPDATA%\ms-playwright` (or `PLAYWRIGHT_BROWSERS_PATH`), asks when it is missing or a different build, writes `harness.json` and `HARNESS.md`, and runs the smoke test. No user name or path is hardcoded. `-Scope Project` puts the harness in `<project>\.claude\tools\pw-harness\` and adds `.claude/tools/` to `.gitignore`.
- **Standard review script** `sdd-review/references/review-script.template.cjs` and `review-script.md`: login per role, route x viewport matrix (360, 390, 1280, 200% zoom), sideways scroll, axe against a baseline, console errors, a 40-stop keyboard walk, Tab-out (rapid and settled), Escape and focus return for each dialog, evidence files and `PASS|FAIL|INFO` lines with a `SUMMARY`. Keeps the features the real project needed: `ready` and `readyRoles` per route, a warm-up for cold dev servers (`WARMUP_MS`), a `setup` hook per overlay, visible-only dialog lookups, no `networkidle`, short waits, a task-specific section. It reads the browser paths from `harness.json`.
- **Open browser items force a browser run** (`sdd-review` step 3): any unticked browser box, `Browser: NOT RUN (<reason>)` line or "to be tested in a browser" note is run through the page, even when the diff touches no UI path, or listed under Not verified with the reason.
- **Fixed marker** `Browser: NOT RUN (<reason>)`: the Coder writes it whenever a UI task was not run in a browser (`sdd-code`, task template); Douglas searches for it first.
- **"Browser setup missing"**: with no page (or only the template), Douglas stops the browser step and reports it; Cutter offers the setup step (Jerome, `sdd-setup` section 3b). Only a user waiver skips it.
- **Session brief** warns when `BROWSER_CHECKS.md` is missing, still the template, or has open `TODO: ask the user` items (only once `RULES.md` is filled in).
- **`CPT_CUTTER.md` section 2d "Browser checks"**: who follows the page (Douglas always; Alice on UI tasks; the ODST on planned tasks, including medium tasks sent alongside Alice) and who skips it (the Marines and the ODST on a quick fix). The brief template gets `Open browser items:` and `Drop:` lines. Section 2a gets the **parallel drop** (only on the user's order: Alice on the high task, the ODST on the medium tasks at the same time) and the **ODST quick fix**.
- **Restart reminder:** when the installer adds or changes an agent, its last message says to restart Claude Code now and names the agents, because Cutter cannot send an agent Claude Code has not loaded.
- Global depot map: `.agents/supply/BROWSER_CHECKS.md` (shared) and `.agents/evidence/` (per branch).

### Changed (ported from the live project)
- **`sdd-review`**: step 3 Browser is required for any task touching the page's UI paths and points to `references/review-script.md`, headless unless the mission says watch; step 7 Test data cleanup checks before/after counts and deleted ids; new **Browser evidence** block in the verdict; new **Gate**: a UI task cannot be APPROVED without that block unless the brief quotes the user waiving it ("browser evidence missing" is CHANGES REQUESTED).
- **`sdd-review/references/playwright.md`** rewritten: the project's page and the standard script first; the old `playwright.config` + `e2e/` flow is a fallback; probes live in the scratchpad; `--headed` for visible mode; flaky-failure rule; "Leave things clean" (delete by id, never by time window; stop only your own dev server; `git status` clean).
- **`demo-tour.md`**: uses the page's harness when there is one; "isolated test environment" instead of "isolated e2e database".
- **`sdd-code`**: a user-facing change runs the standard script as a self-check before hand-off; who owes the browser check; the fixed marker.
- **`sdd-audit`**: probes start from the review-script template, run from the scratchpad, follow the page; evidence paths (screenshots, `run.log`) in findings.
- **`sdd-plan/templates/task.md`**: acceptance box "Browser check (UI tasks)", "name the routes, roles and overlays the browser check must cover", and the marker.
- **`sdd-setup`** section 3b: creates the page from the template, fills what the code shows, marks the rest `TODO: ask the user`, asks before creating accounts or writing to a database, adds the axe baseline entry to `DECISIONS.md`, ends with the harness smoke result.
- **Agents `alice`, `jerome`, `douglas`**: new step "Load these skills when the work matches" (`verification-before-completion` before any "done"; `differential-review` and `security-best-practices` for protected areas; the project's database and ORM skills; `receiving-code-review` for Alice's fix rounds; `frontend-design` for NEW screens; `RULES.md` and `DECISIONS.md` always win). Database and deploy lines are written for any stack (the live copies named Prisma, Supabase and Vercel). Douglas reports "browser setup missing"; Jerome names routes, roles and overlays for UI tasks; Alice writes the marker.
- **`odst`** and **`sdd-marine`**: when the browser rule applies to them and when it does not.
- `.gitignore` template: `.agents/evidence/`.
- `README.md`: new section "Browser checks".

### Not shipped, on purpose
- **No third-party Playwright skill.** Anders vetted six on 2026-11-13 and recommended none (see README "Browser checks"). The vetting rule is unchanged.
- **Windows PowerShell only.** macOS and Linux are out of scope.

### Changed files
New: `project-template/.agents/supply/BROWSER_CHECKS.md`, `user-level/tools/pw-harness/` (`package.json`, `smoke.cjs`, `HARNESS.template.md`), `sdd-review/references/review-script.md`, `review-script.template.cjs`. Changed: agents `alice`, `jerome`, `douglas`, `odst`; skills `sdd-review` (+ `playwright.md`, `demo-tour.md`), `sdd-code`, `sdd-audit`, `sdd-plan` (task template), `sdd-setup`, `sdd-marine`; `.claude/CPT_CUTTER.md`, `.claude/hooks/session-brief.mjs`, `.claude/hooks/depot.mjs`, the `RULES.md` and `.gitignore` templates, `install.ps1`, `README.md`.

### Release check (for whoever builds the package)
The review script and its guide must stay project-neutral. Before a release, this must print nothing (add the names of the projects the framework was tried on):
```powershell
Select-String -Path user-level\skills\sdd-review\references\review-script.*, project-template\.agents\supply\BROWSER_CHECKS.md -Pattern '<project name>', '<test account prefix>', 'C:\\Users\\<name>'
```
v0.5 passed it for the project it came from.

### Upgrading from v0.4.1
1. **If you patched framework files yourself** (agents, skills, `CPT_CUTTER.md`, hooks), note that `-Update` replaces every framework file that differs and keeps the old copy as `<name>.bak-<date-time>`. After the update, **diff each `.bak` copy against the new file** and carry over anything of yours that v0.5 does not already have. (v0.4.1's own `-Update` would have undone the browser-check patches; v0.5 ships them.)
2. Run the installer with `-Update` and the same choices you installed with, for example `.\install.ps1 -Scope Global -Project "<path>" -Update`. Answer **Y** to "Install browser checks?" (or pass `-Skip Browser` to leave them out).
3. `BROWSER_CHECKS.md` is added to the depot only when it is missing; your `RULES.md` is never replaced, so change its browser line under "Commands" to `Browser checks: .agents/supply/BROWSER_CHECKS.md` (or ask Cutter to compare `RULES.md` with the template).
4. If you already built a harness by hand in `%USERPROFILE%\.claude\tools\pw-harness\`, the installer keeps your `HARNESS.md`, replaces `package.json` only if it differs (with a `.bak`), and writes `harness.json` with the browser it finds. If your old project-specific review script lives elsewhere, the new template replaces it; keep project facts in `BROWSER_CHECKS.md`.
5. Ask Cutter for the setup mission, browser part, to fill `BROWSER_CHECKS.md` (or check yours against the template's sections). Move known axe items into `DECISIONS.md` if they only live in `NOTEBOOK.md`.
6. **Restart Claude Code** so it loads the changed agents and skills.

## v0.4.1: the ODST, a cheaper Coder for low and medium tasks, 2026-11-13

Most planned tasks are low or medium effort, and until now every one of them was built by Alice on Sonnet. v0.4.1 adds a second Coder on a cheaper model for those, and keeps Alice for the risky work. The proof rules and Douglas's review are unchanged.

### New
- **ODST** (`odst` agent, Haiku, effort low by default): builds one TASK-N file whose **Suggested effort** is **low** or **medium**, with the `sdd-code` procedure (failing test first, mutation checks, the full gate once). It refuses high-effort tasks and review fixes ("Not an ODST task ... Send Alice."), and pulls out with **"Needs Alice"** when a task turns out to touch a risk area, is wrong or bigger than written, or keeps failing. Reports in about 10 lines and marks `Built by: ODST` in the task's Result.
- **Skip in the installer**, for when you already have your own setup for part of it. Every question has an `[S] Skip` choice (agents and skills; the project folder; the depot), and a new fourth question lists the parts (Spartans and ODST, armory skills, commander, hooks, supply depot, `.gitignore`): Enter installs all, or type the numbers to skip (for example `2,4`). `-Skip Agents,Skills,Commander,Hooks,Depot,GitIgnore` does the same without questions. A skipped commander prints the `CLAUDE.md` loader lines to add by hand; a skipped `.gitignore` prints the lines it would have added.
- **CPT_CUTTER section 2a, "Who builds a task":** low or medium → ODST; high or no effort line → Alice; an ODST hand-back → Alice on the same task; CHANGES REQUESTED → Alice, also on ODST tasks. The user can override, but the ODST never takes a high task.

### Changed
- **Alice** now takes high-effort tasks, tasks the ODST handed back, and every round of review fixes.
- **Jerome** knows the effort picks the builder: risk areas are always high, and low and medium tasks must be buildable from their own Context block.
- **Douglas** reviews ODST work the same way; findings still go back to Alice.
- `sdd-code` (Result starts with `Built by:`), `sdd-plan` and its task and plan templates, `sdd-review`, `sitrep`, the `RULES.md` template, the installer's messages and `README.md` mention the ODST.

### Changed files
New agent `odst`; agents `alice`, `jerome`, `douglas`; skills `sdd-code`, `sdd-plan` (+ task and plan templates), `sdd-review`, `sitrep`; `.claude/CPT_CUTTER.md`, the `RULES.md` template, `install.ps1` (Skip choices and `-Skip`), `README.md`.

### Upgrading from v0.4
1. Run the installer with `-Update` and the same choices you installed with (for example `.\install.ps1 -Scope Global -Project "<path>" -Update`). It adds `odst.md` and replaces the changed agents, skills and `CPT_CUTTER.md` (old copies kept as `.bak-<date-time>`).
2. Your `RULES.md` is never replaced: change "Jerome, Alice and Douglas" in its first lines to "Jerome, Alice, the ODST and Douglas" if you like; nothing depends on it.
3. Tasks already written keep working: their Suggested effort now picks the builder. Tasks without an effort line go to Alice.
4. Restart Claude Code so it sees the new agent.

## v0.4: choose where the supply depot lives, 2026-11-09

Specs, tasks and memory no longer have to be committed with the code.

### New
- **Depot question in the installer:** *in the project, committed* (as before), *in the project, ignored by git* (`.agents/` added to `.gitignore`), or *global, by project and branch* (`~/.claude/spirit-of-fire/<owner-repo>/`). `-Depot Project|ProjectIgnored|Global` and `-DepotName` skip the questions. The choice is saved as `depot` (and `depotName`) in `.claude/spirit-of-fire.json`.
- **Global depot layout:** `RULES.md`, `MEMORY.md`, `DECISIONS.md`, `policies/`, `research/` and `archive/` are shared by all branches; `branches/<branch>/` holds each branch's `NOTEBOOK.md`, `specs/` and `tasks/`. A branch's folder is created with an empty notebook the first time a session starts on it.
- **`.claude/hooks/depot.mjs`** works out the depot and branch folder. The session brief prints a **Depot map** (`.agents/...` path → real path); `node .claude/hooks/depot.mjs` prints it after a branch switch.
- **Archive a branch** mission: "<branch> is merged, archive it" moves its folder to `archive/<branch>/` (only on the user's word, never guessed from git).
- **Moving to global:** an existing `.agents/` is copied into the depot (never moved or overwritten); the installer prints the `git rm -r --cached .agents` command if it was tracked.
- The installer adds the depot to `permissions.additionalDirectories` in `.claude/settings.local.json` (per machine, now in `.gitignore`).
- A `CLAUDE.md` from another setup is no longer only skipped: the installer shows the loader lines and asks before adding them (with a backup).

### Changed
- **`CPT_CUTTER.md` moved to `.claude/CPT_CUTTER.md`.** `CLAUDE.md` now loads it plus `RULES.md` and `MEMORY.md` (and `NOTEBOOK.md` for an in-project depot) directly, so the loader can point at a global depot. A v0.3 loader (`@.agents/CPT_CUTTER.md`) is updated automatically with a backup; delete the old `.agents/CPT_CUTTER.md` afterwards.
- Cutter copies the Depot map into every mission brief; Jerome, Alice, Douglas, Anders and `sitrep` use it when the depot is global. Skills still write `.agents/...` paths.

## v0.3.1: choose global or project only, 2026-11-09

### New
- **The installer asks where to install.** Run `.\install.ps1` with no options: it asks *Globally* or *Project only*, then the project folder, shows a preview of what is already there (same-name Spartans and skills, `CLAUDE.md`, `.claude\settings.json`, `.claude\hooks`, `.agents\`), and copies only after your `Y`.
- **Project-only install.** Spartans and skills go to `<project>\.claude\agents` and `<project>\.claude\skills`; nothing is written to your user folder, so other projects and other SDD setups never see Spirit of Fire. The preview warns when a user-level Spartan or skill has the same name.
- **`-Scope Global|Project`** to skip the questions. `-UserLevel` and `-Project` work as before (global).

### Changed
- Jerome, Alice, Douglas and `CPT_CUTTER.md` look for skill files in the project's `.claude/skills/` as well as `~/.claude/skills/`, so the fallback paths work for a project-only install.

## v0.3: lower usage, same accuracy, 2026-11-02

A real project run on v0.2 (about 18 reviewed tasks plus a production release in 1.5 days) used around 40% of the account's usage. Most of it was agents re-reading the same files: by the end, the depot every agent read at start had grown to about 7,400 words, the biggest spec plus plan to about 7,850, and the full test suite ran for every mutation check. v0.3 cuts the reading and the repeated runs. Reproduce-first, mutation checks, ripple checks, independent review, gated hand-offs and "ship only on the user's word" are unchanged.

### New
- **Two editions.** *General*: `.agents/policies/` starts empty; the setup mission asks about company, client or personal rules and writes policy files from `sdd-setup/templates/policy.md`, never from a guess. *Company*: the same, plus the GitHub connectivity policy (HTTPS on 443, no SSH on port 22).
- **Professor Anders** (`anders` agent, Sonnet, medium): researcher and skill vetter. Read-only, with a `tools:` list and no shell, so a hostile skill she reads cannot make her run anything. Writes one report under `.agents/research/`.
- **`find-skills`** (Anders only): a search-only copy of vercel-labs/skills `find-skills` (MIT), using WebFetch instead of `npx`.
- **Context block** in every task (`sdd-plan/templates/task.md`): the 10 to 20 spec and plan lines the task needs, so Alice does not read the whole spec.
- **`.agents/tasks/evidence/`** for long evidence (matrices, tables, logs), linked from the task, so later readers open it only when needed.
- **"Keep sessions short"** (CPT_CUTTER section 1c) and **"Skills from outside"** (section 9).

### Changed
- **MEMORY.md** capped at **800 words** instead of 100 lines (77 long lines had reached 2,948 words). One line per task while a feature is open, one line per finished feature.
- **Jerome** defaults to effort **medium** (Cutter raises it for risk areas), has a reading budget, sends the built-in `Explore` agent for wide sweeps, writes Context blocks, and prefers fewer, coherent tasks.
- **Alice** reads the task's Context, runs only the affected tests while working and for each mutation check, and runs the full gate once at the end.
- **Douglas** reads the full spec only in independent reviews; at least 1 own mutation check in a normal review, 3 or more in an independent review or a protected area.
- **Every agent reports back in about 15 lines**; the full record stays in the task or spec file. Task Result and Review sections stay around 40 lines.
- **Notebook reminder** default lowered from 150,000 to **80,000** tokens, and it now suggests a fresh session.
- `DECISIONS.md` is searched, not read whole.
- Agent descriptions are shorter (they sit in every session's context).

### Changed files
Agents `jerome`, `alice`, `douglas`, new `anders`; skills `sdd-plan` (+task template), `sdd-code`, `sdd-review`, `sdd-marine`, `sdd-setup`, new `find-skills`; `CPT_CUTTER.md`, `RULES.md` and `MEMORY.md` templates, `spirit-of-fire.json`, `notebook-reminder.mjs`, `README.md`.

### Upgrading an installed copy
1. Run `.\install.ps1 -UserLevel -Update` and `.\install.ps1 -Project "<path>" -Update`.
2. In each project, replace the MEMORY.md part of "Memory and notebook" in `RULES.md` with the new template text, then ask Cutter to "shrink MEMORY.md to the new format (one line per finished feature, under 800 words)". The installer never rewrites your RULES.md or MEMORY.md.
3. Lower `notebookReminderTokens` in `.claude/spirit-of-fire.json` to 80000 (the installer keeps your copy).
4. For plans already written, ask Jerome to "add a Context block to each open task, from the spec".
5. Restart Claude Code.

## v0.2: lessons from a real project (ER Tool 2.0), 2026-10-30

The workflow was used by hand for weeks on a real project (a Laravel + React app with three roles). What kept working, and what was added each time something went wrong, is now built into the framework. The idea and the direction are the user's; the pieces below were proven on real work before being written here.

### New
- **Audit mission** and the **`sdd-audit` skill** (Douglas). Test an existing module before fixes are planned: probe through the real UI and data paths on an isolated environment, try to break it (duplicates, other letter case, half-failed saves, reload, double submit, parallel requests, edit conflicts, imports, lock-outs, messages that leak SQL), and write **findings with evidence and severity** into `.agents/specs/<module>-review/spec.md` (`templates/findings.md`). Jerome plans from those findings.
- **Hand-off mode** `handoff` (`gated` default, or `auto`) in `.claude/spirit-of-fire.json`, shown by the session brief. Gated mode stops after each stage with a fixed one-line hand-off ("Audit done...", "Done planning.", "The work is ready for review.", the verdict) so the user decides when the next stage starts, and can change the model in between.
- **`DECISIONS.md`** in the supply depot: what the user chose to leave as it is. No line cap, never pruned by age (`MEMORY.md` and `NOTEBOOK.md` are capped and pruned, so a decision kept only there gets forgotten). Every unit searches it before "fixing" a gap.
- **Demo tour** reference (`sdd-review/references/demo-tour.md`): a guided, visible, one-window tour that signs out and in between roles, with an on-screen caption.
- **`install.ps1 -Update`**: takes improved agents, skills, commander orders and hooks after a `git pull`, saving the old copy as `.bak-<date-time>`. Project-owned files are never replaced.

### Stronger rules (in `RULES.md` template, the skills and the agents)
- **Testing standard:** behavior where it lands, not appearance; **reproduce first** (failing test recorded before the fix); a **mutation check** for every fix (undo it, a test fails, restore, `diff` identical); tests and probes only on isolated data; a failure that passes on rerun is reported as a suspected flake.
- **Ripple check** before changing shared state, in the spec, the plan and each task.
- **Independent review** for features of 3+ tasks and for an audit's fixes: the reviewer sees only the spec, the task files and the diff, hunts for holes the coder missed, and runs his own mutation checks (at least 3).
- **Ship only on the user's word:** commit, push, merge and porting between branches each need an explicit OK; "maybe we should" is a question. Porting is done by hand (diff, `git apply --check`, `git apply`, never cherry-pick).
- **Honest hand-offs:** every report says what was *not* verified; never tick an unverified box.
- **Quick fixes still owe a test** (Marines): written first, failure recorded, mutation-checked.
- **No database or framework text on a screen**; planner **business defaults** are listed so the user can confirm them.

### Changed files
`CPT_CUTTER.md` (missions, hand-off mode, ship rule, decisions), `RULES.md` template, `DECISIONS.md` (new), `spirit-of-fire.json` (+`handoff`), `session-brief.mjs` (prints the mode), agents `jerome`, `alice`, `douglas`, skills `sdd-plan` (+templates), `sdd-code`, `sdd-review` (+Playwright and demo references), `sdd-marine` (+template), `sdd-setup`, `sitrep`, new `sdd-audit`, `install.ps1`, `README.md`.

### Upgrading an installed copy
1. `git pull` this folder, then `.\install.ps1 -UserLevel -Update` and `.\install.ps1 -Project "<path>" -Update`.
2. In each project, ask Cutter to compare `RULES.md` with the template and add the missing sections (the installer never rewrites `RULES.md`), and add `"handoff": "gated"` to `.claude/spirit-of-fire.json` if you want to state it (gated is the default).
3. Restart Claude Code.

## v0.1: first version, 2026-10
Cutter, Jerome (Planner), Alice (Coder), Douglas (Reviewer), Marines, the `sdd-*` skills, `sitrep`, three hooks (session brief, branch guard, notebook reminder), `install.ps1`, and the `sdd-setup` first mission.
