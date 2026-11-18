# Spec: <title>

Request: <who>, <date>. <one or two sentences in the user's words>

## Why
<the problem today, and what the user wants instead>

## What changes
### Backend
- ...
### Frontend
- ...
### Data / schema
- <tables, columns, migrations; "none" if none>
### API contracts
- `METHOD /path` → `{ data, message }` (errors `{ message, errors }`), or the project's own format

## Non-goals
- <what is deliberately not done, and why>

## Decisions (planner defaults, tell the user)
Business choices the plan assumes. The user confirms or changes them; do not hide them in the tasks.
- P1 <choice>: default <...>, because <...>.

## Ripple check
Readers of anything this changes (status, field, setting, rule) and what each needs. "None: no shared state changes" is a valid answer.
| Reader | What it needs |
|---|---|
| <file, page, template, email, tracker> | <...> |

## Test plan
One row per area this changes. Pick the **lowest level that proves it**: unit for logic, integration for the API and database, browser only for the user flows that matter (the browser check covers the rest). Cover the critical path, error handling, edge cases, the role and permission boundaries and data integrity; skip trivial getters, framework code and one-off scripts.
| Area | Level (unit / integration / browser) | Cases that must be tested |
|---|---|---|
| <service, endpoint, page> | <level> | <happy path; empty or null; error; wrong role; ...> |
Gaps in existing tests this work depends on: <list, or "none">

## Acceptance (high level)
- <behavior a user or a test can confirm, checked where it lands: the other role's page, the row, the email>

## Known limits / risks for the user to accept
- ...

## Open questions (must be answered before task files)
Q1. <question>?
  a) <option> (Recommended): <consequence>
  b) <option>: <consequence>
  Current plan assumes: <...>

## Answers (user, <date>)
<filled in after Cutter relays the answers>
