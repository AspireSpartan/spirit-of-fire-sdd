# Third-party notices

Spirit of Fire SDD is MIT licensed (see `LICENSE`). It includes or adapts the following third-party work.

## vercel-labs/skills: `find-skills`
- Files: `user-level/skills/find-skills/SKILL.md` (modified copy).
- License: MIT, (c) 2026 Vercel, Inc. See `user-level/skills/find-skills/LICENSE`.

## anthropics/knowledge-work-plugins: engineering `code-review` and `testing-strategy`
- Source: https://github.com/anthropics/knowledge-work-plugins, `engineering/skills/code-review/SKILL.md` and `engineering/skills/testing-strategy/SKILL.md`, commit `e91a134584eb798bac7fb0379358006a2b63b965`.
- License: Apache License 2.0. A copy is in `licenses/Apache-2.0-anthropics-knowledge-work-plugins.txt` (the license text only; the upstream file has unrelated lines after the license, which are left out).
- What was adapted (v0.5.1), rewritten in Spirit of Fire's own words and shortened:
  - `user-level/skills/sdd-review/SKILL.md`: the review dimensions (security, performance, correctness, maintainability) as a pass over the changed lines in step 2.6; an area tag on each finding; a "Looks good" line in the verdict.
  - `user-level/skills/sdd-plan/SKILL.md` and `templates/spec.md`, `templates/task.md`: the testing pyramid and the cover/skip list as the spec's **Test plan** and the task's **Tests to write**.
  - `user-level/skills/sdd-code/SKILL.md`: the Coder writes the task's **Tests to write** at the level named.
- Each changed skill carries a comment under its front matter naming the source. No other files from that repository are included.

## DietrichGebert/ponytail: `ponytail` skill
- Source: https://github.com/DietrichGebert/ponytail, `skills/ponytail/SKILL.md`, commit `96608e078b2d5ea607c5c3b8b5a54d1c1fba6846`.
- License: MIT, Copyright (c) 2026 DietrichGebert. A copy is in `licenses/MIT-DietrichGebert-ponytail.txt`.
- What was adapted (v0.5.2), rewritten in Spirit of Fire's own words and shortened:
  - `user-level/skills/sdd-code/SKILL.md` step 3: the "smallest complete change" ladder, the rules on wrappers, deletion, root-cause fixes, moved code and `shortcut:` comments, and the "never cut" list. Its levels (lite, full, ultra), session mode, reply footer and its own test rule are left out; the task's **Tests to write** (v0.5.1) govern tests.
  - `user-level/skills/sdd-review/SKILL.md` step 2.6: "code the task did not ask for" as a maintainability finding.
- `sdd-code` carries a comment under its front matter naming the source. No other files from that repository are included.
