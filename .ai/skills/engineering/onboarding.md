---
name: onboarding
description: Онбординг разработчика TISS.AI.KIT: структура репозитория, стек, локальный старт, AI workflow, review flow и geo-специфика.
triggers:
  - onboarding
  - онбординг
  - новый разработчик
  - вход в проект
  - как начать работу
---

# Назначение
Дать новому разработчику конкретный маршрут входа в проект без устных договорённостей: что прочитать, как работать с AI-артефактами, какие review checks обязательны.

# Когда использовать
- Новый разработчик входит в проект.
- Нужно быстро объяснить AI workflow команды.
- Нужно проверить, что участник знает обязательные политики и review flow.

# Стартовый порядок
1. Прочитать `AGENTS.md` и понять обязательную маршрутизацию через `.ai/router.md`.
2. Прочитать `.ai/catalog.md`, чтобы увидеть canonical artifacts и владельцев.
3. Прочитать `.ai/policies/security_sdlc.md` и `.ai/policies/ai-usage-policy.md`.
4. Прочитать `docs/review/CODE_REVIEW.md`.
5. Прочитать `.ai/skills/engineering/dev-workflow.md`.
6. Для .NET backend задач прочитать профильный skill/subagent из `.ai/router.md`.
7. Для geo-sensitive задач прочитать `.ai/skills/dotnet/conventions/geo-distribution.md`.
8. Прочитать `.ai/mcp/servers.md` и настроить локальные env для MCP-серверов (см. раздел ниже).
9. Установить **Node.js 18+** — нужен для MCP (`npx`), session-хуков и компилятора AI-kit.
10. Понять модель «единое описание → генерация» (раздел ниже): что является источником правды и почему нельзя править сгенерированные файлы.

# Стек проекта
- .NET 10 для backend services.
- Clean Architecture, DDD, CQRS, Result pattern, MediatR, FluentValidation.
- PostgreSQL для persistence.
- RabbitMQ для messaging.
- MinIO для object storage.
- Angular для frontend, когда код присутствует в репозитории или submodule.
- Serilog, health checks и базовая observability для сервисов.

# Локальная работа
- Перед изменениями получить контекст задачи и выбрать route по `.ai/router.md`.
- Не менять unrelated файлы и не делать коммиты без явного запроса.
- Не создавать тестовые сценарии без прямой инструкции.
- Для backend API по умолчанию использовать порт `5001`, если задача требует запуска сервера.
- После изменения `.cs` учитывать правила formatting, sorting и CRLF из `docs/review/CODE_REVIEW.md`.
- **Не редактировать сгенерированные файлы** (`.claude/agents/**`, `.claude/skills/**`, `.cursor/skills/**`, `.ai/routes.generated.md`, блок `AIKIT:ROUTES` в `.ai/router.md`) — менять источник в `.ai/` и пересобирать (см. раздел ниже).

# Подключение submodule `s3lab-ai-kit`
- В прикладном проекте подключить центральный AI Kit как submodule:
  ```cmd
  git submodule add http://git-web.tiss.ru/tiss-ai-kit/s3lab-ai-kit.git s3lab-ai-kit
  ```
- Инициализировать и подтянуть содержимое submodule:
  ```cmd
  git submodule update --init --recursive
  ```
- После клонирования родительского проекта с уже подключённым submodule выполнить:
  ```cmd
  git submodule update --init --recursive
  ```
- Из корня прикладного проекта запустить синхронизацию AI Kit:
  ```cmd
  .\s3lab-ai-kit\scripts\ai\sync-ai-kit.cmd
  ```
- Если нужно посмотреть действия без записи файлов, использовать dry-run:
  ```cmd
  .\s3lab-ai-kit\scripts\ai\sync-ai-kit.cmd --dry-run
  ```
- После синхронизации в корне прикладного проекта появляются `CURSOR.md`, `CLAUDE.md`, `CODEX.md` (entry-файлы, направляют AI-клиенты к канону в `s3lab-ai-kit`), сгенерированные нативные артефакты `.claude/agents/**`, `.claude/skills/**`, `.cursor/skills/**`, а также vendor-конфиги хуков `.claude/settings.json`, `.cursor/hooks.json`, `.codex/hooks.json`, `.codex/config.toml` (для этого нужен **Node.js 18+** в PATH).
- Vendor-конфиги создаются **только если отсутствуют** — свои настройки не затираются. Пути скриптов в них переписаны под submodule (`s3lab-ai-kit/scripts/...`). Если конфиг уже есть и нужны хуки kit — сверь его с шаблоном внутри submodule.
- Проверить результат:
  ```cmd
  git status
  git submodule status
  dir CURSOR.md CLAUDE.md CODEX.md
  ```
- В MR родительского проекта должны попасть `.gitmodules`, запись submodule и корневые entry-point файлы, если проект хранит их в git. Не коммитить содержимое `s3lab-ai-kit` как обычную папку.

# Единое описание AI-kit и нативная генерация
- **Источник правды** — frontmatter файлов `.ai/skills/**` и `.ai/subagents/**` (`name`, `description`, `triggers`, опционально `model`, `tools`).
- Компилятор `scripts/ai/build-ai-kit.mjs` разворачивает источник в нативные артефакты вендоров:
  - Claude — `.claude/agents/<name>.md` (видны в Task) и `.claude/skills/<name>/SKILL.md` (нативный `/`);
  - Cursor — `.cursor/skills/<name>/SKILL.md`;
  - vendor-neutral индекс `.ai/routes.generated.md`; таблица в `.ai/router.md` (блок `AIKIT:ROUTES`).
- Все эти файлы помечены `DO NOT EDIT` — править руками нельзя. Меняешь источник в `.ai/`, затем пересобираешь:
  ```cmd
  node scripts\ai\build-ai-kit.mjs          :: пересобрать нативные артефакты
  node scripts\ai\build-ai-kit.mjs --check  :: проверить дрейф (как в CI и pre-commit)
  ```
- В прикладном проекте генерация выполняется автоматически из `sync-ai-kit.cmd` (с `--out` в корень проекта), отдельно запускать компилятор не нужно.
- Класс модели субагента задаётся полем `model` (`heavy` / `standard` / `light`); конкретные ID моделей — только в `.ai/policies/ai-usage-policy.md`.
- **Чтобы `/` и список агентов обновились** в Claude/Cursor после `pull` или пересборки — перезапустить сессию клиента (или `/agents` в Claude Code).

# Гейты качества (локально и в CI)
- Один раз поставить git pre-commit хук: `scripts\hooks\install-git-hooks.cmd` (Windows) или `sh scripts/hooks/install-git-hooks.sh` (macOS/Linux). Хук прогоняет CRLF-валидацию и `build-ai-kit --check`.
- CI (`.gitlab-ci.yml`, джоба `ai-kit-drift-check`) повторяет drift-проверку на MR и ветках `develop` / `main`.
- Session-хуки (sync submodule, usage log, secret-guard, CRLF-гейт перед `git commit`) — кросс-платформенные Node-скрипты `scripts/ai/*.mjs` и `scripts/hooks/crlf-commit-guard.mjs`; vendor-конфиги вызывают их через `node`.

# Настройка MCP-серверов (локально)
- Список одобренных серверов и их назначение — `.ai/mcp/servers.md`. Правила и работа с секретами — `.ai/mcp/conventions.md`.
- Vendor-конфиги уже в репозитории: `.claude/settings.json` (`mcpServers`), `.cursor/mcp.json`, `.codex/config.toml`. Менять их **не нужно** — они производные от реестра.
- Каждый сервер запускается через `npx`, поэтому требуется **Node.js 18+**.
- Секреты и пути в vendor-конфигах заданы через `${ENV_VAR}`. Реальные значения держать в `~/.env` или Windows Credential Manager, **не** в репозитории. Нужно задать локально:
  - `GH_PAT` — GitHub PAT с минимальным scope (`repo`, `read:org`); для сервера `github`.
  - `MCP_FS_WHITELIST` — абсолютный путь (или пути), к которым разрешён доступ серверу `filesystem`; не включать каталоги с prod-дампами и `.env`.
  - `MCP_MEMORY_PATH` — путь к локальному JSON графа сервера `memory`, например `%USERPROFILE%\.tiss-mcp-memory\graph.json`.
- Серверы `git` и `sequential-thinking` env не требуют.
- Сервер `wikijs` пока в статусе `🚧 Planned` (нет согласованной реализации). Не настраивать до перевода в `✅ Approved` — следить за чеклистом блокеров в `.ai/mcp/servers.md`.
- Запрещённые данные в MCP (секреты, PII, prod-дампы) — раздел 5 и 8 `.ai/policies/ai-usage-policy.md` распространяются полностью.

# AI workflow
- Сложное планирование: `.ai/subagents/planner.md`.
- .NET реализация, рефакторинг и создание сервисов: `.ai/subagents/dotnet/senior_dotnet_developer.md`.
- Создание .NET сервисов: senior-subagent делегирует в `clean_architecture_service_builder.md`, `simple_service_builder.md` или `dotnet_project_clarifier.md`.
- Локальное ревью: `.ai/skills/engineering/code_review_before_push.md`.
- MR/PR ревью: `.ai/skills/engineering/code_review_after_mr.md`.
- Аудит ambient-зависимостей (время, guid, env, fs, random, culture, прямой `HttpClient`): `.ai/skills/engineering/ambient_dependencies_audit.md`.
- Второй взгляд: `.ai/subagents/reviewer.md`.
- Архитектурные решения: `.ai/subagents/dotnet/architect.md`.

# Review flow
- Перед push проверить текущий diff через `code_review_before_push.md`.
- Перед merge проверить MR/PR через `code_review_after_mr.md`.
- Если diff затрагивает время, генерацию идентификаторов, чтение окружения, файловую систему, рандом, культуру или прямой `HttpClient` — обязательный чек-лист в `ambient_dependencies_audit.md` (замена на port-интерфейс для возможности мокирования).
- Для сложных изменений запросить `reviewer.md`.
- Для архитектурных решений или ADR запросить `dotnet/architect.md`.
- Все замечания оформлять по `docs/review/CODE_REVIEW.md`.

# Geo-specific checklist
- Persisted timestamps в UTC.
- Regional settings только через env/config.
- RabbitMQ consumers идемпотентны и имеют DLQ/retry policy.
- PostgreSQL миграции идемпотентны, FK и frequent filters имеют индексы.
- MinIO presigned URLs имеют ограниченный expiry, bucket access не публичный.
- PII не попадает в logs, prompts, metrics labels и object keys.

# Формат вывода
1) **Onboarding status:** `ready` | `needs_context` | `blocked`
2) **Что прочитать**
3) **Что настроить**
4) **Первый safe task**
5) **Риски или вопросы**

# Планка качества
- [ ] Ответ содержит конкретные файлы проекта.
- [ ] Указан обязательный review flow.
- [ ] Указана geo-специфика, если разработчик работает с backend/infra.
- [ ] Нет устных правил без ссылки на `.ai/**` или `docs/**`.
