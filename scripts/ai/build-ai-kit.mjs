#!/usr/bin/env node
// =============================================================================
// build-ai-kit.mjs — компилятор единого описания AI-kit.
//
// Источник правды: .ai/skills/**/*.md (kind=skill) и .ai/subagents/**/*.md
// (kind=subagent). Каждый файл имеет frontmatter (name/description/triggers,
// опционально tools/model/kind/globs/always_apply/vendor_overrides).
//
// Компилятор детерминированно разворачивает источник в нативные артефакты
// вендоров. Все целевые файлы — сборочный выход с баннером DO NOT EDIT.
//
// Использование:
//   node scripts/ai/build-ai-kit.mjs           — сборка (перезапись выходов)
//   node scripts/ai/build-ai-kit.mjs --check    — CI-режим: сравнить, не писать
//   node scripts/ai/build-ai-kit.mjs --verbose   — подробный лог
//
// Кросс-платформенный, без внешних зависимостей. Node >= 18.
// =============================================================================

import { readdir, readFile, writeFile, mkdir, rm } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const KIT_ROOT = path.resolve(SCRIPT_DIR, '..', '..');

const ARGV = process.argv.slice(2);
const CHECK = ARGV.includes('--check');
const VERBOSE = ARGV.includes('--verbose');

// --out <dir> — корень для записи (по умолчанию сам kit). Для проекта-
// потребителя указывается его корень: нативные .claude/.cursor создаются там,
// а источник по-прежнему читается из kit (submodule).
let OUT_ROOT = KIT_ROOT;
const outIdx = ARGV.findIndex((a) => a === '--out' || a.startsWith('--out='));
if (outIdx !== -1) {
  const a = ARGV[outIdx];
  const val = a.includes('=') ? a.slice(a.indexOf('=') + 1) : ARGV[outIdx + 1];
  if (val) OUT_ROOT = path.resolve(val);
}
const EXTERNAL = path.resolve(OUT_ROOT) !== path.resolve(KIT_ROOT);
// Префикс пути источника при внешней сборке (например "s3lab-ai-kit/").
const KIT_REL = EXTERNAL ? path.relative(OUT_ROOT, KIT_ROOT).replace(/\\/g, '/') + '/' : '';

const EOL = '\r\n'; // .gitattributes: * text=auto eol=crlf

// --- Источники: каталог .ai/<dir> → kind по умолчанию -----------------------
const SOURCES = [
  { dir: '.ai/subagents', kind: 'subagent' },
  { dir: '.ai/skills', kind: 'skill' },
  // Политики: попадают в таблицу router и индекс, но не проецируются в нативные
  // skills/agents (это справочные документы). optional — файлы без frontmatter
  // (например security_sdlc.md) просто пропускаются, а не ломают сборку.
  { dir: '.ai/policies', kind: 'policy', optional: true },
  // Path-scoped правила: генерируются в .cursor/rules/*.mdc по полю globs.
  // Не маршруты — в таблицу router / индекс не попадают.
  { dir: '.ai/rules', kind: 'rule' },
];

// Полностью генерируемые каталоги (очищаются перед сборкой).
// .cursor/rules — полностью генерируется из .ai/rules; вручную .mdc не добавлять.
const GENERATED_DIRS = ['.claude/agents', '.claude/skills', '.cursor/skills', '.cursor/rules'];

// Vendor-конфиги хуков/MCP — проецируются в проект-потребитель (--out) из
// собственных конфигов kit с переписанными под submodule путями скриптов.
// Создаются только если отсутствуют (не затираем кастомные конфиги).
const VENDOR_CONFIGS = [
  '.claude/settings.json',
  '.cursor/hooks.json',
  '.codex/hooks.json',
  '.codex/config.toml',
];

const log = (...a) => VERBOSE && console.log(...a);
const warn = (m) => console.warn(`  ! ${m}`);

// Схема frontmatter (см. .ai/schema.md). Неизвестные ключи — предупреждение.
const ALLOWED_KEYS = new Set([
  'name', 'description', 'triggers', 'kind', 'model', 'tools', 'globs', 'always_apply', 'vendor_overrides',
]);
const VALID_MODELS = new Set(['heavy', 'standard', 'light', 'opus', 'sonnet', 'haiku', 'inherit']);
const DESC_MAX = 1000; // мягкий предел длины description (предупреждение)

// =============================================================================
// Парсер frontmatter (подмножество YAML: скаляры, кавычки, folded/literal
// блоки >-/>/|/|-, простые списки "- item"). Зависимостей нет умышленно.
// =============================================================================
function parseFrontmatter(raw) {
  const text = raw.replace(/\r\n/g, '\n');
  if (!text.startsWith('---\n')) return { data: {}, body: raw };
  const end = text.indexOf('\n---', 4);
  if (end === -1) return { data: {}, body: raw };
  const block = text.slice(4, end);
  const afterMarker = text.indexOf('\n', end + 1);
  const body = afterMarker === -1 ? '' : text.slice(afterMarker + 1);

  const lines = block.split('\n');
  const data = {};
  let i = 0;
  while (i < lines.length) {
    const line = lines[i];
    if (line.trim() === '') { i++; continue; }
    const m = line.match(/^([A-Za-z0-9_]+):\s*(.*)$/);
    if (!m) { i++; continue; }
    const key = m[1];
    const rest = m[2];

    if (rest === '') {
      // Список "- item" или вложенный объект (vendor_overrides) — собираем сырьём.
      const items = [];
      const nested = {};
      let j = i + 1;
      let isList = false;
      let isNested = false;
      while (j < lines.length && /^\s/.test(lines[j]) && lines[j].trim() !== '') {
        const li = lines[j].match(/^\s*-\s+(.*)$/);
        if (li) { isList = true; items.push(stripQuotes(li[1].trim())); }
        else {
          const nm = lines[j].match(/^\s*([A-Za-z0-9_]+):\s*(.*)$/);
          if (nm) { isNested = true; nested[nm[1]] = coerce(stripQuotes(nm[2].trim())); }
        }
        j++;
      }
      if (isList) data[key] = items;
      else if (isNested) data[key] = nested;
      else data[key] = '';
      i = j;
      continue;
    }

    if (['>-', '>', '>+', '|', '|-', '|+'].includes(rest)) {
      const folded = rest[0] === '>';
      const { value, next } = collectBlock(lines, i + 1, folded);
      data[key] = value;
      i = next;
      continue;
    }

    data[key] = coerce(stripQuotes(rest.trim()));
    i++;
  }
  return { data, body };
}

function collectBlock(lines, start, folded) {
  const out = [];
  let j = start;
  while (j < lines.length) {
    const l = lines[j];
    if (l.trim() === '') { out.push(''); j++; continue; }
    if (/^\S/.test(l)) break; // вернулись на уровень ключа
    out.push(l);
    j++;
  }
  const indents = out.filter((s) => s.trim()).map((s) => s.match(/^(\s*)/)[1].length);
  const min = indents.length ? Math.min(...indents) : 0;
  const dedented = out.map((s) => s.slice(min));
  let value;
  if (folded) {
    let res = '';
    let prevBlank = true;
    for (const s of dedented) {
      if (s === '') { res += '\n'; prevBlank = true; }
      else { res += (prevBlank ? '' : ' ') + s; prevBlank = false; }
    }
    value = res.trim();
  } else {
    value = dedented.join('\n').replace(/\n+$/, '');
  }
  return { value, next: j };
}

const stripQuotes = (s) => s.replace(/^"(.*)"$/s, '$1').replace(/^'(.*)'$/s, '$1');
const coerce = (s) => (s === 'true' ? true : s === 'false' ? false : s);

// =============================================================================
// Загрузка и валидация записей
// =============================================================================
async function walkMarkdown(dir) {
  const abs = path.join(KIT_ROOT, dir);
  if (!existsSync(abs)) return [];
  const out = [];
  for (const ent of await readdir(abs, { withFileTypes: true })) {
    const rel = path.join(dir, ent.name);
    if (ent.isDirectory()) out.push(...(await walkMarkdown(rel)));
    else if (ent.isFile() && ent.name.endsWith('.md')) out.push(rel);
  }
  return out;
}

function normalizeName(raw, fallback) {
  const base = (raw || fallback || '').toLowerCase();
  const norm = base
    .replace(/[_\s]+/g, '-')
    .replace(/[^a-z0-9-]/g, '')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '');
  return norm;
}

const errors = [];
const fail = (file, msg) => errors.push(`${file}: ${msg}`);

async function loadEntries() {
  const entries = [];
  for (const src of SOURCES) {
    for (const rel of await walkMarkdown(src.dir)) {
      const raw = await readFile(path.join(KIT_ROOT, rel), 'utf8');
      const { data, body } = parseFrontmatter(raw);
      const kind = data.kind || src.kind;
      const fileBase = path.basename(rel, '.md');
      const name = normalizeName(data.name, fileBase);

      // Опциональный источник: файлы без frontmatter не маршрутизируются.
      if (src.optional && !data.name) { log(`  - ${rel} (без frontmatter — пропуск)`); continue; }

      const description = String(data.description || '').replace(/\s*\n\s*/g, ' ').trim();
      const triggers = Array.isArray(data.triggers) ? data.triggers : [];

      // Errors (валят сборку).
      if (!data.name) fail(rel, 'нет поля name в frontmatter');
      if (!data.description) fail(rel, 'нет поля description в frontmatter');
      if (name && !/^[a-z0-9]+(-[a-z0-9]+)*$/.test(name)) {
        fail(rel, `имя "${name}" не соответствует ^[a-z0-9](-[a-z0-9])*$`);
      }

      // Warnings (не валят сборку).
      if (data.name && name !== String(data.name).toLowerCase()) {
        warn(`${rel}: name "${data.name}" нормализовано в "${name}"`);
      }
      for (const k of Object.keys(data)) {
        if (!ALLOWED_KEYS.has(k)) warn(`${rel}: неизвестное поле frontmatter "${k}"`);
      }
      if (data.model && !VALID_MODELS.has(data.model)) {
        warn(`${rel}: класс model "${data.model}" вне {${[...VALID_MODELS].join(', ')}}`);
      }
      if (kind === 'rule' && !data.globs) warn(`${rel}: rule без globs — правило ни к чему не привяжется`);
      if (description.length > DESC_MAX) warn(`${rel}: description ${description.length} символов (> ${DESC_MAX})`);
      const lower = triggers.map((t) => String(t).toLowerCase());
      const dupT = [...new Set(lower.filter((t, i) => lower.indexOf(t) !== i))];
      if (dupT.length) warn(`${rel}: дубли triggers (без учёта регистра): ${dupT.join(', ')}`);

      entries.push({
        rel, kind, name, description, triggers,
        tools: Array.isArray(data.tools) ? data.tools : null,
        model: data.model || null,
        globs: data.globs || null,
        alwaysApply: data.always_apply === true,
        body: body.trim(),
      });
    }
  }

  // Глобальная уникальность имён (skill+subagent делят namespace .cursor/skills).
  const seen = new Map();
  for (const e of entries) {
    if (seen.has(e.name)) fail(e.rel, `дубль имени "${e.name}" (также ${seen.get(e.name)})`);
    else seen.set(e.name, e.rel);
  }

  // Коллизии триггеров между маршрутами (снижают точность выбора) — warning.
  const trigMap = new Map();
  for (const e of entries) {
    for (const t of e.triggers) {
      const key = String(t).toLowerCase();
      if (!trigMap.has(key)) trigMap.set(key, new Set());
      trigMap.get(key).add(e.name);
    }
  }
  for (const [t, names] of trigMap) {
    if (names.size > 1) warn(`триггер "${t}" у нескольких маршрутов: ${[...names].join(', ')}`);
  }

  return entries;
}

// =============================================================================
// Рендереры вендоров. Каждый возвращает [{ path, content }].
// Добавление нового вендора = новый рендерер, без правок ядра.
// =============================================================================
function banner(srcRel) {
  const src = KIT_REL + srcRel.replace(/\\/g, '/');
  const cmd = EXTERNAL
    ? `node ${KIT_REL}scripts/ai/build-ai-kit.mjs --out .`
    : 'node scripts/ai/build-ai-kit.mjs';
  const lines = [
    '<!--',
    '  GENERATED — DO NOT EDIT.',
    `  Источник правды: ${src}`,
    `  Пересборка: ${cmd}`,
    '-->',
  ];
  // При внешней сборке тело ссылается на пути AI-kit относительно submodule.
  if (EXTERNAL) lines.push('', `> Path base: \`${KIT_REL}\` — относительные пути AI-kit разрешай отсюда.`);
  return lines.join('\n');
}

function yamlString(s) {
  return `"${String(s).replace(/\\/g, '\\\\').replace(/"/g, '\\"')}"`;
}

const MODEL_MAP = { heavy: 'opus', standard: 'sonnet', light: 'haiku' };
const CLAUDE_MODELS = new Set(['opus', 'sonnet', 'haiku', 'inherit']);

function claudeModel(model, srcRel) {
  if (!model) return null;
  const mapped = MODEL_MAP[model] || model;
  if (CLAUDE_MODELS.has(mapped)) return mapped;
  warn(`${srcRel}: model "${model}" не маппится в модель Claude — поле пропущено`);
  return null;
}

function renderClaude(entries) {
  const files = [];
  for (const e of entries) {
    if (e.kind !== 'skill' && e.kind !== 'subagent') continue; // policy — только в router/индекс
    const fm = [`name: ${e.name}`, `description: ${yamlString(e.description)}`];

    if (e.kind === 'subagent') {
      if (e.tools) fm.push(`tools: ${e.tools.join(', ')}`);
      const m = claudeModel(e.model, e.rel);
      if (m) fm.push(`model: ${m}`);
      const content = `---\n${fm.join('\n')}\n---\n\n${banner(e.rel)}\n\n${e.body}\n`;
      files.push({ path: `.claude/agents/${e.name}.md`, content });
    } else {
      const content = `---\n${fm.join('\n')}\n---\n\n${banner(e.rel)}\n\n${e.body}\n`;
      files.push({ path: `.claude/skills/${e.name}/SKILL.md`, content });
    }
  }
  return files;
}

// --- Cursor: Agent Skills (.cursor/skills/<name>/SKILL.md) ------------------
// Cursor нативно обнаруживает Agent Skills. Сабагенты проецируются как skills,
// т.к. у Cursor нет отдельного стабильного каталога agents.
function renderCursor(entries) {
  return entries.filter((e) => e.kind === 'skill' || e.kind === 'subagent').map((e) => {
    const fm = [`name: ${e.name}`, `description: ${yamlString(e.description)}`];
    const content = `---\n${fm.join('\n')}\n---\n\n${banner(e.rel)}\n\n${e.body}\n`;
    return { path: `.cursor/skills/${e.name}/SKILL.md`, content };
  });
}

// --- Универсальный индекс маршрутов (.ai/routes.generated.md) ----------------
// Vendor-neutral. Служит Codex (нет нативного discovery) и людям; единый
// источник списка маршрутов вместо рукописных перечислений.
function renderRouteIndex(entries) {
  const rows = (kind, title) => {
    const list = entries.filter((e) => e.kind === kind);
    if (!list.length) return '';
    const head = `## ${title}\n\n| name | Описание | Триггеры | Источник |\n|---|---|---|---|`;
    const body = list
      .map((e) => {
        const trig = e.triggers.slice(0, 4).join(', ') || '—';
        return `| \`${e.name}\` | ${e.description} | ${trig} | \`${e.rel.replace(/\\/g, '/')}\` |`;
      })
      .join('\n');
    return `${head}\n${body}\n`;
  };
  const content = [
    banner('.ai/skills + .ai/subagents'),
    '',
    '# Индекс маршрутов AI-kit (сгенерировано)',
    '',
    'Полный список skills и subagents. Файл собирается компилятором из',
    'frontmatter источника — не редактировать вручную. Нативное обнаружение:',
    'Claude (`.claude/agents`, `.claude/skills`), Cursor (`.cursor/skills`);',
    'Codex и прочие — этот индекс + `AGENTS.md`.',
    '',
    rows('subagent', 'Subagents (роли)'),
    rows('skill', 'Skills (процедуры)'),
    rows('policy', 'Policies (политики)'),
  ].join('\n');
  return [{ path: '.ai/routes.generated.md', content }];
}

// --- Cursor: path-scoped rules (.cursor/rules/<name>.mdc) из kind=rule -------
function renderCursorRules(entries) {
  return entries.filter((e) => e.kind === 'rule').map((e) => {
    const fm = [`description: ${yamlString(e.description)}`];
    if (e.globs) {
      const g = Array.isArray(e.globs) ? e.globs : [e.globs];
      fm.push(g.length === 1 ? `globs: ${g[0]}` : 'globs:\n' + g.map((x) => `  - "${x}"`).join('\n'));
    }
    fm.push(`alwaysApply: ${e.alwaysApply ? 'true' : 'false'}`);
    const content = `---\n${fm.join('\n')}\n---\n\n${banner(e.rel)}\n\n${e.body}\n`;
    return { path: `.cursor/rules/${e.name}.mdc`, content };
  });
}

const RENDERERS = [renderClaude, renderCursor, renderCursorRules, renderRouteIndex];

// --- Категория маршрута (для таблицы router) --------------------------------
function category(entry) {
  const p = entry.rel.replace(/\\/g, '/');
  if (p.includes('/product/')) return 'product';
  if (p.includes('/qa/') || p.includes('/testing/')) return 'testing';
  if (p.includes('/research/')) return 'research';
  if (p.includes('/writing/')) return 'writing';
  if (p.includes('/design/')) return 'design';
  if (entry.name === 'business-analyst') return 'product';
  if (entry.name === 'qa-engineer') return 'testing';
  if (entry.name === 'ui-designer') return 'design';
  return 'engineering';
}

// --- Inject: таблица маршрутов внутри .ai/router.md -------------------------
// router.md остаётся рукописным (логика, спец-правила, Output Contract), но
// таблица маршрутов генерируется из источника — рассинхрон невозможен.
function renderRouterTable(entries) {
  const order = { subagent: 0, skill: 1, policy: 2 };
  const sorted = [...entries].filter((e) => e.kind !== 'rule').sort(
    (a, b) =>
      order[a.kind] - order[b.kind] ||
      category(a).localeCompare(category(b)) ||
      a.name.localeCompare(b.name)
  );
  const head = '| Категория | Тип | name | Route файл | Триггеры |\n|---|---|---|---|---|';
  const rows = sorted.map((e) => {
    const trig = e.triggers.slice(0, 4).join(', ') || '—';
    return `| ${category(e)} | ${e.kind} | \`${e.name}\` | \`${e.rel.replace(/\\/g, '/')}\` | ${trig} |`;
  });
  return [
    '<!-- GENERATED — не редактировать вручную; источник: frontmatter .ai/skills + .ai/subagents -->',
    head,
    ...rows,
  ].join('\n');
}

// Индекс маршрутов для AGENTS.md (Codex и клиенты без нативного discovery).
function renderAgentsIndex(entries) {
  const section = (kind, title) => {
    const list = entries.filter((e) => e.kind === kind);
    if (!list.length) return '';
    const head = `**${title}**\n\n| name | Описание | Route |\n|---|---|---|`;
    const rows = list
      .map((e) => `| \`${e.name}\` | ${e.description} | \`${e.rel.replace(/\\/g, '/')}\` |`)
      .join('\n');
    return `${head}\n${rows}\n`;
  };
  return [
    '<!-- GENERATED — не редактировать; источник: .ai/skills + .ai/subagents + .ai/policies -->',
    section('subagent', 'Subagents (роли)'),
    section('skill', 'Skills (процедуры)'),
    section('policy', 'Policies (политики)'),
  ]
    .filter(Boolean)
    .join('\n');
}

const INJECTIONS = [
  {
    file: '.ai/router.md',
    start: '<!-- AIKIT:ROUTES:START -->',
    end: '<!-- AIKIT:ROUTES:END -->',
    render: renderRouterTable,
  },
  {
    file: 'AGENTS.md',
    start: '<!-- AIKIT:INDEX:START -->',
    end: '<!-- AIKIT:INDEX:END -->',
    render: renderAgentsIndex,
  },
];

function applyInjection(content, inj, inner) {
  const text = content.replace(/\r\n/g, '\n');
  const s = text.indexOf(inj.start);
  const e = text.indexOf(inj.end);
  if (s === -1 || e === -1 || e < s) {
    fail(inj.file, `не найдены маркеры ${inj.start} … ${inj.end}`);
    return null;
  }
  return text.slice(0, s + inj.start.length) + '\n' + inner + '\n' + text.slice(e);
}

// =============================================================================
// Запись / проверка
// =============================================================================
async function writeAll(files, entries) {
  for (const dir of GENERATED_DIRS) {
    await rm(path.join(OUT_ROOT, dir), { recursive: true, force: true });
  }
  for (const f of files) {
    const abs = path.join(OUT_ROOT, f.path);
    await mkdir(path.dirname(abs), { recursive: true });
    await writeFile(abs, f.content.replace(/\r?\n/g, EOL), 'utf8');
    log(`  + ${f.path}`);
  }
  // Инъекции в рукописные source-файлы — только при сборке самого kit.
  if (!EXTERNAL) {
    for (const inj of INJECTIONS) {
      const abs = path.join(KIT_ROOT, inj.file);
      const cur = await readFile(abs, 'utf8');
      const next = applyInjection(cur, inj, inj.render(entries));
      if (next === null) continue;
      await writeFile(abs, next.replace(/\r?\n/g, EOL), 'utf8');
      log(`  ~ ${inj.file} (inject)`);
    }
  }

  // Проекция vendor-конфигов в проект-потребитель — только при --out.
  if (EXTERNAL) await projectVendorConfigs();
}

// Переносит конфиги хуков/MCP из kit в корень потребителя, переписывая пути
// скриптов под submodule (например scripts/ai/ -> s3lab-ai-kit/scripts/ai/).
// Не затирает существующие файлы (consumer может иметь свои настройки).
async function projectVendorConfigs() {
  let created = 0;
  let skipped = 0;
  for (const rel of VENDOR_CONFIGS) {
    const src = path.join(KIT_ROOT, rel);
    if (!existsSync(src)) continue;
    const dest = path.join(OUT_ROOT, rel);
    if (existsSync(dest)) {
      console.log(`  = ${rel} (уже есть — пропуск; шаблон в ${KIT_REL}${rel})`);
      skipped++;
      continue;
    }
    const content = (await readFile(src, 'utf8'))
      .replace(/scripts\/(ai|hooks|validations)\//g, `${KIT_REL}scripts/$1/`);
    await mkdir(path.dirname(dest), { recursive: true });
    await writeFile(dest, content.replace(/\r?\n/g, EOL), 'utf8');
    console.log(`  + ${rel} (vendor-конфиг хуков)`);
    created++;
  }
  console.log(`Vendor-конфиги: создано ${created}, пропущено ${skipped}.`);
}

async function checkAll(files, entries) {
  const drift = [];
  const expected = new Set(files.map((f) => f.path.replace(/\\/g, '/')));
  for (const f of files) {
    const abs = path.join(OUT_ROOT, f.path);
    if (!existsSync(abs)) { drift.push(`отсутствует: ${f.path}`); continue; }
    const onDisk = (await readFile(abs, 'utf8')).replace(/\r\n/g, '\n');
    if (onDisk !== f.content.replace(/\r\n/g, '\n')) drift.push(`расходится: ${f.path}`);
  }
  // Лишние сгенерированные файлы (источник удалён, выход остался).
  for (const dir of GENERATED_DIRS) {
    for (const rel of await walkAny(dir)) {
      if (!expected.has(rel.replace(/\\/g, '/'))) drift.push(`лишний (нет источника): ${rel}`);
    }
  }
  // Инъекции (только при сборке самого kit).
  if (!EXTERNAL) {
    for (const inj of INJECTIONS) {
      const abs = path.join(KIT_ROOT, inj.file);
      const cur = (await readFile(abs, 'utf8')).replace(/\r\n/g, '\n');
      const next = applyInjection(cur, inj, inj.render(entries));
      if (next === null) { drift.push(`инъекция невозможна: ${inj.file}`); continue; }
      if (cur !== next) drift.push(`расходится (inject): ${inj.file}`);
    }
  }
  return drift;
}

async function walkAny(dir) {
  const abs = path.join(OUT_ROOT, dir);
  if (!existsSync(abs)) return [];
  const out = [];
  for (const ent of await readdir(abs, { withFileTypes: true })) {
    const rel = path.join(dir, ent.name);
    if (ent.isDirectory()) out.push(...(await walkAny(rel)));
    else if (ent.isFile()) out.push(rel);
  }
  return out;
}

// =============================================================================
// main
// =============================================================================
async function main() {
  console.log(`build-ai-kit: ${CHECK ? 'проверка (--check)' : 'сборка'} | источник: ${KIT_ROOT}${EXTERNAL ? ` | выход: ${OUT_ROOT}` : ''}`);
  const entries = await loadEntries();

  if (errors.length) {
    console.error('\nОшибки валидации источника:');
    for (const e of errors) console.error(`  ✗ ${e}`);
    process.exit(1);
  }

  const files = RENDERERS.flatMap((r) => r(entries));
  const counts = entries.reduce((a, e) => ((a[e.kind] = (a[e.kind] || 0) + 1), a), {});
  console.log(`Источник: ${entries.length} записей (${Object.entries(counts).map(([k, v]) => `${k}=${v}`).join(', ')}); выходов: ${files.length}`);

  if (CHECK) {
    const drift = await checkAll(files, entries);
    if (drift.length) {
      console.error('\nДРЕЙФ — выход не совпадает с источником:');
      for (const d of drift) console.error(`  ✗ ${d}`);
      console.error('\nЗапустите: node scripts/ai/build-ai-kit.mjs');
      process.exit(1);
    }
    console.log('OK: сгенерированные артефакты совпадают с источником.');
    return;
  }

  await writeAll(files, entries);
  console.log('Готово.');
}

main().catch((e) => { console.error(e); process.exit(1); });
