# tiss.ai.kit.standart

`tiss.ai.kit.standart` — стандартный набор AI-инструкций, политик, skills, subagents, hooks и вспомогательных скриптов для проектов TISS.

Репозиторий нужен, чтобы все AI-инструменты команды работали по одним правилам: одинаково выбирали маршрут задачи, соблюдали security policy, выполняли обязательный review flow и не зависели от устных договорённостей.

## Для чего введён AI Kit

- Единый вход для AI-агентов через `AGENTS.md` и `.ai/router.md`.
- Общие правила использования AI: инструменты, модели, запрет secrets/PII и требования к review.
- Повторяемые процедуры в `.ai/skills/**` для ревью, онбординга, создания .NET-решений, тестов и research-задач.
- Роли автономных исполнителей в `.ai/subagents/**` для сложных задач: планирование, ревью, .NET-архитектура и генерация сервисов.
- Vendor-specific настройки для Cursor, Claude Code и Codex без дублирования бизнес-правил.
- Логирование AI usage metadata без prompt content, ответов модели, секретов и персональных данных.

## Как подключить к проекту

В родительском проекте подключите этот репозиторий как submodule:

```powershell
git submodule add http://git-web.tiss.ru/tiss-ai-kit/tiss.ai.kit.standart.git tiss.ai.kit.standart
git submodule update --init --recursive
```

После клонирования проекта, где submodule уже подключён, выполните:

```powershell
git submodule update --init --recursive
```

Проверка:

```powershell
git status
git submodule status
```

В MR родительского проекта должны попасть `.gitmodules` и запись submodule. Содержимое `tiss.ai.kit.standart` не нужно коммитить как обычную папку.

## Базовый порядок работы агента

1. Прочитать `AGENTS.md`.
2. Прочитать `.ai/router.md`.
3. Выбрать ровно один route: `skill` из `.ai/skills/**`, policy из `.ai/policies/**` или `subagent` из `.ai/subagents/**`.
4. Выполнить выбранный маршрут по его формату вывода и quality bar.
5. Перед push применить `.ai/skills/engineering/code_review_before_push.md`.
6. Перед merge применить `.ai/skills/engineering/code_review_after_mr.md`.

## Назначение ключевых файлов

### Разделение ответственности

- `.ai/router.md` — исполняемый протокол для агента: что открыть и запустить прямо сейчас.
- `.ai/catalog.md` — манифест владения для команды: что существует в репозитории, кто отвечает и какой minimum set обязателен.
- `.ai/policies/ai-usage-policy.md` — политика для людей: какие инструменты и модели разрешены, какие данные запрещены, какой контроль обязателен.
- `.ai/multi_vendor_tool_matrix.md` — техническая матрица hooks и конфигов: кто что триггерит в Cursor, Claude Code и Codex.

### Корневые инструкции

- `AGENTS.md` — обязательная стартовая инструкция для агента: сначала назвать модель, затем читать `.ai/router.md` и выбирать один маршрут.
- `CLAUDE.md` — входная инструкция для Claude Code: следует корневому `AGENTS.md` и учитывает `.claude/**`.
- `CODEX.md` — входная инструкция для Codex CLI: следует корневому `AGENTS.md` и учитывает `.codex/**`.
- `CURSOR.md` — входная инструкция для Cursor: следует корневому `AGENTS.md` и учитывает `.cursor/**`.

### Каталог и маршрутизация

- `.ai/router.md` — главный протокол выбора маршрута. Определяет категории задач, таблицу skills/subagents и общий Output Contract.
- `.ai/catalog.md` — каталог AI-артефактов: какие файлы являются canonical, кто владеет изменениями и какие minimum skills/subagents должны быть в репозитории.
- `.ai/multi_vendor_tool_matrix.md` — матрица hooks и vendor-specific конфигов для Cursor, Claude Code и Codex. Не содержит правила выбора моделей и инструментов: они живут в `.ai/policies/ai-usage-policy.md`.
- `docs/ai/AI_STANDARDIZATION.md` — общий план стандартизации AI для .NET, Angular и разных AI-вендоров.

### Политики

- `.ai/policies/ai-usage-policy.md` — правила использования AI: одобренные инструменты, модели, обязательный Code Review, запретные данные, geo-ограничения и контроль.
- `.ai/policies/security_sdlc.md` — политика по данным и SDLC: secrets, PII, production data, DoR/DoD и incident response.

### Engineering skills

- `.ai/skills/engineering/onboarding.md` — онбординг разработчика: что читать, как настроить локальную работу, как подключить submodule, какой review flow обязателен.
- `.ai/skills/engineering/dev-workflow.md` — жизненный цикл задачи: DoR, ветки, MR requirements, AI steps, QA и Definition of Done.
- `.ai/skills/engineering/code_review_before_push.md` — локальное ревью текущего diff перед push.
- `.ai/skills/engineering/code_review_after_mr.md` — ревью MR/PR перед merge.
- `.ai/skills/engineering/repository_layer_audit.md` — аудит классов `*Repository*`: в репозиториях должен быть доступ к данным, а не бизнес-логика.
- `.ai/skills/engineering/create_skill.md` — процедура создания или изменения skill в `.ai/skills/**` и строки в `.ai/router.md`.

### .NET skills

- `.ai/skills/dotnet/create_solution_dotnet10.md` — создание нового backend-решения на .NET 10.
- `.ai/skills/dotnet/create_project_dotnet10_clean_architecture.md` — создание .NET 10 проекта по Clean Architecture.
- `.ai/skills/dotnet/create_project_dotnet10_simple_service.md` — создание простого .NET 10 сервиса.
- `.ai/skills/dotnet/add_clean_architecture_feature_cqrs.md` — добавление CQRS-фичи в существующий Clean Architecture сервис.
- `.ai/skills/dotnet/configure_infrastructure_database.md` — настройка БД в Infrastructure-слое.
- `.ai/skills/dotnet/configure_service_observability.md` — настройка Serilog, health checks и базовой observability.
- `.ai/skills/dotnet/dotnet_unit_tests_xunit_moq.md` — правила unit-тестов для .NET: xUnit + Moq, без реальной БД.
- `.ai/skills/dotnet/clarify_dotnet_project_type.md` — уточнение типа .NET проекта перед созданием.
- `.ai/skills/dotnet/conventions/geo-distribution.md` — правила geo-sensitive разработки: UTC, RabbitMQ, PostgreSQL, MinIO, compliance и latency.

### Product, testing, research и writing skills

- `.ai/skills/product/prd_mvp_nocode.md` — подготовка PRD/MVP.
- `.ai/skills/product/jira_sprint_ac.md` — задачи спринта, acceptance criteria и DoD.
- `.ai/skills/testing/webapp_testing.md` — web/e2e/UI testing через Playwright.
- `.ai/skills/research/research_competitors.md` — исследование конкурентов, технологий и рынка.
- `.ai/skills/writing/article_habr.md` — структура и тон статьи для Habr/VC.

### Subagents

- `.ai/subagents/planner.md` — декомпозиция задачи, риски и зависимости.
- `.ai/subagents/reviewer.md` — второй взгляд на diff, регрессии, тесты и нарушение слоёв.
- `.ai/subagents/dotnet/senior_dotnet_developer.md` — основная точка входа для .NET реализации, рефакторинга и создания backend-сервисов.
- `.ai/subagents/dotnet/architect.md` — архитектурные решения и ADR review для .NET Clean Architecture и geo-контекста.
- `.ai/subagents/dotnet/dotnet_project_clarifier.md` — уточнение типа нового .NET 10 backend-проекта.
- `.ai/subagents/dotnet/simple_service_builder.md` — создание простого .NET 10 сервиса.
- `.ai/subagents/dotnet/clean_architecture_service_builder.md` — создание .NET 10 сервиса по Clean Architecture.

### Vendor-specific настройки

- `.cursor/hooks.json` — настройки Cursor hooks: AI usage metadata, shell guard и CRLF validate перед commit.
- `.cursor/hooks/*.cmd` — Windows wrappers для Cursor hooks.
- `.cursor/rules/*.mdc` — path-scoped правила Cursor для конкретных типов файлов.
- `.claude/settings.json` — настройки Claude Code и hooks.
- `.claude/hooks/*.cmd` — wrappers для Claude Code hooks.
- `.codex/hooks.json` — hooks для Codex.
- `.codex/config.toml` — настройки Codex CLI.

### Скрипты и логи

- `scripts/ai/log-ai-usage.cmd` и `scripts/ai/log-ai-usage.ps1` — запись metadata об AI-сессиях без содержимого prompt и ответов модели.
- `scripts/ai/ai-usage-report.ps1` — агрегация usage metadata.
- `logs/ai-usage.jsonl` — локальный журнал AI usage metadata.
- `logs/.gitignore` — правила, чтобы в git не попадали лишние runtime-логи.

## Обязательные правила для команды

- Изменения в `.ai/**`, `AGENTS.md`, политиках и vendor-specific настройках проходят через MR + review.
- Secrets, токены, private keys, connection strings с паролями, production dumps и PII нельзя отправлять в AI prompts, logs и telemetry.
- AI-assisted Code Review обязателен перед push и перед merge в `develop` или `main`.
- Для .NET unit-тестов используется `xUnit + Moq`; NUnit не добавлять.
- Для backend API по умолчанию использовать порт `5001`, если задача требует локального запуска сервера.
- Для geo-sensitive задач учитывать UTC, data residency, RabbitMQ DLQ/retry, PostgreSQL индексы и MinIO access policy.
