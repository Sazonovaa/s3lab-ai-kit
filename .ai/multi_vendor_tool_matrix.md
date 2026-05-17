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

| Механизм | Инициатор | Событие | Действие | Конфиг |
|----------|-----------|---------|----------|--------|
| Cursor hooks | Cursor IDE | `sessionStart` | Синхронизация submodule | `.cursor/hooks/sync-submodule-on-start.cmd` |
| Cursor hooks | Cursor IDE | `beforeShellExecution` | Проверка секретов в команде | `.cursor/hooks/secret-guard.cmd` |
| Cursor hooks | Cursor IDE | `beforeShellExecution` + matcher `git commit` | Валидация CRLF | `.cursor/hooks/validate-crlf-before-commit.cmd` |
| Claude Code hooks | Claude Code | `PreToolUse` (Bash) | Валидация CRLF перед коммитом | `.claude/settings.json` → `hooks` |
| Codex hooks | Codex CLI | `PreToolUse` | Валидация CRLF | `.codex/hooks.json` |
| GitLab CI | GitLab (push / MR) | pipeline trigger | Обязательные quality gates | `.gitlab-ci.yml` |
| GitLab Webhook | GitLab | HTTP POST | Интеграция Jira / боты | внешний сервис |

> GitLab CI — **обязательная** граница качества. AI-хуки дополняют, не заменяют CI.

---

## Конфиги по клиентам

### Cursor

| Файл | Назначение |
|------|-----------|
| `.cursor/hooks.json` | Декларация хуков: `sessionStart`, `beforeShellExecution` |
| `.cursor/hooks/*.cmd` | Скрипты хуков (Windows CMD) |
| `.cursor/AGENTS.md` | Доп. правила workspace: xUnit+Moq, ссылка на `AGENTS.md` |
| `.cursor/rules/*.mdc` | Path-scoped правила (C#, тесты; Angular — при появлении кода) |

### Claude Code

| Файл | Назначение |
|------|-----------|
| `.claude/settings.json` | Конфиг Claude Code; блок `hooks` по [документации](https://code.claude.com/docs/en/hooks) |
| `CLAUDE.md` | Точка входа: читать `AGENTS.md` → `.ai/router.md` |

### Codex CLI

| Файл | Назначение |
|------|-----------|
| `.codex/config.toml` | Конфиг Codex; `codex_hooks = false` до включения командой |
| `.codex/hooks.json` | Хуки Codex (заготовка) |
| `CODEX.md` | Точка входа: читать `AGENTS.md` → `.ai/router.md` |

---

## Общие правила для хуков

- **Allowlist команд** — хук `secret-guard` блокирует только явно опасные паттерны. Не расширять без ревью.
- **Таймауты** — все хуки должны завершаться за ≤ 60 секунд. Долгие проверки — в CI, не в хуках.
- **Не логировать содержимое промптов** — только имя скила, результат, время.
- **Хуки не заменяют CI** — они первая линия защиты на машине разработчика.

---

## Синхронизация submodule

Все три клиента запускают `sync-submodule-on-start` при старте сессии.
Скрипт обновляет `.ai/` из TISS.AI.KIT до актуальной версии.

```
sessionStart
  └── sync-submodule-on-start.cmd
        └── git submodule update --remote --merge
```

При конфликте submodule — разрешать вручную, не через AI-сессию.
