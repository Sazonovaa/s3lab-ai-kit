---
name: prd-mvp-nocode
description: PRD / MVP scope with no-code or low-code constraints and clear acceptance criteria.
triggers: [PRD, MVP, scope, roadmap, no-code, product]
---

# Purpose
Сформировать **короткий PRD** или срез MVP с ограничениями «без кастомного кода» / «минимум разработки», пригодный для постановки в бэклог.

# When to use
- Новая инициатива, пилот, «vibe» продукт с жёстким лимитом на разработку.
- Нужно согласовать объём до оценки инженерией.

# Inputs needed
- Целевая аудитория, проблема, метрика успеха.
- Ограничения: срок, бюджет, запрещённые интеграции, compliance.

# Procedure
1) Сформулировать **проблему** и **ценность** в 1–2 абзацах.
2) Выделить **MVP scope** (in / out) явным списком.
3) Описать **user stories** (3–7) с критериями приёмки.
4) Зафиксировать **non-goals** и риски.
5) Дать **DoD** для MVP (без технического дизайна, если не запрошен).

# Output format
1) **Executive summary**
2) **MVP scope** (In / Out)
3) **User stories + AC**
4) **Risks & assumptions**
5) **Open questions** для стейкхолдеров

# Quality bar (self-check)
- [ ] AC проверяемы (given/when/then или эквивалент).
- [ ] Out of scope явно отделён от MVP.
- [ ] Нет скрытых требований к инфраструктуре без метки «assumption».

# Anti-patterns
- ❌ Расписывать реализацию на C#/Angular, если запрошен только продуктовый срез.
- ❌ Включать секреты или персональные данные примеров.
