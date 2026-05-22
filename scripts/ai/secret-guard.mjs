#!/usr/bin/env node
// Кросс-платформенный порт secret-guard.cmd (JScript).
// Читает JSON хука из stdin, извлекает shell-команду и блокирует её (exit 2),
// если в ней встречается секрет. Те же паттерны, что в исходнике.
import { readFileSync } from 'node:fs';

const PATTERNS = [
  /AKIA[0-9A-Z]{16}/i,                       // AWS access key id
  /sk-(ant|proj|live)-[a-zA-Z0-9\-]{10,}/i,  // Anthropic / OpenAI-style
  /-----BEGIN[A-Z ]*PRIVATE KEY-----/i,      // PEM private key
  /xox[baprs]-[0-9a-z\-]{10,}/i,             // Slack token
  /ghp_[0-9a-zA-Z]{20,}/i,                   // GitHub PAT
  /AIza[0-9A-Za-z\-_]{20,}/i,                // Google API key
];

try {
  const raw = readFileSync(0, 'utf8').replace(/^﻿/, '');
  if (!raw.trim()) process.exit(0);

  let data;
  try { data = JSON.parse(raw); } catch { process.exit(0); }

  const command = String(data.command || data.Command || '');
  if (!command) process.exit(0);

  if (PATTERNS.some((re) => re.test(command))) {
    process.stderr.write('secret-guard: blocked shell command matching sensitive pattern.\n');
    process.exit(2);
  }
} catch {
  process.exit(0);
}
process.exit(0);
