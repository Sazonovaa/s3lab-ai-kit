#!/usr/bin/env node
// Кросс-платформенный порт log-ai-usage.cmd.
// Дописывает одну JSON-строку в logs/ai-usage.jsonl. Никогда не падает.
// Аргументы: <vendor> <event> [result] [skill] [subagent]
import { spawnSync } from 'node:child_process';
import { appendFileSync, mkdirSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

try {
  const [vendor, event, result, skill, subagent] = process.argv.slice(2);
  if (!vendor || !event) process.exit(0);

  const r = spawnSync('git', ['rev-parse', '--show-toplevel'], { encoding: 'utf8' });
  const repoRoot = r.status === 0 && r.stdout.trim()
    ? r.stdout.trim()
    : path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');

  const logDir = path.join(repoRoot, 'logs');
  mkdirSync(logDir, { recursive: true });

  const now = new Date();
  const entry = { timestamp: now.toISOString(), timestampLocal: now.toLocaleString(), vendor, event };
  if (result) entry.result = result;
  if (skill) entry.skill = skill;
  if (subagent) entry.subagent = subagent;

  appendFileSync(path.join(logDir, 'ai-usage.jsonl'), JSON.stringify(entry) + '\n');
} catch {
  // Логирование не должно прерывать сессию.
}
process.exit(0);
