# Browser checks: how every browser run is done here

<!-- sof:template — this line marks an unfilled template. The sdd-setup mission (browser part) removes it when this page is filled in. -->

Read by Cutter, Alice, the ODST and Douglas before any run in a real browser (review, audit, self-check). RULES.md "Commands" points here. The Marines and the ODST on a quick fix skip it (CPT_CUTTER 2d).

Fill every `<...>`. Jerome's setup mission fills what the code shows and writes `TODO: ask the user` for the rest. Never put a password in this page.

## 1. Harness
- Path: `<%USERPROFILE%\.claude\tools\pw-harness\ (global install) or <project>\.claude\tools\pw-harness\ (project-only install)>`, outside the repo for a global install. Packages `playwright-core` and `axe-core`, exact versions. Paths, versions and the smoke command are in its `HARNESS.md`: read it, do not retype versions.
- Browser builds: the harness downloads none. It reuses the cached builds in `%LOCALAPPDATA%\ms-playwright\`; the exact `executablePath` for headless and visible runs is in `HARNESS.md` (and `harness.json`, which the review script reads). Always pass `executablePath`; never `npx playwright install`.
- Script template: `sdd-review/references/review-script.template.cjs` (in `~/.claude/skills/`, or the project's `.claude/skills/` for a project-only install). Scripts live in the session scratchpad or the task's evidence folder, never in the repo.

## 2. Dev server for a run
- Pick a free port, default `<port, e.g. 3199>`: `Get-NetTCPConnection -LocalPort <port> -ErrorAction SilentlyContinue` must print nothing, else try the next lower port.
- Start it in PowerShell, in the background: `<dev command with the port, e.g. npx next dev -p <port>, plus any env var the auth library needs for that port>`. Wait for `curl -s -o NUL -w "%{http_code}" http://localhost:<port><login route>` to answer 200 (the first request compiles; give it 20 s or more).
- Never stop, restart or reuse the user's own dev server (`<usual port, e.g. 3000>`). `<anything that must not run at the same time, e.g. no production build while a dev server runs>`.
- When done, stop **your** server by its port: find the owner with `Get-NetTCPConnection -LocalPort <port> -State Listen`, then `taskkill /PID <pid> /T /F`. Record that the port is free and the user's server untouched.

## 3. Database
`<the check that proves the run uses the local/isolated database, e.g. a db:check script showing host localhost; when to stop>`. Rules: RULES.md "Testing standard", Isolated data and Cleanup. Never a shared, staging or production database.

## 4. Accounts per role
| Role | Email or user name | Lands on after sign-in |
|---|---|---|
| `<ROLE>` | `<test account>` | `<route>` |

Password: `<where it lives, e.g. a gitignored script or a password manager entry>`; never copy it into a task file, evidence or this page. Create the accounts with `<command>` (only with the user's explicit OK; local database only). Say whether they are standing accounts or deleted after a run.

**Password into the run's env var:** `<a PowerShell line that sets the env var named in the script's passwordEnv without printing it>`. The variable lives only in that shell. Never `echo` it, never write it to a file, never paste its value into a log or task.

## 5. Routes per module and role
Access from `<files that define access, e.g. the role table and the nav items>`. `<n>` pages. Y = can open, - = refused (redirect to the role's home or a no-access page).

| Route | Needs | `<ROLE 1>` | `<ROLE 2>` |
|---|---|---|---|
| `/login` | none | Y | Y |
| `<route>` | `<permission>` | `<Y or ->` | `<Y or ->` |

Recount with `<glob for page files>` when pages are added.

## 6. Gate paths
A task touching `<UI paths, e.g. src/app/**, src/components/**, the client API helpers>` needs the "Browser evidence" block in Douglas's review, unless the user waived it in the brief.

## 7. Check set
Viewports 360x780, 390x844, 1280x800 and 200% zoom (640x400); axe with the tags in the template; keyboard walk of 40 stops plus Tab-out-of-dialog for each overlay; console errors; sideways scroll; headless unless the brief says visible. The template does all of it. `<anything this project adds or leaves out>`.

## 8. Test data
- Values a run saves start with `<test tag, e.g. SOF-TEST>`. Count the touched tables before and after with `<a script that prints counts only>`.
- **Logins may add session rows** (one per sign-in). "Counts identical" means every other table; record the session delta on its own line.
- Scripts never open `.env*` files themselves; database counts and deletes go through a script that uses the app's own database setup.
- Delete **by id only**, ids recorded in the task file. Never delete by a time window or a broad pattern (it can remove other people's rows). A cleanup script, if the project has one: `<name>`, dry run first, never on rows you did not create.

## 8b. Overlay setup example
An overlay that needs client state before its opener works (for example a cart that opens only once it has a line) gets a `setup` in the script's ROUTES entry. A `setup` changes client state only (clicks, typing), writes no rows, and **asserts its own effect**, so a broken click fails instead of passing on an empty overlay:
```
{ path: '<route>', roles: ['<role>'], overlays: [
  { name: '<overlay>', opener: '<opener selector>', vp: [360, 390],
    setup: async (page) => {
      await page.getByRole('button', { name: /<first action>/ }).first().click();
      // Assert the effect: throws (so the run logs "setup failed") if it never appears.
      await page.getByRole('button', { name: /<text that proves the state, e.g. a count>/ }).waitFor({ state: 'visible', timeout: 3000 });
    } },
] },
```
`vp` limits the overlay to the widths where it is a dialog (a side panel on wide screens is not). `readyRoles` lists the roles that must see the route's `ready` selector; pick a marker that is visible at every width the route runs at. Overlays that need a database row: seed it with `<seed recipe>`, tag it with the test tag, record the ids, delete by id afterwards.

`<project overlays and their notes>`

## 9. Evidence
`.agents/evidence/TASK-N/` (global depot: the `.agents/evidence/` line of the Depot map): `<role>-<route-slug>-<width>.png`, `-zoom200.png`, `-<overlay>.png`, and the script's `run.log`. The written record goes in `.agents/tasks/evidence/TASK-N.md`, linked from the task. `<ignored by git? kept after archiving? deleted only on the user's word?>`

## Axe baseline
Known axe items live in `DECISIONS.md` (entry "Known axe and layout baseline"), never only in `NOTEBOOK.md`, which gets replaced. Copy its rule list into `KNOWN_AXE` in the run config. Findings that match are `baseline`; a new node of the same rule on another route is NEW.

`<rule id, route, widths: one line each, or "none yet">`
