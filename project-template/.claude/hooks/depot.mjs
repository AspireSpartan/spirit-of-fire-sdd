// Spirit of Fire: where the supply depot lives.
// The depot (rules, memory, decisions, notebook, specs, tasks) is either inside the project
// (.agents/, committed or ignored by git) or in a global folder per project and branch:
//
//   ~/.claude/spirit-of-fire/<depotName>/
//     RULES.md, MEMORY.md, DECISIONS.md, policies/, research/, archive/   shared by all branches
//     branches/<branch>/NOTEBOOK.md, specs/, tasks/                         one set per branch
//
// Skills and orders always write paths as ".agents/...". In global mode this file turns them
// into the real paths. The session brief imports it; run it by hand to print the current map:
//   node .claude/hooks/depot.mjs
import { readFileSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { execSync } from 'node:child_process';
import { join, basename, sep } from 'node:path';
import { homedir } from 'node:os';
import { fileURLToPath } from 'node:url';

export function branchSlug(branch) {
  return branch.replace(/[\\/:*?"<>|\s]+/g, '-').replace(/^-+|-+$/g, '') || 'unnamed';
}

export function currentBranch(root) {
  try {
    const name = execSync('git branch --show-current', { cwd: root, stdio: ['ignore', 'pipe', 'ignore'] })
      .toString()
      .trim();
    return { name: name || 'detached HEAD', slug: name ? branchSlug(name) : 'detached-HEAD' };
  } catch {
    return { name: 'not a git repository', slug: 'no-git' };
  }
}

function readConfig(root) {
  try {
    const path = join(root, '.claude', 'spirit-of-fire.json');
    return existsSync(path) ? JSON.parse(readFileSync(path, 'utf8')) : {};
  } catch {
    return {};
  }
}

export function resolveDepot(root) {
  const config = readConfig(root);
  const mode = ['project', 'project-ignored', 'global'].includes(config.depot) ? config.depot : 'project';
  const branch = currentBranch(root);

  if (mode !== 'global') {
    // In the project: the paths are the ones the skills already use. Older projects keep the
    // supply files in .agents/skills/ instead of .agents/supply/.
    const supplyDir = existsSync(join(root, '.agents', 'supply')) || !existsSync(join(root, '.agents', 'skills'))
      ? join(root, '.agents', 'supply')
      : join(root, '.agents', 'skills');
    return {
      mode,
      branch,
      base: join(root, '.agents'),
      exists: existsSync(join(root, '.agents')),
      files: {
        rules: join(supplyDir, 'RULES.md'),
        memory: join(supplyDir, 'MEMORY.md'),
        decisions: join(supplyDir, 'DECISIONS.md'),
        notebook: join(supplyDir, 'NOTEBOOK.md'),
        browserChecks: join(supplyDir, 'BROWSER_CHECKS.md'),
      },
      map: null,
    };
  }

  const name = String(config.depotName || basename(root)).replace(/[^\w.-]+/g, '-');
  const base = join(homedir(), '.claude', 'spirit-of-fire', name);
  const branchDir = join(base, 'branches', branch.slug);
  return {
    mode,
    branch,
    base,
    branchDir,
    exists: existsSync(base),
    files: {
      rules: join(base, 'RULES.md'),
      memory: join(base, 'MEMORY.md'),
      decisions: join(base, 'DECISIONS.md'),
      notebook: join(branchDir, 'NOTEBOOK.md'),
      browserChecks: join(base, 'BROWSER_CHECKS.md'),
    },
    // Order matters: the first matching prefix wins (archive before the rest of tasks/).
    map: [
      ['.agents/supply/RULES.md', join(base, 'RULES.md')],
      ['.agents/supply/MEMORY.md', join(base, 'MEMORY.md')],
      ['.agents/supply/DECISIONS.md', join(base, 'DECISIONS.md')],
      ['.agents/supply/NOTEBOOK.md', join(branchDir, 'NOTEBOOK.md')],
      ['.agents/supply/BROWSER_CHECKS.md', join(base, 'BROWSER_CHECKS.md')],
      ['.agents/policies/', join(base, 'policies') + sep],
      ['.agents/research/', join(base, 'research') + sep],
      ['.agents/tasks/archive/', join(base, 'archive') + sep],
      ['.agents/evidence/', join(branchDir, 'evidence') + sep],
      ['.agents/specs/', join(branchDir, 'specs') + sep],
      ['.agents/tasks/', join(branchDir, 'tasks') + sep],
    ],
  };
}

// Global mode: a branch seen for the first time gets its own folder and a fresh notebook.
// Only when the project's depot exists (the installer creates it); never creates a depot by itself.
export function ensureBranchFolder(depot) {
  if (depot.mode !== 'global' || !depot.exists) return false;
  if (existsSync(depot.branchDir)) return false;
  for (const dir of ['specs', 'tasks', join('tasks', 'requires-review'), join('tasks', 'evidence')]) {
    mkdirSync(join(depot.branchDir, dir), { recursive: true });
  }
  const today = new Date().toISOString().slice(0, 10);
  writeFileSync(
    depot.files.notebook,
    [
      '# Session Notebook',
      '',
      '## Date and branch',
      `- ${today}. Branch \`${depot.branch.name}\`.`,
      '',
      '## Done this session',
      '- Nothing yet.',
      '',
      '## In progress',
      '- Nothing open.',
      '',
      '## Decisions made by the user',
      '- None yet.',
      '',
      '## Open questions',
      '- None.',
      '',
      '## Next',
      '1. Waiting for orders.',
      '',
    ].join('\n')
  );
  return true;
}

export function mapLines(depot) {
  if (!depot.map) return [];
  return [
    `Depot: global, ${depot.base}`,
    `Depot branch folder: ${depot.branchDir}`,
    'Depot map (paths written as .agents/... in orders and skills mean these real paths):',
    ...depot.map.map(([logical, real]) => `  ${logical} -> ${real}`),
  ];
}

// Run directly: print the map for the current branch (for Cutter after a branch switch).
if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  const root = process.env.CLAUDE_PROJECT_DIR || process.cwd();
  const depot = resolveDepot(root);
  if (depot.mode !== 'global') {
    console.log(`Depot: in the project (${depot.mode}), ${depot.base}. Paths are as written.`);
  } else {
    if (!depot.exists) console.log(`Depot folder not found: ${depot.base}. Run install.ps1 for this project.`);
    else if (ensureBranchFolder(depot)) console.log(`New branch folder created: ${depot.branchDir}`);
    console.log(`Branch: ${depot.branch.name}`);
    console.log(mapLines(depot).join('\n'));
  }
}
