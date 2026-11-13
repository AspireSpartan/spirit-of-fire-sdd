# TASK-N — <short title>

**Spec/Blueprint:** `.agents/specs/<request>/spec.md`, `plan.md`
**Findings closed:** <audit finding IDs, e.g. U1, U4, or "none">
**Depends on:** TASK-<N-1>, or "nothing"
**Suggested effort:** low / medium / high   (low or medium: the ODST builds it; high: Alice)
**Files touched:** <exact paths, new and existing>

## Context (from the spec)
The 10 to 20 lines of the spec and plan this task needs, copied or tightly summarized: the decisions (P-numbers, answers), the contracts, the ripple rows and the check recipe steps that apply. The Coder (ODST or Alice) reads this instead of the whole spec, so for a low or medium task it must be enough on its own. Name the spec sections it came from, so a reviewer can check them.

## What
1 to 3 sentences. Concrete implementation details.

## Why
One line tying back to the spec.

## Rules to watch
Anything from RULES.md, DECISIONS.md or policies that matters here.

## Ripple check
(Only when shared state changes: a status, action name, shared column, settings key, API field, uniqueness rule.) Every reader of it, and what each needs:
- <reader (file or page)>: <what it needs>

## Acceptance check
- [ ] <specific, testable statement: command + expected result, or browser behavior, checked where the effect lands>
- [ ] <another one>
- [ ] **Reproduced first** (bugs): the failing test was written before the fix and its failure recorded in Result.
- [ ] **Mutation check recorded:** undo the fix, a test fails, restore it (`diff` identical).
- [ ] Formatter and linter pass on touched files.

## Notes for Coder
Gotchas. Existing code to copy the style of. What not to touch.

## Result
(Coder fills in, at most about 40 lines: commands and counts, the failing-first run, one line per mutation check, what was verified, what was not and why. Long evidence goes in `.agents/tasks/evidence/TASK-N.md`.)

## Review
(Reviewer fills in: verdict, evidence, findings, the reviewer's own mutation checks.)
