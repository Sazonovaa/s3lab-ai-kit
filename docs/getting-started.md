# Getting started

Как подключить s3lab-ai-kit к проекту за 2 минуты.

## Требования

- macOS или Linux (Windows не поддерживается — используются symlinks)
- Git ≥ 2.30
- Bash ≥ 4
- Установлен хотя бы один из AI-инструментов: Claude Code, Cursor, или Codex CLI

## Установка в новый проект

```bash
.ai-kit/bin/new-project my-service ~/Projects
cd ~/Projects/my-service
```

Скрипт сделает за вас:
1. Создаст директорию проекта
2. `git init` с веткой `main`
3. Добавит kit как submodule в `.ai-kit/`
4. Запустит `sync-ai-kit` — создаст все адаптеры и symlinks
5. Создаст первый коммит

## Установка в существующий проект

```bash
cd ~/Projects/my-existing-project
git submodule add git@github.com:s3lab/s3lab-ai-kit.git .ai-kit
.ai-kit/bin/sync-ai-kit
```

После этого:
- Откройте `.ai/project-context.md` и заполните специфику проекта
- Закоммитьте: `git add -A && git commit -m "chore: install s3lab-ai-kit"`

## Проверка установки

В корне проекта должны появиться:

```
CLAUDE.md                  # 5 строк — импортит .ai-kit/ai/core.md
AGENTS.md                  # для Codex/CLI агентов
.ai-kit/                   # submodule
.ai/
├── project-context.md     # ваша проектная специфика
└── overrides/             # переопределения kit-агентов (пока пусто)
.claude/
├── settings.json
├── agents -> ../../.ai-kit/ai/agents/       # symlink
└── commands -> ../../.ai-kit/ai/commands/   # symlink
.cursor/
└── rules -> ../.ai-kit/cursor-rules/        # symlink
docs/
├── architecture.md
└── adr/
.github/
├── ISSUE_TEMPLATE/
├── PULL_REQUEST_TEMPLATE.md
└── workflows/
.editorconfig
```

## Первая проверка работы

### В Claude Code

```bash
claude
> /memory
```

В списке загруженных файлов должны быть `CLAUDE.md` и через `@`-импорты:
`.ai-kit/ai/core.md`, `.ai-kit/ai/stack.md`, все conventions, `.ai/project-context.md`.

Затем:
```
> /agents
```

Должны появиться все 8 субагентов (orchestrator, backend-dotnet, frontend-angular,
api-contract, devops, reviewer, tester, designer).

Запустите тестовый pipeline:
```
> /feature добавить healthcheck endpoint
```

### В Cursor

Откройте проект, затем Settings → Rules. Должны быть видны правила из `.cursor/rules/`:
- `000-core` (alwaysApply)
- `010-dotnet` (auto-attach на C# файлах)
- `020-angular` (auto-attach на TS/HTML файлах фронта)
- `040-security` (alwaysApply)
- `050-git` (alwaysApply)

### В Codex CLI

`AGENTS.md` будет автоматически загружен агентом при работе в директории проекта.

## Обновление kit

```bash
git submodule update --remote .ai-kit
.ai-kit/bin/sync-ai-kit
git add .ai-kit && git commit -m "chore: bump ai-kit to v$(cat .ai-kit/VERSION)"
```

Симлинки переподключаются автоматически. Шаблоны (CI, ADR, docs/architecture.md и т.д.)
обновляются только при отсутствии — существующие проектные файлы не перезаписываются.

## Что дальше

- `how-it-works.md` — подробное описание архитектуры kit ↔ проект
- `customization.md` — как переопределять правила и агентов под конкретный проект
- `upgrade-guide.md` — миграция между мажорными версиями kit
