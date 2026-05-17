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
| `.claude/settings.json` | Конфиг Claude Code; блок `hooks` — по [доке](https://code.claude.com/docs/en/hooks) (сейчас пустой `{}`) |
| `.codex/config.toml` | Конфиг Codex; `codex_hooks = true` для проектных hooks |
| `.codex/hooks.json` | Хуки Codex: startup sync и AI usage metadata |

## Cursor-specific
| Path | Role |
|------|------|
| `.cursor/AGENTS.md` | Доп. правила workspace (тесты xUnit+Moq) |
| `.cursor/rules/*.mdc` | Path-scoped правила C# / тестов / (при появлении) Angular |
| `.cursor/hooks.json` | Пилот: AI usage metadata, shell guard + CRLF validate перед commit |
| `.cursor/hooks/*.cmd` | Cursor hook wrappers для Windows shell |
| `scripts/ai/*.cmd` / `scripts/ai/*.ps1` | Общие AI scripts: sync, usage logging, usage report |

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
- `webapp_testing.md` — Playwright / web QA
- `research_competitors.md` — исследование рынка/инструментов
- `article_habr.md` — статья Habr/VC

## Minimum subagents
- `planner.md` — декомпозиция и риски
- `reviewer.md` — вторая голова по диффу
- `dotnet/senior_dotnet_developer.md` — основная точка входа для .NET реализации и делегирования builder/clarifier/architect
- `dotnet/architect.md` — архитектурные решения и ADR review под Clean Architecture и geo
- `dotnet/clean_architecture_service_builder.md` — создание .NET 10 сервиса по Clean Architecture через skill-contract

## Angular (когда появится код в репозитории)
- Добавить `.cursor/rules/angular-ai.mdc` с glob на `*.ts` / `*.html` приложения и skill `feature_implementation_angular.md` по шаблону существующих skills.
