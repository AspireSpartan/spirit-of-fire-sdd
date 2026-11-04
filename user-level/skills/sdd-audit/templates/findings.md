# Module review: <module> (<YYYY-MM-DD>)

Request: <who>, <date>: "<the user's words>".

## How it was tested
<Environment (isolated), probe file name and that it was deleted, which roles, which paths (form, API, import), code and database constraints read.>

## Findings (with evidence)

| # | Severity | Finding | Evidence |
|---|---|---|---|
| U1 | **High** | <what happens, and why it matters> | <request → response; rows found; screenshot path; file:line of the cause> |
| U2 | Medium | ... | ... |
| U3 | Low | ... | ... |

## Already safe (tried, no problem)
- <what was tried and what happened, so nobody re-tests it>

## Decisions (planner defaults, tell the user)
- P1 <business choice a fix needs>: default <...>. Change on request.
- P2 ...

## Open questions (the user must answer before task files)
Q1. <question>?
  a) <option> (Recommended): <consequence>
  b) <option>: <consequence>
  Current plan assumes: <...>

## Not verified
- <what could not be tested and why, for example a real concurrent race on a single-threaded test server>

## Acceptance (feature level, for the fixes)
- <behavior a user or a test can confirm, one line each; each finding gets a closing check>
