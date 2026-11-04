// Spirit of Fire: notebook reminder (UserPromptSubmit hook).
// Reads the context size of the latest reply from the conversation transcript
// (input + cache tokens in its "usage" record). When it passes
// "notebookReminderTokens" in .claude/spirit-of-fire.json, Cpt. Cutter is told
// once per session to offer writing the notebook before the context fills up.
// It only reminds; the notebook is still written only when the user says so.
import { readFileSync, existsSync, statSync, writeFileSync, mkdirSync, openSync, readSync, closeSync } from 'node:fs';
import { join } from 'node:path';

const root = process.env.CLAUDE_PROJECT_DIR || process.cwd();

function tail(path, bytes) {
  const size = statSync(path).size;
  const length = Math.min(size, bytes);
  const buffer = Buffer.alloc(length);
  const fd = openSync(path, 'r');
  readSync(fd, buffer, 0, length, size - length);
  closeSync(fd);
  return buffer.toString('utf8');
}

try {
  const input = JSON.parse(readFileSync(0, 'utf8') || '{}');
  const transcript = input.transcript_path;
  const session = String(input.session_id || 'unknown').replace(/[^\w-]/g, '');
  if (!transcript || !existsSync(transcript)) process.exit(0);

  let limit = 80000;
  const configPath = join(root, '.claude', 'spirit-of-fire.json');
  if (existsSync(configPath)) {
    const value = Number(JSON.parse(readFileSync(configPath, 'utf8')).notebookReminderTokens);
    if (value > 0) limit = value;
  }

  // the latest "usage" record; it can contain nested objects, so read the numbers directly
  const text = tail(transcript, 4 * 1024 * 1024);
  const at = text.lastIndexOf('"usage":{');
  if (at === -1) process.exit(0);
  const usage = text.slice(at, at + 1000);
  const field = (name) => Number((usage.match(new RegExp(`"${name}":(\\d+)`)) || [])[1] || 0);
  const context = field('input_tokens') + field('cache_creation_input_tokens') + field('cache_read_input_tokens');
  if (context < limit) process.exit(0);

  // remind once per session
  const stateDir = join(root, '.claude', '.state');
  const marker = join(stateDir, `notebook-reminded-${session}`);
  if (existsSync(marker)) process.exit(0);
  mkdirSync(stateDir, { recursive: true });
  writeFileSync(marker, new Date().toISOString());

  console.log(
    `NOTEBOOK REMINDER: the conversation context is about ${context.toLocaleString('en-US')} tokens ` +
      `(reminder set at ${limit.toLocaleString('en-US')}). ` +
      'Every new message re-sends this whole context, so long sessions are the most expensive part of the workflow. ' +
      'Cpt. Cutter: after answering, ask the user once: "This session is getting long and costly. Want me to write the notebook so you can start a fresh session?" ' +
      'Write it only if they say yes.'
  );
} catch {
  // never block the user's prompt
}
process.exit(0);
