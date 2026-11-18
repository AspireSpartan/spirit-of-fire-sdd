---
name: sdd-plan
description: Planner procedure for spec-driven development (SDD) in full-stack projects that keep an .agents/ folder. Use it whenever you plan a feature, bug fix, schema or API change, migration, deployment or refactor before coding; whenever someone asks for a spec, plan, blueprint, task breakdown or TASK-N files; and always when acting as Jerome or the Planner role, even if the request does not say "spec".
---
<!-- Parts adapted from anthropics/knowledge-work-plugins engineering/skills/testing-strategy/SKILL.md @ e91a134 (Apache-2.0; see THIRD_PARTY_NOTICES.md). Changes: testing pyramid and cover/skip list turned into the spec's test plan and the task's Tests to write. -->

# SDD Plan (Jerome)

Turn a request into three things, in order: `spec.md` (what and why), `plan.md` (how and in what order), and atomic `TASK-N` files (what to build next, with checks). The point is that the Coder never has to guess and the Reviewer has something concrete to check against. Planning mistakes are cheap here and expensive in code.

## 1. Read the supply depot first

Every project keeps its shared state in `.agents/`:

| File | Why you read it |
|---|---|
| `.agents/supply/RULES.md` | Fixed stack, conventions, branch rules. Your plan must not break them. |
| `.agents/supply/MEMORY.md` | Current state, the `Highest TASK number` line (the next task is that number + 1) and `Last IDs`. Older lines live in `memory-archive/`: use the **Archive index**, then search that file for the ID or `|area|`; never read an archive whole. |
| `.agents/supply/NOTEBOOK.md` | What happened last session and what is unfinished. |
| `.agents/supply/DECISIONS.md` | What the user decided to leave as it is. Search its **Index** for the area you plan and open only the entries you need by ID; never plan a "fix" for something listed there without asking. |
| `.agents/policies/*.md` | Policies that bind every role (company, client or the user's own rules), if any. |
| `.agents/specs/`, `.agents/tasks/` | Only when the request continues existing work, or **when an audit left findings** (`.agents/specs/<module>-review/spec.md`): then that spec is your input. Otherwise start clean so old scope does not leak in. |

Older projects may keep RULES/MEMORY/NOTEBOOK in `.agents/skills/` instead of `.agents/supply/`; use whichever exists.

## 2. Investigate before you write

**Reading budget:** search first (grep, file lists), then open only the files on your ripple list. If you need more than about 25 files, or a sweep of the whole codebase, send the built-in `Explore` agent and read its summary instead of the files. Look at the real code the request touches: the files, the routes, the schema, the tests. Count things (how many call sites, how many tests depend on X) instead of guessing; numbers in a spec make the risk visible. If a choice between technologies or designs is involved, use the `architecture` skill and save the decision record next to the spec.

### Ripple check (before you plan any change to shared state)
If the work changes a status value, an action name, a shared column, a settings key, an API field name or a uniqueness rule, **list everything that reads it** (grep backend, frontend, templates/PDF, email, trackers, dashboards, tests). Write that list in the plan and in each task that touches it, with what each reader needs. A change that looks local often breaks a reader nobody remembered; it is cheaper to find it here than in review.

### Planning from audit findings
When a `<module>-review/spec.md` exists, it is the contract: plan one fix per finding (or group closely related ones), keep its IDs (U1, U2, ...) in the task files, and add a closing check for each finding. Take the audit's **Decisions (planner defaults)** into the spec unchanged unless the user's answers say otherwise. Fixes that came out of an audit are reviewed **independently** (see `sdd-review`), so make every task testable by someone who has not seen your reasoning.

## 3. Write `spec.md` and `plan.md`

Folder: `.agents/specs/<request-name>/` (short kebab-case). Use the templates in `templates/spec.md` and `templates/plan.md`.

- **spec.md**: problem, goals, non-goals, data/schema changes, API contracts in the project's response format, a **test plan**, high-level acceptance, known limits, **open questions**.
- **Test plan** (a short table in the spec): for each area, the lowest test level that proves it (unit for logic, integration for API and database, browser only for flows that matter) and the cases that must be tested: critical path, error handling, edge cases (empty, null, too long, duplicate), role and permission boundaries, data integrity. Skip trivial code. Note gaps in existing tests the work relies on. Each task copies its rows into **Tests to write**.
- **plan.md**: task order with a reason for the order, files to create and change (exact paths), patterns to copy, risks.

## 4. Open questions go back to the commander

You cannot talk to the user. Anything that is the user's call (business rules, schema meaning, which of two valid options, cost, scope) goes in the spec under **Open questions** and in your report, in this shape so Cutter can ask it as a multiple-choice question:

```
Q1. <question>?
  a) <option> (Recommended): <what happens if chosen>
  b) <option>: <what happens>
  Current plan assumes: <a or b, or "nothing yet">
```

Stop after writing the spec when there are open questions. When Cutter sends the answers, record them in the spec under **Answers (user, <date>)** and continue. Do not create task files while questions are open; tasks built on a guess have to be rewritten.

## 5. Write the task files

Folder: `.agents/tasks/`, named `TASK-<N>_<short-name>.md`, numbered in execution order starting at `Highest TASK number + 1`. Use `templates/task.md`, and fill its **Context** block for every task: the spec and plan lines that task needs, so the Coder does not read the whole spec. Prefer fewer, coherent tasks over many small ones: each task costs a full agent start for the Coder and for Douglas. Each task should be small enough for one Coder session and have acceptance boxes a stranger could verify (a command and its expected result, a behavior in the browser, a grep that returns nothing). Put a **suggested effort** (low, medium, high) at the top of each task. Cutter uses it to pick the Coder: **low and medium go to the ODST** (a cheaper model), **high goes to Alice**. Mark high for protected areas, migrations, security, money, dates and time zones; a low or medium task must be buildable from its own Context block.

Every task lists its **Tests to write** (its rows from the test plan: level and cases, 1 to 5 lines), and carries, as acceptance boxes (see `templates/task.md`): a **ripple check** when it changes shared state, **reproduce first** for a bug (the failing test, recorded), and a **mutation check** (undo the fix, a test fails, restore). The last task of a feature is usually an independent review task for Douglas (browser test plus acceptance pass).

## 6. Update memory and report

Update `Highest TASK number` and add one labeled line for the feature under **Open work** in `MEMORY.md` (`[M-n|area|TASK-a..b]`, next ID from `Last IDs`; respect its word cap and the 700-word ask, see the rules there). Then report to Cutter in at most about 15 lines: files written, open questions, **the business choices you made as defaults** (so the user can confirm them), task list with suggested effort. End your report with **"Done planning."** In gated mode Cutter now stops and waits for the user's go before the Coder starts.

## What not to do
- Do not write application code, config or tests. If you catch yourself editing `src/` or `app/`, stop.
- Do not quietly drop part of the request; list it under non-goals with the reason.
- Do not invent business rules. Ask.
