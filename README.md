# s3lab-ai-kit

Единый стандарт работы с AI-инструментами (Claude Code, Cursor, Codex) для всех проектов s3lab.
Подключается в проект как git submodule. После одной команды `sync-ai-kit` все три инструмента
автоматически работают по общим правилам, читают общие промпты субагентов и используют общие
пайплайны.

## Quick start

В вашем проекте:

```bash
git submodule add git@github.com:s3lab/s3lab-ai-kit.git .ai-kit
.ai-kit/bin/sync-ai-kit
```

После этого:

- Claude Code читает `CLAUDE.md` → импортирует `.ai-kit/ai/core.md`
- Cursor читает `.cursor/rules/*.mdc` (symlink на `.ai-kit/cursor-rules/`)
- Codex / GitHub Copilot CLI читает `AGENTS.md`
- В `.claude/agents/` и `.claude/commands/` появляются симлинки на промпты из kit

## Обновление kit во всех проектах

```bash
git submodule update --remote .ai-kit
.ai-kit/bin/sync-ai-kit
git add .ai-kit && git commit -m "chore: bump ai-kit to $(cat .ai-kit/VERSION)"
```

Поскольку всё подключено симлинками, новые версии промптов **сразу видны** всем AI-инструментам.

## Структура kit

```
ai/                      ← источник правды
├── core.md              ← главный контекст, импортится из CLAUDE.md проекта
├── stack.md             ← стек технологий
├── workflow.md          ← пайплайн работы
├── conventions/         ← правила по технологиям (dotnet, angular, ...)
├── agents/              ← полные промпты субагентов
└── commands/            ← пайплайны (feature, bugfix, ...)

cursor-rules/            ← native .mdc файлы для Cursor
adapters/                ← шаблоны тонких stub'ов в проект
templates/               ← одноразовые шаблоны (CI, ADR, и т.д.)
bin/                     ← sync-ai-kit и утилиты
```

## Дисциплина

- **Не редактируйте сгенерированные файлы в проекте** (симлинки и stub'ы) —
  изменения вносите сюда, в kit, затем `git submodule update --remote` в проектах.
- **Проектная специфика** — в `.ai/project-context.md` каждого проекта.
- **Override агента или правила** — в `.ai/overrides/<name>.md` проекта; kit-агенты
  читают их автоматически.
- **Семвер обязателен**: MAJOR = breaking, MINOR = новый агент/правило, PATCH = улучшение.
- **CHANGELOG.md** обновляется при каждом теге.

## Поддерживаемые ОС

macOS и Linux. Submodule-based архитектура использует symlinks; Windows на текущий момент
не поддерживается.

## Документация

- `docs/getting-started.md` — подробная установка и первый запуск
- `docs/how-it-works.md` — как устроена связь kit ↔ проект
- `docs/customization.md` — как переопределять правила в проекте
- `docs/upgrade-guide.md` — миграция между версиями
