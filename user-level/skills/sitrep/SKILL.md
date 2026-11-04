---
name: sitrep
description: Situation report for projects using the Spirit of Fire SDD workflow (.agents/ folder). Use when the user types /sitrep or asks "where are we", "status", "what's next", "what's open", "sitrep", or returns after a break and wants to know the state of the project, even mid-session.
---

# Sitrep

Give the user a short, factual status of the project at any moment. Use facts from the files, not memory of the conversation, because the files are what the next session will see.

## Gather
1. Run the session brief script if the project has it:
   `node "$CLAUDE_PROJECT_DIR/.claude/hooks/session-brief.mjs"` (from the project root `node .claude/hooks/session-brief.mjs` also works).
   If it is missing, read `.agents/supply/NOTEBOOK.md` and `.agents/supply/MEMORY.md` (older projects: `.agents/skills/`).
2. List task files: `.agents/tasks/*.md` (open), `.agents/tasks/requires-review/*.md` (waiting for Douglas).
3. `git status --short` and `git log --oneline -3` for uncommitted work and the last commits.

## Report (this exact shape, keep it short)
```
SITREP
Branch:        <branch>   (<n> uncommitted files, or "clean")
Hand-off mode: <gated | auto>   (gated = each stage stops and waits for the user's go)
Last commits:  <hash subject>, <hash subject>
Open tasks:    <TASK-N names, or "none">
For review:    <TASK-N names, or "none">
Notebook next: <item 1 of the notebook Next list>
Next task no.: <Highest TASK number + 1>
```
If a stage was waiting for the user's go (for example "Done planning" with tasks not yet built, or "ready for review" not yet reviewed), say so in the recommendation. Then one line with your recommendation for the next order, for example "Recommend: send Alice on TASK-153 (effort high)". Do not start work; wait for orders.
