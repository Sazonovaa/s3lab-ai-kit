---
name: design-system-contract
description: Контракт design system — design tokens, состояния компонентов, a11y AA, hand-off для Angular.
triggers: [design tokens, design system, состояния компонента, accessibility, WCAG, hand-off]
---

# Purpose
Зафиксировать **контракт дизайна** между дизайнером и Angular-разработчиком: какие токены, какие состояния, какие a11y-требования, как оформить hand-off.

# When to use
- Новый экран / компонент с состояниями.
- Изменение существующего компонента и его состояний.
- Согласование a11y-требований и design tokens до реализации.

# Inputs needed
- Сценарий пользователя или AC из постановки.
- Текущая design system (если есть) или ссылка на токены.
- Бренд-ограничения, темы (light / dark), локали, целевые устройства.

# Procedure
1. **Design tokens** — описать в форме `name: value` по категориям:
   - `color.*` (semantic: `surface`, `on-surface`, `primary`, `on-primary`, `error`, `success`, `warning`, `info`).
   - `typography.*` (font family, weight, size, line-height по ролям: `display`, `title`, `body`, `caption`).
   - `spacing.*` (scale: `0`, `1`, `2`, ...).
   - `radius.*`, `shadow.*`, `motion.*` (duration, easing).
   - Использовать существующие токены проекта; новые токены явно помечать как **new**.
2. **Состояния компонента** — таблица:
   - `default`, `hover`, `focus`, `active`, `disabled`, `loading`, `empty`, `error`, `success`.
   - Для каждого: визуальные правила (какие токены применяются), текст / placeholder, поведение.
3. **A11y чеклист (WCAG 2.1 AA)**:
   - Контраст текста ≥ 4.5:1 (≥ 3:1 для крупного текста и иконок-как-смысл).
   - Видимый focus state, не убирать `outline` без замены.
   - Keyboard order совпадает с visual order.
   - Все интерактивные элементы доступны клавиатурой.
   - Поля формы имеют `label` (видимый или ARIA).
   - Ошибки связаны с полем через `aria-describedby`, `aria-invalid`.
   - Live regions (`aria-live`) для асинхронных сообщений.
   - Альт-текст / `aria-label` для иконок-как-смысл; декоративные иконки `aria-hidden`.
4. **Hand-off для Angular** — что важно разработчику:
   - Структура шаблона (smart vs presentational).
   - Inputs / outputs (signal-based) и события.
   - Async-состояния (loading / error / empty) и их источники.
   - Используемые / новые токены.
   - i18n-ключи user-facing строк.
   - Edge cases (длинные тексты, отсутствие данных, ошибки сети).

# Output format
1) **Design tokens** — таблица `name: value`, помечать новые токены `(new)`.
2) **Component states** — таблица состояний.
3) **A11y checklist** — отмеченные пункты под фичу.
4) **Hand-off notes** — структура и контракт для разработчика.

# Quality bar (self-check)
- [ ] Все состояния компонента описаны (default / hover / focus / active / disabled / loading / empty / error / success — где применимо).
- [ ] Используются semantic tokens, а не hex / px напрямую.
- [ ] Новые токены явно помечены.
- [ ] Контраст и focus state соответствуют WCAG 2.1 AA.
- [ ] Keyboard и screen reader сценарии описаны.
- [ ] Hand-off содержит inputs / outputs / async states.
- [ ] Нет PII / реальных адресов / номеров карт в примерах.

# Anti-patterns
- ❌ Хардкод цветов / spacing / типографики без токенов.
- ❌ A11y "потом".
- ❌ Описание визуала без поведения и состояний.
- ❌ Финальный пиксельный макет без контракта для разработчика.
- ❌ Реальные PII в макетах.
