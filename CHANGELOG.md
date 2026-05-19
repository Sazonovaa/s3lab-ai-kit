# Changelog

Все значимые изменения kit'а фиксируются здесь. Формат — [Keep a Changelog](https://keepachangelog.com/),
версии — [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.2.1] — CRLF protection

### Added
- `.gitattributes` enforcing LF line endings for shell scripts (`*.sh`, `bin/sync-ai-kit`,
  `bin/new-project`), markdown, YAML, JSON, and `*.tmpl` files.

### Why
- When kit was first uploaded via GitHub web UI / on certain Windows/macOS setups with
  `core.autocrlf=true`, shell scripts got CRLF line terminators. This breaks shebang
  lines: `#!/usr/bin/env bash` becomes `#!/usr/bin/env bash\r`, and the OS tries to
  run a non-existent interpreter named `bash\r`, producing:
  `env: bash\r: No such file or directory`.
- With `.gitattributes` enforcing `eol=lf`, git normalises line endings on commit/checkout
  regardless of platform.

### Migration for existing projects
- Update kit in projects: `git submodule update --remote .ai-kit`
- If submodule shows files modified after pull (`bin/sync-ai-kit`, etc.), run inside the
  submodule: `git checkout .` to apply the LF normalisation.

## [0.2.0] — monorepo guidance

### Added
- `docs/multirepo.md` — подробный гайд по миграции из двух репозиториев в монорепо
  с сохранением истории через `git subtree`.
- В `ai/workflow.md` явно зафиксировано предположение о monorepo как требование
  для работы pipeline'а.

### Why
- Pipeline `/feature` критически зависит от способности атомарно изменять backend
  и frontend в одном коммите (особенно для синхронизации OpenAPI ↔ TypeScript client).
- Multi-repo setup ломает это требование — задача требует 3 скоординированных PR,
  что для соло-разработчика создаёт неприемлемый оверхед.
- Альтернативные подходы (meta-repo с submodules, изолированные репы) описаны в
  multirepo.md с указанием их компромиссов.

## [0.1.0] — initial release

### Added
- Базовая структура kit: `ai/`, `cursor-rules/`, `adapters/`, `templates/`, `bin/`.
- `ai/core.md` — главный контекст, импортируемый проектами.
- `ai/stack.md` и `ai/workflow.md` — стек и пайплайн.
- Conventions: `dotnet`, `angular`, `rabbitmq`, `postgres`, `identity-auth`, `git`, `security`.
- Субагенты: `orchestrator`, `backend-dotnet`, `frontend-angular`, `api-contract`,
  `devops`, `reviewer`, `tester`, `designer`.
- Команды: `feature`, `bugfix`, `review-pr`, `sync-contract`.
- Cursor rules: core (alwaysApply), path-scoped для dotnet и angular,
  description-based для остальных областей.
- Адаптеры: `CLAUDE.md.tmpl`, `AGENTS.md.tmpl`, `project-context.md.tmpl`.
- Шаблоны: GitHub workflows для backend/frontend CI и deploy на VPS,
  ADR-шаблон, шаблоны issue/PR.
- `bin/sync-ai-kit` — идемпотентный установщик kit в проект.
- `bin/new-project` — bootstrap нового проекта с kit'ом.

### Compatibility
- macOS, Linux. Symlink-based, Windows не поддерживается.
- AI-инструменты: Claude Code, Cursor, Codex / GitHub Copilot CLI.
