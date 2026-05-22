# Онбординг — TISS AI Kit

Единая стандартизация работы с AI-агентами (Cursor, Claude Code, Codex) для всех проектов команды. Один источник правды в `.ai/` компилируется в нативные артефакты каждого вендора.

Это короткая «страница входа». Полный онбординг-скилл с шагами, review flow и geo-спецификой — [`.ai/skills/engineering/onboarding.md`](.ai/skills/engineering/onboarding.md).

## Требования
- **Node.js 18+** в PATH — нужен для компилятора, session-хуков и MCP (`npx`).
- Git. На Windows скрипты используют `cmd`, на macOS/Linux — `.sh`; логика хуков и компилятор — кросс-платформенный Node.

## Быстрый старт (работа над самим kit)
```cmd
git clone http://git-web.tiss.ru/tiss-ai-kit/s3lab-ai-kit.git
cd s3lab-ai-kit

:: поставить git pre-commit (CRLF + drift-гейт). Windows:
scripts\hooks\install-git-hooks.cmd
:: macOS/Linux:  sh scripts/hooks/install-git-hooks.sh

:: пересобрать нативные артефакты из источника .ai/
node scripts\ai\build-ai-kit.mjs
```
После сборки перезапусти сессию AI-клиента (или `/agents` в Claude Code), чтобы `/` и список агентов подхватили изменения.

## Как это устроено: единое описание → генерация
- **Источник правды** — frontmatter файлов `.ai/skills/**` и `.ai/subagents/**` (`name`, `description`, `triggers`, опц. `model`, `tools`).
- Компилятор [`scripts/ai/build-ai-kit.mjs`](scripts/ai/build-ai-kit.mjs) разворачивает его в нативные артефакты:
  - **Claude** — `.claude/agents/<name>.md` (Task) и `.claude/skills/<name>/SKILL.md` (нативный `/`);
  - **Cursor** — `.cursor/skills/<name>/SKILL.md`;
  - vendor-neutral индекс `.ai/routes.generated.md` и таблица в `.ai/router.md` (блок `AIKIT:ROUTES`).
- Все сгенерированные файлы помечены `DO NOT EDIT`. **Правишь только источник в `.ai/`, затем пересобираешь.**

```cmd
node scripts\ai\build-ai-kit.mjs          :: пересобрать
node scripts\ai\build-ai-kit.mjs --check  :: проверить дрейф (как в CI и pre-commit)
```

- Класс модели субагента задаётся полем `model` (`heavy` / `standard` / `light`); компилятор маппит в модель Claude (opus / sonnet / haiku). Конкретные ID — только в [`.ai/policies/ai-usage-policy.md`](.ai/policies/ai-usage-policy.md).

## Гейты качества
- **pre-commit** (после `install-git-hooks`): CRLF-валидация + `build-ai-kit --check`.
- **CI** ([`.gitlab-ci.yml`](.gitlab-ci.yml), джоба `ai-kit-drift-check`): drift-проверка на MR и ветках `develop`/`main`.
- **session-хуки** (sync submodule, usage log, secret-guard, CRLF-гейт) — Node-скрипты `scripts/ai/*.mjs` и `scripts/hooks/crlf-commit-guard.mjs`, вызываются из vendor-конфигов через `node`.

## Использование как submodule в прикладном проекте
```cmd
git submodule add http://git-web.tiss.ru/tiss-ai-kit/s3lab-ai-kit.git s3lab-ai-kit
git submodule update --init --recursive

:: синхронизация: обновляет submodule, создаёт CURSOR/CLAUDE/CODEX.md и
:: генерирует нативные .claude/.cursor артефакты в корне проекта
.\s3lab-ai-kit\scripts\ai\sync-ai-kit.cmd
```
В git родительского проекта попадают `.gitmodules`, запись submodule и корневые entry-файлы. Содержимое `s3lab-ai-kit` не коммитить как обычную папку.

## Карта репозитория
| Путь | Что это |
|------|---------|
| `AGENTS.md` | Обязательный старт агента → `.ai/router.md` |
| `.ai/router.md` | Протокол выбора маршрута; таблица — генерируемый блок `AIKIT:ROUTES` |
| `.ai/skills/**`, `.ai/subagents/**` | **Источник правды** (рукописный) |
| `.ai/catalog.md` | Каталог артефактов и владельцы |
| `.ai/policies/` | Политика данных/SDLC и использования AI |
| `.claude/`, `.cursor/`, `.codex/` | Vendor-конфиги; `agents`/`skills` — **генерируемые** |
| `scripts/ai/build-ai-kit.mjs` | Компилятор единого описания |
| `scripts/ai/*.mjs`, `scripts/hooks/` | Session-хуки и установка git-хуков |
| `docs/ai/AI_STANDARDIZATION.md` | Полный план стандартизации |

## Дальше читать
1. [`AGENTS.md`](AGENTS.md) → [`.ai/router.md`](.ai/router.md) — как выбирается маршрут.
2. [`.ai/catalog.md`](.ai/catalog.md) — состав и владение артефактами.
3. [`.ai/policies/security_sdlc.md`](.ai/policies/security_sdlc.md), [`.ai/policies/ai-usage-policy.md`](.ai/policies/ai-usage-policy.md) — данные и модели.
4. [`docs/review/CODE_REVIEW.md`](docs/review/CODE_REVIEW.md) — стандарт ревью.
5. [`.ai/skills/engineering/onboarding.md`](.ai/skills/engineering/onboarding.md) — подробный онбординг-скилл (стек, geo, review flow).
