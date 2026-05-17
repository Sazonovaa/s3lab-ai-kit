---
name: angular-unit-tests
description: Unit-тесты Angular — TestBed, spectator-style паттерны, моки сервисов, тестирование signals и async, без сетевых вызовов.
triggers: [angular tests, unit test angular, TestBed, jasmine, jest, spectator]
---

# Purpose
Написать или проверить unit-тесты Angular для компонентов, сервисов, pipes, директив и guards — без реальных HTTP-вызовов и реального state-store.

# When to use
- Добавление новой фичи / компонента / сервиса с покрытием тестами.
- Рефакторинг существующего кода с сохранением поведения.
- Разбор flaky / падающих тестов Angular.

# Inputs needed
- Test runner репозитория (Karma+Jasmine или Jest или Vitest — определить по `package.json` / `angular.json`).
- AC и публичный контракт тестируемого юнита.
- Список зависимостей, которые нужно замокать.

# Procedure
1. **Определить runner**: прочитать `package.json` / `angular.json` и взять существующий runner проекта. Не вводить новый runner без согласования.
2. **TestBed setup**:
   - Standalone компонент — импортировать сам компонент, не объявлять в `declarations`.
   - Моки сервисов — через `providers: [{ provide: X, useValue: mock }]`.
   - `HttpClient` — через `provideHttpClientTesting()` и `HttpTestingController`.
3. **Структура теста**:
   - `describe('FooComponent', () => { ... })`.
   - `it('should ... when ...')` — поведенческие названия.
   - Arrange / Act / Assert визуально разделять пустыми строками.
4. **Signals**:
   - Читать значения через `.set()` / `.update()` в Arrange, ассертить через `signal()` или `computed()` get.
   - Для эффектов — оборачивать в `TestBed.runInInjectionContext(...)` или фикстуру компонента.
5. **Async**:
   - `fakeAsync` + `tick()` для контроля времени.
   - `flushMicrotasks()` для промисов / signal-эффектов.
   - Для `toSignal(observable$)` — прогонять источник через `cold/hot` или `Subject` под контролем теста.
6. **HTTP**:
   - Никаких реальных вызовов; только `HttpTestingController.expectOne(...)`.
   - Проверять URL, метод, заголовки, тело.
7. **DOM**:
   - Селекторы — `data-testid` атрибуты или роли (`getByRole`).
   - Не зависеть от структурного XPath / индексов.
8. **Coverage**:
   - Покрытие поведения, не строк. Минимум — happy path + 1-2 граничных кейса + ошибки.

# Output format
1) **Plan** — список тестируемых юнитов и кейсов.
2) **Deliverable** — код тестов по файлам (`*.spec.ts`).
3) **Self-check** (см. ниже).

# Quality bar (self-check)
- [ ] Использован существующий runner проекта.
- [ ] Standalone компоненты импортируются напрямую.
- [ ] Нет реальных HTTP / сетевых вызовов.
- [ ] Сервисы замоканы через `useValue` / `jest.fn()` / `jasmine.createSpyObj`.
- [ ] Signals и async тестируются предсказуемо.
- [ ] DOM-локаторы по `data-testid` / ролям.
- [ ] Тестируется поведение по AC, а не реализация.
- [ ] Нет утечек таймеров и подписок между тестами.
- [ ] Нет секретов / PII в фикстурах.

# Anti-patterns
- ❌ Реальные HTTP-вызовы в тестах.
- ❌ Зависимость от глобального DOM-состояния между тестами.
- ❌ `setTimeout` в тестах вместо `fakeAsync` / `tick`.
- ❌ Тестирование внутренней структуры (private поля) вместо публичного поведения.
- ❌ Селекторы по индексу / XPath без причины.
- ❌ Введение нового test runner без согласования.
