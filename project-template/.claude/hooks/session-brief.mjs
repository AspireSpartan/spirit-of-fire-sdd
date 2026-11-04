// Spirit of Fire: session-start brief.
// Claude Code runs this at session start (see .claude/settings.json) and adds
// what it prints to the conversation, so Cpt. Cutter opens with a status report
// without the user having to say "read the notebook".
// Never fails the session: any error just prints a shorter brief.
import { readFileSync, existsSync } from 'node:fs';
import { execSync } from 'node:child_process';
import { join } from 'node:path';

const root = process.env.CLAUDE_PROJECT_DIR || process.cwd();

function firstExisting(...paths) {
  return paths.map((p) => join(root, p)).find((p) => existsSync(p));
}

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

let branch = 'unknown';
try {
  branch = execSync('git branch --show-current', { cwd: root, stdio: ['ignore', 'pipe', 'ignore'] })
    .toString()
    .trim() || 'detached HEAD';
} catch {
  branch = 'not a git repository';
}

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

const notebookPath = firstExisting('.agents/supply/NOTEBOOK.md', '.agents/skills/NOTEBOOK.md');
if (notebookPath) {
  const notebook = readFileSync(notebookPath, 'utf8');
  out.push('', 'Notebook - In progress:', section(notebook, 'In progress') || '(section missing)');
  out.push('', 'Notebook - Next:', section(notebook, 'Next') || '(section missing)');
} else {
  out.push('', 'No NOTEBOOK.md found in .agents/supply/ or .agents/skills/.');
}

const rulesPath = firstExisting('.agents/supply/RULES.md', '.agents/skills/RULES.md');
// The template's RULES.md carries a marker line; the setup mission removes it.
if (rulesPath && readFileSync(rulesPath, 'utf8').includes('sof:template')) {
  out.push('', 'RULES.md is not filled in (still the template). Recommend the first mission: Jerome with sdd-setup.');
}

const memoryPath = firstExisting('.agents/supply/MEMORY.md', '.agents/skills/MEMORY.md');
if (memoryPath) {
  const match = readFileSync(memoryPath, 'utf8').match(/Highest TASK number:\s*(\d+)/i);
  if (match) out.push('', `Highest TASK number: ${match[1]} (next task: ${Number(match[1]) + 1})`);
}

out.push(
  '',
  'Cpt. Cutter: open this session with the 3-line status (Branch / Last stop / Next), then wait for orders.'
);

console.log(out.join('\n'));
