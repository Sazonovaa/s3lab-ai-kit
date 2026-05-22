---
name: qa-bug-report
description: Формат bug-report — title, environment, steps, expected, actual, severity, артефакты, без утечки PII.
triggers: [bug report, баг-репорт, дефект, найден баг]
---

# Purpose
Оформить **bug-report**, по которому разработчик сразу воспроизводит и чинит проблему, без долгих уточнений.

# When to use
- Найден баг в среде разработки / staging / prod.
- Регрессия после изменения.
- Падение Playwright-сценария с понятной причиной.

# Inputs needed
- Среда: URL, ветка / сборка, роль пользователя, время.
- Шаги воспроизведения.
- Ожидаемое vs. фактическое поведение.
- Артефакты: trace, screenshot, HAR (если политика позволяет), логи.

# Procedure
1. **Title** — короткое описание сути: `[scope] symptom under condition`.
2. **Environment** — URL, ветка / сборка, browser / OS, роль, регион / локаль, время.
3. **Preconditions** — что должно быть выполнено до шагов.
4. **Steps to reproduce** — пронумерованные атомарные шаги.
5. **Expected result** — что должно произойти.
6. **Actual result** — что произошло.
7. **Severity / Priority**:
   - `S1` — блокер релиза, потеря данных, security.
   - `S2` — critical path сломан, нет workaround.
   - `S3` — есть workaround.
   - `S4` — cosmetic / minor.
8. **Frequency** — `always` / `sometimes` (X/Y) / `once`.
9. **Artifacts** — ссылки на trace, screenshot, лог, видео; маскировать PII.
10. **Suspect area** — гипотеза о причине (если есть), без обвинений.

# Output format
```text
**Title:** ...
**Environment:** URL=..., build=..., browser=..., role=..., locale=..., time=...
**Preconditions:** ...
**Steps:**
1. ...
2. ...
**Expected:** ...
**Actual:** ...
**Severity / Priority:** S2 / P1
**Frequency:** always
**Artifacts:** [trace](...), [screenshot](...)
**Suspect area:** компонент X, последний релиз затронул Y
```

# Quality bar (self-check)
- [ ] Шаги атомарны и воспроизводимы.
- [ ] Expected / Actual различаются явно.
- [ ] Severity обоснован.
- [ ] Артефакты не содержат секретов / токенов / PII (всё маскировано).
- [ ] URL без prod credentials / tokens в query string.
- [ ] Нет токсичных формулировок и обвинений.

# Anti-patterns
- ❌ "не работает" без шагов и ожидаемого результата.
- ❌ Скриншот без шагов.
- ❌ Утечка cookies / tokens / PII в trace или HAR.
- ❌ Обвинительный тон — только факты.
- ❌ Объединять несколько разных багов в один report.
