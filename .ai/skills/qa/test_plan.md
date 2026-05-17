---
name: qa-test-plan
description: Формат test plan под фичу — scope, критический путь, сценарии happy/edge/negative, критерии «зелёного» прогона.
triggers: [test plan, тест план, regression checklist, smoke план]
---

# Purpose
Сформировать **test plan** под фичу или релиз: что тестируем, в каком объёме, по каким критериям считаем «зелёным».

# When to use
- Новая фича перед слиянием в `develop` / `main`.
- Релиз: regression чеклист перед deploy.
- Bug-fix: проверка отсутствия регрессии.

# Inputs needed
- AC из постановки (Business Analyst) или ссылка на тикет.
- Среда тестирования и роли пользователя.
- Тестовые данные (синтетика).
- Приоритет: блокеры релиза vs. полная регрессия.

# Procedure
1. **Scope** — что в плане и что вне (in / out).
2. **Risk areas** — что чувствительно (auth, payments, persistence, integrations) — приоритет тестам.
3. **Test types** — какие пирамида тестов задействована (unit / integration / e2e / manual smoke).
4. **Critical path** — основной сценарий пользователя по шагам.
5. **Cases** — таблица:
   - `id`, `type` (happy / edge / negative), `precondition`, `steps`, `expected`, `priority`.
6. **Data fixtures** — анонимизированные тестовые данные.
7. **Exit criteria** — критерии «зелёного» прогона:
   - Все P0 и P1 кейсы — pass.
   - Известные P2 баги — задокументированы и согласованы.
   - Прогон стабилен (нет flaky без объяснения).
8. **Out of scope** — что явно не проверяем.

# Output format
1) **Scope** (in / out)
2) **Risk areas**
3) **Test types**
4) **Critical path**
5) **Cases** (таблица)
6) **Data fixtures**
7) **Exit criteria**
8) **Out of scope**

# Quality bar (self-check)
- [ ] Каждый case проверяем (есть steps + expected).
- [ ] Покрыты happy / edge / negative.
- [ ] Покрыты roles / permissions, если фича их затрагивает.
- [ ] Учтены i18n / темы / target устройства, если в scope.
- [ ] Учтены a11y-проверки (keyboard, focus, screen reader basics), если затронут UI.
- [ ] Тестовые данные — синтетика, без PII.
- [ ] Exit criteria измеримы.

# Anti-patterns
- ❌ Кейсы вида «работает корректно» без шагов и expected.
- ❌ Реальные PII / production данные в фикстурах.
- ❌ План без приоритезации и exit criteria.
- ❌ Полная регрессия там, где достаточно smoke (и наоборот).
