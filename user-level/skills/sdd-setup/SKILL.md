---
name: sdd-setup
description: First-mission setup for a project that just got the Spirit of Fire SDD template. Inspects the codebase and fills in .agents/supply/RULES.md (stack, versions, folders, conventions, response format, test/lint/build commands, protected areas, branches), seeds MEMORY.md, and drafts the CLAUDE.md header, so the user only reviews instead of filling every <...> by hand. Use when RULES.md still has <...> placeholders, when the user says "set up", "first mission", "onboard this project", "fill in the rules", or when moving an older project's CLAUDE.md/.agents into this layout. Normally run by Jerome.
---

# SDD Setup (first mission)

A fresh template has a `RULES.md` full of `<...>`. Every unit obeys that file, so a wrong guess there spreads into every later task. Your job: fill it from **evidence in the code**, mark what you inferred, and send the real decisions back to the user. A reviewed draft beats a blank template, and an honest "unsure" beats a confident guess.

## 1. Look around (read-only)

Gather facts before writing anything. Note the file each fact comes from.

| Find | Where to look |
|---|---|
| Backend framework + version, language version | `composer.json`, `package.json`, `pyproject.toml`/`requirements.txt`, `go.mod`, `Gemfile`, `pom.xml`/`build.gradle`, `*.csproj` |
| Frontend framework, build tool, router, data fetching, HTTP client, styling, icons | frontend `package.json` dependencies |
| Database and ORM | `.env.example` (`DB_CONNECTION`, `DATABASE_URL`), `config/database.*`, ORM config, migrations folder |
| Auth | auth packages (Sanctum, Passport, NextAuth, Devise, JWT libs), auth config, login routes |
| Folder structure and placement rules | top-level tree, `app/`, `src/` (role folders? feature folders? services layer?) |
| API response format | 2 or 3 controllers/handlers and their tests: what shape do success and error responses have? |
| HTTP client rule (frontend) | is there one central API module (e.g. `src/services/api.js`) that components import? |
| Test isolation: which database the tests and browser tests use, whether they roll back or reset, ports, how uploads and records are cleaned up | `phpunit.xml`, test base classes/traits, `.env.testing`/`.env.e2e`, `playwright.config.*`, `global-setup`/`global-teardown`, a `TESTING.md`. Fills the "Isolated data" and "Cleanup" lines of RULES.md "Testing standard" |
| Test, format, lint, build commands | `composer.json`/`package.json` scripts, `phpunit.xml`, `pytest.ini`, `vitest`/`jest`/`playwright` configs, `Makefile`, CI files (`.github/workflows/`) |
| Branch names | `git branch -a`; default branch; any naming pattern |
| Hosting | `Dockerfile`, `docker-compose*`, `vercel.json`, `netlify.toml`, `fly.toml`, `render.yaml`, CI deploy steps, `DEPLOYMENT.md` |
| Existing agent instructions | an old `CLAUDE.md`, `.agents/`, `.cursorrules`, `AGENTS.md`, `CONTRIBUTING.md`, `README.md` |

Run the test command once if it is cheap and safe (no production database); record the pass count as the baseline. Never run anything destructive (`migrate:fresh`, seeders on a shared database, deploys).

## 2. Protected areas: suggest, don't decide

Which parts must not change without explicit permission is a business decision. Suggest candidates from evidence: authentication, payments, anything with legal or HR meaning, soft-delete behavior, audit logs, data the old instructions already call protected. List them as **suggested**, and ask.

## 2b. Policies: ask, never invent

Policies are rules from outside the code: a company, a client contract, a regulator, or the user's own standing rules (for example how Git may connect, which hosting or AI services are allowed, how customer data is handled, which licenses are acceptable). They bind every unit, so they are the user's call, like protected areas.
- Look for evidence: existing files in `.agents/policies/`, `SECURITY.md`, `CONTRIBUTING.md`, compliance or security docs, rules in an old `CLAUDE.md` or `AGENTS.md`. Files already in `.agents/policies/` are kept as they are; list them in the report.
- **Never write a policy from a guess.** Ask the user whether they have rules agents must follow, and offer to turn what they paste or describe into a policy file.
- When the user gives one, write one file per policy, `.agents/policies/<NAME>.md`, from `templates/policy.md`, with its **Source** line filled in from what they gave you. Keep their wording for the rules; add the "What this means for agents" lines and show them in the report for the user to confirm.
- "No policies for now" is a fine answer: leave the folder empty. The user can add one later by asking Cutter ("add a policy: ...").

## 3. Write the files

- **`.agents/supply/RULES.md`**: replace every `<...>` and delete the `<!-- sof:template ... -->` marker line at the top (the session brief uses it to detect an unfilled template). After each inferred line add a short source in brackets, e.g. `Laravel 13 [composer.json]`. Where you could not tell, write `UNSURE: <what you need>` instead of guessing. Keep the template's section order and the "Memory and notebook" section unchanged. The sections **Testing standard**, **Ripple check**, **Independent review**, **Accepted decisions** and the "Ship only on the user's word" and "Porting" lines under **Branches** are the framework's own rules: keep them as written and only fill the `<...>` in them (how tests are isolated, how cleanup works, branch names). Do not weaken them.
- **`.agents/supply/DECISIONS.md`**: leave the template as it is (an empty log with the Index and the entry format). If the old instructions or the code already record choices the user wants kept ("we deliberately don't ..."), add them as labeled entries (`D-001`, `D-002`...) with one Index line each, and update `Last IDs` in `MEMORY.md`.
- **`.agents/supply/MEMORY.md`**: under "Core conventions" add 3 to 8 one-line facts a new teammate must know (from the code or the old instructions), each labeled `[M-n|area|-]` from `M-001`, and set `Last IDs`. Leave `Highest TASK number: 0` unless the project already has numbered tasks; then continue that numbering.
- **`CLAUDE.md`**: fill in the project name and one stack line at the top. Keep the `@` loader lines (`@.claude/CPT_CUTTER.md` and the depot lines under it; older projects: `@.agents/CPT_CUTTER.md`).
- **Older project being moved in**: carry over every rule from the old `CLAUDE.md`/`.agents` into `RULES.md` (nothing silently dropped). If something does not fit, list it in the report.
- **Do not edit `.claude/spirit-of-fire.json`.** Only the user changes the allowed branches. Put your proposed `allowedBranches` list in the report instead.

## 3b. Browser checks page (`.agents/supply/BROWSER_CHECKS.md`)

Every browser run (Douglas's reviews and audits, Alice's and the ODST's self-checks) follows this page. Do this part in the normal setup, and on its own when Cutter sends you on "setup, browser part" (Douglas reported "browser setup missing"). A project with no UI: say so in the report, and ask whether to write the page as "no UI paths" so the gate never applies.
- **Create it from the template** (the depot already has it after the installer; otherwise copy `project-template/.agents/supply/BROWSER_CHECKS.md` from the installer folder, or write the same sections). Keep its section order: 1 Harness, 2 Dev server, 3 Database, 4 Accounts per role, 5 Routes per module and role, 6 Gate paths, 7 Check set, 8 Test data (+ 8b overlay setup), 9 Evidence, Axe baseline.
- **Fill what the code shows**, with a source in brackets like RULES.md: the dev command and how it takes a port (`package.json` scripts, the framework's `--help`), the env var the auth library needs for a non-default port, the login route and its form selectors (the login page component: `name`, `type`, labels), the roles (the role enum or table, the access rules), the routes per role (page files and the access checks or nav items), the UI paths for section 6 (the folders that render screens and the client API helpers), and how the project proves it is on its local database.
- **Write `TODO: ask the user`** for everything else: which test accounts to use and where their password lives, the default port to avoid, the test-data tag, the cleanup recipe, whether evidence is kept after archiving. Never invent an account or a password.
- **Never without the user's explicit OK:** creating test accounts, seeding, or any other write to a database. The isolated-data rule in RULES.md applies: local or test database only.
- **Harness:** read `HARNESS.md` in the harness folder (`%USERPROFILE%\.claude\tools\pw-harness\`, or the project's `.claude\tools\pw-harness\` for a project-only install). Copy its path into section 1, and run its **smoke command**; record the output (expected: `<playwright-core version> <axe-core version> ok`). Missing harness: write `TODO: run install.ps1 (browser checks)` and say so in the report.
- **Axe baseline:** add an entry `D-n|browser|- <date>: Known axe and layout baseline` (and its Index line) to `DECISIONS.md` (empty list for now, "fill after the first full run"), so known items never live only in `NOTEBOOK.md`.
- Point RULES.md "Commands" at the page (`Browser checks: .agents/supply/BROWSER_CHECKS.md`). Remove the page's `<!-- sof:template ... -->` marker line only when no `<...>` is left; `TODO: ask the user` lines may stay until the user answers (the session brief counts them).

## 4. Report for the user to review

Return this to Cutter (he relays it and asks the questions as multiple choice):

```
SETUP REPORT
Filled from evidence: <count> items  (stack, folders, commands, ...)
Baseline tests: <command> → <result>, or "not run: <reason>"
UNSURE (need the user): <list>
Suggested protected areas: <list with one-line reason each>
Policies: <files already in .agents/policies/, evidence of rules found elsewhere, or "none found">
Proposed allowedBranches for .claude/spirit-of-fire.json: [<...>]
Browser checks: BROWSER_CHECKS.md <filled n sections / TODO n items>; harness smoke: <output, or "harness missing">
Carried over from old instructions: <list>, or "none"

Questions:
Q1. <question>?
  a) <option> (Recommended): <consequence>
  b) <option>: <consequence>
```

Always include one question about policies, for example:

```
Q<n>. Do agents need to follow any company, client or personal rules (Git connectivity, allowed services, data handling, licenses)?
  a) No policies for now (Recommended if none apply): the policies folder stays empty; add one later by asking Cutter.
  b) Yes, I'll paste or describe them: Jerome writes one policy file per rule set for you to confirm.
```

When the answers come back, write any policy files the user described, update `RULES.md` (remove the `UNSURE:` lines and the source brackets the user confirmed if they prefer a clean file) and report done.
