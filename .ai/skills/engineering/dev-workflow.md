---
name: dev-workflow
description: Стандарт жизненного цикла разработки: DoR, ветки, MR, AI-assisted review, QA и Definition of Done.
triggers:
  - dev workflow
  - процесс разработки
  - жизненный цикл задачи
  - definition of ready
  - definition of done
  - правила MR
---

# Назначение
Задекларировать единый процесс разработки для задач TISS.AI.KIT, чтобы разработчик и агент проходили одинаковые этапы от входа задачи до Done.

# Когда использовать
- Нужно проверить готовность задачи к старту.
- Нужно подготовить MR/PR к review.
- Нужно понять, какой AI skill или subagent применять на этапе задачи.
- Нужно сверить DoR/DoD перед передачей в QA или merge.

# Жизненный цикл
1. Backlog: задача описана, но ещё не готова к разработке.
2. DoR check: проверены контекст, acceptance criteria, данные, зависимости и риски.
3. In Progress: реализация ведётся в отдельной ветке.
4. Pre-push review: локальный diff проверен через `code_review_before_push.md`.
5. MR/PR: создано описание, приложены проверки, логи или скриншоты при необходимости.
6. Code Review: MR/PR проверен вручную и через `code_review_after_mr.md`.
7. QA: проверены acceptance criteria и критичные сценарии.
8. Done: изменения смержены, документация обновлена, known risks зафиксированы.

# Definition of Ready
- Есть цель задачи и ожидаемое поведение.
- Есть acceptance criteria или понятный критерий завершения.
- Известны затронутые сервисы, API contracts, persistence и внешние интеграции.
- Указаны ограничения: migration policy, feature flags, запрет unrelated refactoring.
- Для geo-sensitive задач указан регион, data residency и timezone/localization контекст.

# Branch naming
- `feature/TICKET-123-short-desc` — новая функциональность.
- `fix/TICKET-456-what-fixed` — исправление дефекта.
- `hotfix/TICKET-789-critical-fix` — срочное production-исправление.
- `chore/TICKET-321-maintenance` — техобслуживание без продуктового поведения.

# MR requirements
- Описание цели и пользовательского эффекта.
- Ссылка на тикет или ADR.
- Список ключевых изменений.
- Команды проверок и результат.
- Скриншот, лог или пример ответа API, если изменение затрагивает UI/API/infra.
- Отдельно указать migrations, feature flags, breaking changes и geo-impact.

# AI in workflow
- Планирование сложной задачи: `.ai/subagents/planner.md`.
- Создание или изменение skill: `.ai/skills/engineering/create_skill.md`.
- Локальное ревью перед push: `.ai/skills/engineering/code_review_before_push.md`.
- MR/PR ревью перед merge: `.ai/skills/engineering/code_review_after_mr.md`.
- Аудит ambient-зависимостей (`DateTime.UtcNow`, `Guid.NewGuid`, `Environment.*`, `File.*`, `Random`, `CultureInfo.Current*`, прямой `HttpClient`) с обязательной заменой на port-интерфейс: `.ai/skills/engineering/ambient_dependencies_audit.md`.
- Аудит классов `*Repository*` против бизнес-логики: `.ai/skills/engineering/repository_layer_audit.md`.
- Второй взгляд на сложный diff: `.ai/subagents/reviewer.md`.
- Архитектурные trade-offs и ADR: `.ai/subagents/dotnet/architect.md`.

# Geo checks
- Все persisted timestamps хранятся в UTC.
- Regional URLs, bucket names, routing keys и connection strings задаются через config/env.
- Cross-region вызовы имеют timeout, retry и circuit breaker, согласованные с latency.
- PII и customer data не перемещаются между регионами без явного compliance-решения.

# Definition of Done
- Acceptance criteria выполнены.
- Сборка и обязательные проверки зелёные.
- `code_review_after_mr.md` не содержит блокеров.
- QA подтвердил критичные сценарии или явно зафиксировал исключение.
- Документация, политики или `.ai/**` обновлены, если поведение процесса изменилось.

# Формат вывода
1) **Статус задачи:** `ready` | `not_ready` | `ready_with_risks`
2) **Недостающие элементы DoR/DoD**
3) **AI шаги:** какие skills/subagents применить
4) **Проверки:** команды, QA или review steps
5) **Риски:** migration, API, geo, security

# Планка качества
- [ ] Ответ привязан к конкретной задаче, MR или diff.
- [ ] Не добавлены лишние этапы сверх процесса.
- [ ] Geo-impact проверен, если затронуты данные, интеграции или регионы.
- [ ] AI checks указаны конкретными файлами из `.ai/**`.
