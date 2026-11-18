# Project Memory & State Tracker

Max 800 words; check the word count before and after every write. At 700 words, stop and ask the user: archive, trim, or both. One fact per line, about 200 characters, each with a label `[M-n|area|TASK-n]`. Details live in the task files, never here. Rules: `RULES.md` → "Memory and notebook".

**Highest TASK number: 0.** **Last IDs: M-000, D-000.** Task files: active in `.agents/tasks/`, waiting for review in `requires-review/`, finished in `archive/<feature>/` (quick fixes in `archive/quick-fixes/`). Long evidence: `.agents/tasks/evidence/`.

## Core conventions
- <[M-001|area|-] one fact per line: stack decisions, schema conventions, gotchas everyone must know>

## Known issues
- <[M-002|area|-] environment quirks and traps, one line each>

## Open work
While a feature is open, one line per task under it, at most about 20 words: `TASK-N short name: status`. When the feature is approved, replace its lines with one line under Finished.
- <[M-003|area|TASK-a..b] feature (planned date, spec path): one-line summary>
  - <TASK-N short name: status>

## Finished (one line per feature; details in `archive/<feature>/`)
- <[M-004|area|TASK-a..b] feature: what it did. APPROVED date; commits>

## Archive index (entries moved out; grep the file for the ID or `|area|`, never read it whole)
- <memory-archive/M-001.md: M-001..M-087; areas auth, billing, ui; moved 2026-11-18>
