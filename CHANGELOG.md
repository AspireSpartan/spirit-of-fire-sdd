# Changelog

## v0.3: lower usage, same accuracy, 2026-11-02

A real project run on v0.2 (about 18 reviewed tasks plus a production release in 1.5 days) used around 40% of the account's usage. Most of it was agents re-reading the same files: by the end, the depot every agent read at start had grown to about 7,400 words, the biggest spec plus plan to about 7,850, and the full test suite ran for every mutation check. v0.3 cuts the reading and the repeated runs. Reproduce-first, mutation checks, ripple checks, independent review, gated hand-offs and "ship only on the user's word" are unchanged.

### New
- **Two editions.** *General*: `.agents/policies/` starts empty; the setup mission asks about company, client or personal rules and writes policy files from `sdd-setup/templates/policy.md`, never from a guess. *Company*: the same, plus a company policy, shipped as a separate private package.
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
