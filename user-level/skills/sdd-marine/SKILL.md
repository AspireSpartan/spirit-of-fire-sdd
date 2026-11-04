---
name: sdd-marine
description: All-in-one plan, code and check procedure for light work in projects that keep an .agents/ folder: small bug fixes, text or style tweaks, a missing validation, a config value, a one-endpoint addition, anything about 3 files or fewer with no schema, API-contract or protected-area change. Use it whenever the commander sends Marines or the change is clearly minor; it keeps the SDD record with a one-page quick task instead of a full spec and plan.
---

# SDD Marine (light work, all in one)

Marines handle the small fights so the Spartans stay free for the big ones. You do plan, code and check yourself in one pass, but you still leave a record: a quick task file. That keeps the project history complete and lets anyone see later why a line changed.

## Is this really Marine work?
All of these must hold; if one does not, stop and tell Cutter it needs the Spartans:
- About 3 files or fewer.
- No database schema change, no change to an API contract other code depends on.
- No protected area from RULES.md (for example auth, payments, legal documents).
- The user's intent is clear (no business rule to decide).
- It does not change shared state that other code reads (a status, field name, settings key, uniqueness rule). If it does, list the readers first (ripple check); if the list is long, it needs the Spartans.
- It is not listed in `.agents/supply/DECISIONS.md` as something the user chose to leave alone.

## Steps
1. **Read** `.agents/supply/RULES.md` and `.agents/supply/MEMORY.md` (older projects: `.agents/skills/`). Take the next number from `Highest TASK number`.
2. **Write the quick task** first: `.agents/tasks/TASK-<N>_<short-name>.md` from `templates/quick-task.md`. Two minutes, not twenty: what, why, files, 2 to 4 acceptance boxes.
3. **Fix** it, matching the surrounding code style.
4. **Check**: **a quick fix still owes a test** that fails without the fix: write it first, run it on the unfixed code and see it fail, then fix. Then undo the fix once, see the test fail, restore it (`diff` identical). Run the tests closest to the change and the formatter/linter. For a visible change, look at it in the browser (Playwright headless, or visible if the user asked). If a test is truly impractical, say why in the Result instead of skipping it silently.
5. **Record**: fill **Result** in the quick task, check verified boxes only, move it straight to `.agents/tasks/archive/quick-fixes/` (Marines self-review; no Douglas pass unless the user asks). Update `Highest TASK number` and add one line of at most about 20 words to `MEMORY.md` (word cap in RULES.md).
6. **Report** in a few lines: what changed, where, how it was verified, what was not. Do not commit or push unless the user said so.

If during the fix it grows beyond the limits above, stop, keep the quick task as notes, and tell Cutter to hand it to Jerome.
