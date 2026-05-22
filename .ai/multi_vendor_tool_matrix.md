# Multi-vendor hooks matrix (Cursor / Claude Code / Codex)

## Назначение

Один документ для механики хуков и конфигов по трём AI-клиентам:
кто что триггерит, где лежит конфиг, что переносимо между клиентами.

> Какие инструменты и модели разрешены → `.ai/policies/ai-usage-policy.md`
> Какой скил запустить для задачи    → `.ai/router.md`
> Что существует в репозитории       → `.ai/catalog.md`
> Реестр MCP-серверов                → `.ai/mcp/servers.md`

---

## Переносимость артефактов

| Тип | Переносимо | Примеры |
|-----|-----------|---------|
| **Portable** | Да — любой клиент читает | `.ai/skills/*.md`, `.ai/subagents/*.md`, `AGENTS.md`, `docs/review/CODE_REVIEW.md` |
| **Vendor** | Нет — формат специфичен для клиента | `.cursor/*`, `.claude/*`, `.codex/*` |

Правило: **правила и процедуры живут в `.ai/`** (portable).
Vendor-папки содержат только конфиги запуска и хуки конкретного клиента.

---

## Хуки: кто что триггерит

Все хуки вызывают **один и тот же набор кросс-платформенных Node-скриптов** из `scripts/ai/` (и `scripts/hooks/`).

```text
node scripts/ai/<script>.mjs [args]
```

| Механизм | Инициатор | Событие | Действие | Конфиг → команда |
|----------|-----------|---------|----------|------------------|
| Cursor hooks | Cursor IDE | `sessionStart` | Sync submodule + log usage metadata | `.cursor/hooks.json` → `node scripts/ai/*.mjs` |
| Cursor hooks | Cursor IDE | `beforeShellExecution` | Log usage + secret-guard + CRLF-гейт | `.cursor/hooks.json` → `node scripts/ai/*.mjs`, `node scripts/hooks/crlf-commit-guard.mjs` |
| Claude Code hooks | Claude Code | `SessionStart` | Sync submodule + log usage | `.claude/settings.json` → `hooks.SessionStart` |
| Claude Code hooks | Claude Code | `PreToolUse` (Bash) | Log usage metadata | `.claude/settings.json` → `hooks.PreToolUse` |
| Codex hooks | Codex CLI | `sessionStart` | Sync submodule + log usage | `.codex/hooks.json` |
| Codex hooks | Codex CLI | `PreToolUse` | Log usage metadata | `.codex/hooks.json` |
| GitLab CI | GitLab (push / MR) | pipeline trigger | Обязательные quality gates | `.gitlab-ci.yml` |
| GitLab Webhook | GitLab | HTTP POST | Интеграция Jira / боты | внешний сервис |

> GitLab CI — **обязательная** граница качества. AI-хуки дополняют, не заменяют CI.

### Требование к среде

- **Node.js 18+** — единственная зависимость хуков; скрипты `.mjs` работают одинаково на Windows, macOS и Linux.
- Hook-конфиги вызывают `node scripts/ai/<script>.mjs` напрямую — без `cmd.exe` / PowerShell-обёрток, поэтому кодировка вывода и поведение не зависят от клиента и ОС.
- CRLF-валидатор остаётся в двух формах (`validate-crlf.sh` / `.cmd`) и выбирается по ОС; вся остальная логика хуков — Node.

---

## Конфиги по клиентам

### Cursor

| Файл | Назначение |
|------|-----------|
| `.cursor/hooks.json` | Декларация хуков: `sessionStart`, `beforeShellExecution` |
| `.cursor/rules/*.mdc` | Path-scoped правила (C#, Angular) |

### Claude Code

| Файл | Назначение |
|------|-----------|
| `.claude/settings.json` | Конфиг Claude Code; блок `hooks` вызывает `node scripts/ai/*.mjs` |
| `CLAUDE.md` | Точка входа: читать `AGENTS.md` → `.ai/router.md` |

### Codex CLI

| Файл | Назначение |
|------|-----------|
| `.codex/config.toml` | Конфиг Codex; `codex_hooks = true` для активации хуков |
| `.codex/hooks.json` | Хуки Codex: `sessionStart` + `PreToolUse` |
| `CODEX.md` | Точка входа: читать `AGENTS.md` → `.ai/router.md` |

---

## Общие правила для хуков

- **Allowlist команд** — хук `secret-guard` блокирует только явно опасные паттерны. Не расширять без ревью.
- **Таймауты** — все хуки должны завершаться за ≤ 60 секунд. Долгие проверки — в CI, не в хуках.
- **Не логировать содержимое промптов** — только имя скила, результат, время.
- **Хуки не заменяют CI** — они первая линия защиты на машине разработчика.

---

## MCP-серверы по клиентам

Подключение MCP-серверов — vendor-специфично, но **список одобренных серверов
единый**: [`.ai/mcp/servers.md`](mcp/servers.md). Vendor-файлы — производные.

| Клиент      | Файл vendor-конфига                  | Формат                                                                |
|-------------|--------------------------------------|------------------------------------------------------------------------|
| Claude Code | `.claude/settings.json` (`mcpServers`) или `.mcp.json` в корне проекта | JSON: `{ "mcpServers": { "<id>": { "command", "args", "env" } } }` |
| Cursor      | `.cursor/mcp.json`                   | JSON: `{ "mcpServers": { "<id>": { "command", "args", "env" } } }`     |
| Codex CLI   | `.codex/config.toml` (`[mcp_servers.<id>]`) | TOML: блок на каждый сервер с полями `command`, `args`, `env`   |

### Правила

- Имя сервера (`id`) одинаково во всех трёх клиентах.
- Секреты — только через `${ENV_VAR}`, никогда не коммитятся в vendor-конфиг.
- Добавление/изменение — через MR + [`.ai/skills/engineering/configure_mcp_server.md`](skills/engineering/configure_mcp_server.md).
- Полные конвенции (transport, write-флаг, секреты) — [`.ai/mcp/conventions.md`](mcp/conventions.md).

---

## Синхронизация submodule

Все три клиента запускают `node scripts/ai/sync-submodule-on-start.mjs` при старте сессии.
Скрипт fast-forward'ит submodule до upstream, если нет диверсии локальной истории.

```text
sessionStart
  └── node scripts/ai/sync-submodule-on-start.mjs
        ├── git -C s3lab-ai-kit fetch
        ├── проверка fast-forward
        └── git -C s3lab-ai-kit pull --ff-only
```

При конфликте submodule или diverged history — скрипт логирует причину и выходит без изменений.
Резолвить вручную, не через AI-сессию.
