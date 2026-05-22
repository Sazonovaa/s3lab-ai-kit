#!/usr/bin/env node
// Кросс-платформенный порт sync-submodule-on-start.cmd.
// При старте сессии делает ff-only pull submodule `s3lab-ai-kit`, если
// он отстал от upstream и не разошёлся. В самом kit-репо (submodule отсутствует)
// — no-op. Всегда печатает `{}` в stdout и завершает 0 (не блокирует сессию).
import { spawnSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import path from 'node:path';

const SUBMODULE_NAME = 's3lab-ai-kit';
const done = (msg) => { if (msg) process.stderr.write(`sync-submodule-on-start: ${msg}\n`); process.stdout.write('{}\n'); process.exit(0); };
const git = (args, cwd) => {
  const r = spawnSync('git', args, { cwd, encoding: 'utf8' });
  return { ok: r.status === 0, out: (r.stdout || '').trim() };
};

const root = git(['rev-parse', '--show-toplevel']);
if (!root.ok || !root.out) done('not a Git repository');
const sub = path.join(root.out, SUBMODULE_NAME);

if (!existsSync(path.join(sub, '.git'))) done(`submodule directory not found: ${sub}`);
if (!git(['rev-parse', '--is-inside-work-tree'], sub).ok) done(`submodule is not a Git repository: ${sub}`);
if (!git(['fetch', '--quiet'], sub).ok) done('failed to fetch remote changes');

const upstream = git(['rev-parse', '--abbrev-ref', '--symbolic-full-name', '@{u}'], sub);
if (!upstream.ok || !upstream.out) done('current submodule branch has no upstream');

const local = git(['rev-parse', 'HEAD'], sub).out;
const remote = git(['rev-parse', upstream.out], sub).out;
const base = git(['merge-base', 'HEAD', upstream.out], sub).out;

if (local === remote) done('submodule is already up to date');
if (local !== base) done('submodule has local commits or diverged history; skipping automatic pull');

if (!git(['pull', '--ff-only', '--quiet'], sub).ok) done('failed to fast-forward submodule');
done('submodule fast-forwarded');
