#!/usr/bin/env node
import { spawnSync } from 'node:child_process';
import { mkdirSync, readFileSync, writeFileSync, existsSync, copyFileSync, chmodSync } from 'node:fs';
import { join, dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { ensureGitleaks } from './ensure-gitleaks.mjs';

const PLUGIN_VERSION = '0.1.0';
const SENTINEL_RE = /# s3lab-policy v([0-9]+\.[0-9]+\.[0-9]+)/;

const SELF_DIR = dirname(fileURLToPath(import.meta.url));

const HOOK_TEMPLATES = [
  { name: 'pre-commit', template: join(SELF_DIR, 'pre-commit.sh'), mode: 0o755 },
  { name: 'pre-push', template: join(SELF_DIR, 'pre-push.sh'), mode: 0o755 },
];
const CONFIG_TEMPLATE = { template: join(SELF_DIR, 'gitleaks.toml'), mode: 0o644 };

function emit(message) {
  process.stdout.write(JSON.stringify({ systemMessage: `s3lab-policy: ${message}` }) + '\n');
}

function runGit(args) {
  const r = spawnSync('git', args, { encoding: 'utf8' });
  return { ok: r.status === 0, stdout: (r.stdout || '').trim(), stderr: (r.stderr || '').trim() };
}

function sentinelVersionOf(filePath) {
  if (!existsSync(filePath)) return null;
  const head = readFileSync(filePath, 'utf8').split('\n').slice(0, 10).join('\n');
  const m = head.match(SENTINEL_RE);
  return m ? m[1] : null;
}

function installFile({ targetPath, templatePath, mode }) {
  const action = { target: targetPath };
  if (existsSync(targetPath)) {
    const ver = sentinelVersionOf(targetPath);
    if (ver === PLUGIN_VERSION) {
      action.status = 'up-to-date';
      return action;
    }
    if (ver) {
      copyFileSync(targetPath, `${targetPath}.bak`);
      copyFileSync(templatePath, targetPath);
      chmodSync(targetPath, mode);
      action.status = 'updated';
      action.previousVersion = ver;
      return action;
    }
    action.status = 'user-managed-skipped';
    return action;
  }
  mkdirSync(dirname(targetPath), { recursive: true });
  copyFileSync(templatePath, targetPath);
  chmodSync(targetPath, mode);
  action.status = 'installed';
  return action;
}

function main() {
  const gitDir = runGit(['rev-parse', '--git-dir']);
  if (!gitDir.ok) {
    emit('not a git repo, skipping guard install.');
    return;
  }
  const gitDirAbs = resolve(gitDir.stdout);

  const repoRoot = runGit(['rev-parse', '--show-toplevel']);
  if (!repoRoot.ok) {
    emit('git dir resolved but repo root missing, skipping.');
    return;
  }

  const gitleaks = ensureGitleaks();

  const actions = [];
  for (const t of HOOK_TEMPLATES) {
    actions.push({
      kind: 'hook',
      name: t.name,
      ...installFile({
        targetPath: join(gitDirAbs, 'hooks', t.name),
        templatePath: t.template,
        mode: t.mode,
      }),
    });
  }

  actions.push({
    kind: 'config',
    name: 'gitleaks.toml',
    ...installFile({
      targetPath: join(repoRoot.stdout, '.s3lab-policy', 'gitleaks.toml'),
      templatePath: CONFIG_TEMPLATE.template,
      mode: CONFIG_TEMPLATE.mode,
    }),
  });

  const installed = actions.filter(a => a.status === 'installed').map(a => a.name);
  const updated = actions.filter(a => a.status === 'updated').map(a => a.name);
  const userManaged = actions.filter(a => a.status === 'user-managed-skipped').map(a => a.name);

  const parts = [];
  if (installed.length) parts.push(`installed: ${installed.join(', ')}`);
  if (updated.length) parts.push(`updated: ${updated.join(', ')}`);
  if (userManaged.length) parts.push(`user-managed (skipped): ${userManaged.join(', ')} — run /policy-status`);
  if (!parts.length) parts.push('hooks up-to-date');
  parts.push(`gitleaks: ${gitleaks.status}`);

  emit(parts.join('; '));
}

main();
