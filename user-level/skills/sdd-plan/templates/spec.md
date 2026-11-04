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
