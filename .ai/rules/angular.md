---
name: angular
description: Path-scoped правила Cursor для Angular кода — standalone, signals, OnPush, разделение слоёв.
globs:
  - "**/*.component.ts"
  - "**/*.service.ts"
  - "**/*.directive.ts"
  - "**/*.pipe.ts"
  - "**/*.guard.ts"
  - "**/*.resolver.ts"
  - "**/*.routes.ts"
  - "**/app/**/*.ts"
  - "**/app/**/*.html"
always_apply: false
---

# Angular path-scoped правила

## Контракт компонента
- `standalone: true` по умолчанию.
- `changeDetection: ChangeDetectionStrategy.OnPush` всегда.
- Локальный стейт — через `signal()` / `computed()`; async-источники — через `toSignal()` или `async pipe`.
- Презентационные компоненты не делают HTTP и не зависят от store.

## Структура файлов
- В одном файле — один объект (компонент, сервис, тип, mapper) — см. user rule репозитория.
- DTO ↔ Model маппинг в отдельных файлах в `data/`.
- Routes для standalone routing — в `<feature>.routes.ts`.

## Imports
- Все `import` — в начале файла. Никаких inline imports.

## TypeScript
- Exhaustive switch для unions / enums (см. правило `typescript-exhaustive-switch`).
- `any` запрещён без явного обоснования в комментарии.

## Templates / HTML
- Семантические теги (`button`, `a`, `nav`, `main`, `section`) — приоритет перед `div` + ARIA.
- Логика не в шаблоне — выносить в pipe / signal / getter.
- Все user-facing строки — через i18n механизм проекта.

## Формы
- Reactive forms типизированы (`FormGroup<...>` / `FormControl<T>`).
- Валидаторы переиспользуемые — выносить в отдельные файлы.

## API
- `HttpClient` только в `data/` слое.
- Ошибки маппятся в доменные типы; никакого `any` для `HttpErrorResponse`.

## Tests
- См. `.ai/skills/angular/angular_unit_tests.md`.
- Селекторы по `data-testid` / ролям, без XPath.

## Required reads для агента при правках
- `.ai/skills/angular/feature_implementation_angular.md`
- `.ai/skills/angular/angular_unit_tests.md` (при правке `*.spec.ts`)
- `.ai/skills/design/design_system_contract.md` (при работе с UI / стилями)

## Forbidden
- Использование `NgModule` без явного ограничения проекта.
- HTTP-вызовы в шаблонах и презентационных компонентах.
- `subscribe` без `takeUntilDestroyed` / `async pipe`.
- Хардкод цветов, spacing, типографики — только через design tokens.
