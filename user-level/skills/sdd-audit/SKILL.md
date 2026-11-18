---
name: sdd-audit
description: Audit (module review) procedure for spec-driven development (SDD) in projects that keep an .agents/ folder. Use it when the user asks to test and review an existing module or feature, "try to break it", find loopholes, check duplicates or validation, QA something before fixing it, or says "audit", "recon", "module review"; and always when acting as Douglas on an audit mission. It tests through the real UI and data paths on an isolated environment, records findings with evidence and severity in a spec, and hands them to the Planner. It never fixes anything.
---

# SDD Audit (Douglas, recon before the plan)

An audit answers one question: **what actually happens when someone uses this module badly?** The code looking right proves little; a probe that shows a half-created account, a raw SQL error, or a lockout proves a lot. Your output is a findings spec with evidence, so Jerome can plan fixes and the user can decide what matters. You fix nothing.

## 1. Read first
- `.agents/supply/RULES.md` (stack, commands, how tests and probes are isolated), `MEMORY.md`, `.agents/policies/*.md`.
- `.agents/supply/DECISIONS.md`: anything listed there is a deliberate choice, not a finding. Search its **Index** for the module's area or name and open only the entries you need by ID.
- The module's code: routes, controller or handler, service, validation rules, the page or form, the tests that already exist, and the **database constraints** (unique indexes, foreign keys, cascade rules). Note where the app's rule and the database's rule disagree; that gap is where most holes live.

## 2. Map the surface
List every way the module's data can be written: forms, API endpoints, imports (CSV), jobs, other modules writing the same tables. A hole is often in the path nobody tested (the import, the edit, the second endpoint).

## 3. Probe, on isolated data only
- Use the project's isolated test environment (RULES.md "Testing standard"). **Never probe development, staging, UAT or production data.** If you cannot tell the environment is isolated, stop and report.
- Write a throwaway probe in the **session scratchpad**, never in the repo: start from `sdd-review/references/review-script.template.cjs` plus your probe lines, and follow the project's browser-check page if it has one (`sdd-review/references/playwright.md`). It prints one clear line per probe. Screenshots go to the project's evidence folder. **Delete the probe when you finish** and confirm with `git status`.
- Check both layers: what the **API** returns and what the **user sees** on screen (a screenshot of the message, then a reload).

### The attack list (use what applies)
| Try | Look for |
|---|---|
| Same value twice: exact, other letter case, extra spaces | Does validation agree with the database's unique rule? A mismatch shows as a 500 or a duplicate |
| A save that fails halfway | Is anything left behind (a row saved before the failing step)? Can that leftover log in or act? Is the save in one transaction? |
| Reload the page after a refused save | Does the half-saved record show up? Can the user get stuck in a loop? |
| Double click, and two identical requests at once | One record or two? |
| Edit to a value another record owns; edit that fails on a later field | Is anything changed anyway? |
| Every role and every entry path (form, import, API) | The same rules everywhere? Does a second path skip the check? |
| Lock yourself out: disable, delete, demote your own account or the last admin | Is anyone always left in charge? |
| Odd values: very long, only spaces, wrong type, arrays | A clear 422, or a 500? |
| The messages | Do they say what is wrong and who or what conflicts? Does any show SQL, table names, hosts or stack traces? Check with debug on **and** the production setting |
| Who is allowed | Can a lower role call it directly with a token? |

## 4. Write the findings
Folder `.agents/specs/<module>-review/`, file `spec.md`, from `templates/findings.md`. Every finding has an ID (U1, U2, ...), a **severity**, what happens, and **evidence** (the request and response, the rows, the evidence paths: screenshots, `run.log`). Also list what you tried that was **already safe**, so nobody re-tests it.

Severity:
- **High**: data corruption or loss, a security or access hole, an account or record left in a harmful half-state.
- **Medium**: a gap that needs a rare or deliberate action, or a rule that is missing but not dangerous.
- **Low**: wording, polish, a consistency issue.

Add **Decisions (planner defaults)**: the business choices a fix would need, each with your recommended default, so the user can confirm or change them. Put the ones the user must answer under **Open questions** in the multiple-choice shape `sdd-plan` describes.

## 5. Hand off
Report to Cutter: the findings table (ID, severity, one line), the path of the spec, what was already safe, the questions for the user, and anything you could not test and why. Cutter says **"Audit done: findings are in <path>. Ready to plan."** and (in gated mode) waits for the user.

## What not to do
- Do not fix production code or tests. Findings go to Jerome.
- Do not test on real data, and do not leave a probe behind.
- Do not report a finding without evidence, and do not call something safe without having tried it.
- Do not decide business questions; list them.
