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

# Подключение submodule `tiss.ai.kit.standart`
- В родительском проекте подключить submodule командой:
  ```powershell
  git submodule add http://git-web.tiss.ru/tiss-ai-kit/tiss.ai.kit.standart.git tiss.ai.kit.standart
  ```
- Инициализировать и подтянуть содержимое submodule:
  ```powershell
  git submodule update --init --recursive
  ```
- После клонирования родительского проекта с уже подключённым submodule выполнить:
  ```powershell
  git submodule update --init --recursive
  ```
- Проверить результат:
  ```powershell
  git status
  git submodule status
  ```
- В MR родительского проекта должны попасть `.gitmodules` и запись submodule. Не коммитить содержимое `tiss.ai.kit.standart` как обычную папку.

# AI workflow
- Сложное планирование: `.ai/subagents/planner.md`.
- .NET реализация, рефакторинг и создание сервисов: `.ai/subagents/dotnet/senior_dotnet_developer.md`.
- Создание .NET сервисов: senior-subagent делегирует в `clean_architecture_service_builder.md`, `simple_service_builder.md` или `dotnet_project_clarifier.md`.
- Локальное ревью: `.ai/skills/engineering/code_review_before_push.md`.
- MR/PR ревью: `.ai/skills/engineering/code_review_after_mr.md`.
- Второй взгляд: `.ai/subagents/reviewer.md`.
- Архитектурные решения: `.ai/subagents/dotnet/architect.md`.

# Review flow
- Перед push проверить текущий diff через `code_review_before_push.md`.
- Перед merge проверить MR/PR через `code_review_after_mr.md`.
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
