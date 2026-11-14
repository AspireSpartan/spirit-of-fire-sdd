---
name: sdd-code
description: Coder procedure for spec-driven development (SDD) in full-stack projects that keep an .agents/ folder. Use it whenever you implement a TASK-N file, continue a half-finished task, or fix findings a reviewer sent back; and always when acting as Alice, the ODST or the Coder role. Covers reading the task, reproducing a bug with a failing test first, matching existing code style, the ripple check, mutation checks, verifying every acceptance box, running formatters and tests, and leaving an honest record in the task file and memory.
---

# SDD Code (Alice and the ODST)

Build exactly one task, prove it works, and leave a record good enough that someone who was not there can trust it. The task file is the contract: it was agreed with the user through the spec, so neither shrink it nor grow it.

## 1. Read before you touch anything
1. `.agents/supply/RULES.md`, `.agents/supply/MEMORY.md`, `.agents/policies/*.md` (older projects: `.agents/skills/` instead of `supply/`). Search `.agents/supply/DECISIONS.md` for the area: a listed decision is deliberate, not a bug to fix.
2. The task file named in the mission. Check **Depends on**: if an earlier task is not finished, stop and report it.
3. The code the task points at, and a neighbor file to copy the style from (naming, comment density, error format, folder placement).
4. The task's **Ripple check**. If the task changes shared state and has no ripple list, grep the readers yourself and add the list to the task before coding.

No task file means no code. If the mission has none, say so and stop.

## 2. Reproduce first (bugs and audit findings)
Before the fix, write the test that shows the bug and **run it on the unfixed code**. Record in **Result** that it failed and how. A fix whose test never failed has not been shown to fix anything. For a feature, write the tests for the new behavior alongside the code, at the level where the effect lands (the other role's page, the row, the email), not only the form.

## 3. Build
- Write complete code, never placeholders like `// ...rest`.
- Keep the project's conventions: folder per role, logic in services, response envelopes, API calls through the shared client. RULES.md lists them.
- Protected areas named in RULES.md change only when the task says so.
- No new packages unless RULES.md lists them or the task says the user approved them.
- Errors shown to people are plain sentences. Never let a database or framework message (SQL, table names, hosts) reach a screen; log it and show a safe sentence.

**When reality disagrees with the task** (a file is not where the task says, a fix would change behavior the spec did not mention): do not quietly work around it. Write what you found in the task file under **Result**, and if the change is small and clearly within the task's intent, adjust and note it. If it changes scope or behavior, stop and report options to Cutter.

## 4. Prove it
- While you work, run only the test files that cover what you changed (`npx vitest run <file>` or the task's named tests). Run the **full gate once**, at the end, before you hand off; if the change touches a shared helper or rule, that final run is what catches the other areas. For a user-facing change (the UI paths in the project's browser-check page), run the standard review script (`sdd-review/references/review-script.md`) on the touched routes before handing off, save its output to the evidence folder, and put its summary in Result. Douglas reruns it; your run catches what he would otherwise find first.
- **Who owes the browser self-check** (the rule above and the project's `BROWSER_CHECKS.md`): **Alice**, always, on a UI task. **The ODST**, on every planned UI task that is not a quick fix, including a **medium** task sent alongside Alice on the user's order (CPT_CUTTER 2a): the full rule, same as Alice. **The ODST on a quick fix** (the brief says `Drop: quick fix`) and **the Marines**: the rule does not apply; write the marker below with the reason `quick fix`. Douglas's own browser run (his Gate) still applies to every task he reviews.
- **Browser marker (fixed wording).** When a UI task was not run in a browser, for any reason, write exactly `Browser: NOT RUN (<reason>)` as its own line in **Result** (for example `Browser: NOT RUN (port 3199 busy)`, `Browser: NOT RUN (no BROWSER_CHECKS.md)`, `Browser: NOT RUN (quick fix)`). Douglas searches for this line, so do not reword it. Leave any open browser box in the Acceptance check unticked.
- Keep command output short: use the quiet or summary reporter and read only the failing part. Never paste a whole passing run into the task file; record the command and the counts.
- Run the formatter and linter from RULES.md on touched files.
- **Mutation check, for each fix:** undo it (one line), run **only the test file that should catch it**, confirm at least one test fails, restore the file, and verify with `diff` that it is identical. Record the result in one line. If nothing fails, the test is not guarding the fix: add or sharpen a test and repeat. Never run the full suite for a mutation check.
- Walk the **Acceptance check** list. Check a box only when you saw it pass yourself. An unchecked box with a reason is honest; a checked box that was not verified breaks the whole system of trust.
- A test that fails once and passes on rerun: say so ("suspected flake, ran twice: fail, pass"), never hide it.

## 5. Record and hand off
- Fill **Result** in the task file, starting with `Built by: Alice` or `Built by: ODST`, at most about 40 lines: commands and counts, the failing-first run, one line per mutation check, what was verified, **what was not verified and why**. Long evidence (matrices, full tables) goes in `.agents/tasks/evidence/TASK-N.md`, linked from Result, so later readers open it only when they need it.
- Update `MEMORY.md`: one line of at most about 20 words for the task under its feature in **Open work** (`TASK-N short name: status`). Details stay in the task file. Respect the word cap in RULES.md.
- Move the task file to `.agents/tasks/requires-review/`.
- **Do not commit, push, or port** unless the user said so (RULES.md "Ship only on the user's word").
- Report to Cutter: files changed, results, open boxes, and what Douglas should look at closely (risky spots, protected areas touched, anything only checkable in a browser). End with **"The work is ready for review."**; in gated mode Cutter stops there so the user can start the review.

## Fixing review findings
When Cutter sends findings from Douglas, fix only those: write the failing test first, fix, add a short **Fixes after review** note in the task file, rerun the affected checks (and the mutation check for the new fix), and hand back. A finding the user decides to leave as it is goes into `DECISIONS.md` instead of the code.
