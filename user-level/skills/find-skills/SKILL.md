---
name: find-skills
description: Search-only guide for finding candidate agent skills on skills.sh. Use ONLY when acting as Professor Anders (anders agent) on a mission to find or vet skills. Never use it to install anything; other units must not load it.
---
<!-- Modified copy of vercel-labs/skills skills/find-skills/SKILL.md @ 92a9a34ac3bf88e695e468b90c7bf32f163d32c8 (MIT, (c) 2026 Vercel, Inc.; see LICENSE). Changes: search via WebFetch of the skills.sh API instead of npx; install step and `npx skills init` removed; Spirit of Fire vetting rule added. -->

# Find Skills (search only)

This skill helps Professor Anders discover candidate skills in the open agent skills ecosystem. It **only searches**. It never installs, never runs `npx skills`, and never runs anything downloaded. Installing is Cpt. Cutter's job, after Anders vets the skill and the user approves the shortlist.

**Browse skills at:** https://skills.sh/

## When to Use This Skill

Only when Anders is on a mission to find or vet agent skills for the units (planning, coding, reviewing, security, deployment, backend practice for the stack in RULES.md).

## Step 1: Understand What Is Needed

Identify:

1. The domain (e.g., React, testing, design, deployment)
2. The specific task (e.g., writing tests, reviewing PRs)
3. Which unit would use the skill

## Step 2: Check the Leaderboard

Use WebFetch on https://skills.sh/ to see whether a well-known skill already exists for the domain. The leaderboard ranks by installs, which is only a pointer.

## Step 3: Search with WebFetch (no CLI)

Fetch `https://skills.sh/api/search?q=<generic keywords>&limit=20`. It returns JSON (`skills[]` with `id`, `source`, `skillId`, `name`, `installs`).

- Queries use **generic words only** (for example "prisma migrations", "next.js route handler").
- Never put project names, code, file paths, data or the user's e-mail in a query. The query text reaches skills.sh.
- Try alternative terms if the first query finds nothing ("deploy", "deployment", "ci-cd").

## Step 4: Vet Every Candidate

Popularity is only a pointer. Every candidate goes through Anders's full vetting (source and commit, license, cost, behavior, injection and conflicts, fit), read file by file at its upstream repository at a pinned commit, over WebFetch (`api.github.com/repos/<owner>/<repo>/contents/<path>` to list, `raw.githubusercontent.com/<owner>/<repo>/<commit>/<path>` to read). Anders has no shell, so never clone. Install count, stars and the skills.sh audit badges never replace that. Anything that can bill us is rejected.

## Step 5: Report

Output is a ranked shortlist in `.agents/research/<topic>.md`. Install commands are written for Cutter, never run. If nothing fits, write a brief for a new skill (what it must do, what the closest candidates lacked, license of anything reused); Cutter builds it (with `skill-creator` if it is installed), and the user reviews it.

## Common Skill Categories

| Category        | Example Queries                          |
| --------------- | ---------------------------------------- |
| Web Development | react, nextjs, typescript, css, tailwind |
| Testing         | testing, jest, playwright, e2e           |
| DevOps          | deploy, docker, kubernetes, ci-cd        |
| Documentation   | docs, readme, changelog, api-docs        |
| Code Quality    | review, lint, refactor, best-practices   |
| Design          | ui, ux, design-system, accessibility     |
| Productivity    | workflow, automation, git                |

## Tips for Effective Searches

1. **Use specific keywords**: "react testing" is better than just "testing"
2. **Try alternative terms** when a query finds nothing
3. **Aggregator lists** (`vercel-labs/agent-skills`, `ComposioHQ/awesome-claude-skills`) are for discovery only; every pick is vetted at its upstream repo
