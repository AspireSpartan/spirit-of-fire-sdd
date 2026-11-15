# Using and contributing

## Start your own copy
Click **Use this template** at the top of the repository. You get a clean, independent copy
of the latest version. Then follow the README (run `install.ps1`). Past versions are on the
Releases page as zips.

## Contribute back
A template copy has no link to this repository, so to send improvements **fork** it instead:
1. Fork this repository and create a branch.
2. Make your change. Keep personal info (names, emails, machine names, home paths,
   company names) out of every file.
3. Describe what changed and why in a short pull request. Add a line to `CHANGELOG.md`.

## Ground rules
- Keep the agents' rules intact: reproduce-first, mutation checks, independent review,
  gated hand-offs. Propose changes to them in an issue first.
- Prefer changes that lower token use without lowering accuracy.
- Anything that can bill the user, or runs unpinned downloads, will be rejected.
