---
name: code-review-after-mr
description: Code review после создания MR / PR: проверка готовности к merge, контрактов, тестов, архитектуры и production-рисков.
triggers:
  - code review after MR
  - MR review
  - PR review
  - merge request review
  - pull request review
  - review PR
  - review MR
  - после MR
  - после PR
  - ревью MR
  - ревью PR
  - ревью pull request
  - ревью merge request
  - проверь MR
  - проверь PR
  - проверь pull request
  - проверь merge request
  - проверка перед merge
  - готово к merge
---

# Назначение
Проверить MR / PR как готовое изменение перед merge по общему стандарту [`docs/review/CODE_REVIEW.md`](../../../docs/review/CODE_REVIEW.md).

# Когда использовать
- Пользователь просит ревью MR / PR.
- Есть ссылка на MR / PR или полный diff ветки.
- Перед merge в `develop` / release branch.

# Входные данные
- Ссылка на MR / PR или перечень изменённых файлов.
- Краткий контекст задачи.
- Известные ограничения: feature flag, migration policy, запрет unrelated refactoring.

# Процедура
1) Прочитать общий стандарт [`docs/review/CODE_REVIEW.md`](../../../docs/review/CODE_REVIEW.md).
2) Если MR затрагивает регионы, время, локализацию, RabbitMQ, PostgreSQL или MinIO — прочитать [`geo-distribution.md`](../dotnet/conventions/geo-distribution.md).
3) Определить границу MR: API, persistence, auth, messaging, UI/API contracts.
4) Проверить обратную совместимость, миграции, security/auth и production-риски.
5) Проверить слои Clean Architecture и отсутствие бизнес-логики в репозиториях к БД.
6) Оценить тесты, моки границ, покрытие изменённого поведения и отсутствие зависимости unit-тестов от реальной БД.
7) Разделить замечания на блокеры и nits.

# Формат вывода
1) **Вердикт:** `approve` | `approve_with_nits` | `request_changes`
2) **Блокеры** (до 5): файл/символ — проблема — как проверить исправление
3) **Nits**
4) **Тесты:** что добавить или прогнать
5) **Вопросы автору** (если контракт неясен)

# Планка качества (self-check)
- [ ] Каждый блокер воспроизводим или ссылается на конкретный риск.
- [ ] Нет «воды» без привязки к diff / файлам.
- [ ] Упомянуты тесты, слои и контракты, если они затронуты.
- [ ] Проверена бизнес-логика в репозиториях к БД, если затронут persistence.

# Антипаттерны
- ❌ Переписывать код в ответе вместо списка замечаний, если не просили правки.
- ❌ Требовать unrelated refactoring.
- ❌ Требовать NUnit — в репозитории **xUnit + Moq**.
