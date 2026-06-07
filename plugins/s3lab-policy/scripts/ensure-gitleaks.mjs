#!/usr/bin/env node
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

export function ensureGitleaks() {
  const which = spawnSync('which', ['gitleaks'], { encoding: 'utf8' });
  if (which.status === 0) {
    return { status: 'present', path: (which.stdout || '').trim() };
  }
  const brew = spawnSync('which', ['brew'], { encoding: 'utf8' });
  if (brew.status !== 0) {
    return { status: 'missing-no-brew' };
  }
  const install = spawnSync('brew', ['install', 'gitleaks'], { encoding: 'utf8' });
  if (install.status === 0) {
    return { status: 'installed' };
  }
  const errorText = (install.stderr || install.stdout || '').toString().slice(0, 500);
  return { status: 'install-failed', error: errorText };
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const result = ensureGitleaks();
  process.stdout.write(JSON.stringify(result) + '\n');
}
