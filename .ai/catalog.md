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
| `.ai/schema.md` | Спецификация frontmatter источника и правил валидации компилятора |
| `.ai/skills/*.md` | Процедуры, контракты и формат результата |
| `.ai/subagents/*.md` | Исполнительные роли и границы автономной работы; могут ссылаться на skill-contract |
| `.ai/rules/*.md` | Path-scoped правила (источник `.cursor/rules/*.mdc`); frontmatter с `globs` |
| `.ai/catalog.md` | Этот файл: минимальный состав и владение |
| `.ai/policies/security_sdlc.md` | Данные, секреты, DoR/DoD |
| `.ai/policies/ai-usage-policy.md` | Политика использования AI-инструментов, моделей, данных и telemetry |
| `.ai/multi_vendor_tool_matrix.md` | Матрица hooks и vendor-specific конфигов Cursor / Claude Code / Codex |
| `.ai/mcp/servers.md` | Реестр одобренных MCP-серверов; источник правды для vendor-конфигов |
| `.ai/mcp/conventions.md` | Конвенции MCP: transport, секреты, синхронизация vendor-конфигов |
| `docs/ai/README.md` | Индекс документации AI; полный план — `docs/ai/AI_STANDARDIZATION.md` |
| `docs/ai/CODEX.md` | Опциональная отсылка к корневому `CODEX.md` (альтернатива дублированию) |
| Path | Role |
|------|------|
| `CURSOR.md` | Для Cursor: требует следовать `AGENTS.md` рядом с этим файлом + ссылки на `.cursor/*` |
| `CLAUDE.md` | Для Claude Code: требует следовать `AGENTS.md` рядом с этим файлом + `.claude/*` |
| `CODEX.md` | Для Codex CLI: требует следовать `AGENTS.md` рядом с этим файлом + `.codex/*` |

## Claude Code / Codex (vendor, в репозитории)
| Path | Role |
|------|------|
| `.claude/settings.json` | Конфиг Claude Code; блоки `hooks` и `mcpServers` |
| `.codex/config.toml` | Конфиг Codex; `codex_hooks = true` + блоки `[mcp_servers.<id>]` |
| `.codex/hooks.json` | Хуки Codex: `sessionStart` (sync + log), `PreToolUse` (log) |

## Cursor-specific
| Path | Role |
|------|------|
| `.cursor/hooks.json` | AI usage metadata + sync-submodule на старте сессии |
| `.cursor/mcp.json` | Vendor-конфиг MCP-серверов для Cursor (производный от `.ai/mcp/servers.md`) |

## Windows scripts
| Path | Role |
|------|------|
| `scripts/ai/sync-ai-kit.cmd`, `ai-usage-report.cmd` | Windows cmd-скрипты: синхронизация kit, отчёт по usage |
| `scripts/ai/sync-submodule-on-start.mjs`, `log-ai-usage.mjs`, `secret-guard.mjs`, `scripts/hooks/crlf-commit-guard.mjs` | Кросс-платформенные Node-хуки сессии (вызываются из vendor-конфигов) |
| `scripts/ai/ai-kit.default-path` | Путь по умолчанию до AI-kit submodule |
| `scripts/ai/ai-kit.sync-exclude.json` | Top-level имена, исключаемые при синхронизации |

## Компилятор единого описания
| Path | Role |
|------|------|
| `scripts/ai/build-ai-kit.mjs` | Кросс-платформенный компилятор: из frontmatter `.ai/skills` и `.ai/subagents` генерирует нативные артефакты вендоров. `--out <dir>` — корень проекта-потребителя; `--check` — CI/pre-commit drift-гейт |

Источник правды — frontmatter каждого `.ai/skills|subagents/**.md` (`name`,
`description`, `triggers`, опционально `tools`/`model`). Команда сборки:
`node scripts/ai/build-ai-kit.mjs`. `sync-ai-kit.cmd` вызывает её с `--out`
корнем потребителя, поэтому нативные папки появляются в проекте, а не в submodule.

При `--out` (проект-потребитель) компилятор дополнительно проецирует vendor-конфиги
хуков (`.claude/settings.json`, `.cursor/hooks.json`, `.codex/hooks.json`,
`.codex/config.toml`) из собственных конфигов kit, переписывая пути скриптов под
submodule. Создаются **только если отсутствуют** — кастомные конфиги не затираются.

### Generated (DO NOT EDIT — собирается компилятором)
| Path | Role |
|------|------|
| `.claude/agents/<name>.md` | Сабагенты Claude Code (нативное обнаружение, Task) — из `.ai/subagents/**` |
| `.claude/skills/<name>/SKILL.md` | Skills Claude Code (нативный `/`) — из `.ai/skills/**` |
| `.cursor/skills/<name>/SKILL.md` | Agent Skills Cursor — из `.ai/skills/**` и `.ai/subagents/**` |
| `.cursor/rules/<name>.mdc` | Path-scoped правила Cursor — из `.ai/rules/**` (по полю `globs`) |
| `.ai/routes.generated.md` | Vendor-neutral индекс маршрутов; для Codex и людей |
| `AGENTS.md` (блок `AIKIT:INDEX`) | Индекс маршрутов для Codex — инъекция между маркерами |
| `.ai/router.md` (блок `AIKIT:ROUTES`) | Таблица маршрутов — инъекция между маркерами; остальной router рукописный |

## Гейты качества (CRLF + drift)
| Path | Role |
|------|------|
| `scripts/validations/validate-crlf.cmd` / `.sh` | Проверка CRLF staged-файлов (исключение для `eol=lf`, напр. `*.sh`); Windows и POSIX |
| `scripts/hooks/install-git-hooks.cmd` / `.sh` | Установка кросс-платформенного pre-commit: CRLF-валидация + `build-ai-kit.mjs --check` |
| `.gitlab-ci.yml` | CI-джоба `ai-kit-drift-check`: `node build-ai-kit.mjs --check` на MR и ветках `develop`/`main` |

## Minimum skills и subagents (must exist in repo)

Полный список routes — таблица в [`.ai/router.md`](router.md). Каждый skill и
subagent из этой таблицы является **canonical artifact** и обязан существовать
в репозитории. Изменения списка (добавление, удаление, переименование) — через
MR + ревью владельца (см. раздел **Owner** выше).

`router.md` — единственный источник правды для состава routes. `catalog.md` не
дублирует список, чтобы избежать дрейфа.

## Path-scoped rules (источник)
Правила живут в `.ai/rules/*.md` (frontmatter `name`/`description`/`globs`/`always_apply` + тело) и **генерируются** компилятором в `.cursor/rules/*.mdc`. Вручную `.mdc` не редактировать.
- `.ai/rules/angular.md` → `.cursor/rules/angular.mdc` — Angular (`*.component.ts`, `*.service.ts`, `app/**`): standalone, signals, OnPush, слои, a11y.
- `.ai/rules/dotnet-testing.md` → `.cursor/rules/dotnet-testing.mdc` — `src/**/*.cs`: xUnit + Moq, без NUnit.
