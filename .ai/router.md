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
| Категория | Тип маршрута | Файл маршрута | Когда использовать |
|---|---|---|---|
| engineering | subagent | `.ai/subagents/tech_lead.md` | Широкие / кросс-доменные задачи; маршрутизация по ролям команды |
| engineering | subagent | `.ai/subagents/solution_architect.md` | Кросс-стек архитектура, контракты API/событий, integrations, ADR |
| engineering | subagent | `.ai/subagents/database_architect.md` | Архитектура БД: схема, индексы, миграции, partitioning, perf review |
| product | subagent | `.ai/subagents/business_analyst.md` | Постановка задачи: PRD, user stories, acceptance criteria, DoR |
| engineering | subagent | `.ai/subagents/ui_designer.md` | UX / UI: user flows, состояния, design tokens, a11y AA |
| testing | subagent | `.ai/subagents/qa_engineer.md` | Test plan, e2e/smoke, регрессии, bug-reports |
| engineering | subagent | `.ai/subagents/planner.md` | Декомпозиция, риски, зависимости (без реализации) |
| engineering | subagent | `.ai/subagents/reviewer.md` | Второй взгляд на уже сделанные изменения и diff |
| engineering | subagent | `.ai/subagents/angular/senior_angular_developer.md` | Точка входа для реализации, рефакторинга и фичей Angular |
| engineering | skill | `.ai/skills/angular/feature_implementation_angular.md` | Стандарт реализации Angular фичи (standalone, signals, OnPush) |
| engineering | skill | `.ai/skills/angular/angular_unit_tests.md` | Unit-тесты Angular (TestBed, signals, моки) |
| design | skill | `.ai/skills/design/design_system_contract.md` | Контракт дизайна: tokens, состояния, a11y AA, hand-off |
| testing | skill | `.ai/skills/qa/test_plan.md` | Формат test plan под фичу / релиз |
| testing | skill | `.ai/skills/qa/bug_report.md` | Формат bug-report (severity, артефакты, без PII) |
| engineering | skill | `.ai/skills/engineering/create_skill.md` | Добавить или изменить skill в **`.ai/skills/`** и строку в **`.ai/router.md`** |
| engineering | skill | `.ai/skills/engineering/code_review_before_push.md` | Локальное ревью перед push: текущий diff, архитектурные риски, готовность к публикации |
| engineering | skill | `.ai/skills/engineering/code_review_after_mr.md` | Ревью MR/PR после создания: готовность к merge, контракты, риски, тесты |
| engineering | subagent | `.ai/subagents/reviewer.md` | Второй взгляд на дифф MR/PR: регрессии, нарушение слоёв, тесты |
| engineering | skill | `.ai/skills/engineering/dev-workflow.md` | Стандарт жизненного цикла задачи: DoR, ветки, MR, AI-assisted review, DoD |
| engineering | skill | `.ai/policies/ai-usage-policy.md` | Правила использования AI: инструменты, модели, данные |
| engineering | skill | `.ai/skills/engineering/onboarding.md` | Онбординг разработчика: стек, локальная среда, AI-инструменты, review flow |
| engineering | skill | `.ai/skills/dotnet/dotnet_unit_tests_xunit_moq.md` | Написать или проверить unit-тесты на **xUnit + Moq** |
| engineering | skill | `.ai/skills/engineering/repository_layer_audit.md` | Классы с именем `*Repository*`: доступ к данным против бизнес-логики |
| engineering | skill | `.ai/skills/dotnet/create_solution_dotnet10.md` | Новое backend-решение **.NET 10**, **`.slnx`** / SLNX-каркас, структура `net10.0` |
| engineering | subagent | `.ai/subagents/dotnet/senior_dotnet_developer.md` | Основная точка входа для реализации, рефакторинга и создания .NET backend-сервисов; делегирует builder/clarifier/architect |
| engineering | subagent | `.ai/subagents/dotnet/dotnet_project_clarifier.md` | Внутренний делегат senior-subagent: уточнить тип нового **.NET 10** backend-проекта |
| engineering | subagent | `.ai/subagents/dotnet/architect.md` | Архитектурные решения и ADR review для .NET Clean Architecture и гео-распределения |
| engineering | subagent | `.ai/subagents/dotnet/simple_service_builder.md` | Внутренний делегат senior-subagent: создать простой **.NET 10** сервис, Minimal API или Worker Service |
| engineering | subagent | `.ai/subagents/dotnet/clean_architecture_service_builder.md` | Внутренний делегат senior-subagent: создать сервис **.NET 10** по Clean Architecture |
| engineering | skill | `.ai/skills/dotnet/add_clean_architecture_feature_cqrs.md` | Добавить CQRS-фичу в существующий .NET Clean Architecture сервис |
| engineering | skill | `.ai/skills/dotnet/configure_service_observability.md` | Настроить Serilog, HealthCheck и базовую observability для существующего .NET сервиса |
| engineering | skill | `.ai/skills/dotnet/configure_infrastructure_database.md` | Добавить инфраструктуру БД в Infrastructure для .NET Clean Architecture сервиса |
| engineering | skill | `.ai/skills/dotnet/conventions/geo-distribution.md` | Конвенции гео-распределения: UTC, локализация, RabbitMQ, PostgreSQL, MinIO, compliance |
| product | skill | `.ai/skills/product/prd_mvp_nocode.md` | PRD/MVP, ограничения no-code/vibe |
| product | skill | `.ai/skills/product/jira_sprint_ac.md` | Sprint tasks + Acceptance Criteria + DoD |
| testing | skill | `.ai/skills/testing/webapp_testing.md` | Локальное тестирование webapp через Playwright |
| research | skill | `.ai/skills/research/research_competitors.md` | Исследование конкурентов / обзор инструментов и рынка |
| writing | skill | `.ai/skills/writing/article_habr.md` | Структура и тон статьи для Habr/VC |

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
