# Multi-vendor hooks matrix (Cursor / Claude Code / Codex)

## Назначение

Один документ для механики хуков и конфигов по трём AI-клиентам:
кто что триггерит, где лежит конфиг, что переносимо между клиентами.

> Какие инструменты и модели разрешены → `.ai/policies/ai-usage-policy.md`
> Какой скил запустить для задачи    → `.ai/router.md`
> Что существует в репозитории       → `.ai/catalog.md`

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

Все хуки вызывают **один и тот же набор кроссплатформенных pwsh-скриптов** из `scripts/ai/`. Команда вызова идентична на Windows / macOS / Linux:

```text
pwsh -NoProfile -File ./scripts/ai/<script>.ps1 [args]
```

| Механизм | Инициатор | Событие | Действие | Конфиг → команда |
|----------|-----------|---------|----------|------------------|
| Cursor hooks | Cursor IDE | `sessionStart` | Sync submodule + log usage metadata | `.cursor/hooks.json` → `pwsh ... sync-submodule-on-start.ps1` + `pwsh ... log-ai-usage.ps1` |
| Cursor hooks | Cursor IDE | `beforeShellExecution` | Log usage metadata | `.cursor/hooks.json` → `pwsh ... log-ai-usage.ps1` |
| Claude Code hooks | Claude Code | `SessionStart` | Sync submodule + log usage | `.claude/settings.json` → `hooks.SessionStart` |
| Claude Code hooks | Claude Code | `PreToolUse` (Bash) | Log usage metadata | `.claude/settings.json` → `hooks.PreToolUse` |
| Codex hooks | Codex CLI | `sessionStart` | Sync submodule + log usage | `.codex/hooks.json` |
| Codex hooks | Codex CLI | `PreToolUse` | Log usage metadata | `.codex/hooks.json` |
| GitLab CI | GitLab (push / MR) | pipeline trigger | Обязательные quality gates | `.gitlab-ci.yml` |
| GitLab Webhook | GitLab | HTTP POST | Интеграция Jira / боты | внешний сервис |

> GitLab CI — **обязательная** граница качества. AI-хуки дополняют, не заменяют CI.

### Установка `pwsh` (один раз на хосте)

- **macOS**: `brew install --cask powershell`
- **Linux**: см. [инструкцию Microsoft](https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-linux)
- **Windows**: `winget install --id Microsoft.PowerShell -e` (или есть из коробки на Win 10/11)

---

## Конфиги по клиентам

### Cursor

| Файл | Назначение |
|------|-----------|
| `.cursor/hooks.json` | Декларация хуков (вызывает `pwsh` напрямую): `sessionStart`, `beforeShellExecution` |
| `.cursor/rules/*.mdc` | Path-scoped правила (C#, Angular) |

### Claude Code

| Файл | Назначение |
|------|-----------|
| `.claude/settings.json` | Конфиг Claude Code; блок `hooks` вызывает `pwsh -NoProfile -File ./scripts/ai/*.ps1` |
| `CLAUDE.md` | Точка входа: читать `AGENTS.md` → `.ai/router.md` |

### Codex CLI

| Файл | Назначение |
|------|-----------|
| `.codex/config.toml` | Конфиг Codex; `codex_hooks = true` для активации хуков |
| `.codex/hooks.json` | Хуки Codex: `sessionStart` + `PreToolUse` (вызывают `pwsh`) |
| `CODEX.md` | Точка входа: читать `AGENTS.md` → `.ai/router.md` |

---

## Общие правила для хуков

- **Allowlist команд** — хук `secret-guard` блокирует только явно опасные паттерны. Не расширять без ревью.
- **Таймауты** — все хуки должны завершаться за ≤ 60 секунд. Долгие проверки — в CI, не в хуках.
- **Не логировать содержимое промптов** — только имя скила, результат, время.
- **Хуки не заменяют CI** — они первая линия защиты на машине разработчика.

---

## Синхронизация submodule

Все три клиента запускают `scripts/ai/sync-submodule-on-start.ps1` при старте сессии (через `pwsh`).
Скрипт fast-forward'ит submodule до upstream, если нет диверсии локальной истории.

```text
sessionStart
  └── pwsh -NoProfile -File ./scripts/ai/sync-submodule-on-start.ps1
        ├── git -C tiss.ai.kit.standart fetch
        ├── проверка fast-forward
        ├── git -C tiss.ai.kit.standart pull --ff-only
        └── pwsh ./scripts/ai/sync-ai-kit.ps1 -DryRun
```

При конфликте submodule или diverged history — скрипт логирует причину и выходит без изменений.
Резолвить вручную, не через AI-сессию.
