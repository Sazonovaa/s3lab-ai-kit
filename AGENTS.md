## Обязательный запуск
База путей: все относительные пути в этом файле разрешай относительно директории, где расположен этот `AGENTS.md`. Если kit используется как submodule, используй `s3lab-ai-kit/` как базовую директорию.

Перед началом любой задачи:
1) Напиши имя модели, которая занимается задачей и переведи строку на новую
2) Прочитай `.ai/router.md`
3) Следуй ему и выбери ровно один route: skill из `.ai/skills/` или subagent из `.ai/subagents/`
4) Соблюдай формат вывода и quality bar выбранного route
5) Опционально: каталог артефактов и политики — [`.ai/catalog.md`](.ai/catalog.md), [`.ai/policies/security_sdlc.md`](.ai/policies/security_sdlc.md); полный план переноса: [`docs/ai/AI_STANDARDIZATION.md`](docs/ai/AI_STANDARDIZATION.md)

## Индекс маршрутов
Полный каталог skills / subagents / policies. Удобно для клиентов без нативного обнаружения (например Codex). Сгенерировано из frontmatter — **не редактировать вручную**. Протокол выбора и триггеры — в [`.ai/router.md`](.ai/router.md).

<!-- AIKIT:INDEX:START -->
<!-- GENERATED — не редактировать; источник: .ai/skills + .ai/subagents + .ai/policies -->
**Subagents (роли)**

| name | Описание | Route |
|---|---|---|
| `senior-angular-developer` | Точка входа для реализации, рефакторинга и создания Angular frontend; делегирует фичи, тесты и a11y review. | `.ai/subagents/angular/senior_angular_developer.md` |
| `business-analyst` | Постановщик задач — PRD, user stories, acceptance criteria, Definition of Ready; готовит вход для команды разработки. | `.ai/subagents/business_analyst.md` |
| `database-architect` | Архитектура БД — схема, индексы, миграции, партиционирование, performance review для PostgreSQL и других хранилищ проекта. | `.ai/subagents/database_architect.md` |
| `dotnet-architect` | Архитектурные решения, ADR review и trade-off анализ для .NET Clean Architecture, DDD, CQRS и гео-распределения. | `.ai/subagents/dotnet/architect.md` |
| `clean-architecture-service-builder` | Внутренний делегат senior-subagent: создать новый .NET 10 сервис по Clean Architecture внутри существующего SLNX-решения. | `.ai/subagents/dotnet/clean_architecture_service_builder.md` |
| `dotnet-project-clarifier` | Внутренний делегат senior-subagent: уточнить тип нового .NET 10 backend-проекта до генерации файлов. | `.ai/subagents/dotnet/dotnet_project_clarifier.md` |
| `senior-dotnet-developer` | Основная точка входа для реализации, рефакторинга и создания .NET 10 backend-сервисов; делегирует builder/clarifier/architect. | `.ai/subagents/dotnet/senior_dotnet_developer.md` |
| `simple-service-builder` | Внутренний делегат senior-subagent: создать простой .NET 10 сервис, Minimal API или Worker Service без Clean Architecture. | `.ai/subagents/dotnet/simple_service_builder.md` |
| `planner` | Декомпозиция задачи на шаги, риски и зависимости без реализации кода и без детального ревью диффа. | `.ai/subagents/planner.md` |
| `qa-engineer` | Тестировщик — test plan, e2e/smoke сценарии Playwright, регрессии, bug-reports, критерии «зелёного» прогона. | `.ai/subagents/qa_engineer.md` |
| `reviewer` | Второй взгляд на уже сделанные изменения: diff, MR/PR, регрессии, нарушение слоёв, тесты и production-риски. | `.ai/subagents/reviewer.md` |
| `solution-architect` | Кросс-стек архитектура программы — bounded contexts, контракты API и событий, integrations, выбор технологий между сервисами, ADR. | `.ai/subagents/solution_architect.md` |
| `tech-lead` | Точка входа для широких, кросс-доменных или неопределённых задач; выбирает маршрут, делегирует ролям команды, координирует результат. | `.ai/subagents/tech_lead.md` |
| `ui-designer` | UX/UI дизайнер — user flows, текстовые wireframes, design tokens, состояния компонентов, a11y AA. | `.ai/subagents/ui_designer.md` |

**Skills (процедуры)**

| name | Описание | Route |
|---|---|---|
| `angular-unit-tests` | Unit-тесты Angular — TestBed, spectator-style паттерны, моки сервисов, тестирование signals и async, без сетевых вызовов. | `.ai/skills/angular/angular_unit_tests.md` |
| `feature-implementation-angular` | Стандарт реализации Angular фичи — standalone, signals, OnPush, презентационные компоненты, маршрутизация, формы, integration с API. | `.ai/skills/angular/feature_implementation_angular.md` |
| `design-system-contract` | Контракт design system — design tokens, состояния компонентов, a11y AA, hand-off для Angular. | `.ai/skills/design/design_system_contract.md` |
| `add-clean-architecture-feature-cqrs` | Добавляет CQRS-фичу в существующий .NET Clean Architecture сервис: размещает файлы в Application по схеме Features/<Entity>/<Feature>/, использует MediatR, FluentValidation и Result pattern, не добавляет бизнес-логику в Api или Infrastructure. | `.ai/skills/dotnet/add_clean_architecture_feature_cqrs.md` |
| `clarify-dotnet-project-type` | Skill-contract для subagent, который уточняет тип нового .NET backend-проекта, если запрос слишком короткий, неоднозначный или содержит конфликтующие сигналы между Clean Architecture и простым сервисом. Не создаёт файлы. | `.ai/skills/dotnet/clarify_dotnet_project_type.md` |
| `configure-infrastructure-database` | Добавляет или проверяет инфраструктуру конкретной БД в .NET Clean Architecture сервисе: размещает всё, что относится к БД, внутри Infrastructure в отдельной папке по типу БД, включая модели, контекст, конфигурации и реализации портов. | `.ai/skills/dotnet/configure_infrastructure_database.md` |
| `configure-service-observability` | Настраивает или проверяет observability в .NET Clean Architecture сервисе: Serilog как host logger, HealthCheck endpoints, конфигурацию логирования и DI-регистрации без добавления бизнес-логики. | `.ai/skills/dotnet/configure_service_observability.md` |
| `geo-distribution` | Конвенции гео-распределения для .NET сервисов TISS.AI.KIT: UTC, локализация, RabbitMQ, PostgreSQL, MinIO, compliance и latency. | `.ai/skills/dotnet/conventions/geo-distribution.md` |
| `create-project-dotnet10-clean-architecture` | Skill-contract для subagent, который создаёт новый сервис внутри существующего .NET 10 SLNX-решения по Clean Architecture: нормализация имён, слои Api, Application, Domain, Infrastructure и Tests, шаблон Tiss.<Проект>.<Сервис>.<Слой>, src/<Сервис>/, solution folder, CQRS, Result, MediatR, Serilog, HealthCheck и FluentValidation. Применять только при явных сигналах DDD, CQRS, bounded context, enterprise, сложного домена или масштаба на несколько команд. | `.ai/skills/dotnet/create_project_dotnet10_clean_architecture.md` |
| `create-project-dotnet10-simple-service` | Skill-contract для subagent, который создаёт простой .NET 10 backend-сервис: Minimal API или Worker Service без Clean Architecture, лишних слоёв и архитектурных абстракций. Применять для CRUD, webhook, уведомлений, фоновых задач, прототипов и небольших сервисов. | `.ai/skills/dotnet/create_project_dotnet10_simple_service.md` |
| `create-solution-dotnet10` | Создаёт бэкенд-решение .NET 10 (net10.0) в формате SLNX (.slnx): сначала запрашивается название проекта (в т.ч. составное через точку), название нормализуется в PascalCase, имя решения — Tiss.{имя}.backend, далее dotnet new sln и выбор: оставить solution пустым или делегировать создание .NET-проекта отдельному skill. | `.ai/skills/dotnet/create_solution_dotnet10.md` |
| `dotnet-unit-tests-xunit-moq` | Стандарт модульных тестов .NET в этом репозитории: xUnit + Moq, Theory-first с параметром expectedResult, моки всех DI-зависимостей и недетерминизма (время, Guid, окружение, файлы, HTTP, шина), отказ от реальных БД и внешних систем, единые правила именования и группировки, числовые пороги для декомпозиции SUT перед написанием тестов. Применять при написании, ревью и оценке тестируемости любого .NET кода. | `.ai/skills/dotnet/dotnet_unit_tests_xunit_moq.md` |
| `ambient-dependencies-audit` | Аудит прямых обращений к недетерминистичным / ambient API (`DateTime.UtcNow`, `Guid.NewGuid`, `Random`, `Environment.*`, `File.*`, `CultureInfo.Current*`, прямой `HttpClient`) в production-коде и обязательная замена на port-интерфейс для возможности мокирования в xUnit + Moq. | `.ai/skills/engineering/ambient_dependencies_audit.md` |
| `code-review-after-mr` | Code review после создания MR / PR: проверка готовности к merge, контрактов, тестов, архитектуры и production-рисков. | `.ai/skills/engineering/code_review_after_mr.md` |
| `code-review-before-push` | Локальное code review перед push в ветку: быстрый контроль diff, архитектурных рисков и готовности к публикации изменений. | `.ai/skills/engineering/code_review_before_push.md` |
| `configure-mcp-server` | Стандарт добавления, изменения или удаления MCP-сервера: запись в реестр `.ai/mcp/servers.md`, синхронизация во все три vendor-конфига (`.claude/settings.json`, `.cursor/mcp.json`, `.codex/config.toml`), обработка секретов и согласование с политикой. | `.ai/skills/engineering/configure_mcp_server.md` |
| `create-skill` | Оформляет новый skill в `.ai/skills/<группа>/`: запрос назначения, варианты имён на выбор или ввод своего, YAML, тело на русском, затем пересборка компилятором. Применять при создании/добавлении skill или расширении `.ai/skills`. | `.ai/skills/engineering/create_skill.md` |
| `dev-workflow` | Стандарт жизненного цикла разработки: DoR, ветки, MR, AI-assisted review, QA и Definition of Done. | `.ai/skills/engineering/dev-workflow.md` |
| `onboarding` | Онбординг разработчика TISS.AI.KIT: структура репозитория, стек, локальный старт, AI workflow, review flow и geo-специфика. | `.ai/skills/engineering/onboarding.md` |
| `repository-layer-audit` | Audit classes named *Repository* for business logic; require refactor plan toward domain/application. | `.ai/skills/engineering/repository_layer_audit.md` |
| `jira-sprint-ac` | Sprint-sized work breakdown with acceptance criteria and Definition of Done. | `.ai/skills/product/jira_sprint_ac.md` |
| `prd-mvp-nocode` | PRD / MVP scope with no-code or low-code constraints and clear acceptance criteria. | `.ai/skills/product/prd_mvp_nocode.md` |
| `qa-bug-report` | Формат bug-report — title, environment, steps, expected, actual, severity, артефакты, без утечки PII. | `.ai/skills/qa/bug_report.md` |
| `qa-test-plan` | Формат test plan под фичу — scope, критический путь, сценарии happy/edge/negative, критерии «зелёного» прогона. | `.ai/skills/qa/test_plan.md` |
| `research-competitors` | Competitor and tool landscape research with sourced claims and comparison tables. | `.ai/skills/research/research_competitors.md` |
| `webapp-testing` | Local web application testing with Playwright — plans, selectors, failure triage. | `.ai/skills/testing/webapp_testing.md` |
| `article-habr` | Long-form technical article structure for Habr / VC.ru style audiences. | `.ai/skills/writing/article_habr.md` |

**Policies (политики)**

| name | Описание | Route |
|---|---|---|
| `ai-usage-policy` | Политика использования AI-инструментов в команде разработки TISS. Декларирует одобренные инструменты, модели, правила работы с данными, обязательные и запрещённые сценарии, контроль и гео-ограничения. Распространяется на всю команду — backend, frontend, QA, дизайн. | `.ai/policies/ai-usage-policy.md` |

<!-- AIKIT:INDEX:END -->