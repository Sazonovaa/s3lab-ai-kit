# AI artifact catalog (minimum set)

## Owner
- **Primary owner:** Tech Lead / Team Architect (назначается командой).
- **Backup:** любой maintainer с правом merge в `main`/`develop`.
- Изменения в `.ai/**`, корневом `AGENTS.md` и политиках — через **MR + ревью** (как код).

## Canonical (vendor-neutral, git)
| Path | Role |
|------|------|
| `AGENTS.md` | Обязательный старт агента, ссылка на router |
| `.ai/router.md` | Ровно **один** route на запрос: skill или subagent |
| `.ai/skills/*.md` | Процедуры, контракты и формат результата |
| `.ai/subagents/*.md` | Исполнительные роли и границы автономной работы; могут ссылаться на skill-contract |
| `.ai/catalog.md` | Этот файл: минимальный состав и владение |
| `.ai/policies/security_sdlc.md` | Данные, секреты, DoR/DoD |
| `.ai/policies/ai-usage-policy.md` | Политика использования AI-инструментов, моделей, данных и telemetry |
| `.ai/multi_vendor_tool_matrix.md` | Матрица hooks и vendor-specific конфигов Cursor / Claude Code / Codex |
| `docs/ai/README.md` | Индекс документации AI; полный план — `docs/ai/AI_STANDARDIZATION.md` |
| `docs/ai/CODEX.md` | Опциональная отсылка к корневому `CODEX.md` (альтернатива дублированию) |
| Path | Role |
|------|------|
| `CURSOR.md` | Для Cursor: явно требует следовать корневому `AGENTS.md` + ссылки на `.cursor/*` |
| `CLAUDE.md` | Для Claude Code: явно требует следовать корневому `AGENTS.md` + `.claude/*` |
| `CODEX.md` | Для Codex CLI: явно требует следовать корневому `AGENTS.md` + `.codex/*` |

## Claude Code / Codex (vendor, в репозитории)
| Path | Role |
|------|------|
| `.claude/settings.json` | Конфиг Claude Code; блок `hooks` вызывает `pwsh -NoProfile -File ./scripts/ai/*.ps1` |
| `.codex/config.toml` | Конфиг Codex; `codex_hooks = true` для проектных hooks |
| `.codex/hooks.json` | Хуки Codex: `sessionStart` (sync + log), `PreToolUse` (log) |

## Cursor-specific
| Path | Role |
|------|------|
| `.cursor/rules/*.mdc` | Path-scoped правила C# / Angular |
| `.cursor/hooks.json` | AI usage metadata + sync-submodule на старте сессии |

## Cross-platform скрипты
| Path | Role |
|------|------|
| `scripts/ai/*.ps1` | Единые pwsh-скрипты (Win/macOS/Linux): sync-kit, sync-submodule, log usage, usage report |
| `scripts/ai/ai-kit.default-path` | Путь по умолчанию до AI-kit submodule |
| `scripts/ai/ai-kit.sync-exclude.json` | Top-level имена, исключаемые при синхронизации |

## Minimum skills (must exist in repo)
- `prd_mvp_nocode.md` — product MVP
- `jira_sprint_ac.md` — спринт + AC + DoD
- `code_review_before_push.md` — локальное ревью перед push
- `code_review_after_mr.md` — ревью MR/PR перед merge
- `dev-workflow.md` — жизненный цикл задачи и AI-assisted процесс разработки
- `onboarding.md` — вход нового разработчика в стек и AI workflow
- `dotnet_unit_tests_xunit_moq.md` — модульные тесты .NET
- `dotnet/conventions/geo-distribution.md` — гео-распределение: UTC, RabbitMQ, PostgreSQL, MinIO, compliance
- `repository_layer_audit.md` — аудит `*Repository*`
- `engineering/ambient_dependencies_audit.md` — аудит прямых обращений к ambient API (`DateTime.UtcNow`, `Guid.NewGuid`, `Environment.*`, `File.*`, `Random`, `CultureInfo.Current*`, прямой `HttpClient`) и обязательная замена на port-интерфейс для мокирования в тестах
- `webapp_testing.md` — Playwright / web QA
- `qa/test_plan.md` — формат test plan под фичу/релиз
- `qa/bug_report.md` — формат bug-report
- `angular/feature_implementation_angular.md` — стандарт реализации Angular фичи
- `angular/angular_unit_tests.md` — unit-тесты Angular
- `design/design_system_contract.md` — контракт дизайна и hand-off
- `research_competitors.md` — исследование рынка/инструментов
- `article_habr.md` — статья Habr/VC

## Minimum subagents
- `tech_lead.md` — оркестратор широких / кросс-доменных задач
- `solution_architect.md` — кросс-стек архитектура, контракты, integrations
- `database_architect.md` — схема БД, индексы, миграции, performance
- `business_analyst.md` — постановщик: PRD, AC, DoR
- `ui_designer.md` — UX/UI, состояния, design tokens, a11y AA
- `qa_engineer.md` — test plan, e2e/smoke, bug-reports
- `planner.md` — декомпозиция и риски
- `reviewer.md` — вторая голова по диффу
- `angular/senior_angular_developer.md` — точка входа для Angular реализации
- `dotnet/senior_dotnet_developer.md` — точка входа для .NET реализации; делегирует builder/clarifier/architect
- `dotnet/architect.md` — архитектурные решения внутри .NET сервиса и ADR review

## Vendor-specific path-scoped rules
- `.cursor/rules/angular-ai.mdc` — path-scoped правила Cursor для `*.component.ts` / `*.service.ts` / `app/**/*.html` (Angular standalone, signals, OnPush, a11y).
