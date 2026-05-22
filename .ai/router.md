# Router: протокол выбора маршрута агента

## Цель
Для каждого запроса пользователя выбрать ровно **один** наиболее подходящий маршрут исполнения и стабильно выдать нужный артефакт.

Типы маршрутов:
- **skill** — процедурный чеклист или контракт из `.ai/skills/`; использовать для сфокусированных задач, ревью, тестов, текстов, исследований или небольших шагов реализации.
- **subagent** — автономная исполнительная роль из `.ai/subagents/`; использовать для сложных задач реализации, которые создают или меняют много файлов и требуют изолированного контекста.

## Шаг 0 — классификация задачи (обязательно)
Классифицировать запрос в одну основную категорию:

- **product**: PRD, требования, объём MVP, user stories, acceptance criteria, roadmap.
- **engineering**: реализация, рефакторинг, отладка, архитектура, изменения PR, репозитории, unit-тесты.
- **testing**: e2e/ui-тесты, Playwright, test plan, QA steps, скриншоты/логи.
- **research**: анализ конкурентов, обзор технологий, сравнение инструментов, ссылки на источники.
- **writing**: черновики статей, посты, редактура тона, структура, storytelling.

Если подходит несколько категорий, выбрать ту, которая лучше всего соответствует **финальному артефакту**.

## Шаг 1 — выбор маршрута (выбрать один)
Выбрать наиболее подходящий маршрут, строго один, по приоритету:
1) явный запрос пользователя: «use skill X» / «use subagent Y»;
2) совпадение по метаданным файла маршрута, заголовку, описанию, triggers или роли;
3) ближайшее совпадение по ожидаемому артефакту из таблицы ниже.

### Специальное правило: оркестрация команды (широкие/неопределённые задачи)
Если запрос охватывает несколько ролей (backend + frontend + БД + QA + дизайн + постановка) или сформулирован как «организуй / распиши / спланируй команду / разнеси по ролям» — выбрать ровно один route:

1. **tech_lead** → `.ai/subagents/tech_lead.md`
   Tech Lead сам делегирует в `solution_architect`, `database_architect`, `business_analyst`, `planner`, `ui_designer`, `qa_engineer`, `senior_dotnet_developer`, `senior_angular_developer` и `reviewer`.

Если задача узкая и роль очевидна — не идти через Tech Lead, а выбирать прямой маршрут из таблицы ниже.

### Специальное правило: Angular frontend-реализация
Если пользователь просит реализовать, изменить, отрефакторить компонент / экран / фичу / форму / маршрут в Angular, выбрать ровно один route:

1. **senior_angular_developer** → `.ai/subagents/angular/senior_angular_developer.md`
   Точка входа для всей реализации Angular. Сам решает, когда обращаться к `ui_designer` за hand-off, к `solution_architect` за контрактом API, и когда писать тесты.
2. **angular-specific skill** → `.ai/skills/angular/*.md`
   Выбирать напрямую только для узких задач: реализация фичи по контракту, написание unit-тестов.

### Специальное правило: .NET backend-реализация
Если пользователь просит реализовать, изменить, отрефакторить или создать `.NET` / `C#` сервис, API, микросервис, worker или backend, выбрать ровно один route:

1. **senior_dotnet_developer** → `.ai/subagents/dotnet/senior_dotnet_developer.md`
   Выбирать для общих задач реализации, изменения существующего .NET кода и создания новых .NET сервисов. Senior-subagent сам решает, когда делегировать в builder, clarifier или architect.
2. **dotnet-specific skill** → `.ai/skills/dotnet/*.md`
   Выбирать напрямую только для узких процедурных задач без автономной реализации: unit-тесты, CQRS-фича, observability, infrastructure database или geo-conventions.

Не выбирать `dotnet_project_clarifier.md`, `clean_architecture_service_builder.md` или `simple_service_builder.md` напрямую из router для обычного запроса пользователя. Эти subagents вызываются через `senior_dotnet_developer.md`, кроме явного запроса пользователя `use subagent ...`.

### Таблица маршрутов

<!-- AIKIT:ROUTES:START -->
<!-- GENERATED — не редактировать вручную; источник: frontmatter .ai/skills + .ai/subagents -->
| Категория | Тип | name | Route файл | Триггеры |
|---|---|---|---|---|
| design | subagent | `ui-designer` | `.ai/subagents/ui_designer.md` | UX, UI, дизайнер, wireframe |
| engineering | subagent | `clean-architecture-service-builder` | `.ai/subagents/dotnet/clean_architecture_service_builder.md` | clean architecture builder, создать сервис clean architecture, clean architecture сервис |
| engineering | subagent | `database-architect` | `.ai/subagents/database_architect.md` | database architect, архитектор БД, схема БД, миграции БД |
| engineering | subagent | `dotnet-architect` | `.ai/subagents/dotnet/architect.md` | dotnet architect, архитектурное решение, ADR review, trade-off analysis |
| engineering | subagent | `dotnet-project-clarifier` | `.ai/subagents/dotnet/dotnet_project_clarifier.md` | project clarifier, уточнить тип проекта, какой тип сервиса |
| engineering | subagent | `planner` | `.ai/subagents/planner.md` | planner, планировщик, декомпозиция, work breakdown |
| engineering | subagent | `reviewer` | `.ai/subagents/reviewer.md` | reviewer, вторая голова, проверь дифф, subagent review |
| engineering | subagent | `senior-angular-developer` | `.ai/subagents/angular/senior_angular_developer.md` | angular, frontend, реализуй компонент, реализуй экран |
| engineering | subagent | `senior-dotnet-developer` | `.ai/subagents/dotnet/senior_dotnet_developer.md` | senior dotnet, реализация .net, .net сервис, backend реализация |
| engineering | subagent | `simple-service-builder` | `.ai/subagents/dotnet/simple_service_builder.md` | simple service builder, простой сервис, minimal api, worker service |
| engineering | subagent | `solution-architect` | `.ai/subagents/solution_architect.md` | solution architect, системный архитектор, архитектор программы, контракт API |
| engineering | subagent | `tech-lead` | `.ai/subagents/tech_lead.md` | tech lead, тимлид, тех лид, оркестрация задачи |
| product | subagent | `business-analyst` | `.ai/subagents/business_analyst.md` | постановщик, бизнес-аналитик, business analyst, PRD |
| testing | subagent | `qa-engineer` | `.ai/subagents/qa_engineer.md` | QA, тестировщик, test plan, bug report |
| design | skill | `design-system-contract` | `.ai/skills/design/design_system_contract.md` | — |
| engineering | skill | `add-clean-architecture-feature-cqrs` | `.ai/skills/dotnet/add_clean_architecture_feature_cqrs.md` | добавить фичу, новая cqrs feature, cqrs фича, MediatR handler |
| engineering | skill | `ambient-dependencies-audit` | `.ai/skills/engineering/ambient_dependencies_audit.md` | DateTime.UtcNow, DateTime.Now, DateTimeOffset.UtcNow, DateTimeOffset.Now |
| engineering | skill | `angular-unit-tests` | `.ai/skills/angular/angular_unit_tests.md` | — |
| engineering | skill | `clarify-dotnet-project-type` | `.ai/skills/dotnet/clarify_dotnet_project_type.md` | уточнить тип проекта, какой сервис создать, dotnet clarify, короткий запрос на сервис |
| engineering | skill | `code-review-after-mr` | `.ai/skills/engineering/code_review_after_mr.md` | code review after MR, MR review, PR review, merge request review |
| engineering | skill | `code-review-before-push` | `.ai/skills/engineering/code_review_before_push.md` | code review before push, pre-push review, before push, перед push |
| engineering | skill | `configure-infrastructure-database` | `.ai/skills/dotnet/configure_infrastructure_database.md` | добавить БД, настроить database, infrastructure database, dbcontext |
| engineering | skill | `configure-mcp-server` | `.ai/skills/engineering/configure_mcp_server.md` | mcp, mcp server, mcp сервер, подключить mcp |
| engineering | skill | `configure-service-observability` | `.ai/skills/dotnet/configure_service_observability.md` | настроить serilog, добавить healthcheck, health checks, observability |
| engineering | skill | `create-project-dotnet10-clean-architecture` | `.ai/skills/dotnet/create_project_dotnet10_clean_architecture.md` | clean architecture service, clean architecture, чистая архитектура, микросервис |
| engineering | skill | `create-project-dotnet10-simple-service` | `.ai/skills/dotnet/create_project_dotnet10_simple_service.md` | simple service, minimal api, worker service, простой сервис |
| engineering | skill | `create-skill` | `.ai/skills/engineering/create_skill.md` | создать скил, создать skill, новый skill, новый скил |
| engineering | skill | `create-solution-dotnet10` | `.ai/skills/dotnet/create_solution_dotnet10.md` | SLNX, slnx, dotnet 10 solution, солюшин dotnet 10 |
| engineering | skill | `dev-workflow` | `.ai/skills/engineering/dev-workflow.md` | dev workflow, процесс разработки, жизненный цикл задачи, definition of ready |
| engineering | skill | `dotnet-unit-tests-xunit-moq` | `.ai/skills/dotnet/dotnet_unit_tests_xunit_moq.md` | xUnit, Moq, unit test, модульный тест |
| engineering | skill | `feature-implementation-angular` | `.ai/skills/angular/feature_implementation_angular.md` | — |
| engineering | skill | `geo-distribution` | `.ai/skills/dotnet/conventions/geo-distribution.md` | geo distribution, гео-распределение, мультирегион, timezone |
| engineering | skill | `onboarding` | `.ai/skills/engineering/onboarding.md` | onboarding, онбординг, новый разработчик, вход в проект |
| engineering | skill | `repository-layer-audit` | `.ai/skills/engineering/repository_layer_audit.md` | — |
| product | skill | `jira-sprint-ac` | `.ai/skills/product/jira_sprint_ac.md` | — |
| product | skill | `prd-mvp-nocode` | `.ai/skills/product/prd_mvp_nocode.md` | — |
| research | skill | `research-competitors` | `.ai/skills/research/research_competitors.md` | — |
| testing | skill | `qa-bug-report` | `.ai/skills/qa/bug_report.md` | — |
| testing | skill | `qa-test-plan` | `.ai/skills/qa/test_plan.md` | — |
| testing | skill | `webapp-testing` | `.ai/skills/testing/webapp_testing.md` | — |
| writing | skill | `article-habr` | `.ai/skills/writing/article_habr.md` | — |
| engineering | policy | `ai-usage-policy` | `.ai/policies/ai-usage-policy.md` | политика использования AI, ai usage policy, какие AI-инструменты разрешены, какую модель использовать |
<!-- AIKIT:ROUTES:END -->

Если маршрут не найден, работать по базовым правилам `AGENTS.md`, но **всё равно соблюдать Output Contract** ниже.

## Шаг 2 — правила исполнения (обязательно)
После выбора маршрута:
- Если тип маршрута **skill**:
  - полностью прочитать выбранный skill-файл;
  - внутренне выполнить его раздел **Process** пошагово;
  - выдать результат строго по его **Output format**;
  - применять **Anti-patterns** skill как жёсткие ограничения.
- Если тип маршрута **subagent**:
  - полностью прочитать выбранный subagent-файл;
  - прочитать каждый skill-contract, на который ссылается subagent;
  - делегировать реализацию subagent-роли, если нужна генерация кода или файлов;
  - если запрос требует несколько независимых экземпляров одного subagent, запускать отдельный subagent на каждый экземпляр параллельно одним батчем, а не объединять всё в один контекст;
  - количество запусков subagent должно быть равно количеству уникальных названий, явно указанных пользователем;
  - если названия конфликтуют между собой или уже заняты в целевом контексте, не запускать subagents и запросить у пользователя новые уникальные названия;
  - финальный ответ пользователю сформировать по разделу **Output** выбранного subagent.

## Output Contract (по умолчанию)
Каждый ответ начинается с обязательного header'а из `AGENTS.md` (`Model:` / `Route:` / опционально `Delegated:`). После header'а тело ответа оформлять так:

1) **Route rationale** (1 строка) — почему выбран именно этот route
2) **Plan** (2–6 пунктов)
3) **Deliverable** (артефакт, который запросил пользователь)
4) **Self-check** (3–7 пунктов чеклиста)

Если пользователь явно просит «только финальный результат», убрать Plan и Route rationale, оставить header + Deliverable + Self-check. Header пропускать **нельзя** ни при каких условиях.

Если выбранный маршрут переопределяет формат тела (`Output (strict)` в subagent или `Output format` в skill), следовать ему, но header сохранять.

## Safety / Quality gates (всегда включены)
- Не выдумывать файлы, API или метрики. Если есть неопределённость — явно указать её и предложить проверку.
- При изменении кода предпочитать минимальные правки: smallest viable diff.
- Избегать длинных объяснений; отвечать прямо и сначала давать артефакт.
- Для `.NET` тестов в этом репозитории использовать только **xUnit + Moq** (`src/Tiss.Chatbot.Test`). Не добавлять NUnit.
