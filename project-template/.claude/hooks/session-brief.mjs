// Spirit of Fire: session-start brief.
// Claude Code runs this at session start (see .claude/settings.json) and adds
// what it prints to the conversation, so Cpt. Cutter opens with a status report
// without the user having to say "read the notebook".
// Never fails the session: any error just prints a shorter brief.
import { readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { resolveDepot, ensureBranchFolder, mapLines } from './depot.mjs';

const root = process.env.CLAUDE_PROJECT_DIR || process.cwd();

function section(text, heading) {
  const lines = text.split(/\r?\n/);
  const start = lines.findIndex((l) => l.trim().toLowerCase() === `## ${heading}`.toLowerCase());
  if (start === -1) return null;
  const body = [];
  for (const line of lines.slice(start + 1)) {
    if (line.startsWith('## ')) break;
    body.push(line);
  }
  return body.join('\n').trim() || null;
}

const depot = resolveDepot(root);
const branch = depot.branch.name;
let newBranchFolder = false;
try {
  newBranchFolder = ensureBranchFolder(depot);
} catch {
  // a read-only or missing home folder never fails the session
}
const existing = (path) => (existsSync(path) ? path : null);

// Hand-off mode from .claude/spirit-of-fire.json: "gated" (stop after each stage) or "auto". Default gated.
let handoff = 'gated';
try {
  const configPath = join(root, '.claude', 'spirit-of-fire.json');
  if (existsSync(configPath)) {
    const configured = JSON.parse(readFileSync(configPath, 'utf8')).handoff;
    if (configured === 'auto' || configured === 'gated') handoff = configured;
  }
} catch {
  // a broken config never fails the session
}

const out = ['SESSION BRIEF (automatic, from the supply depot)', `Branch: ${branch}`, `Hand-off mode: ${handoff}`];

if (depot.mode === 'global') {
  if (!depot.exists) {
    out.push('', `Depot folder not found: ${depot.base}. Tell the user to run install.ps1 for this project (depot: global).`);
  } else {
    out.push('', ...mapLines(depot));
    out.push('Copy the Depot map into every mission brief. After a branch switch, run `node .claude/hooks/depot.mjs` for the new map.');
    if (newBranchFolder) out.push(`First session on this branch: created its folder with an empty notebook.`);
  }
} else if (depot.mode === 'project-ignored') {
  out.push('Depot: in the project (.agents/), ignored by git.');
}

const notebookPath = existing(depot.files.notebook);
if (notebookPath) {
  const notebook = readFileSync(notebookPath, 'utf8');
  out.push('', 'Notebook - In progress:', section(notebook, 'In progress') || '(section missing)');
  out.push('', 'Notebook - Next:', section(notebook, 'Next') || '(section missing)');
} else {
  out.push('', `No NOTEBOOK.md found at ${depot.files.notebook}.`);
}

const rulesPath = existing(depot.files.rules);
// The template's RULES.md carries a marker line; the setup mission removes it.
if (rulesPath && readFileSync(rulesPath, 'utf8').includes('sof:template')) {
  out.push('', 'RULES.md is not filled in (still the template). Recommend the first mission: Jerome with sdd-setup.');
}

// Browser checks: warn like RULES.md when the page is missing or still the template.
// Only for a filled-in project (an unfilled RULES.md already sends the user to setup).
if (rulesPath && !readFileSync(rulesPath, 'utf8').includes('sof:template')) {
  const browserPath = existing(depot.files.browserChecks);
  if (!browserPath) {
    out.push('', `BROWSER_CHECKS.md not found (${depot.files.browserChecks}). Douglas will stop UI reviews with "browser setup missing". Offer: Jerome with sdd-setup, browser part (or the user waives browser checks).`);
  } else {
    const text = readFileSync(browserPath, 'utf8');
    const todos = (text.match(/(^|[^`])TODO: ask the user/g) || []).length; // `TODO: ask the user` in backticks is the page's own instruction
    if (text.includes('sof:template')) {
      out.push('', 'BROWSER_CHECKS.md is not filled in (still the template). Offer: Jerome with sdd-setup, browser part.');
    } else if (todos) {
      out.push('', `BROWSER_CHECKS.md has ${todos} open "TODO: ask the user" item(s). Ask the user before the next browser run.`);
    }
  }
}

const memoryPath = existing(depot.files.memory);
if (memoryPath) {
  const match = readFileSync(memoryPath, 'utf8').match(/Highest TASK number:\s*(\d+)/i);
  if (match) out.push('', `Highest TASK number: ${match[1]} (next task: ${Number(match[1]) + 1})`);
}

out.push(
  '',
  'Cpt. Cutter: open this session with the 3-line status (Branch / Last stop / Next), then wait for orders.'
);

console.log(out.join('\n'));
