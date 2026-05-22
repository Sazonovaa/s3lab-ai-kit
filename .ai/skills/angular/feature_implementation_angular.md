---
name: feature-implementation-angular
description: Стандарт реализации Angular фичи — standalone, signals, OnPush, презентационные компоненты, маршрутизация, формы, integration с API.
triggers: [angular, feature, standalone, signals, forms, routing, реализация фичи]
---

# Purpose
Реализовать фичу или экран на Angular единообразно: предсказуемая структура папок, разделение smart / presentational, signals для локального стейта, RxJS только где это уместно.

# When to use
- Новая фича / экран / компонент в Angular приложении.
- Рефакторинг существующего компонента под актуальный стандарт (standalone, signals, OnPush).
- Интеграция нового API endpoint в UI.

# Inputs needed
- AC из постановки (Business Analyst).
- Hand-off дизайнера: состояния, токены, a11y-чеклист.
- Контракт API: endpoint, метод, DTO, error codes.
- Имя фичи / модуля / маршрута.

# Procedure
1. **Структура папок** (feature-based):
   ```text
   src/app/features/<feature-name>/
     pages/                # smart / container компоненты, привязаны к роутам
     components/           # презентационные компоненты
     services/             # фасады поверх data/, бизнес-логика UI
     models/               # типы домена UI (не DTO)
     data/                 # API клиенты, DTO, mappers DTO ↔ Model
     <feature>.routes.ts   # routes для standalone routing
   ```
2. **Компоненты**:
   - `standalone: true`, `changeDetection: ChangeDetectionStrategy.OnPush`.
   - Smart компоненты: вызывают сервисы, пробрасывают данные в презентационные.
   - Презентационные: только `input()` / `output()` (signal-based) или `@Input`/`@Output`; без HTTP и без state-store.
3. **State**:
   - Локальный стейт компонента — через `signal()` / `computed()`.
   - Async-источники — через `toSignal(observable$)` или `async pipe`.
   - Глобальный стейт — через сервис с `signal()` (или существующий store, если есть в проекте).
4. **Forms**:
   - Reactive forms по умолчанию (`FormGroup` / `FormControl` типизированные).
   - Валидаторы выносить в отдельные файлы при переиспользовании.
5. **API**:
   - `HttpClient` только в `data/` слое.
   - DTO ↔ Model маппинг через функции `toModel(dto)` / `toDto(model)` в отдельных файлах.
6. **Routing**:
   - Standalone routes: `provideRouter`, `loadChildren: () => import(...)` для feature-level lazy loading.
   - Guards и resolvers — в отдельных файлах в `pages/` или корне фичи.
7. **i18n**:
   - Все user-facing строки — через i18n механизм проекта (`$localize` / transloco / ngx-translate — что используется в репозитории).
   - Без хардкода строк в шаблонах.
8. **Tests** (если запрошены):
   - Следовать `.ai/skills/angular/angular_unit_tests.md`.

# Output format
1) **Plan** — структура папок и список файлов.
2) **Deliverable** — реализация (код по файлам).
3) **Self-check** (см. ниже).

# Quality bar (self-check)
- [ ] `standalone: true` + `ChangeDetectionStrategy.OnPush`.
- [ ] Презентационные компоненты не делают HTTP и не знают о store.
- [ ] Local state через signals / computed; async через `toSignal` или `async pipe`.
- [ ] Reactive forms типизированы.
- [ ] DTO ↔ Model mappers в отдельных файлах.
- [ ] Один объект — один файл (компонент, сервис, тип, mapper).
- [ ] Все imports на верху, без inline imports.
- [ ] Exhaustive switch для unions / enums.
- [ ] A11y: семантика, focus, ARIA там, где нужно.
- [ ] Дизайн через design tokens; нет хардкода.
- [ ] Нет PII / secrets в коде и фикстурах.

# Anti-patterns
- ❌ HTTP-вызов в презентационном компоненте.
- ❌ Логика в шаблоне через сложные выражения; выносить в pipe / signal / getter.
- ❌ `any` без обоснования.
- ❌ `subscribe` без `takeUntilDestroyed` / `async pipe`.
- ❌ Глобальный mutable state без явного владельца.
- ❌ Хардкод строк, цветов, spacing.
- ❌ Добавлять NgRx / Akita / прочие state-фреймворки без ADR.
