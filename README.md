# Spirit of Fire SDD

**Edition: general.** The policies folder starts empty and Jerome asks about your rules at setup. A company edition with a Git connectivity policy is a separate package.

A reusable **spec-driven development (SDD)** setup for Claude Code, for any full-stack project. It is built around the crew of the *Spirit of Fire* from Halo Wars:

| In the game | In this setup | What it does | Model |
|---|---|---|---|
| **Captain Cutter** | The main Claude conversation | Talks with you, picks who takes each job, sets the effort, asks you questions, reports back | your session model (Sonnet recommended) |
| **Jerome** (Red Team leader) | `jerome` agent | **Planner**: writes the spec, the plan and the task files. Never writes code. | Opus |
| **Alice** | `alice` agent | **Coder**: builds one task at a time and proves it works | Sonnet |
| **Douglas** | `douglas` agent | **Reviewer and Auditor**: reviews finished work in a browser (Playwright), and **audits** an existing module before fixes are planned. Approves or sends it back. | Sonnet |
| **Professor Anders** | `anders` agent | **Researcher and Skill vetter**: finds facts outside the repo, and finds and vets new skills before anything is installed. Read-only, no shell. | Sonnet |
| **Marines** | Cutter himself, using the `sdd-marine` skill | Small fixes: plan, code and check in one pass | your session model |
| **Supply depot** | `.agents/` in each project, or a global folder per project and branch | Rules, memory, notebook, **decisions**, policies, specs, tasks: what every unit reads first | |
| **Armory** | `~/.claude/skills/` | Skills any unit can pick up (debug, architecture, testing-strategy, ...) | |

**In one sentence:** you give the order, Cutter decides whether the Marines handle it or the Spartans (Jerome, then Alice, then Douglas) take it, and every job leaves a written record in the supply depot.

**New in v0.4** (see `CHANGELOG.md`): the installer asks **where to install** (globally or this project only) and **where the supply depot lives**: in the project and committed, in the project but ignored by git, or in a **global folder per project and branch**, outside the repository, so specs and memory are never committed and every branch's work can be read without switching branches.

**New in v0.3** (lower usage, see `CHANGELOG.md`): agents read less (short memory capped by words, a **Context** block in every task instead of the whole spec), tests run cheaper (affected tests while working, the full gate once), reports back are short, Jerome plans at medium effort, Cutter suggests fresh sessions, and **Professor Anders** vets every outside skill. The accuracy rules are unchanged.

**New in v0.2** (lessons from a real project): an **Audit** mission (Douglas probes a module and writes findings before anything is planned), **gated hand-offs** (each stage stops for your go), a never-pruned **`DECISIONS.md`**, hard rules for **reproduce-first, mutation checks, ripple checks and independent review**, and **"ship only on the user's word"**.

---

## What's in this folder

```
Spirit-of-Fire-SDD/
├── README.md                  ← you are here
├── install.ps1                ← asks: global or project only, and where the depot lives; then copies (never overwrites; -Update replaces framework files after a backup)
├── user-level/                ← install ONCE for your Windows user; shared by all projects
│   ├── agents/                    jerome.md, alice.md, douglas.md (reviews and audits), anders.md (research, skill vetting)
│   └── skills/                    sdd-setup, sdd-audit, sdd-plan, sdd-code, sdd-review (+ demo tour), sdd-marine, sitrep, find-skills (Anders only)
└── project-template/          ← copy into EACH project
    ├── CLAUDE.md                  short loader: Cutter's orders + RULES and MEMORY from the depot
    ├── .gitignore                 ignores the hooks' per-machine state and settings.local.json
    ├── .claude/
    │   ├── CPT_CUTTER.md          the commander's standing orders (was .agents/CPT_CUTTER.md)
    │   ├── settings.json          turns on the 3 hooks below
    │   ├── spirit-of-fire.json    YOUR settings: allowed branches, notebook reminder level, hand-off mode, depot
    │   └── hooks/
    │       ├── session-brief.mjs      session start: branch, depot map, notebook "In progress"/"Next"
    │       ├── depot.mjs              works out where the depot is (project or global, which branch)
    │       ├── branch-guard.mjs       blocks push/merge/PR to branches not on your list
    │       └── notebook-reminder.mjs  offers to write the notebook when context gets full
    └── .agents/                   the supply depot (in the project, or copied to the global folder)
        ├── supply/                RULES.md, MEMORY.md, NOTEBOOK.md, DECISIONS.md
        ├── policies/              your company, client or personal rules (empty; Jerome asks at setup)
        ├── specs/                 one folder per request
        └── tasks/                 TASK-N files → requires-review/ → archive/
```

**Why two parts?** The Spartans and their skills are the same in every project, so they live in your user folder (`C:\Users\<you>\.claude\`). Each project only brings its own supply depot, because rules and memory are different per project.

---

## Setup

### Step 0: Get this folder on your computer

Clone it from wherever you keep it:

```powershell
git clone https://github.com/<your-account>/spirit-of-fire-sdd.git
cd spirit-of-fire-sdd
```

To get updates later: `git pull`, then run the installer again (it only adds new files; see "Updating" below).

### Step 1: Run the installer and choose global or project only

Open PowerShell in this folder and run:

```powershell
.\install.ps1
```

It asks three questions, then shows a preview before it copies anything:

1. **Where to install:**
   - **[1] Globally:** the Spartans and skills go to `C:\Users\<you>\.claude\` and every project on this computer sees them. The commander, supply depot and hooks go into the project you name. Pick this when Spirit of Fire is your only SDD setup.
   - **[2] Project only:** everything goes inside the project, including the Spartans and skills (to `<project>\.claude\agents\` and `<project>\.claude\skills\`). Nothing is written to your user folder. Pick this to try Spirit of Fire, or when you run **another SDD setup** in other projects, so the two never mix.
2. **Which project folder** (Enter uses the current folder). For a global install you can type `-` to install only the agents and skills.
3. **Where the supply depot lives** (rules, memory, notebook, specs, tasks). See "Where the supply depot lives" below:
   - **[1] In the project, committed** (`.agents\`, the v0.3 layout).
   - **[2] In the project, ignored by git**: `.agents/` is added to `.gitignore`.
   - **[3] Global folder, by project and branch**: `C:\Users\<you>\.claude\spirit-of-fire\<owner-repo>\`, outside the repository. It also asks the folder name (Enter keeps `owner-repo` from the git remote).
4. **The preview** lists what is already there with the same name: Spartans, skills, `CLAUDE.md`, `.claude\settings.json`, `.claude\hooks` and `.agents\`. Those are skipped, never overwritten. For a project-only install it also warns when your user folder has a Spartan or skill of the same name, because Claude Code may use that copy instead. Type `Y` to go on or `N` to stop with nothing copied.

**Trying it next to another SDD setup?** Use project only, on a separate git branch or worktree of the project, and check the preview. If it lists `CLAUDE.md` or `.claude\settings.json`, Spirit of Fire or its hooks won't load until you merge them (see "already has a CLAUDE.md" below).

**Without questions** (scripts, or when you already know):

```powershell
.\install.ps1 -Scope Global  -Project "D:\path\to\your-project"   # global agents + skills, and this project
.\install.ps1 -Scope Global                                         # global agents + skills only
.\install.ps1 -Scope Project -Project "D:\path\to\your-project"   # everything inside this project
.\install.ps1 -Scope Project -Project "D:\path\to\your-project" -Depot Global           # ... with a global depot
.\install.ps1 -Scope Global  -Project "D:\path\to\your-project" -Depot ProjectIgnored   # depot in the project, not committed
```

`-Depot` is `Project` (default), `ProjectIgnored` or `Global`; `-DepotName <name>` sets the global folder's name.

The older `-UserLevel` and `-Project "<path>"` options still work and mean a global install, as before.

### Where the supply depot lives

Pick it once per project in the installer; it is saved as `depot` in `.claude/spirit-of-fire.json`.

| Choice | Where | Committed? | Good for |
|---|---|---|---|
| **In the project, committed** (`project`) | `<project>\.agents\` | yes | a team that wants specs and tasks in the repo |
| **In the project, ignored** (`project-ignored`) | `<project>\.agents\`, listed in `.gitignore` | no | keeping it private; git leaves ignored files alone, so every branch sees the same files |
| **Global** (`global`) | `C:\Users\<you>\.claude\spirit-of-fire\<owner-repo>\` | no, outside the repo | private files, one set per branch, readable from any branch or worktree |

**The global layout**, for example a repo `acme/er-tool` with branches `main` and `SEMI-CLOUD-123/login`:

```
D:\work\er-tool\                       the project: no private files in it
├── CLAUDE.md                          @.claude/CPT_CUTTER.md + RULES and MEMORY from the depot
└── .claude\
    ├── CPT_CUTTER.md, settings.json, spirit-of-fire.json, hooks\
    ├── settings.local.json            lets Claude Code use the depot folder (per machine, not committed)
    └── agents\  skills\               only for a project-only install

C:\Users\you\.claude\spirit-of-fire\acme-er-tool\
├── RULES.md  MEMORY.md  DECISIONS.md  shared by every branch
├── policies\  research\               shared
├── archive\                           finished tasks, and merged branches
│   └── SEMI-CLOUD-120-reports\
└── branches\
    ├── main\                          NOTEBOOK.md, specs\, tasks\ (requires-review\, evidence\)
    └── SEMI-CLOUD-123-login\          "/" in a branch name becomes "-"
```

How it works:
- **Rules, memory and decisions are shared**, because they describe the whole project: a decision made on one branch is still known on `main`. Task numbers stay unique across branches.
- **Each branch has its own notebook, specs and tasks.** The session brief hook finds the branch's folder at every start and creates it with an empty notebook the first time you open a new branch. You never type a path.
- **Read another branch's work without switching:** *"read the login spec from SEMI-CLOUD-123"*. Cutter opens it straight from the depot.
- **Skills keep saying `.agents/...`.** The session brief prints a **Depot map** from those paths to the real ones, and Cutter puts it in every mission brief. After a branch switch inside a session, Cutter runs `node .claude/hooks/depot.mjs` for the new map.
- **After a merge, say** *"SEMI-CLOUD-123 is merged, archive it"*. Cutter moves its folder to `archive\SEMI-CLOUD-123-login\`, adds one line to `MEMORY.md` and asks before moving any task that is still open. Nothing is archived on a guess.
- **Moving an existing project to global:** run the installer and pick Global. Your `.agents\` is **copied** into the depot (specs and open tasks into the current branch's folder, archived tasks into `archive\`); nothing is moved, deleted or overwritten. Check the depot, then delete `.agents\` yourself. If `.agents\` was committed, the installer prints the `git rm -r --cached .agents` command to stop tracking it.
- **First session:** Claude Code asks once whether `CLAUDE.md` may load files from outside the project (the depot). Say yes.
- **It lives only on this computer.** A teammate, another computer or a cloud session does not see it; a new clone gets an empty branch folder once you run the installer there. To back it up or share it between your computers, make the depot folder its own private git repo.

### Step 2: Finish the setup in the project

Then, in that project:
1. **Check Node.js is installed** (`node -v`). The hooks need it.
2. **Start Claude Code in the project.** The session brief sees that `RULES.md` is still the template, and Cutter offers the **first mission**:
   > "Send Jerome on the setup mission? He inspects the code and fills in RULES.md for you to review."

   Say yes. Jerome reads the code (package files, configs, folders, controllers, tests, CI, git branches, any old CLAUDE.md) and fills in `.agents/supply/RULES.md`, `MEMORY.md` and the top of `CLAUDE.md`. Every line he inferred shows its source, for example `Laravel 13 [composer.json]`. Anything he couldn't tell is marked `UNSURE`.
3. **Review his report and answer his questions.** Cutter asks them as multiple choice. Protected areas and policies are always asked, never guessed, because they're business decisions.

   `RULES.md` is the most important file: every unit obeys it. Read it once after setup. You can still fill it by hand instead if you prefer.
4. **Set your branches in `.claude/spirit-of-fire.json`.** Jerome proposes a list, but only you edit this file. List every branch the AI may push or merge to. An entry ending in `*` means "starts with":
   ```json
   {
     "allowedBranches": ["SEMI-CLOUD-*"],
     "notebookReminderTokens": 80000
   }
   ```
   Everything not on the list is blocked. Leave the list empty (`[]`) to turn the guard off.
5. **Restart Claude Code** so the branch list takes effect for the hooks.

**The project already has a `CLAUDE.md` or `.agents/`?** The installer skips those files. If your `CLAUDE.md` is not a Spirit of Fire loader (for example another SDD setup's), the installer shows the loader lines it needs and asks before adding them to the end (a backup is kept). A v0.3 loader (`@.agents/CPT_CUTTER.md`) is updated to the v0.4 lines automatically, with a backup. Easiest: ask Cutter for the setup mission. Jerome carries every old rule into `RULES.md` and lists anything that didn't fit. Or merge by hand:
- Move what your old `CLAUDE.md` says into `.agents/supply/RULES.md` or `.claude/CPT_CUTTER.md`, then replace `CLAUDE.md` with the short loader from `project-template/CLAUDE.md`.
- Older projects keep RULES/MEMORY/NOTEBOOK in `.agents/skills/`. Either move them to `.agents/supply/` (recommended, so they aren't confused with Claude skills) or leave them there; the skills and the hook look in both places. If you leave them, change the three `@.agents/supply/...` lines in `CLAUDE.md` to `@.agents/skills/...`.

### Step 3: Check it works

Start Claude Code in the project. The first reply should be a 3-line status, for example right after setup:

```
Branch: main
Last stop: Nothing open.
Next: First mission: send Jerome on setup to fill in RULES.md.
```

You don't have to type "read the notebook" any more; the hook does it.

---

## Daily use

You talk to Cutter as usual. He decides who takes the job and tells you in one line.

| You say | What happens |
|---|---|
| "Set up this project" / "first mission" | **Jerome** inspects the code and fills in `RULES.md`, `MEMORY.md` and the `CLAUDE.md` header for you to review (`sdd-setup`). Also works for moving an older project's `CLAUDE.md` / `.agents` into this layout. |
| "The save button on the profile page is misaligned" | **Marines**: Cutter writes a one-page quick task, fixes it, checks it, archives it. |
| "Test and review user creation" / "try to break the login" / "audit this module" | **Audit mission:** **Douglas** probes the module on an isolated test environment (duplicates, reload, double submit, edit conflicts, imports, lock-outs, leaked messages), writes findings with evidence and severity into `.agents/specs/<module>-review/`. Then **Jerome** plans the fixes, **Alice** builds them, **Douglas** reviews them independently. |
| "Add CSV export to the reports page" | **Jerome** writes the spec. If he has questions, Cutter asks you with multiple-choice options. Then Jerome writes the tasks. |
| "Go" / "continue" after a stop (gated mode) | Cutter sends the next unit. |
| "Continue" / "do the next task" | **Alice** builds the next task, then **Douglas** reviews it. |
| "Review TASK-12, and I want to watch the browser" | **Douglas** runs Playwright in a **visible** browser window. |
| "Just fix it" / "send the Spartans" | You override Cutter's choice. |
| "Write the notebook" | Cutter writes the session handoff (only when you ask). |
| "Demo the whole app, two rounds, one window" | **Douglas** runs a guided, visible tour (`sdd-review/references/demo-tour.md`): one browser, signing out and in between roles, with a caption on screen. |
| "Leave it for now" | Cutter records it in `DECISIONS.md` so nobody "fixes" it later. |
| `/sitrep` | A status report any time: branch, hand-off mode, uncommitted work, open tasks, tasks waiting for review, next step. |
| "How does X behave in version Y?" / "Find a skill for Z" | **Anders** researches, or finds and vets candidate skills, and writes a report in `.agents/research/`. You approve each skill by name and commit; then Cutter installs it. |

### How Cutter chooses Marines or Spartans
- **Marines** (all of these): about 3 files or fewer, no database or API-contract change, no protected area, and it's clear what you want.
- **Spartans**: anything else, or anything you call complex.

### Effort (how hard each Spartan thinks)
Cutter picks **low**, **medium** or **high** for every mission:
- **low**: mechanical work (renames, docs, copying a pattern)
- **medium**: normal features, fixes and planning (default for every agent, Jerome included)
- **high**: protected areas, data migrations, security, money, dates and time zones, or anything that failed review once

Jerome suggests an effort in each task file, and Cutter normally follows it.

### Gated or auto (hand-off mode)
`handoff` in `.claude/spirit-of-fire.json`:
- **`gated`** (default): every stage ends with a **stop and a one-line hand-off**, and Cutter waits for your go: *"Audit done: findings are in ..."*, *"Done planning."*, *"The work is ready for review."*, then the verdict. Use the pause to change the model, answer questions or read the files. You can also say "stop after each step" for one mission.
- **`auto`**: Cutter runs Jerome → Alice → Douglas without stopping (findings go back to Alice), and stops only for your questions and for anything that ships.

### Commit, push and porting wait for your word
Cutter (and every Spartan) never commits, pushes, merges or ports a change to another branch until you say so. "Maybe we should" counts as a question, not a yes. The branch guard hook blocks wrong *targets*; this rule covers the *decision*.

### Watching the browser tests
Douglas runs Playwright **headless** (no window) by default. To watch, say so when you ask for the review: "and show me the browser" or "visible test". He then runs with one visible window, slowed down so you can follow it.

---

## Automatic guards (hooks)

Hooks are small scripts Claude Code runs by itself at certain moments. They work even if the AI forgets a rule.

| Hook | When it runs | What it does |
|---|---|---|
| **Session brief** | Every session start (and after a context compaction) | Gives Cutter the branch, the Depot map (global depot), the notebook's "In progress" and "Next", and the next task number, so he opens with a status report. |
| **Branch guard** | Before any terminal command | **Blocks** `git push`, `git merge`, `git rebase` and `gh pr create` when a target branch isn't in `allowedBranches`. Also always blocks `git push --all` / `--mirror`. The AI is told to stop and explain, and never to edit the list itself. |
| **Notebook reminder** | Each time you send a message | When the conversation's context passes `notebookReminderTokens`, Cutter asks you **once** per session: "Context is getting full. Want me to write the notebook now?" He writes it only if you say yes. |

**Choosing `notebookReminderTokens`:** this is a cost setting, not a context-window setting. Every message re-sends the whole conversation, so a long session costs more with every turn. The default, 80,000, asks you to write the notebook and start fresh well before the session gets expensive. Raise it only if you often lose useful context; keep it far below your context window, even with a 1,000,000-token window.

---

## The rules every unit follows

These are built into `CPT_CUTTER.md` and the skills:
1. **No task file, no code.** Even Marines write a short quick task first.
2. **Ask before acting** when something is unclear or conflicts with the plan: 2 to 4 options, recommended first, then act on your answer.
3. **Check boxes only when verified.** An open box with a reason is fine; a box ticked without checking is not.
4. **Policies** in `.agents/policies/` bind everyone. The folder starts empty: during setup Jerome asks whether you have company, client or personal rules (Git connectivity, allowed services, data handling, licenses) and writes one policy file per rule set from what you give him, never from a guess. Add one later by telling Cutter "add a policy: ...".
5. **Memory** (`MEMORY.md`, max 800 words) is updated after every job. **Notebook** (`NOTEBOOK.md`, max 50 lines) is written only when you ask. **Decisions** (`DECISIONS.md`, no cap, never pruned) hold what you chose to leave as it is.
6. **Prove it:** a bug gets a failing test **before** the fix, every fix gets a **mutation check** (undo it, a test fails, restore it), and tests check the effect **where it lands** (the other role's page, the row, the email), on isolated data only.
7. **Ripple check** before changing shared state: list everything that reads it.
8. **Independent review** for features of 3+ tasks and for an audit's fixes: Douglas sees only the spec, the tasks and the diff, and runs his own mutation checks.
9. **Ship only on the user's word:** commit, push, merge and porting.

---

## Customizing

| To change | Edit |
|---|---|
| Which model a Spartan uses | `model:` in `~/.claude/agents/<name>.md`, or `<project>/.claude/agents/<name>.md` for a project-only install (`opus`, `sonnet`, `haiku`) |
| A Spartan's default effort | `effort:` in the same file |
| How a role works | `~/.claude/skills/sdd-<role>/SKILL.md` (or the project's `.claude/skills/` for a project-only install) |
| When Marines vs Spartans | Section 2 of `.claude/CPT_CUTTER.md` |
| Effort guide | Section 3 of `.claude/CPT_CUTTER.md` |
| What the session brief shows | `.claude/hooks/session-brief.mjs` |
| Allowed branches, reminder level, gated or auto hand-offs | `.claude/spirit-of-fire.json` |
| Turn a hook off | Remove its block from `.claude/settings.json` |

### Updating

By default the installer never overwrites, so a plain run only adds **new** files. After a `git pull` of this folder, take the improved agents, skills, commander orders and hooks with **`-Update`**:

```powershell
.\install.ps1 -Update                                                    # asks global or project only, like a first install
.\install.ps1 -Scope Global  -Project "D:\path\to\your-project" -Update   # global agents + skills, and this project
.\install.ps1 -Scope Project -Project "D:\path\to\your-project" -Update   # a project-only install
```

Use the same choices you installed with. A project-only install is updated once per project. Files in a global depot are always yours and never replaced.

For every file that differs, the old copy is saved next to it as `<name>.bak-<date-time>` and the new one replaces it. **Your project files are never replaced, even with `-Update`** (they are listed as KEPT): `CLAUDE.md`, `.gitignore`, `.agents\supply\*` (RULES, MEMORY, NOTEBOOK, DECISIONS), `.agents\policies\*` and `.claude\spirit-of-fire.json`.

Because `RULES.md` is yours, an existing project does **not** receive the new rule sections by itself. Ask Cutter: *"Compare RULES.md with the template and add the missing sections"*, or copy the sections *Testing standard*, *Ripple check*, *Independent review*, *Accepted decisions* and the two new lines under *Branches* by hand. Add `"handoff": "gated"` to your `spirit-of-fire.json` to choose the hand-off mode (gated is the default if the line is missing). `DECISIONS.md` is added automatically if it does not exist yet.

`opus` and `sonnet` always mean the newest version (today Opus 5.5 and Sonnet 5.5).

---

## Good to know (limits)

- **Spartans can't talk to you directly.** When Jerome needs a decision, he returns his questions to Cutter, Cutter asks you, and then sends your answers back to the same Jerome. You only ever talk to Cutter.
- **Spartans start fresh.** They don't see your conversation, only Cutter's mission brief and the supply depot. That's why the depot files matter and why Cutter's briefs include your exact words.
- **Cost.** Every agent start re-reads the depot, the task and its skill, so small jobs go to the Marines on purpose, memory is capped at 800 words, and tasks carry their own Context block. See "Keeping usage low" below.
- **The name `CLAUDE.md` must stay.** Claude Code only loads a file with that exact name, so it stays as a tiny loader and the commander's orders live in `.claude/CPT_CUTTER.md`.
- **Agents folder.** User-level agents must be in `C:\Users\<you>\.claude\agents\`, not inside the skills folder.
- **The branch guard reads commands, not intentions.** It covers `git push`, `merge`, `rebase` and `gh pr create`, including chained commands (`git add . && git push ...`). It doesn't stop you typing commands yourself in a terminal; it only guards what Claude runs. For full protection, also turn on branch protection in GitHub.
- **Tested vs. draft.** The hooks and the installer (including `-Update`) were tested. The agents and skills are drafts that encode a workflow proven by hand on a real project (see `CHANGELOG.md`); try them on one real feature or audit first, then adjust the skills from what you see.
- **Gated mode needs you to answer.** In gated mode nothing moves to the next stage until you say go; that is the point, but it means a long chain takes several messages from you. Switch to `auto` if you prefer fewer stops.

---

## Keeping usage low

Most usage comes from re-reading: every message re-sends the whole conversation, and every agent start reads the depot, its skill, the task and part of the spec. v0.3 is built to keep that small. Your part:

1. **Start a fresh session** after "Done planning.", after a feature is approved, and after a long break. Say "write the notebook" first; the session brief picks it up.
2. **Run the main session on Sonnet.** Switch to Opus only while you discuss design with Cutter.
3. **Keep `MEMORY.md` under 800 words.** It is read at the start of every mission. Results and evidence belong in the task files.
4. **Let Jerome write the Context block** in every task, so Alice does not read the whole spec.
5. **Use high effort only for risky work** (protected areas, money, migrations, security, dates).
6. **Add skills only through Anders**, and prefer small skills: a skill's description sits in every session, and its body is read every time an agent loads it.

To see the effect, run `/context` at the start of a session and check `/usage` before and after a mission.

## Skills from outside (Anders)

Outside skills run with your permissions, so they are treated like code from a stranger:
- **Anders** searches (`find-skills`, which only searches) and vets each candidate: source and commit, license, cost (anything that can bill you is rejected), commands and network calls, `allowed-tools` lines (they skip permission prompts), `` !` `` lines (they run a command when the skill loads), injection, and token cost. She has no shell, so a hostile skill cannot make her run anything.
- **You approve** each skill by name and commit hash. Anders' verdict is advice.
- **Cutter installs** it, and removes `allowed-tools` and auto-run lines unless you approved them.
- `RULES.md`, `DECISIONS.md` and the policies always win over a skill.
