// Spirit of Fire: branch guard (PreToolUse hook for Bash and PowerShell).
// Blocks git push / merge / rebase / gh pr create when a target branch is not
// in "allowedBranches" of .claude/spirit-of-fire.json. A written rule can be
// forgotten; this makes pushing to the wrong branch family impossible.
// Exit 2 = block (the reason on stderr is shown to Claude). Exit 0 = allow.
import { readFileSync, existsSync } from 'node:fs';
import { execSync } from 'node:child_process';
import { join } from 'node:path';

const root = process.env.CLAUDE_PROJECT_DIR || process.cwd();
const configPath = join(root, '.claude', 'spirit-of-fire.json');

let input = {};
try {
  input = JSON.parse(readFileSync(0, 'utf8') || '{}');
} catch {
  process.exit(0);
}
const command = input?.tool_input?.command;
if (typeof command !== 'string' || !/\b(git|gh)\b/.test(command)) process.exit(0);

let allowed = [];
try {
  if (!existsSync(configPath)) process.exit(0); // no config: guard off
  allowed = JSON.parse(readFileSync(configPath, 'utf8')).allowedBranches || [];
} catch {
  block('could not read .claude/spirit-of-fire.json; fix the file before pushing or merging.');
}
if (allowed.length === 0) process.exit(0);

function block(reason) {
  console.error(`BLOCKED by Spirit of Fire branch guard: ${reason}\nAllowed branches: ${allowed.join(', ') || '(none)'}\nIf this is intended, the user must change .claude/spirit-of-fire.json themselves.`);
  process.exit(2);
}

function currentBranch() {
  try {
    return execSync('git branch --show-current', { cwd: root, stdio: ['ignore', 'pipe', 'ignore'] }).toString().trim();
  } catch {
    return '';
  }
}

function isAllowed(name) {
  const branch = name.replace(/^\+/, '').replace(/^refs\/heads\//, '').replace(/^(origin|upstream)\//, '');
  return allowed.some((pattern) =>
    pattern.endsWith('*') ? branch.startsWith(pattern.slice(0, -1)) : branch === pattern
  );
}

function tokens(segment) {
  return (segment.match(/"[^"]*"|'[^']*'|\S+/g) || []).map((t) => t.replace(/^["']|["']$/g, ''));
}

// Split chained commands so "git add . && git push origin X" is checked too.
const segments = command.split(/&&|\|\||;|\|/).map((s) => s.trim()).filter(Boolean);

for (const segment of segments) {
  const t = tokens(segment);
  const gitAt = t.indexOf('git');
  const ghAt = t.indexOf('gh');

  if (gitAt !== -1) {
    // skip git global options like -C <path>, -c key=value
    let i = gitAt + 1;
    while (t[i] && t[i].startsWith('-')) i += t[i] === '-C' || t[i] === '-c' ? 2 : 1;
    const sub = t[i];
    const args = t.slice(i + 1);
    // options whose next token is a value, not a branch (e.g. git merge -m "msg" X)
    const takesValue = new Set(['-m', '-s', '-X', '-F', '-o', '--push-option', '--repo', '--strategy', '--strategy-option', '--onto', '--file']);
    const positional = args.filter((a, k) => !a.startsWith('-') && !takesValue.has(args[k - 1]));

    if (sub === 'push') {
      if (args.includes('--all') || args.includes('--mirror')) block('git push --all / --mirror is never allowed.');
      const refspecs = positional.slice(1); // first positional is the remote
      const targets = refspecs.length
        ? refspecs.map((r) => {
            const dest = r.includes(':') ? r.split(':').pop() : r;
            return dest === 'HEAD' || dest === '' ? currentBranch() : dest;
          })
        : [currentBranch()];
      for (const target of targets) {
        if (target && !isAllowed(target)) block(`push to "${target}" is outside the allowed branches.`);
      }
    }

    if (sub === 'merge' || sub === 'rebase') {
      const here = currentBranch();
      if (here && !isAllowed(here)) block(`you are on "${here}", which is outside the allowed branches.`);
      for (const source of positional) {
        if (/^[0-9a-f]{7,40}$/.test(source)) continue; // a commit hash, not a branch
        if (!isAllowed(source)) block(`${sub} with "${source}" would bring in work from outside the allowed branches.`);
      }
    }
  }

  if (ghAt !== -1 && t[ghAt + 1] === 'pr' && t[ghAt + 2] === 'create') {
    const baseAt = t.findIndex((x) => x === '--base' || x === '-B');
    if (baseAt !== -1 && t[baseAt + 1] && !isAllowed(t[baseAt + 1])) {
      block(`a pull request into "${t[baseAt + 1]}" is outside the allowed branches.`);
    }
  }
}

process.exit(0);
