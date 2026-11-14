# Playwright harness (one pinned install, shared by every review and audit)

The installer writes this file as `HARNESS.md` next to `package.json`, with the values below filled in. It never overwrites your `HARNESS.md`; if a value changes, edit it here.

- **Path:** `{{HARNESS}}` ({{SCOPE}})
- **Packages (exact, no ^ or ~):** `playwright-core@{{PW_VERSION}}`, `axe-core@{{AXE_VERSION}}`
- **Installed:** {{DATE}} with `npm install --save-exact --ignore-scripts` and `PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1`.
- **User's OK:** {{DATE}}, "Y" to "Install browser checks?" in `install.ps1`.
- **No browser is downloaded by this harness.** It uses the cached builds in `{{BROWSERS_DIR}}`:
  - Headless (default): `{{HEADLESS}}`
  - Visible (only when the user asks to watch): `{{VISIBLE}}`
  - {{BUILD_NOTE}}
  - The same two paths are in `harness.json` here; the standard review script reads them from it.
- **Rules:** never run `npx playwright install`; never upgrade either package without the user's OK; only localhost URLs; scripts live in the scratchpad or the task's evidence folder, never in the repo.

## Smoke command (expects `{{PW_VERSION}} {{AXE_VERSION}} ok`)
```
{{SMOKE}}
```
