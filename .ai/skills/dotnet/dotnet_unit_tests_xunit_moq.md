---
name: dotnet-unit-tests-xunit-moq
description: Author or review unit tests with xUnit + Moq — Theory data, repository mocks, no real DB in unit tests.
triggers: [xUnit, Moq, unit test, Theory, InlineData, MemberData, mock, repository test]
---

# Purpose
Стандартизировать **модульные тесты** в этом репозитории: **xUnit** + **Moq**, параметризация, моки границ данных, **без** реальной БД в unit-слое.

# When to use
- Написание или ревью тестов в `src/Tiss.Chatbot.Test` (или другом `*.Test` проекте решения).
- Вопросы про `[Fact]` vs `[Theory]`, данные границ, мок `IRepository` / `DbContext` factory.

# Inputs needed
- Класс/метод под тест, контракт (входы/выходы/ошибки).
- Существующие интерфейсы для моков.

# Procedure
1) Определить **классы эквивалентности** входов (null, пустая строка, типичный, граница, невалидный формат).
2) Выбрать **`[Theory]`** + `[InlineData]` / `[MemberData]` когда вариантов несколько; в `[Fact]` — один сценарий с ясным именем метода.
3) **Изолировать** доступ к данным: `Mock<I...Repository>()`, фейковые `DbContext` только если уже принято в проекте — иначе моки unit-of-work; **не** поднимать Testcontainers без явного запроса на интеграционные тесты.
4) Проверить **именование**: `MethodName_Scenario_ExpectedBehavior` или эквивалент команды.
5) Для репозиториев: если видите бизнес-ветвление — отослать к skill `.ai/skills/engineering/repository_layer_audit.md`.

# Output format
1) **Test matrix** (вход → ожидание)
2) **Suggested test code** (или diff-идея), только xUnit+Moq
3) **Gaps** — что ещё покрыть
4) **Рефакторинг** (если тест невозможен без распутывания BL из репозитория) — кратко куда вынести логику

# Quality bar (self-check)
- [ ] Нет `NUnit` (`[Test]`, `Assert.That` из NUnit).
- [ ] Нет скрытого сетевого/DB I/O в «юнит» сценарии.
- [ ] Каждый `[Theory]` строка данных понятна с имени/`DisplayName` при необходимости.

# Anti-patterns
- ❌ `[Fact]` с копипастой одного теста на 10 наборов данных вместо `MemberData`.
- ❌ Реальный SQL / docker в unit-тестах без отдельного типа задачи.
