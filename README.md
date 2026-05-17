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

## Prerequisites

Все скрипты в `scripts/ai/` написаны на **PowerShell Core (pwsh)** и работают одинаково на Windows, macOS и Linux. Установите `pwsh`, если его ещё нет:

- **macOS**: `brew install --cask powershell`
- **Linux**: см. [официальная инструкция Microsoft](https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-linux)
- **Windows 10/11**: `winget install --id Microsoft.PowerShell -e` (или есть из коробки)

Проверка установки:

```bash
pwsh -Version
```

Прямой запуск скриптов (одна команда на всех ОС):

```bash
pwsh -NoProfile -File ./scripts/ai/log-ai-usage.ps1 -Vendor cursor -Event sessionStart
pwsh -NoProfile -File ./scripts/ai/sync-ai-kit.ps1 -DryRun
pwsh -NoProfile -File ./scripts/ai/ai-usage-report.ps1 -LastDays 30
```

## Как подключить к проекту

В родительском проекте подключите этот репозиторий как submodule:

```bash
git submodule add http://git-web.tiss.ru/tiss-ai-kit/tiss.ai.kit.standart.git tiss.ai.kit.standart
git submodule update --init --recursive
```

После клонирования проекта, где submodule уже подключён, выполните:

```bash
git submodule update --init --recursive
```

Проверка:

```bash
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

### Angular skills

- `.ai/skills/angular/feature_implementation_angular.md` — стандарт реализации Angular фичи (standalone, signals, OnPush, разделение smart/presentational).
- `.ai/skills/angular/angular_unit_tests.md` — unit-тесты Angular (TestBed, signals, моки сервисов, без сетевых вызовов).

### Design skills

- `.ai/skills/design/design_system_contract.md` — контракт дизайна: design tokens, состояния компонентов, a11y AA, hand-off для разработки.

### QA skills

- `.ai/skills/qa/test_plan.md` — формат test plan под фичу/релиз.
- `.ai/skills/qa/bug_report.md` — формат bug-report (severity, артефакты, без PII).

### Product, testing, research и writing skills

- `.ai/skills/product/prd_mvp_nocode.md` — подготовка PRD/MVP.
- `.ai/skills/product/jira_sprint_ac.md` — задачи спринта, acceptance criteria и DoD.
- `.ai/skills/testing/webapp_testing.md` — web/e2e/UI testing через Playwright.
- `.ai/skills/research/research_competitors.md` — исследование конкурентов, технологий и рынка.
- `.ai/skills/writing/article_habr.md` — структура и тон статьи для Habr/VC.

### Subagents (AI-команда разработки)

Иерархия и ответственность:

```text
Tech Lead (.ai/subagents/tech_lead.md)
├── Solution Architect       — кросс-стек архитектура, контракты API/событий
│   └── Database Architect   — схема БД, индексы, миграции, performance
│       └── .NET Architect   — архитектура внутри .NET сервиса (Clean Arch / DDD)
├── Business Analyst         — PRD, user stories, AC, DoR (постановщик)
├── Planner                  — декомпозиция, риски, зависимости
├── UX/UI Designer           — user flows, состояния, design tokens, a11y AA
├── Senior .NET Developer    — реализация backend
├── Senior Angular Developer — реализация frontend
├── QA Engineer              — test plan, e2e/smoke, bug-reports
└── Reviewer                 — второй взгляд на diff
```

- `.ai/subagents/tech_lead.md` — точка входа для широких / кросс-доменных задач; маршрутизация по ролям.
- `.ai/subagents/solution_architect.md` — кросс-стек архитектура, контракты API и событий, integrations, ADR.
- `.ai/subagents/database_architect.md` — схема БД, индексы, миграции, partitioning, performance review.
- `.ai/subagents/business_analyst.md` — постановщик: PRD, user stories, acceptance criteria, Definition of Ready.
- `.ai/subagents/ui_designer.md` — UX/UI: user flows, состояния компонентов, design tokens, a11y AA, hand-off для Angular.
- `.ai/subagents/qa_engineer.md` — test plan, e2e/smoke сценарии Playwright, bug-reports.
- `.ai/subagents/planner.md` — декомпозиция задачи, риски и зависимости.
- `.ai/subagents/reviewer.md` — второй взгляд на diff, регрессии, тесты и нарушение слоёв.
- `.ai/subagents/angular/senior_angular_developer.md` — точка входа для реализации, рефакторинга и фичей Angular.
- `.ai/subagents/dotnet/senior_dotnet_developer.md` — точка входа для .NET реализации, рефакторинга и создания backend-сервисов.
- `.ai/subagents/dotnet/architect.md` — архитектурные решения и ADR review для .NET Clean Architecture и geo-контекста.
- `.ai/subagents/dotnet/dotnet_project_clarifier.md` — уточнение типа нового .NET 10 backend-проекта.
- `.ai/subagents/dotnet/simple_service_builder.md` — создание простого .NET 10 сервиса.
- `.ai/subagents/dotnet/clean_architecture_service_builder.md` — создание .NET 10 сервиса по Clean Architecture.

Правила маршрутизации:
- Для **широкой / неясной задачи** — `tech_lead`; он делегирует ролям.
- Для **узкой задачи** с одной очевидной ролью — идти напрямую в нужный subagent, минуя Tech Lead.
- Для **архитектурных решений без реализации** — `solution_architect` (кросс-стек), `database_architect` (БД) или `dotnet/architect` (внутри .NET сервиса).
- Для **реализации** — `senior_dotnet_developer` (backend) или `senior_angular_developer` (frontend).

### Vendor-specific настройки

Все vendor-хуки вызывают **один и тот же набор кроссплатформенных pwsh-скриптов** из `scripts/ai/`. Никаких `.cmd` / `.sh` обёрток — одна команда на всех ОС: `pwsh -NoProfile -File ./scripts/ai/<script>.ps1`.

- `.cursor/hooks.json` — Cursor hooks: `sessionStart` (sync submodule + log usage), `beforeShellExecution` (log usage).
- `.cursor/rules/*.mdc` — path-scoped правила Cursor для конкретных типов файлов (C#, Angular).
- `.claude/settings.json` — Claude Code hooks: `SessionStart`, `PreToolUse` (Bash).
- `.codex/hooks.json` — Codex hooks: `sessionStart`, `PreToolUse`.
- `.codex/config.toml` — `codex_hooks = true` для активации хуков Codex.

### Скрипты и логи

Все скрипты — на PowerShell Core (`pwsh`), работают на Windows / macOS / Linux. См. раздел [Prerequisites](#prerequisites) выше.

- `scripts/ai/log-ai-usage.ps1` — запись metadata об AI-сессиях (vendor, event, skill/subagent) без содержимого prompt и ответов модели.
- `scripts/ai/ai-usage-report.ps1` — агрегация usage metadata за период.
- `scripts/ai/sync-ai-kit.ps1` — копирование содержимого AI-kit submodule в корень сервисного репо.
- `scripts/ai/sync-submodule-on-start.ps1` — авто-fast-forward submodule на старте сессии.
- `scripts/ai/ai-kit.default-path` — путь к kit submodule по умолчанию.
- `scripts/ai/ai-kit.sync-exclude.json` — top-level имена, исключаемые при синхронизации.
- `logs/ai-usage.jsonl` — локальный журнал AI usage metadata.
- `logs/.gitignore` — правила, чтобы в git не попадали лишние runtime-логи.

## Обязательные правила для команды

- Изменения в `.ai/**`, `AGENTS.md`, политиках и vendor-specific настройках проходят через MR + review.
- Secrets, токены, private keys, connection strings с паролями, production dumps и PII нельзя отправлять в AI prompts, logs и telemetry.
- AI-assisted Code Review обязателен перед push и перед merge в `develop` или `main`.
- Для .NET unit-тестов используется `xUnit + Moq`; NUnit не добавлять.
- Для backend API по умолчанию использовать порт `5001`, если задача требует локального запуска сервера.
- Для geo-sensitive задач учитывать UTC, data residency, RabbitMQ DLQ/retry, PostgreSQL индексы и MinIO access policy.
