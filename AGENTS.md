## Mandatory startup
Before starting any task:
1) Напиши имя модели, которая занимается задачей и переведи строку на новую
2) Read `.ai/router.md`
3) Follow it to select exactly one route: skill from `.ai/skills/` or subagent from `.ai/subagents/`
4) Follow the selected route's Output format and Quality bar  
5) Optional: artifact catalog and policies — [`.ai/catalog.md`](.ai/catalog.md), [`.ai/policies/security_sdlc.md`](.ai/policies/security_sdlc.md); полный план переноса: [`docs/ai/AI_STANDARDIZATION.md`](docs/ai/AI_STANDARDIZATION.md)

## Mandatory answer header
Каждый ответ должен начинаться с двух (или трёх) строк **до** любого другого текста:

```text
Model: <model-slug>
Route: <относительный путь к skill или subagent, например .ai/subagents/tech_lead.md>
Delegated: <через запятую пути делегированных subagents>   # только если route = оркестратор и были делегирования
```

Правила:
- Если ни один route из `.ai/router.md` не подошёл — `Route: none (base AGENTS.md rules)`.
- Если задействован `tech_lead` — обязательна строка `Delegated:` со списком фактически делегированных subagents.
- Header не дублирует Plan / Deliverable; это только декларация выбора route.
- Header пишется на каждый ответ в рамках сессии, не только на первый.
