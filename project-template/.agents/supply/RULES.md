# Rules — read every time

<!-- sof:template — this line marks an unfilled template. The sdd-setup mission removes it when RULES.md is filled in. -->

These bind Cpt. Cutter, the Marines, Jerome, Alice, the ODST and Douglas. Every session. Fill in every `<...>` when you set up a project.

## The stack is fixed

**Backend:** <framework + version, language version, auth, database, ORM, test runner, formatter>
**Frontend:** <framework, build tool, router, data fetching, HTTP client, styling, icons>
**Hosting:** <where each part runs, or "local only">

- Do not install anything not on this list without asking.
- <Do not swap X for Y.>

## Conventions that must not break
- Folder structure: add to it, don't reorganize. <e.g. controllers in role folders; pages in src/pages/<role>/>
- API responses: <e.g. `{ data, message }`; errors `{ message, errors }`>.
- <e.g. Never call the HTTP client directly from components; use src/services/api.js.>
- Real logic goes in <services folder>, not in controllers or pages.
- One job per file.

## Protected areas
Change these only when a task file explicitly says so:
- <e.g. authentication, payments, legal documents, soft-delete behavior>

## Commands
- Backend tests: `<command>`
- Backend format: `<command>`
- Frontend lint: `<command>`
- Frontend build: `<command>`
- Browser tests: `<command>` (see `sdd-review` → Playwright)

## Branches
- <branch family and allowed push/merge targets; anything else: stop and ask>
- The allowed list is enforced by the branch guard hook: `allowedBranches` in `.claude/spirit-of-fire.json` (exact names, or a prefix ending in `*`). Keep it in sync with this section. Only the user edits it.
- Never use `git push --all` or `--mirror`.
- **Ship only on the user's word:** commit, push, merge and porting a change to another branch each need the user's explicit OK. "Maybe we should" is a question, not an OK.
- **Porting a change between branches** (user OK each time): commit on the source branch, `git diff <hash>~1 <hash>` (leave out `MEMORY.md` and `NOTEBOOK.md`) into a scratch file, check out the target, `git apply --check`, then `git apply`. Never cherry-pick or merge unless the user asks. Run the target's tests, update the target's own `MEMORY.md`, commit with "Re-applied by hand from <branch> (<hash>)".

## SDD flow
`spec.md` → `plan.md` → `TASK-N` files → code → review. No task file, no code (Marines write a quick task file first).

## Testing standard
- **Behavior, not appearance.** Every save path a task touches is exercised end to end and the effect is checked **where it lands**: another role's page, the database row, a login attempt, the PDF, the email. A label or icon test is not proof that a feature works.
- **Reproduce first** for bugs: write the failing test before the fix and record that it failed.
- **Mutation check:** for each fix, undo it, show a test fails, restore it (verify with `diff`), and record the result in the task file. If undoing a fix does not fail any test, the test is not guarding it; add one.
- **Isolated data.** Tests and throwaway probes run on a test database or an isolated test environment: <how>. Never probe or test destructively on development, staging, UAT or production data.
- **Cleanup.** <If tests upload files or create records, say how they are cleaned up, and where the reviewer sees proof.>
- A failure that passes on rerun is reported as a **suspected flake** (with both results), never silently ignored.

## Ripple check (before changing shared state)
Before changing a status value, an action name, a shared column, a settings key, an API field name or a uniqueness rule, list **everything that reads it** (grep backend, frontend, templates/PDF, email, trackers, dashboards, tests) and write the list in the task file with what each reader needs. A change that looks local often breaks a reader nobody remembered.

## Independent review
For a feature of **3 or more tasks**, and for the fixes that come out of an audit, the review is independent: Douglas (or any fresh session) gets only the spec, the task files and the diff, not the Coder's reasoning, re-tests every claim himself, and runs his own mutation checks. His verdict is APPROVED or CHANGES REQUESTED.

## Accepted decisions
`.agents/supply/DECISIONS.md` lists what the user decided to leave as it is, and known limits. It has no line cap and is never pruned by age. Search it before "fixing" something that looks like a gap, and add an entry when the user says "leave it".

## Memory and notebook

**`MEMORY.md`: project state, max 800 words.** Every unit reads it at the start of every mission, so its size is paid many times.
- Check the word count before and after every write (PowerShell: `(Get-Content .agents/supply/MEMORY.md -Raw).Split().Count`). Never go over 800.
- Keep `Highest TASK number: N` near the top; update it with every new task.
- One fact per line, about 200 characters max. Results, numbers and evidence go in the task file, never here.
- While a feature is open: one line per task under it in **Open work**, at most about 20 words (`TASK-N short name: status`). When the feature is approved: replace those lines with one line under **Finished**.
- When near the cap, shorten the oldest Finished lines first. Never prune open work or core conventions just because they are old.

**Task files and evidence.** A task's **Result** and **Review** stay short (about 40 lines each). Long evidence (matrices, full tables, logs) goes in `.agents/tasks/evidence/TASK-N.md`, linked from the task, so later readers open it only when they need it.

**`DECISIONS.md` is searched, not read whole.** Keep each entry's first line short and searchable: `<date> | <area> | <decision>`.

**`NOTEBOOK.md`: session handoff, max 50 lines.**
- Written only when the user asks ("write the notebook"). Each write replaces the whole file.
- Sections, in order: **Date and branch**, **Done this session** (with commit hashes or "not committed"), **In progress**, **Decisions made by the user**, **Open questions**, **Next** (numbered, first step first).
- Facts only: paths, commands and results, what was and was not verified.
- The session-start hook reads **In progress** and **Next**, so keep those headings exactly.

## When unsure
Stop and ask. Don't guess at schema, business rules, or which of two options is right.
