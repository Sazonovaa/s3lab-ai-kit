#!/usr/bin/env node
// Кросс-платформенный порт validate-crlf-before-commit.cmd.
// Хук beforeShellExecution / PreToolUse: если команда — `git commit`, прогоняет
// CRLF-валидатор (validate-crlf.sh на POSIX, .cmd на Windows) и возвращает
// permission allow/deny. Иначе — allow.
import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const allow = () => { process.stdout.write('{ "permission": "allow" }\n'); process.exit(0); };

let raw = '';
try { raw = readFileSync(0, 'utf8'); } catch { allow(); }

// Не git commit — пропускаем (как findstr в исходнике).
if (!/git(\.exe)?\s+commit/i.test(raw)) allow();

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const validations = path.resolve(scriptDir, '..', 'validations');

let res;
if (process.platform === 'win32') {
  res = spawnSync('cmd.exe', ['/d', '/c', path.join(validations, 'validate-crlf.cmd')], { encoding: 'utf8' });
} else {
  res = spawnSync('sh', [path.join(validations, 'validate-crlf.sh')], { encoding: 'utf8' });
}

if (res.status === 0) allow();

process.stdout.write(JSON.stringify({
  permission: 'deny',
  user_message: 'Commit blocked: staged text files must use CRLF line endings.',
  agent_message: 'Run scripts/validations/validate-crlf for details.',
}) + '\n');
process.exit(2);
