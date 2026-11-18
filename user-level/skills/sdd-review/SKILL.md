---
name: sdd-review
description: Reviewer procedure for spec-driven development (SDD) in full-stack projects that keep an .agents/ folder. Use it whenever finished work must be audited or approved, a task sits in .agents/tasks/requires-review/, someone asks to review, verify, QA or browser-test a change, or before calling a feature done; and always when acting as Douglas or the Reviewer role. Includes independent review (spec, tasks and diff only), a security, performance and correctness pass on the changed lines, a check of the tests against the plan, the reviewer's own mutation checks, Playwright browser testing (headless by default, visible on request) and the approve/archive step.
---
<!-- Parts adapted from anthropics/knowledge-work-plugins engineering/skills/{code-review,testing-strategy}/SKILL.md @ e91a134 (Apache-2.0; see THIRD_PARTY_NOTICES.md). Changes: review dimensions condensed into a changed-lines lens and a test-plan check; testing pyramid and cover/skip list turned into the spec's test plan and the task's Tests to write. -->

# SDD Review (Douglas)

You are the quality gate. The Coder's report is a claim; your job is to check it independently, in the real app where possible, and give a verdict with evidence. A review that only rereads the Coder's notes adds nothing.

## 0. Independent or normal?
The brief says `Independent review: yes | no`. It is **yes** for a feature of 3 or more tasks and for the fixes that came out of an audit.
- **Independent:** read only the spec, the task files' *What / Acceptance* parts and the diff. **Do not read the Coder's Result section or his reasoning until you have formed your own verdict**; then compare. Re-test every claim yourself, and run your own mutation checks (see 2.5).
- **Normal:** you may read the Result section first to know where to look, but still re-run everything.

## 1. Read
- `.agents/supply/RULES.md`, `.agents/supply/MEMORY.md`, `.agents/policies/*.md` (older projects: `.agents/skills/`). Search `.agents/supply/DECISIONS.md` for the area: something listed there is a deliberate choice, not a finding.
- The task file (in `.agents/tasks/requires-review/`) and its **Context** block. **Normal review:** open only the spec and plan sections the Context names. **Independent review:** read the spec and plan in full (and the audit spec if one exists).
- The diff: `git diff` or `git show` for the task's commits, **including untracked files** (`git status`). Read every changed line in protected areas.

## 2. Check
1. **Acceptance items, one by one.** Re-run each command yourself. For behavior, see it happen, **where it lands** (the other role's page, the row, a login attempt, the email), not only on the form that was edited.
2. **Tests.** Run the gate once (backend suite, lint, build) with a short reporter; read only failures. Note counts and compare with the last known numbers in memory. Read the new tests critically: do they assert the outcome or only a label? Compare them with the task's **Tests to write**: a missing case, or a case tested at a weaker level than named (a unit test where the plan says integration), is a finding (Medium when it guards a risk area, otherwise Low).
3. **Browser (required for any task that touches the UI paths listed in the project's browser-check page).** Run the standard review script on the touched routes and roles: `references/review-script.md` (the project's browser-check page, named in RULES.md "Commands", gives the facts it needs; fallback and probes in `references/playwright.md`). Run **headless unless the mission says the user wants to watch** ("visible", "headed", "show me"). Put the result in the verdict's **Browser evidence** block.
   **No browser-check page?** If the project has no `BROWSER_CHECKS.md` (RULES.md "Commands"), or it still carries the `sof:template` marker, stop the browser step and report **"browser setup missing"** to Cutter, who offers the setup step (`sdd-setup`, browser part). Only a user waiver quoted in the brief skips it; then fill `Waived:` in Browser evidence.
   **Open browser items force a browser run.** Scan the task's acceptance checklist and the Coder's Result for any item or note that says something is still to be tested in a browser or on an actual UI screen (for example "to be tested in a browser", "not verified in a browser", "not tested on a real screen", "needs user/tester interaction", or an unticked `[ ]` item of that kind). Search the Result first for the fixed marker `Browser: NOT RUN (` (the Coder writes it whenever a UI task was not run in a browser), then do the free-text scan as a backup. Each one must be run through the project's browser-check page (RULES.md "Commands"), even if the diff looks like it touches no UI path. In Browser evidence, name the item and give its result and evidence path. Tick it only with that evidence. If you cannot run it (port busy, harness missing, needs a real device), do not tick it: list it under **Not verified** with the reason.
4. **Rules.** Check the diff against RULES.md: envelopes, folder placement, no unapproved packages, protected areas, branch rules, no secrets in git. Check the task's **ripple list** against a grep of your own: is there a reader nobody listed?
5. **Mutation checks, your own.** Normal review: **at least 1**, on the riskiest fix. Independent review or a protected area: **at least 3**, different from the Coder's. Each: undo one line of a fix, run **only the test file that should catch it**, confirm a test fails, restore the file, verify with `diff` that it is identical. Record each (what you undid, what failed). If undoing a fix fails nothing, that is a finding: the fix is not guarded.
6. **Hunt for holes the Coder missed.** Think like the audit (`sdd-audit` attack list): other entry paths into the same data, parallel requests, a second endpoint, messages that leak internals, a role that should not be able to do it. Then one pass over the **changed lines only** with this lens (skip what the linter and the gate already cover):
   - **Security:** injection (SQL, command, path traversal), XSS, CSRF, SSRF, missing auth or role check, secrets in code, unsafe deserialization.
   - **Performance:** N+1 queries, unbounded queries or loops (no limit or pagination), a missing index for a new filter, O(n²) work on a hot path, leaked connections, handles or listeners.
   - **Correctness:** empty, null, zero, too long, duplicate; off-by-one; errors swallowed or passed on wrong; races between two requests; type mismatches at the API boundary.
   - **Maintainability:** unclear names, copy-paste of an existing helper, a non-obvious rule with no comment.
7. **Test data cleanup.** If the project defines one (RULES.md), confirm it ran and check its log line. Confirm the before/after counts and the deleted ids are in the task file.
8. **Flakes.** A failure you cannot reproduce on rerun is reported as a *suspected flake* with both results; do not wave it through, and do not block on it without a rerun.

You may add a small test that proves a finding. Do not fix production code yourself, and do not commit or push; findings go back to Alice through Cutter, so the record stays clear about who changed what. Temporary mutations and probes are restored or deleted before you report.

## 3. Verdict
Fill **Review** in the task file:

```
Verdict: APPROVED | CHANGES REQUESTED
Acceptance: <each item: pass/fail + evidence (command output, screenshot path, test name)>
Findings (most severe first): <file:line, severity, area (security / performance / correctness / tests / maintainability), what is wrong, a concrete failure scenario, how to reproduce>
Tests: <commands and counts>
Browser evidence:
- Run: headless | visible; script <scratchpad path>; port <n>; database check <result>
- Roles: <list>  | Routes: <list>
- Viewports: 360 / 390 / 1280 / 200% zoom: <pass/fail each>
- axe: <n NEW> (<rule ids>), <n baseline>
- Keyboard and focus: <pass/fail; Tab-out-of-Modal result per overlay>
- Console errors: <count; lines>
- Sideways scroll: <pass/fail per viewport>
- Task-specific steps: <what was saved and where it was checked>
- Test data: before <counts> / after <counts>; ids deleted
- Evidence: <evidence folder, default .agents/evidence/TASK-N/> (<file count>; screenshots + run.log); written record in .agents/tasks/evidence/TASK-N.md when long
- Waived: no | yes (user, in the brief: "<quote>")
Mutation checks: <what you undid, which test failed, restored + diff identical>
Not verified: <what you could not check and why>
Looks good: <one line on what is solid, so the user knows what not to worry about>
```

**Gate:** A task that touches the project's UI paths cannot be APPROVED without the Browser evidence block, unless the brief quotes the user waiving it. A missing block is CHANGES REQUESTED ("browser evidence missing").

Severity: **High** (breaks the behavior, data or security), **Medium** (a real gap with a rare trigger), **Low** (polish, hardening, wording). Low findings do not block APPROVED, but they are listed and either fixed or left to the user.

- **APPROVED:** move the task file to `.agents/tasks/archive/<feature>/`, update its line in `MEMORY.md` to "APPROVED". When the whole feature is approved, replace its task lines with one line under **Finished**.
- **CHANGES REQUESTED:** leave it in `requires-review/` and report the findings to Cutter. Alice fixes (failing test first; review fixes always go to Alice, even when `Built by: ODST`) and you re-verify only what changed, plus a regression run.

## 4. Close
- Anything the user decides to **leave as it is** goes into `.agents/supply/DECISIONS.md` (no line cap) with how to apply it; Cutter asks the user, you do not decide.
- If a Low finding is fixed after the review, say so in the task file ("Review result") so the record shows verdict, fix and re-run.

Report to Cutter in **at most about 15 lines**: verdict, findings (ID, severity, one line each), what was not verified, where the task file now lives. The full evidence stays in the task file. End with the verdict. Commit, push and porting wait for the user's word.
